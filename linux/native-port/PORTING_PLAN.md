# Native Linux Port Plan (No Wine)

This document tracks what is already done for the native Linux path and what comes next.

## Current Status

- Native `BSArch` CLI build works on Linux (`BSArch-linux` launcher -> `linux/bin/bsarch-core`).
- Linux platform compatibility layer exists in Pascal core (`wbPlatform` and helper units).
- Linux wrappers and start scripts are present (`start-bsarch.sh`, `linux/bsarch-ui.sh`).
- Native GUI exists as C++/Qt app (`BSArchSE`) with archive list workflows.
- GUI supports:
  - archive browsing + drag and drop
  - file list filtering/search/sorting
  - unpack selected
  - pack selected
  - archive info dialog
  - double-click open via `Tmp` extraction
- xEdit headless FPC build chain currently advances through:
  - `wbDefinitionsFO4.pas` (passes)
  - `wbDefinitionsFO76.pas` (passes)
  - `wbDefinitionsTES3.pas` (passes after FPC-guarded definition body)
- `xedit-core` headless build now links successfully via `linux/native-port/build-xedit-headless.sh`
- Headless smoke test now covers both `-h` and init path (`-dummy`) via
  `linux/native-port/smoke-test-xedit-headless.sh`
- FPC headless init no longer crashes in early FO4 common definitions:
  - `DefineCommon` uses a reduced bootstrap path under `FPC + XEDIT_HEADLESS`
  - keeps `xedit-core -dummy` stable for headless smoke checks
  - FPC branch now completes through `wbWorldVisibleCellsData` without early `DefineCommon` exit
  - `wbDATAPosRot` uses a headless FPC fallback (`DATA` byte-array) to avoid `wbVec3PosRot` init crash
  - default headless startup no longer emits a script-host warning unless `-scripthost` is explicitly requested
  - temporary `DefineCommon` exception swallowing in `DefineFO4` was removed after stabilization

## Completed Milestones

1. Dependency boundary setup
- Windows-specific calls were isolated enough for BSArch path.
- Linux-safe helper units were added.

2. Native BSArch CLI milestone
- `pack`, `unpack`, `list`, `dump` run natively on Linux.
- CLI launch path is now independent from Wine.

3. Native BSArch GUI milestone
- Python prototype replaced with C++/Qt (`BSArchSE`).
- KDE/Plasma workflow improved (Dolphin/start scripts/desktop entry).

## Open Work (Next)

1. Stabilization and startup hardening
- Verify Dolphin launch behavior across Plasma sessions.
- Add explicit fallback dialog when GUI cannot open.
  - Implemented in `linux/bsarch-ui.sh` (kdialog/zenity/xmessage fallback).
- Keep startup logs minimal and rotate/clean them.
  - Implemented log rotation + success trimming in `linux/bsarch-ui.sh`.

2. Functional parity checks
- Validate `Pack Selected` and `Unpack Selected` against large archives.
- Add regression tests for path normalization (`\\` vs `/`, root entries, nested folders).
- Validate `Tmp` cleanup behavior on crash and normal close.
- Implemented automated path regression script: `linux/native-port/regression-paths-bsarch.sh`.
- Implemented large-archive stress script: `linux/native-port/stress-large-bsarch.sh` (pack/list/unpack/launcher passthrough).

3. Packaging
- Ship `BSArchSE` and `bsarch-core` as one distributable artifact.
- Add desktop entry/icon install script defaults for user-level install.
- Add release checklist for Arch/Garuda.
- Implemented packaging script: `linux/native-port/package-bsarchse.sh`.
- Implemented release checklist: `linux/native-port/release-checklist-arch-garuda.md`.

4. Next native targets
- Evaluate `xDump` CLI feasibility with same platform abstraction model.
- Record blockers for full xEdit GUI migration (VCL forms, script host, registry assumptions).
- Implemented xEdit bootstrap doc: `linux/native-port/XEDIT_NATIVE_BOOTSTRAP.md`.
- Implemented xEdit readiness audit script/report:
  - `linux/native-port/xedit-readiness-audit.sh`
  - `linux/native-port/reports/xedit-readiness.txt`
