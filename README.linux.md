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

## Manual usage

```bash
./linux/xedit-linux-launcher.sh --mode TES5
./linux/xedit-linux-launcher.sh --mode SSE
./linux/xedit-linux-launcher.sh --mode FO4
```

You can pass normal xEdit arguments after the mode.

## Optional environment variables

- `WINEPREFIX`: override Wine prefix
- `XEDIT_BUILD_DIR`: path to folder containing `xEdit.exe`
- `XEDIT_EXTRA_DIRS`: colon-separated fallback directories for exe lookup
- `WINE_BIN`: force a specific Wine command
