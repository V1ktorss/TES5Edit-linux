# xEdit Native Bootstrap (Linux)

This is the first practical track for moving from `BSArchSE` success toward `xEdit` native feasibility.

## Goal

Create a measurable readiness baseline before touching GUI migration code.

## Step 1: Readiness Audit

Run:

```bash
linux/native-port/xedit-readiness-audit.sh
```

Enforced check:

```bash
linux/native-port/check-xedit-readiness.sh
```

Output:

- `linux/native-port/reports/xedit-readiness.txt`

This report identifies:

- Windows/VCL/Registry/Shell API hotspots in `xEdit/`
- highest-impact files for staged refactor order
- script-host adapter blockers (`xEdit/JvI/*`)

Current snapshot (latest audit in repo):

- Core blocker matches reduced from `81` to `0`
- Core blocker files reduced from `25` to `0`
- Style namespace matches (informational): `0` across `0` files
- Current top hotspots:
  - no current blocker hotspots in audit
  - remaining native-port work is now functionality/parity validation, not namespace-level blockers

Note:

- audit now filters legacy script namespace markers (for example `AddFunction('Windows', ...)`) to focus on actual code dependencies.
- audit now reports core blockers and style namespaces separately to make remaining Linux blockers explicit.
- CI gate: `.github/workflows/xedit-readiness-ci.yml` runs the readiness check on push/PR.

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

1. run compile/runtime validation for native paths after namespace cleanup
2. keep parity checks for script-host behavior while broadening Linux-safe wrappers
3. define and test first non-UI xEdit native startup slice

## Step 3: Define First xEdit Native Milestone

Before GUI parity, target one non-UI executable path:

- `xEdit` headless/startup path that can parse args and run a minimal non-interactive action
- no VCL form creation in the first slice

## Exit Criteria for Bootstrap

- audit report generated and tracked
- top-3 hotspot files have a concrete refactor task list
- one minimal native-safe xEdit startup slice identified