- Started `xeInit` decoupling:
  - moved known-folder and registry-read access behind `wbPlatform` helpers
  - reduced direct platform-coupled calls in `xEdit/xeInit.pas`
  - moved async key-state checks to `wbPlatform.wbIsVirtualKeyPressed`
  - moved MO hook DLL initialization behind `wbPlatform.wbTryInitializeMOHook`
  - removed direct `Windows` unit dependency from `xeInit` (local VK constants)
- Started `xeMainForm` decoupling:
  - moved external URL launch to `wbPlatform.wbOpenUrl`
  - removed direct `ShellAPI` usage from `xEdit/xeMainForm.pas`
  - moved async key-state checks to `wbPlatform.wbIsVirtualKeyPressed`
  - moved sync key-state checks to `wbPlatform.wbIsVirtualKeyPressed`
  - moved direct clipboard read/write usage to `wbGetClipboardText`/`wbSetClipboardText`
- Extended `wbPlatform` helpers:
  - added `wbShowWindowNoActivate` wrapper for non-activating tip-form display
- Started `xejviScriptAdapterMisc` decoupling:
  - added `wbPlatform.OpenUrl` script API bridge
  - routed common `ShellExecute(open, URL)` path through `wbPlatform`
  - replaced script `CopyFile` binding with platform-neutral file copy logic
  - moved `CreateProcessWait` and `GetKeyState` bindings to `wbPlatform` wrappers
  - moved `ShellExecuteWait` and `Sleep` bindings to `wbPlatform` wrappers
  - moved `ShellExecute` binding to `wbPlatform` wrapper and removed direct `ShellApi` dependency
  - initially gated `TRegistryIniFile` script registration to Windows-only
  - reduced direct `Windows` unit dependence in script adapter with cross-platform show-window constants
  - gated clipboard adapter registration/implementation to Windows-only
  - removed remaining direct `Windows` unit import from `xejviScriptAdapterMisc.pas`
  - added `wbPlatform.*` alias registrations in script adapter for process/shell/file helpers
  - moved script `CopyFile` implementation to `wbPlatform.wbCopyFile`
  - replaced `Registry.TRegistryIniFile` script binding with cross-platform `TMemIniFile` alias
  - gated legacy `Windows.*` and `ShellApi.*` script registrations to Windows-only
  - moved clipboard read/write implementation to `wbPlatform` and added `wbPlatform` clipboard aliases
  - removed remaining `Vcl.Clipbrd` usage from `xeModGroupEditForm` by routing copy actions through `wbSetClipboardText`
  - removed unused `Windows`/`Messages` imports from `xeEditWarningForm` to reduce baseline WinAPI coupling
  - moved `xeTipForm` no-activate show path behind `wbShowWindowNoActivate` and dropped direct `Windows` import
  - removed `Windows` unit dependency from `xejviScriptAdapter.pas` by replacing `Int64Rec`-based conversion
  - gated `JvInterpreter_Windows` registration to Windows-only in `xejviScriptAdapter.pas`
  - removed direct `Windows` imports from `xeLocalizationForm` and `xeLocalizePluginForm`
  - replaced `MessageBox` usage in `xeLocalizePluginForm` with cross-platform `MessageDlg`
  - removed `Winapi.Windows` import from `xeRichEditForm` (retained `Messages` for `WM_KEYDOWN`)
  - replaced direct `GetKeyState` in `xeModGroupSelectForm` with `wbIsVirtualKeyPressed` and dropped `Windows`/`Messages` imports
  - moved `xeViewElementsForm` clipboard + compare-launch paths to `wbPlatform` (`wbSetClipboardText`, `wbCreateProcessWait`) and removed direct `Windows`/`ShellApi`/`Clipbrd` imports
  - removed direct `Windows`/`Messages` imports from `xeLODGenForm`, `xeFilterOptionsForm`, and `xeElementDetailForm`
  - replaced legacy `VK_ESCAPE` usage in `xeLODGenForm` and `xeFilterOptionsForm` with cross-platform `vkEscape`
  - removed direct `Windows`/`Messages` imports from `xeWaitForm`, `xeLegendForm`, and `xeLogAnalyzerForm`
  - replaced `GetKeyState` usage in `xeFileSelectForm` with `wbIsVirtualKeyPressed`, switched legacy VK constants to `vk*`, and removed `Windows`/`Messages` imports
  - removed `Winapi.Windows`/`Winapi.Messages` imports from `xeWorldspaceCellDetailsForm`
  - routed `xeDeveloperMessageForm` window-update locking through `wbPlatform.wbLockWindowUpdate` and dropped direct WinAPI imports
  - removed `Windows`/`Messages` imports from `xeOptionsForm` and switched to `vkEscape`
  - removed `Windows`/`Messages` imports from `xeModuleSelectForm`, replaced `GetKeyState` with `wbIsVirtualKeyPressed`, and switched legacy VK constants to `vk*`
  - removed direct `Windows` import from `xeScriptForm`, switched legacy VK constants to `vk*`, and replaced backup copy call with `wbCopyFile`
  - replaced direct `MessageBox` calls in `xeMainForm` rename/backup error paths with `MessageDlg`
  - replaced additional `Application.MessageBox` warnings in `xeMainForm` LOD flow with `MessageDlg`
  - removed `Windows`/`Messages` imports from `xeModGroupEditForm` and switched legacy VK constants to `vk*`
  - switched legacy VK constants to `vk*` in `xeRichEditForm` while keeping `Messages` import for `WM_KEYDOWN`
  - removed unnecessary `Vcl.Mask` imports from `xeMainForm`, `xeRichEditForm`, `xeModGroupEditForm`, `xeModGroupSelectForm`, and `xeModuleSelectForm`
  - removed `Vcl.Mask` import from `xeLogAnalyzerForm`
  - removed direct `Windows` import from `xePushLikeButton` by using local style-flag constants in `CreateParams`
  - removed direct `Windows` import from `xeMainForm` by defining local VK constants and replacing WinAPI directory-change notifications with portable timestamp polling loops
  - replaced `LockWindowUpdate` and warning message-box usages in additional `xeMainForm` paths with platform wrappers / `MessageDlg`
  - normalized many unit-scope names from `Vcl.*` to cross-scope unit names (`Graphics`, `Controls`, `Forms`, `Dialogs`, etc.) in key xEdit forms
  - reduced readiness audit output to mostly style/theme namespaces (`Vcl.Styles.*`, `Vcl.Themes`, and `Vcl.Samples.Spin`) rather than raw WinAPI dependencies
  - replaced `Vcl.Themes`/`Vcl.Styles` with `Themes`/`Styles` in `xeMainForm`
  - replaced `Vcl.Samples.Spin` with `Spin` (and normalized theme unit names) in options/cell-details forms
  - moved `xeRichEditForm` non-activating refresh lock from direct `LockWindowUpdate` to `wbPlatform.wbLockWindowUpdate`
  - kept `JvI/xejviScriptAdapterMisc` legacy script namespaces (`Windows`/`ShellApi`) as cross-platform aliases to existing `wbPlatform` wrappers for Linux script compatibility
  - improved `xejviScriptAdapterMisc` process/shell wrapper error reporting to use `wbPlatform.*` wording plus call context for Linux diagnostics
  - added Linux-specific `xeInit` fallback for `wbDataPath` detection by scanning common Steam install roots (`~/.steam`, `~/.local/share/Steam`, Flatpak Steam path) when command line / local path / Steam ID lookup do not resolve
  - gated Fallout New Vegas Epic (`EOSSDK-Win32-Shipping.dll`) profile-path override to `MSWINDOWS` in `xeInit`
  - cleaned `xeInit` registry path flow so registry variables/functions are compiled only on Windows (`MSWINDOWS`) and no longer participate in Linux code paths
  - extracted Windows registry install-path resolution in `xeInit` into a dedicated helper (`TryResolveWindowsInstallPathFromRegistry`) to keep `DoInitPath` platform branches simpler
  - added optional `XEDIT_DATA_PATH` environment override in `xeInit` to provide a direct non-registry/non-probe data path for headless/native runs
  - improved `XEDIT_DATA_PATH` handling to fall back to normal auto-detection when the env path is invalid, while keeping strict failure for invalid explicit `-D` path
  - normalized `XEDIT_DATA_PATH` handling to accept both game-root paths and direct data-folder paths
  - unified xEdit override normalization so both `-D` and `XEDIT_DATA_PATH` accept game-root or direct data-folder paths
  - added optional xEdit headless smoke env-override lane (`XEDIT_ENV_OVERRIDE_TEST=1`, `XEDIT_ENV_OVERRIDE_PATH=...`, `XEDIT_ENV_OVERRIDE_ARGS=...`) to validate `XEDIT_DATA_PATH` behavior on demand
  - added optional xEdit headless smoke CLI-override lane (`XEDIT_CLI_OVERRIDE_TEST=1`, `XEDIT_CLI_OVERRIDE_PATH=...`, `XEDIT_CLI_OVERRIDE_ARGS=...`) to validate `-D` path behavior
  - added optional xEdit headless negative lane (`XEDIT_INVALID_D_TEST=1`) to assert that invalid explicit `-D` paths fail with non-zero exit
  - wired `run-all-checks.sh` to forward xEdit env-override smoke knobs (`XEDIT_ENV_OVERRIDE_TEST`, `XEDIT_ENV_OVERRIDE_PATH`, `XEDIT_ENV_OVERRIDE_ARGS`) and print them in run config
  - wired `run-all-checks.sh` to forward xEdit CLI-override smoke knobs (`XEDIT_CLI_OVERRIDE_TEST`, `XEDIT_CLI_OVERRIDE_PATH`, `XEDIT_CLI_OVERRIDE_ARGS`) and print them in run config
  - converted additional Delphi inline-variable usages in xEdit/Core hot paths (`xeInitStyles`, `xeScriptForm` indent/dedent, `xeRichEditForm` TOC build, `wbTaskProgressExecute`, `xejviScriptHost` namespace rewrite/error reporting + selected-files branch, `xejviScriptAdapterMisc` math/string-set helpers, `xejviScriptAdapter` template/master helpers, `xeMainForm` message/master/template menu + focused-element/copy helpers + nav popup/formid/header-remove/WMUser + source-drag/apply-script + main-record-compare/nav-add/view-link paths, `xeModuleSelectForm` simulate-load path) to classic declarations for better FPC compatibility
  - gated Delphi-only reflection directives for FPC headless path (`{$METHODINFO ON}` in `Core/wbDefines.inc`, `{$RTTI ...}` in `xEdit/xedit-core.dpr`) to remove illegal-directive warning noise from Linux builds
  - completed `wbDefinitionsSF1.pas` helper decoupling pass for `var <name> := function(...)` patterns (hoisted to classic declarations/assignments for FPC compatibility)
  - completed full `wbDefinitionsSF1.pas` inline-var decoupling across helper arrays/enums/callbacks/record helpers (`ReferenceRecord`, quest alias helpers, LGDI helpers, PACK/RACE helpers, condition core block); active `var <name> :=`/`for var` usage in the unit is now removed (except commented legacy examples)
  - removed remaining inline-variable declarations in `wbDefinitionsFO4.pas` callback/index-key paths (classic `var` blocks for FPC compatibility)
  - normalized inline-variable declarations in `wbNifMath.pas` math/geometry helper paths (classic declarations for FPC compatibility)
  - replaced direct `SendMessage` usage with control `Perform` calls in `xeScriptForm` and `xePushLikeButton` to reduce API-coupled UI message calls
  - replaced remaining direct form-handle `SendMessage`/`PostMessage` calls in `xeMainForm` with `Perform` / `Self.PostMessage`
  - added `wbPlatform.TRegistryIniFile` script class alias in `xejviScriptAdapterMisc` alongside legacy `Registry.TRegistryIniFile` for cross-platform script namespace migration
  - added `wbPlatform` class aliases for `TCustomIniFile`/`TIniFile`/`TMemIniFile` in `xejviScriptAdapterMisc` to support namespace-neutral script migration
  - extended readiness audit core blocker patterns to flag regressions to global API `SendMessage(...)` / `PostMessage(...)` usage (while allowing method calls like `Self.PostMessage(...)`)
  - extended readiness audit core blocker patterns to also catch global API `MessageBox(...)`, `GetKeyState(...)`, `ShellExecute(...)`, and `CreateProcess(...)` regressions
  - replaced direct `GetKeyState` usage in `Core/wbHelpers.pas` console-capture terminate checks with `wbPlatform.wbIsVirtualKeyPressed(vkEscape)`
  - removed unused `Windows` unit import from `Core/wbLOD.pas`
  - replaced global `PostMessage(...)` calls in `Core/wbTaskProgress.pas` with `Self.PostMessage(...)`
  - removed unused `Windows` unit import from `Core/wbInterface.pas`
  - routed `Core/wbTaskProgress.pas` polling sleep through `wbPlatform.wbSleepMs`
  - gated `Core/wbTaskProgress.pas` taskbar COM integration under `MSWINDOWS` and replaced progress-text painting with `Canvas` drawing
  - routed `Core/wbHelpers.pas` alpha-blend helper through new `wbPlatform.wbPlatformAlphaBlend` wrapper (removes direct `Windows.AlphaBlend` call from helper layer)
  - moved taskbar capability gating from `Core/wbTaskProgress.pas` into `wbPlatform.wbSupportsTaskbarProgress`
  - moved taskbar progress COM state/operations (`ITaskbarList3`) from `Core/wbTaskProgress.pas` into `wbPlatform` (`wbTaskbarProgressInitialize/Show/Error/Hide`)
  - removed now-unused conditional `Windows` import from `Core/wbHelpers.pas` after wrapper migration
  - gated `Core/MSHeap.pas` Windows heap override behind `MSWINDOWS` so non-Windows builds keep default memory manager without WinAPI imports
  - updated readiness audit to split core blockers (WinAPI/Registry/Shell) from style-only namespace usage for clearer Linux-port tracking
  - replaced remaining `Vcl.Styles.*` namespace usages with `Styles.*` equivalents across key forms; readiness audit now reports zero core blockers and zero style-namespace matches
  - added readiness gate script `linux/native-port/check-xedit-readiness.sh` and CI workflow `.github/workflows/xedit-readiness-ci.yml` to enforce zero core blockers on push/PR
  - extended readiness gate with strict mode (`ENFORCE_STYLE=1`) and enabled it in CI to keep style namespace usage at zero as well
