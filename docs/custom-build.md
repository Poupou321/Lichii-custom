# Lichii Custom Windows x64

Extract this archive to a NEW directory, separate from build 95. Keep `user/config/` beside
lichii.exe. All emulator data for this package goes into its own user directory. Do not choose
migration or point it at the existing installation. No saved games, firmware, keys, ROMs or
precompiled game shaders are distributed. Do not extract A over B or either over build 95.
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
