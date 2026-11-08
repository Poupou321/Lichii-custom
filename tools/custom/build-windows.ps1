param(
    [Parameter(Mandatory=$true)][ValidateSet('official117','F')][string]$Label,
    [Parameter(Mandatory=$true)][string]$BuildDirectory
)
$ErrorActionPreference = 'Stop'
$diag = Join-Path $env:GITHUB_WORKSPACE "diagnostics/$Label"
New-Item -ItemType Directory -Force $diag | Out-Null
$actual = (git -C source rev-parse HEAD).Trim()
$manifest = Get-Content custom-build.json -Raw | ConvertFrom-Json
$expected = if ($Label -eq 'official117') { $manifest.reference } else { $env:GITHUB_SHA }
if ($actual -ne $expected) { throw "Incorrect $Label source: $actual expected $expected" }
"Source: $actual`nCompiler: clang-cl 22.1.8, Release, ThinLTO + official OoT PGO profile" | Set-Content "$diag/source.txt"
Get-FileHash source/lichii-windows.profdata -Algorithm SHA256 | Format-List | Out-File "$diag/profile.txt"
$profile = (Resolve-Path source/lichii-windows.profdata).Path.Replace('\','/')
$common = "-DWIN32 -D_WINDOWS -DNOMINMAX -flto=thin -fprofile-use=$profile -Wno-error=profile-instr-out-of-date -Wno-error=profile-instr-unprofiled -Wno-error=backend-plugin"
$tag = if ($Label -eq 'official117') { 'build-117' } else { "custom-F-build117-$env:GITHUB_RUN_NUMBER" }
$flags = @(
    '-S', 'source', '-B', $BuildDirectory, '-G', 'Ninja',
    '-DCMAKE_BUILD_TYPE=Release', '-DBUILD_TESTING=ON', '-DYUZU_TESTS=ON',
    '-DENABLE_QT=ON', '-DYUZU_CMD=ON', '-DYUZU_ROOM=OFF', '-DYUZU_ROOM_STANDALONE=OFF',
    '-DYUZU_USE_BUNDLED_QT=OFF', '-DYUZU_USE_BUNDLED_SDL3=ON',
    '-DENABLE_UPDATE_CHECKER=ON', '-DUSE_DISCORD_PRESENCE=OFF', '-DENABLE_WERROR=ON',
    "-DCMAKE_PREFIX_PATH=$env:QT_ROOT_DIR", "-DCPM_SOURCE_CACHE=$env:CPM_SOURCE_CACHE",
    '-DCMAKE_C_COMPILER_LAUNCHER=ccache', '-DCMAKE_CXX_COMPILER_LAUNCHER=ccache',
    "-DCMAKE_C_COMPILER=$env:LLVM_ROOT/bin/clang-cl.exe",
    "-DCMAKE_CXX_COMPILER=$env:LLVM_ROOT/bin/clang-cl.exe",
    "-DCMAKE_LINKER=$env:LLVM_ROOT/bin/lld-link.exe", "-DCMAKE_AR=$env:LLVM_ROOT/bin/llvm-lib.exe",
    "-DCMAKE_C_FLAGS=$common", "-DCMAKE_CXX_FLAGS=-EHsc $common",
    "-DLICHII_BUILD_TAG=$tag", '-DLICHII_BUILD_PLATFORM=windows-x86_64-pgo'
)
ccache --zero-stats
cmake @flags 2>&1 | Tee-Object "$diag/configure.txt"
if ($LASTEXITCODE -ne 0) { throw "$Label configure failed" }
$jobs = [Math]::Min(4, [int]$env:NUMBER_OF_PROCESSORS)
cmake --build $BuildDirectory --parallel $jobs -- -k 0 2>&1 | Tee-Object "$diag/build.txt"
$buildExit = $LASTEXITCODE
ccache --show-stats -v | Tee-Object "$diag/compiler-cache.txt"
if ($buildExit -ne 0) { throw "$Label build failed" }
ctest --test-dir $BuildDirectory --output-on-failure --no-tests=error --timeout 300 2>&1 | Tee-Object "$diag/ctest.txt"
$testExit = $LASTEXITCODE
if (Test-Path "$BuildDirectory/Testing/Temporary/LastTest.log") { Copy-Item "$BuildDirectory/Testing/Temporary/LastTest.log" "$diag/LastTest.log" }
if ($testExit -ne 0) { throw "$Label tests failed; no final archive" }
