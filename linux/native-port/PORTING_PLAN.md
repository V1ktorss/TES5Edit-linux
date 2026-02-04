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
- Keep startup logs minimal and rotate/clean them.

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
  - updated readiness audit to split core blockers (WinAPI/Registry/Shell) from style-only namespace usage for clearer Linux-port tracking
  - replaced remaining `Vcl.Styles.*` namespace usages with `Styles.*` equivalents across key forms; readiness audit now reports zero core blockers and zero style-namespace matches
  - added readiness gate script `linux/native-port/check-xedit-readiness.sh` and CI workflow `.github/workflows/xedit-readiness-ci.yml` to enforce zero core blockers on push/PR
  - extended readiness gate with strict mode (`ENFORCE_STYLE=1`) and enabled it in CI to keep style namespace usage at zero as well
  - configured xEdit readiness CI to run with `RUN_BSARCH=0` so the lane stays focused on xEdit/readiness checks
  - added optional headless smoke script `linux/native-port/smoke-test-xedit-headless.sh` and wired CI to run it when `linux/bin/xedit-core` is available
  - added `linux/native-port/ci-preflight.sh` as shared CI entry point to run all native-port checks with consistent permissions and strict-style gating

## Risks

- Large VCL surface area still blocks direct xEdit GUI port.
- Script host and plugin assumptions may still include Windows-only behavior.
- GUI usability parity with original BSArchPro still needs incremental tuning.

## Immediate Action List

1. Add smoke test script for BSArchSE:
- Implemented: `linux/native-port/smoke-test-bsarch.sh`
- Automated: core pack/list/unpack roundtrip + launcher CLI passthrough
- Manual checklist included for GUI actions (`Unpack Selected`, `Pack Selected`, `Archiv-Info`, double-click open)
- Added convenience runner: `linux/native-port/run-all-checks.sh` (strict readiness + BSArch checks + optional xEdit headless smoke)
- Runner now supports toggles for quicker local loops (`RUN_BSARCH_STRESS=0`, `RUN_BSARCH=0`, `RUN_XEDIT_HEADLESS=0`)
- Runner now also supports readiness mode toggle (`ENFORCE_STYLE=1` strict, `ENFORCE_STYLE=0` core-only)

2. Add basic CI job (Linux) for:
- Implemented workflow: `.github/workflows/bsarch-linux-ci.yml`
- Builds `BSArchSE` (Qt) on Ubuntu
- Always runs `linux/native-port/ci-preflight.sh`:
: full checks when `linux/bin/bsarch-core` exists, readiness-focused checks otherwise
- Uploads readiness report artifact (`bsarch-ci-xedit-readiness-report`) for each run

3. Finalize launcher behavior:
- `BSArch-linux` should remain the single entry point for users.
- Implemented in docs/install scripts: `BSArch-linux` is the default command and desktop launcher target.
- `BSArch-UI` and `start-bsarch.sh` remain compatibility aliases.
