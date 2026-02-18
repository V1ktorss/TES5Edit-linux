# xEdit GUI Migration Plan (Linux Native)

This plan tracks the remaining GUI-specific migration work after core/headless decoupling.

## Current Baseline

Source of truth: `linux/native-port/reports/xedit-gui-surface.txt`

- DFM form files: `21`
- `TForm` descendants: `20`
- GUI units with VCL/gui imports: `23`
- GUI units with direct WinAPI imports: `1`
- Highest-coupled GUI unit: `xEdit/xeMainForm.pas`

## Phase 1: Stabilize GUI Surface Metrics

Goal: prevent regression while migration work continues.

Done:

- GUI surface audit:
  - `linux/native-port/audit-xedit-gui-surface.sh`
  - `linux/native-port/reports/xedit-gui-surface.txt`
- GUI surface budget guard:
  - `linux/native-port/check-xedit-gui-surface-budget.sh`
  - `linux/native-port/baselines/xedit-gui-surface-budget.env`
- Integration:
  - `linux/native-port/run-all-checks.sh`
  - `linux/native-port/ci-preflight.sh`

## Phase 2: Reduce WinAPI Ties in GUI Units

Goal: reduce the final `1` GUI unit that imports `Messages` directly.

Targets:

1. `xEdit/xeMainForm.pas`
  - current message surface baseline:
    - 0 `message WM_*` bindings (rewired to app constants)
    - 3 `TMessage` usages
    - 0 raw `WM_*` references
  - budget guard:
    - `linux/native-port/check-xemainform-message-surface-budget.sh`
    - `linux/native-port/baselines/xemainform-message-surface-budget.env`
  - last-mile guard:
    - `linux/native-port/check-xedit-gui-lastmile-winapi.sh`
    - enforces that this is the only remaining GUI WinAPI import unit

Completed:

- `xEdit/xeRichEditForm.pas` (`Messages` removed; local `WM_KEYDOWN` constant)
- `xEdit/xePushLikeButton.pas` (`Messages` removed; click/toggle path decoupled from `CN_COMMAND`)
- `xEdit/xeScriptForm.pas` (`Messages` removed; `WMMouseWheel` replaced by `DoMouseWheel` override, local `WM_CHAR` constant)

Strategy:

- Replace direct message constants/types with wrappers where practical.
- Keep behavior intact; no UI behavior regressions accepted.
- Re-run GUI budget guard and smoke checks after each file change.

## Phase 3: Separate GUI Application Shell from Edit Core

Goal: isolate form orchestration from editing logic to prepare toolkit-agnostic UI layers.

Work packages:

1. Move window-state and command routing helpers out of `xeMainForm`.
2. Extract non-visual workflows from form event handlers into service units.
3. Keep current VCL GUI as compatibility shell while services become UI-agnostic.

## Exit Criteria to move from Point 1 to Point 2

- GUI migration metrics are stable in CI (no regressions).
- At least one direct GUI WinAPI import site removed or wrapped without behavior regression.
- `xeMainForm` non-visual logic extraction started with testable units.
