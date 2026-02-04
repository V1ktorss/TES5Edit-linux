# Native Linux Port Plan (No Wine)

This is a practical migration plan to make xEdit run natively on Linux.

## Reality check

- Current codebase is tightly coupled to Delphi + VCL + Windows APIs.
- A direct "compile on Linux" switch does not exist.
- Fastest path is staged migration:
  1. Port non-UI tools first
  2. Isolate platform dependencies
  3. Rebuild GUI with Linux-capable framework

## Target architecture

- `core/` Pure parsing/business logic (cross-platform Pascal)
- `platform/` OS abstractions (file dialogs, process launch, registry replacement, paths)
- `apps/bsarch-cli` First native deliverable
- `apps/xedit-gui` Final GUI app (Lazarus LCL or Qt binding)

## Phases

1. **Dependency audit and boundaries (1-2 weeks)**
- Catalog all `Windows`, `Winapi.*`, `Vcl.*`, `Registry`, `ShellAPI` usages.
- Define abstraction units (`uxPlatform*` / `wbPlatform*`) for OS calls.
- Freeze feature scope for first native milestone (BSArch CLI).

2. **Core extraction (2-4 weeks)**
- Move non-UI archive/data parsing units behind platform-neutral interfaces.
- Remove direct Windows type leakage from core units.
- Add Linux-safe path/process/time helpers.

3. **Native BSArch CLI (1-2 weeks)**
- Build with FreePascal/Lazarus.
- Support unpack/pack/list/info on Linux paths.
- Add regression fixtures against known BSA/BA2 archives.

4. **xDump CLI feasibility (1-2 weeks)**
- Port command-line-only pieces.
- Validate performance and output parity.

5. **xEdit GUI strategy spike (2-3 weeks)**
- Option A: Lazarus LCL port (closest Pascal workflow).
- Option B: keep core in Pascal, rebuild GUI in another stack.
- Decide based on prototype: startup, tree rendering, script host viability.

6. **GUI migration (multi-month)**
- Replace VCL forms and VirtualTrees with Linux-capable equivalents.
- Rework scripting host bindings currently tied to Windows/VCL.
- Recreate settings/storage without Windows Registry.

## Highest-risk blockers

- Deep VCL dependency across many forms and controls.
- Script adapter exposes Windows-specific APIs to scripts.
- Registry and Shell integration assumptions in startup/helpers.

## First milestone definition (recommended)

Deliver `bsarch-linux` native binary with:
- archive inspect/list/extract/create
- parity tests for core commands
- packaged release artifact (AppImage or distro package)

This gives immediate user value while reducing risk before GUI migration.

## Immediate next tasks

1. Install toolchain: `fpc`, `lazarus`, `make`, `git`.
2. Run dependency audit script (`audit-windows-deps.sh`).
3. Create `wbPlatform` abstraction unit and port one core unit end-to-end.
4. Attempt first Linux build for BSArch-only target.
