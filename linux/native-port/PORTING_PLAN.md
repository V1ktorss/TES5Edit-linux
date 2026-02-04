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
- Started `xejviScriptAdapterMisc` decoupling:
  - added `wbPlatform.OpenUrl` script API bridge
  - routed common `ShellExecute(open, URL)` path through `wbPlatform`
  - replaced script `CopyFile` binding with platform-neutral file copy logic
  - moved `CreateProcessWait` and `GetKeyState` bindings to `wbPlatform` wrappers
  - moved `ShellExecuteWait` and `Sleep` bindings to `wbPlatform` wrappers
  - moved `ShellExecute` binding to `wbPlatform` wrapper and removed direct `ShellApi` dependency
  - gated `TRegistryIniFile` script registration to Windows-only
  - reduced direct `Windows` unit dependence in script adapter with cross-platform show-window constants
  - gated clipboard adapter registration/implementation to Windows-only
  - removed remaining direct `Windows` unit import from `xejviScriptAdapterMisc.pas`
  - added `wbPlatform.*` alias registrations in script adapter for process/shell/file helpers
  - moved script `CopyFile` implementation to `wbPlatform.wbCopyFile`
  - added non-Windows fallback for `Registry.TRegistryIniFile` scripts (maps to `TMemIniFile`)
  - gated legacy `Windows.*` and `ShellApi.*` script registrations to Windows-only
  - moved clipboard read/write implementation to `wbPlatform` and added `wbPlatform` clipboard aliases
  - removed `Windows` unit dependency from `xejviScriptAdapter.pas` by replacing `Int64Rec`-based conversion
  - gated `JvInterpreter_Windows` registration to Windows-only in `xejviScriptAdapter.pas`

## Risks

- Large VCL surface area still blocks direct xEdit GUI port.
- Script host and plugin assumptions may still include Windows-only behavior.
- GUI usability parity with original BSArchPro still needs incremental tuning.

## Immediate Action List

1. Add smoke test script for BSArchSE:
- Implemented: `linux/native-port/smoke-test-bsarch.sh`
- Automated: core pack/list/unpack roundtrip + launcher CLI passthrough
- Manual checklist included for GUI actions (`Unpack Selected`, `Pack Selected`, `Archiv-Info`, double-click open)

2. Add basic CI job (Linux) for:
- Implemented workflow: `.github/workflows/bsarch-linux-ci.yml`
- Builds `BSArchSE` (Qt) on Ubuntu
- Runs `linux/native-port/smoke-test-bsarch.sh` when `linux/bin/bsarch-core` is present

3. Finalize launcher behavior:
- `BSArch-linux` should remain the single entry point for users.
- Implemented in docs/install scripts: `BSArch-linux` is the default command and desktop launcher target.
- `BSArch-UI` and `start-bsarch.sh` remain compatibility aliases.
