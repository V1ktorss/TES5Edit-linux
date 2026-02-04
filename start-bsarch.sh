#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${ROOT_DIR}/BSArch-linux"
UI="${ROOT_DIR}/linux/bsarch-ui.sh"

if [[ ! -x "$BIN" ]]; then
  echo "BSArch-linux not found or not executable: $BIN" >&2
  exit 1
fi

# If called with arguments, use CLI mode directly.
if [[ $# -gt 0 ]]; then
  exec "$BIN" "$@"
fi

# No arguments: try launching UI in desktop sessions.
if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
  if [[ -x "$UI" ]]; then
    exec "$UI"
  fi
fi

# Fallback to CLI help text.
exec "$BIN"
