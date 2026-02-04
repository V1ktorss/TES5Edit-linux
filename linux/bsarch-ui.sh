#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
UI_SCRIPT="${SCRIPT_DIR}/bsarch_ui.py"

if [[ ! -f "$UI_SCRIPT" ]]; then
  echo "UI script not found: $UI_SCRIPT" >&2
  exit 1
fi

if [[ -z "${BSARCH_BIN:-}" ]]; then
  export BSARCH_BIN="${REPO_ROOT}/BSArch-linux"
fi

if ! python3 -c "import tkinter" >/dev/null 2>&1; then
  echo "python-tk is missing. Install it first (e.g. on Arch/Garuda: sudo pacman -S tk)." >&2
  exit 1
fi

exec python3 "$UI_SCRIPT"
