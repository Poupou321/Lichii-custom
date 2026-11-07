# Lichii Custom Windows x64

Extract this archive to a NEW directory, separate from build 95. Keep `user/config/` beside
lichii.exe. All emulator data for this package goes into its own user directory. Do not choose
migration or point it at the existing installation. No saved games, firmware, keys, ROMs or
precompiled game shaders are distributed. Do not extract one custom build over another or over build 95.
Updates and Discord presence are disabled at compile time. No driver change is required by
this package. Existing AMD Vulkan-capable drivers are needed to play.

Reference: 222877d4f7c8945b2f31a87b76d09f0a92e4f1b8, upstream build 95 (release tag build-94).
The complete source and original authorship are retained in Git history. `COMMITS.json` lists
pinned upstream heads and excluded pieces; `COMMITS.txt` lists integrated history. `BUILD.txt`
links the exact source and Actions run. This code is experimental, without measured RX 7800 XT
FPS gains. A successful CI build is not a game stability or GPU correctness result.

## Integration resolutions

PR 408 conflicts with build 95 in four files:
- host_memory.cpp: retain the existing build-95 move/fallback implementation and allocation tests;
  do not apply a second competing implementation.
- core.cpp: keep ErrorMemoryAllocation propagation and catch failed guest RAM reallocation
  after stop; retain PR 408's event/process teardown ordering.
- spirv_emit_context.cpp: keep all build-95 global atomics and apply DontInline to their helpers.
- vk_rasterizer.h: retain both the build-95 fragment-output mask and PR 408's OOT bypass state.

PR 465 and both commits of PR 463 applied without textual conflicts after PR 408.
PR 437's current branch merges unrelated post-build-95 nx2 changes; that branch is not merged.
Its documentation is ported in B. Its earlier NaN change is superseded by upstream PR 432,
which is included once in B. PR 432's already-present version-54 bump is not applied twice.
PR 437's shader-cache migration is excluded: PR 408 changes graphics keys and deliberately
invalidates those shader caches. Its driver-cache fallback is already implemented by PR 408.
B uses cache version 55 to distinguish its conservative vertex keys and NaN output from A.
A uses version 54. Their separate portable user directories also isolate caches and saves.

## Test and packaging gates

The runner configures Release with tests enabled, builds all default targets and runs all
registered CTest tests. Any build or test failure withholds the portable archive; diagnostics
remain available. No failing test is silently excluded or declared pre-existing without a
matching baseline run. Qt runtime deployment, recursive x64 PE import checks and a 15-second
GUI load test with a sanitized PATH precede ZIP creation. The GUI smoke test opens no game.
Its configuration and profiles are discarded before packaging. `validation/` contains the
actual logs for a successful archive; the Actions diagnostics artifact records failures.
No local Windows, RX 7800 XT, 1440p gameplay, long-session or save-load validation has been
performed by this automation. The GUI smoke test only checks process survival and Qt loading.

## First comparison on your hardware

Start with Vulkan, GPU accuracy High, async shaders enabled and ordinary game defaults.
High can reduce performance by disabling split GPU processing, but is useful as a rendering
comparison. Compare Normal separately and check fog, foliage and textures. Preserve the
same settings and scene across A/B. Compare cold-cache and warm-cache sessions separately.
Do not reuse the original installation's cache or saves directly. If you later test a save,
use a disposable COPY in this package and keep the original untouched.

A includes the complete PR 408 vertex-key mask, which has an unresolved AMD black-title-screen
report: https://github.com/zortos293/Lichii/pull/408#issuecomment-6700864827 . It is a diagnostic
comparison, not the preferred AMD candidate. B keeps every VertexA/VertexB attribute type,
while retaining key reduction for task/mesh programs. This is mitigation, not a proven fix.

B: Native async draws remains Wait by default. Optionally compare Bounded with an 8 ms budget
under Graphics > Advanced. Bounded/Skip can omit pending draws and produce flashes.
EDEN_NX2_ASYNC_DISCARD=1 forces Skip; leave it unset for the first comparison.
PR 463's stale-upload optimization is enabled in B; EDEN_NX2_TC_SKIP_STALE=0 disables it
for a comparison if artifacts appear. EDEN_NX2_TC_LOG=1 enables its counters.
The OOT network bypass from PR 408 stays at Game by default. No sharpening is an optional
separate comparison, not a required AMD setting. Do not enable multiple experiments together.

## Windows test portability

The NUP metadata test closes its first reader before replacing the same temporary archive
again: Windows forbids replacing an archive while those read handles remain open. All
assertions are retained and the NUP writer/loader application code is unchanged from build 95.
The bundled zlib has installation disabled; its standalone installation/example tests are
also disabled with ZLIB_BUILD_TESTING=OFF. All Lichii CTest targets remain enabled.
The other Windows test fixes only give the existing expected opcode/count constants
matching unsigned types. PR 408's local bypass pointer is renamed to avoid member shadowing.

## Variant C — AMD distant terrain texture seams

C starts from B with upstream PR #448. It keeps uneven-block-mip ASTC textures in RGBA8 rather than BC1/BC3 on AMD, addressing grid-like dark lines in distant terrain. It may use more VRAM. To disable, set `EDEN_NX2_UNEVEN_BCN_RGBA8=0` before starting; default is enabled for AMD. Compare B and C at identical settings, and preserve the originals. This is not yet tested on RX 7800 XT.

## Variant D — OoT fog/sky light-probe correction

D adds upstream #351 to C. The game samples lighting probes beyond the previous 64 MiB
read-only table-pointer buffer limit, causing blown-out white fog. Read-only table pointers
now bind to the end of the mapping, limited by the driver and 1 GiB. Writable buffers are
unchanged. The Vulkan TickFrame conflict was resolved by keeping the pre-existing
multi_range_buffers.TickFrame call; only GetMaxStorageBufferRange was added.

This build may reveal other unrelated graphics issues and is not RX 7800 XT-tested.
Compare D against C on the same scene and settings. Preserve all old builds. Do not
reuse or migrate production saves; use a disposable copy.

D test integration: the buffer-cache mock exposes its storage-buffer range capability.
The existing read-only table test now expects the complete 80 MiB mapping, as required
by #351; written/native caps are still checked. Additional cases verify a 128 MiB device
limit and the 1 GiB software limit. All Lichii tests remain enabled.
The custom workflow is manual-only (workflow_dispatch); push triggering is removed.
