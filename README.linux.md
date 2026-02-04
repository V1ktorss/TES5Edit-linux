# Linux Port (Wine Launcher)

This repository contains the xEdit source code, which is developed with Delphi for Windows.  
Native Linux binaries are not part of upstream xEdit, so this Linux port uses a Wine launcher.

## What this provides

- A Linux launcher script that starts `xEdit.exe` with the right game mode argument.
- Local install script for user-level commands and desktop entries.
- Per-user Wine prefix default (`~/.local/share/tes5edit-linux/prefix`).

## Requirements

- Wine (`wine64` or `wine`)
- A built xEdit binary (`xEdit.exe`, `TES5Edit.exe`, etc.) inside `Build/`
- Or an existing binary in a fallback path (default also checks `~/Tools/xEdit`)
- You can override search paths with `XEDIT_BUILD_DIR` and `XEDIT_EXTRA_DIRS`

## Quick start

```bash
cd linux
chmod +x xedit-linux-launcher.sh install-local.sh
./install-local.sh
```

Then run:

```bash
TES5Edit
SSEEdit
FO4Edit
```

For BSArch:

```bash
./BSArch-linux
```

- With no arguments it opens the UI (desktop session) or shows CLI help.
- With arguments it forwards directly to `BSArch-linux`.
- `start-bsarch.sh` remains as a compatibility wrapper.

## Manual usage

```bash
./linux/xedit-linux-launcher.sh --mode TES5
./linux/xedit-linux-launcher.sh --mode SSE
./linux/xedit-linux-launcher.sh --mode FO4
```

You can pass normal xEdit arguments after the mode.

## BSArch Native UI

A native Linux UI for `BSArch-linux` is included:

```bash
chmod +x linux/bsarch-ui.sh linux/install-bsarch-ui.sh
./linux/install-bsarch-ui.sh
BSArch-linux
```

The UI is implemented in `C++` with `Qt Widgets` (`linux/bsarch_ui_cpp`).

The UI supports:
- Archive info
- Drag and drop archive loading
- Input menu (`☰`) with `Archives Browse`
- Multi-archive selection in `Archives Browse` (info/list workflows)
- Archive file list with extension filter, search, and compression filter checkboxes (`All`, `Compressed`, `Uncompressed`)
- Resizable columns: `[Compressed]`, `Asset Name`, `Source File`
- Select helpers: `Rest`, `Clear List`
- Tabs: `Archive File List` and `Archive List`
- Right-click list menu: `Unpack Selected`, `Pack Selected`, `Archiv-Info`
- Double-click an entry to unpack it into `./Tmp` and open it with the default app
- Unpack actions ask for target folder when started
- Command results are shown via dialogs/status bar (no output panel)
- Pack folder -> archive
- Unpack archive -> folder

## Native Port Checks

Native/Linux checks live in `linux/native-port/`.

Run everything locally:

```bash
linux/native-port/run-all-checks.sh
```

This runs:
- xEdit readiness gate (`ENFORCE_STYLE=1`)
- BSArch smoke/path/stress checks (if `linux/bin/bsarch-core` exists)
- xEdit headless smoke (if a native xEdit binary is available)

Important scripts:
- `linux/native-port/check-xedit-readiness.sh`
- `linux/native-port/xedit-readiness-audit.sh`
- `linux/native-port/smoke-test-bsarch.sh`
- `linux/native-port/regression-paths-bsarch.sh`
- `linux/native-port/stress-large-bsarch.sh`
- `linux/native-port/smoke-test-xedit-headless.sh`

## Optional environment variables

- `WINEPREFIX`: override Wine prefix
- `XEDIT_BUILD_DIR`: path to folder containing `xEdit.exe`
- `XEDIT_EXTRA_DIRS`: colon-separated fallback directories for exe lookup
- `WINE_BIN`: force a specific Wine command
