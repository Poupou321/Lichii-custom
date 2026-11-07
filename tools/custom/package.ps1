$ErrorActionPreference = 'Stop'
$manifest = Get-Content custom-build.json -Raw | ConvertFrom-Json
$stage = Join-Path $env:GITHUB_WORKSPACE 'stage'
New-Item -ItemType Directory -Force $stage, artifacts, diagnostics | Out-Null
foreach ($exe in 'lichii.exe', 'eden-cli.exe') {
    if (-not (Test-Path "build/release/bin/$exe")) { throw "Missing $exe" }
}
# Preserve bundled SDL/FFmpeg and other runtime files, excluding test executables.
Copy-Item build/release/bin/* $stage -Recurse -Force
Get-ChildItem $stage -File -Filter *.exe | Where-Object Name -NotIn 'lichii.exe','eden-cli.exe' | Remove-Item
Get-ChildItem $stage -Recurse -File -Include *.pdb,*.ilk,*.lib,*.exp | Remove-Item
windeployqt --release --no-compiler-runtime --no-translations --no-opengl-sw --dir $stage --plugindir "$stage/plugins" "$stage/lichii.exe"
if ($LASTEXITCODE -ne 0) { throw 'Qt deployment failed' }
$crt = Join-Path $env:VCToolsRedistDir 'x64/Microsoft.VC143.CRT'
if (-not (Test-Path $crt)) { throw 'MSVC redistributable DLL directory unavailable' }
Copy-Item "$crt/*.dll" $stage -Force
@('[Paths]', 'Plugins=plugins') | Set-Content "$stage/qt.conf"
foreach ($file in 'lichii.exe','eden-cli.exe','Qt6Core.dll','Qt6Gui.dll','Qt6Widgets.dll','plugins/platforms/qwindows.dll','vcruntime140.dll','msvcp140.dll') {
    if (-not (Test-Path "$stage/$file")) { throw "Missing packaged file: $file" }
}
$report = [System.Collections.Generic.List[string]]::new()
foreach ($binary in Get-ChildItem $stage -Recurse -File | Where-Object Extension -In '.exe','.dll') {
    $headers = & dumpbin /headers $binary.FullName
    if ($LASTEXITCODE -ne 0 -or -not ($headers -match '8664 machine')) { throw "Not an x64 PE: $binary" }
    $imports = & dumpbin /dependents $binary.FullName
    if ($LASTEXITCODE -ne 0) { throw "Cannot inspect imports: $binary" }
    foreach ($line in $imports) {
        if ($line -match '^\s+([\w.\-]+\.dll)\s*$') {
            $dll = $Matches[1]
            $bundled = (Test-Path "$stage/$dll") -or (Test-Path (Join-Path $binary.DirectoryName $dll))
            $apiSet = $dll -match '^(api-ms-|ext-ms-)'
            $system = (Test-Path "$env:WINDIR/System32/$dll") -and $dll -notmatch '^(msvcp|vcruntime|concrt)'
            # The Vulkan loader and ICD are supplied by the existing graphics driver.
            $vulkan = $dll -ieq 'vulkan-1.dll'
            if (-not ($bundled -or $apiSet -or $system -or $vulkan)) { throw "Unresolved DLL $dll imported by $($binary.Name)" }
            $report.Add("$($binary.Name): $dll; bundled=$bundled; windows=$system; apiSet=$apiSet; driver=$vulkan")
        }
    }
}
$report | Set-Content diagnostics/dll-imports.txt
# Both directories are materialized in the ZIP, preventing global-data fallback and migration prompts.
New-Item -ItemType Directory -Force "$stage/user/config" | Out-Null
'Isolated portable data. Keep this directory. Never extract over your build-95 installation.' | Set-Content "$stage/user/config/README.txt"
Copy-Item custom-build.json "$stage/COMMITS.json"
Copy-Item docs/custom-build.md "$stage/README-CUSTOM.md"
Copy-Item docs/custom-shaders-fr.md "$stage/README-SHADERS-FR.md"
Copy-Item LICENSE.txt "$stage/LICENSE.txt"
git log --format=fuller "$($manifest.reference)..HEAD" | Set-Content "$stage/COMMITS.txt"
"Source: https://github.com/$env:GITHUB_REPOSITORY/tree/$env:GITHUB_SHA`nRun: https://github.com/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID" | Set-Content "$stage/BUILD.txt"
Copy-Item diagnostics "$stage/validation" -Recurse
# Confirm the GUI loads from the package without Qt/SDK directories in PATH; no game is opened.
$oldPath = $env:PATH
$oldPlugin = $env:QT_PLUGIN_PATH
$oldPlatform = $env:QT_QPA_PLATFORM_PLUGIN_PATH
$oldQpa = $env:QT_QPA_PLATFORM
try {
    $env:PATH = "$stage;$env:WINDIR/System32;$env:WINDIR"
    $env:QT_PLUGIN_PATH = "$stage/plugins"
    $env:QT_QPA_PLATFORM_PLUGIN_PATH = "$stage/plugins/platforms"
    $env:QT_QPA_PLATFORM = 'windows'
    $env:QT_DEBUG_PLUGINS = '1'
    $process = Start-Process "$stage/lichii.exe" -WorkingDirectory $stage -PassThru -RedirectStandardError diagnostics/gui-stderr.txt -RedirectStandardOutput diagnostics/gui-stdout.txt
    if ($process.WaitForExit(15000)) { throw "Packaged GUI exited early: $($process.ExitCode)" }
    Stop-Process -Id $process.Id -Force
    $log = Get-Content diagnostics/gui-stderr.txt -Raw
    if ($log -match 'Could not load the Qt platform plugin|no Qt platform plugin could be initialized') { throw 'Qt platform plugin load failed' }
    'GUI process remained alive for 15 seconds with packaged Qt and sanitized PATH. No game/GPU validation.' | Set-Content diagnostics/gui-smoke.txt
} finally {
    $env:PATH = $oldPath
    $env:QT_PLUGIN_PATH = $oldPlugin
    $env:QT_QPA_PLATFORM_PLUGIN_PATH = $oldPlatform
    $env:QT_QPA_PLATFORM = $oldQpa
    Remove-Item Env:QT_DEBUG_PLUGINS -ErrorAction SilentlyContinue
    if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
}
# Discard all smoke-test generated configuration, logs and profiles before distribution.
Remove-Item "$stage/user" -Recurse -Force
New-Item -ItemType Directory -Force "$stage/user/config" | Out-Null
'Isolated portable data. Keep this directory. Never extract over your build-95 installation.' | Set-Content "$stage/user/config/README.txt"
Copy-Item diagnostics/* "$stage/validation" -Recurse -Force
$zip = "artifacts/lichii-custom-$($manifest.variant)-windows-x64-$($env:GITHUB_SHA.Substring(0,10)).zip"
Compress-Archive "$stage/*" $zip -CompressionLevel Optimal
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $([IO.Path]::GetFileName($zip))" | Set-Content "$zip.sha256"
"Portable archive: $zip`nSHA256: $hash" | Add-Content $env:GITHUB_STEP_SUMMARY