- configured xEdit readiness CI to run with `RUN_BSARCH=0` so the lane stays focused on xEdit/readiness checks
- added optional headless smoke script `linux/native-port/smoke-test-xedit-headless.sh` and wired CI to run it when `linux/bin/xedit-core` is available
- smoke script now supports multi-case runs (`XEDIT_HEADLESS_CASES`, default `-h|-dummy`) and treats non-zero exit codes as failures
- xDump smoke script now supports an optional mode-init sanity lane (`XDUMP_MODE_SANITY_TEST=1`) to exercise `-TES5 -Dump ...` without requiring real assets and fail on AV/segfault patterns
- xDump smoke script now supports an optional negative explicit-path lane (`XDUMP_INVALID_D_TEST=1`) to assert invalid explicit `-D` paths fail with non-zero exit code
- xDump mode/invalid-path lanes now also assert expected log semantics (mode switches resolve in mode lane; invalid `-D` emits missing data-path error)
- added `linux/native-port/ci-preflight.sh` as shared CI entry point to run all native-port checks with consistent permissions and strict-style gating
  - started xDump CLI decoupling:
  - guarded Windows-only imports and PE flags behind `MSWINDOWS`
  - routed registry lookup through `wbTryReadRegistryString` (Windows only)
  - normalized data path suffix to `Data` + `PathDelim` for cross-platform paths
  - added Linux build helper: `linux/native-port/build-xdump.sh`
  - xDump Linux build now also compiles with `-dXEDIT_HEADLESS`, aligning definition/init behavior with the stabilized headless runtime path used by xEdit
  - made LZ4 Pascal units tolerate non-Windows builds (CPU defines + non-Windows uses)
  - made `xDump.dpr` FPC-friendly in key startup paths (removed inline-var usage, removed `ToLowerInvariant`/`Contains` dependence, guarded debug-only `DebugHook` usage)
  - made Linux resource inclusion optional for xDump (`{$R *.res}` guarded to Windows)
  - removed unused xDump entrypoint dependencies (`ZlibEx`, `lz4`, `wbPlatform`) and dead helpers (`isMode`, unused `ProgramPath`, unused profile alias) to keep headless/native build path cleaner
  - removed unused direct `Windows`/`Registry` imports from `xDump.dpr` (registry access remains routed through `wbPlatform.wbTryReadRegistryString`)
  - gated xDump `{$MAXSTACKSIZE}` directive to Windows to avoid Linux-target warning noise in headless builds
  - gated xDump `{$APPTYPE CONSOLE}` to Windows to avoid unsupported-directive note noise in Linux/FPC builds
  - replaced `wbDefProfiles` pointer/integer object-state hack in `xDump.dpr` with typed `TProfileState` objects and explicit cleanup to avoid pointer/ordinal portability warnings in profile tracking paths
  - normalized several pointer-arithmetic counters in `Core/wbDefinitionsTES5Saves.pas` (`ChangedForm*`, `DumpCounter`, `DataLengthRemainderCounter`) to `PtrUInt`-based math for better cross-platform portability in FPC builds
  - completed follow-up cleanup for `Core/wbDefinitionsTES5Saves.pas` pointer deltas via `NativeUInt` helper paths (`wbPtrDiffNative`, `wbSubtractConsumed`), eliminating remaining `Conversion between ordinals and pointers is not portable` hints for that unit in xDump headless builds
  - removed unused `Math` dependency from `Core/wbDefinitionsTES5Saves.pas` to keep xDump/FPC warning surface smaller
  - hardened local `IOUtils` compatibility shims (`IOUtils.pas`, `System.IOUtils.pas`) to use explicit local result buffers in `GetFiles`, removing managed-result initialization warnings from xEdit/xDump FPC headless builds
  - cleaned `System.*` shim import warnings by gating `System.IOUtils`'s `IOUtils` dependency to non-FPC and adding explicit `System.Diagnostics` type aliases (`TTimeSpan`, `TStopwatch`)
  - removed additional low-risk unused-unit warnings in common shim/core units (`System.Types`, `Graphics`, `Core/wbSteamVDFParser.pas`, `Core/wbStreams.pas`) to keep headless build output cleaner while preserving behavior
  - removed redundant `SyncObjs` import from `System.SyncObjs.pas` wrapper to silence shim warning noise in xEdit/xDump headless builds
  - removed unused `Math` imports from save/definition units where no math helpers are referenced (`Core/wbDefinitionsFO76.pas`, `Core/wbDefinitionsFNVSaves.pas`, `Core/wbDefinitionsFO3Saves.pas`, `Core/wbDefinitionsFO4Saves.pas`, `Core/wbDefinitionsTES4Saves.pas`)
  - trimmed additional unused standard imports from `Core/wbDefinitionsTES5.pas` (`Types`, `Math`, `IOUtils`) while retaining compatibility/signature units
  - removed unused `Types`/`Generics.Collections` imports from `Core/wbLoadOrder.pas` (interface + implementation) to reduce warning noise in headless builds
  - removed unused `System.Types` import from `Core/wbDefinitionsCommon.pas`
  - removed additional unused imports from definition units (`Types` in `Core/wbDefinitionsTES4Saves.pas`, `IOUtils` in `Core/wbDefinitionsFO76.pas`) while keeping xEdit/xDump headless smokes green
  - removed unused `wbBSA`/`WideStrUtils` imports from `Core/wbLocalization.pas`; normalized `Core/wbImplementation.pas` zlib unit reference to `ZlibEx` for Linux/FPC file-case compatibility
  - gated `Core/wbInterface.pas` `System.Types`/`System.SysUtils`/`System.UITypes` imports to non-FPC builds to eliminate FPC headless unused-unit hints without changing Delphi behavior
  - cleaned `Core/wbHelpers.pas` unused import surface (removed unused `System.*` and `ImagingTypes` refs in interface/implementation uses lists) while keeping xEdit/xDump headless smoke lanes passing
  - removed unused `Contnrs` / `System.SyncObjs` imports from `Core/wbImplementation.pas` (no matching symbols used under current build flags)
  - removed unused `System.Diagnostics`/`lz4io`/`ZlibEx` imports from `Core/wbBSA.pas`; normalized `Core/wbBSArchive.pas` zlib unit reference to `ZlibEx` for Linux file-case compatibility
  - reduced additional FPC headless hint noise by suppressing unused element-range parameters in `Core/wbDefinitionsTES5Saves.pas` decider/counter helpers (`wbIgnoreElementRange` rollout, early+mid helper blocks)
  - moved `TxeScriptHost.Create` to public API (`reintroduce`) in `xEdit/xeScriptHost.pas` to remove FPC visibility warning while keeping dynamic host construction paths intact
  - extended compatibility wrappers used by xDump path:
    - `System.Classes`: `TFiler`/`TReader`/`TWriter`, lightweight `TDataModule`
    - `System.SysUtils`: `FileExists`
    - `ZlibEx`: added `ZDecompressStream`
  - updated xDump smoke/build scripts:
    - `smoke-test-xdump-headless.sh` now detects `linux/bin/xDump` fallback
    - `smoke-test-xdump-headless.sh` now supports multi-case runs (`XDUMP_HEADLESS_CASES`, default `-h|-dummy`) and fails on non-zero exit codes
    - `smoke-test-xdump-headless.sh` now supports optional env-override smoke lane (`XDUMP_ENV_OVERRIDE_TEST=1`, `XDUMP_ENV_OVERRIDE_PATH=...`, `XDUMP_ENV_OVERRIDE_ARGS=...`) to validate `XDUMP_DATA_PATH`
    - `smoke-test-xdump-headless.sh` now supports optional CLI-override smoke lane (`XDUMP_CLI_OVERRIDE_TEST=1`, `XDUMP_CLI_OVERRIDE_PATH=...`, `XDUMP_CLI_OVERRIDE_ARGS=...`) to validate `-D` path behavior
    - xDump smoke now supports optional base mode args (`XDUMP_BASE_MODE_ARGS`) so override lanes can opt into explicit mode switches when needed
    - `build-xdump.sh` now normalizes FPC default `xDump` output to `linux/bin/xdump-core`
  - normalized `XDUMP_DATA_PATH` handling to accept both game-root paths and direct data-folder paths
  - unified xDump override normalization so both `-D` and `XDUMP_DATA_PATH` accept game-root or direct data-folder paths
  - added consolidated headless loop runner: `linux/native-port/headless-build-smoke.sh` (`RUN_XEDIT`/`RUN_XDUMP`/`BUILD_ONLY` toggles) for faster xEdit/xDump decoupling verification
  - `headless-build-smoke.sh` now writes a deterministic current transcript (`/tmp/xedit-headless-current.log`) and syncs the legacy path (`/tmp/xedit-headless.log`) for stable follow-up parsing
  - `headless-build-smoke.sh` now enforces a strict hint gate by default (`FAIL_ON_HINTS=1`) and fails on non-allowlisted `Hint:` lines (gate can be disabled with `FAIL_ON_HINTS=0`, allowlist tuned via `HINT_ALLOWLIST_REGEX`)
  - verified:
    - `linux/native-port/build-xdump.sh` succeeds and produces `linux/bin/xdump-core`
    - `linux/native-port/smoke-test-xdump-headless.sh` passes (`-h`, `-dummy`, mode-sanity, invalid-`-D` lane)

