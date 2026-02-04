# xEdit Native Bootstrap (Linux)

This is the first practical track for moving from `BSArchSE` success toward `xEdit` native feasibility.

## Goal

Create a measurable readiness baseline before touching GUI migration code.

## Step 1: Readiness Audit

Run:

```bash
linux/native-port/xedit-readiness-audit.sh
```

Output:

- `linux/native-port/reports/xedit-readiness.txt`

This report identifies:

- Windows/VCL/Registry/Shell API hotspots in `xEdit/`
- highest-impact files for staged refactor order
- script-host adapter blockers (`xEdit/JvI/*`)

Current snapshot (latest audit in repo):

- Match count reduced from `81` to `38`
- Files with matches reduced from `25` to `14`
- Current top hotspots:
  - `xEdit/xeMainForm.pas`
  - `xEdit/xeRichEditForm.pas`
  - `xEdit/xeModGroupEditForm.pas`
  - form units still tied to `Windows` + `Vcl.*`

Note:

- audit now filters legacy script namespace markers (for example `AddFunction('Windows', ...)`) to focus on actual code dependencies.

## Step 2: Stabilize Platform Abstraction Boundary

Prioritize high-impact files:

1. `xEdit/xeInit.pas`
2. `xEdit/xeMainForm.pas`
3. `xEdit/JvI/xejviScriptAdapterMisc.pas`

For each file:

- isolate direct `Windows`/`Vcl`/`Registry` calls behind `wbPlatform*` wrappers
- avoid changing UI behavior in this phase
- add small compile-time guards where needed

Priority for next pass:

1. reduce Windows/VCL imports across the top form units (`xeMainForm`, `xeRichEditForm`, `xeModGroupEditForm`)
2. isolate more message/input helpers from `xeMainForm.pas` into `wbPlatform`
3. keep parity checks for script-host behavior while broadening Linux-safe wrappers

## Step 3: Define First xEdit Native Milestone

Before GUI parity, target one non-UI executable path:

- `xEdit` headless/startup path that can parse args and run a minimal non-interactive action
- no VCL form creation in the first slice

## Exit Criteria for Bootstrap

- audit report generated and tracked
- top-3 hotspot files have a concrete refactor task list
- one minimal native-safe xEdit startup slice identified