## Risks

- Large VCL surface area still blocks direct xEdit GUI port.
- Script host and plugin assumptions may still include Windows-only behavior.
- FPC/Linux still relies on reduced/simplified definition handling in multiple sections (byte-array fallbacks, reduced structures); full `DefineCommon` parity is not complete yet.
- GUI usability parity with original BSArchPro still needs incremental tuning.
- xDump mode-init now has dedicated headless coverage (`XDUMP_MODE_SANITY_TEST=1` + `XDUMP_INVALID_D_TEST=1`), but broader real-data validation is still pending.

## Immediate Action List

1. Add smoke test script for BSArchSE:
- Implemented: `linux/native-port/smoke-test-bsarch.sh`
- Automated: core pack/list/unpack roundtrip + launcher CLI passthrough
- Manual checklist included for GUI actions (`Unpack Selected`, `Pack Selected`, `Archiv-Info`, double-click open)
- Added convenience runner: `linux/native-port/run-all-checks.sh` (strict readiness + BSArch checks + optional xEdit headless smoke)
- Runner now supports toggles for quicker local loops (`RUN_BSARCH_STRESS=0`, `RUN_BSARCH=0`, `RUN_XEDIT_HEADLESS=0`, `RUN_XDUMP_HEADLESS=0`)
- Runner now also supports readiness mode toggle (`ENFORCE_STYLE=1` strict, `ENFORCE_STYLE=0` core-only)
- Added xEdit inline-var regression guard: `linux/native-port/check-xedit-inline-vars.sh` (wired via `RUN_XEDIT_INLINE_GUARD=1` in `run-all-checks.sh`)
- Added xEdit Winapi-import regression guard: `linux/native-port/check-xedit-winapi-imports.sh` (wired via `RUN_XEDIT_WINAPI_GUARD=1` in `run-all-checks.sh`)
- Extended xEdit Winapi guard with direct-call regression checks (`GetKeyState`, `CreateProcess`, `ShellExecute`, `MessageBox`, `SendMessage`, `PostMessage`, `Windows.AlphaBlend`, `Windows.LockWindowUpdate`) while allowlisting platform-layer implementations in `Core/wbPlatform.pas`
- Tightened xEdit Winapi guard import allowlist to `Core/wbPlatform.pas` and `Core/MSHeap.pas` only
- Added Core Winapi-import regression guard: `linux/native-port/check-core-winapi-imports.sh` (wired via `RUN_CORE_WINAPI_GUARD=1` in `run-all-checks.sh`, allowlisted only for `Core/wbPlatform.pas` and `Core/MSHeap.pas`)
- Added xDump Winapi-import regression guard: `linux/native-port/check-xdump-winapi-imports.sh` (wired via `RUN_XDUMP_WINAPI_GUARD=1` in `run-all-checks.sh` for `xDump.dpr` import/direct-call checks)
- Runner now builds `xDump` before xDump headless smoke when `RUN_XDUMP_HEADLESS=1`, mirroring xEdit headless flow.
- Runner now degrades gracefully when `fpc` is unavailable: xDump smoke is skipped only if no prebuilt xDump binary exists.
- xEdit/xDump build helpers now use per-target `flock` locks (`linux/bin/.xedit-core.build.lock`, `linux/bin/.xdump-core.build.lock`) so parallel local/CI checks do not race in shared build output.
- Added headless warning budget guard:
  - `linux/native-port/check-headless-warning-budget.sh`
  - baseline file `linux/native-port/baselines/headless-warning-budget.env`
  - baseline updater `linux/native-port/update-headless-warning-budget.sh` (refuses budget increases unless `ALLOW_INCREASE=1`)
  - tracks both total warning counters and project-only counters (`*.pas(...) Warning:`)
  - total warning budget enforcement is optional via `ENFORCE_TOTAL_WARNING_BUDGET=1` (default `0`)
  - summary report generator `linux/native-port/report-headless-warning-summary.sh` (writes `linux/native-port/reports/headless-warning-summary.txt`)
  - history append helper `linux/native-port/append-headless-warning-history.sh` (writes `linux/native-port/reports/headless-warning-history.tsv`)
  - trend report generator `linux/native-port/report-headless-warning-trend.sh` (writes `linux/native-port/reports/headless-warning-trend.txt`)
  - hotspot report generator `linux/native-port/report-headless-warning-hotspots.sh` (writes `linux/native-port/reports/headless-warning-hotspots.txt`)
  - integrated into `run-all-checks.sh` via `RUN_WARNING_BUDGET_GUARD=1`
  - integrated into `run-all-checks.sh` via `RUN_WARNING_SUMMARY_REPORT=1`
  - integrated into `run-all-checks.sh` via `RUN_WARNING_HISTORY_APPEND=1`
  - integrated into `run-all-checks.sh` via `RUN_WARNING_TREND_REPORT=1`
  - integrated into `run-all-checks.sh` via `RUN_WARNING_HOTSPOT_REPORT=1`
  - currently enforces:
    - `MAX_WARNING_LINES=56`
    - `MAX_ACTIONABLE_WARNING_LINES=0`
    - `MAX_UNIQUE_WARNING_LINES=52`
    - `MAX_UNIQUE_ACTIONABLE_WARNING_LINES=0`

2. Add basic CI job (Linux) for:
- Implemented workflow: `.github/workflows/bsarch-linux-ci.yml`
- Builds `BSArchSE` (Qt) on Ubuntu
- Always runs `linux/native-port/ci-preflight.sh`:
  - full checks when `linux/bin/bsarch-core` exists
  - readiness-focused checks otherwise
- Uploads readiness report artifact (`bsarch-ci-xedit-readiness-report`) for each run
- Uploads headless smoke log artifact (`bsarch-ci-headless-log`) for each run when available
- Uploads headless warning summary/trend/hotspot artifacts for each run when available

3. Finalize launcher behavior:
- `BSArch-linux` should remain the single entry point for users.
- Implemented in docs/install scripts: `BSArch-linux` is the default command and desktop launcher target.
- `BSArch-UI` and `start-bsarch.sh` remain compatibility aliases.
