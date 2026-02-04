#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

DEFAULT_WINEPREFIX="${HOME}/.local/share/tes5edit-linux/prefix"
WINEPREFIX="${WINEPREFIX:-$DEFAULT_WINEPREFIX}"
XEDIT_BUILD_DIR="${XEDIT_BUILD_DIR:-${REPO_ROOT}/Build}"
XEDIT_EXTRA_DIRS="${XEDIT_EXTRA_DIRS:-${REPO_ROOT}:${HOME}/Tools/xEdit}"

show_help() {
  cat <<'EOF'
Usage:
  TES5Edit [xEdit arguments...]
  SSEEdit [xEdit arguments...]
  FO4Edit [xEdit arguments...]
  xedit-linux-launcher.sh --mode TES5 [xEdit arguments...]

Environment variables:
  WINEPREFIX      Override Wine prefix (default: ~/.local/share/tes5edit-linux/prefix)
  XEDIT_BUILD_DIR Path to folder containing xEdit *.exe files (default: <repo>/Build)
  XEDIT_EXTRA_DIRS Colon-separated fallback directories to scan for exe files
  WINE_BIN        Override Wine executable (default: auto-detect)
EOF
}

resolve_mode() {
  local requested="${1:-}"
  if [[ -n "$requested" ]]; then
    printf '%s' "$requested"
    return
  fi

  case "${SCRIPT_NAME,,}" in
    tes5edit|tes5edit.sh) printf 'TES5' ;;
    tes5vredit|tes5vredit.sh) printf 'TES5VR' ;;
    sseedit|sseedit.sh) printf 'SSE' ;;
    tes4edit|tes4edit.sh) printf 'TES4' ;;
    tes4redit|tes4redit.sh) printf 'TES4R' ;;
    fo3edit|fo3edit.sh) printf 'FO3' ;;
    fnvedit|fnvedit.sh) printf 'FNV' ;;
    fo4edit|fo4edit.sh) printf 'FO4' ;;
    fo4vredit|fo4vredit.sh) printf 'FO4VR' ;;
    fo76edit|fo76edit.sh) printf 'FO76' ;;
    sf1edit|sf1edit.sh|sf16edit|sf16edit.sh) printf 'SF1' ;;
    enderaledit|enderaledit.sh) printf 'Enderal' ;;
    enderalseedit|enderalseedit.sh) printf 'EnderalSE' ;;
    *) printf 'TES5' ;;
  esac
}

pick_wine() {
  if [[ -n "${WINE_BIN:-}" ]]; then
    printf '%s' "$WINE_BIN"
    return
  fi

  if command -v wine64 >/dev/null 2>&1; then
    printf 'wine64'
    return
  fi

  if command -v wine >/dev/null 2>&1; then
    printf 'wine'
    return
  fi

  echo "Error: Neither wine64 nor wine is installed." >&2
  exit 1
}

find_exe() {
  local mode="$1"
  local -a dirs=()
  local -a candidates=(
    "${mode}Edit.exe"
    "xEdit.exe"
    "xEdit64.exe"
    "xFOEdit64.exe"
    "xFOEdit.exe"
  )

  IFS=':' read -r -a dirs <<<"${XEDIT_BUILD_DIR}:${XEDIT_EXTRA_DIRS}"

  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    for exe in "${candidates[@]}"; do
      if [[ -f "${dir}/${exe}" ]]; then
        printf '%s' "${dir}/${exe}"
        return
      fi
    done
  done

  return 1
}

MODE=""
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

if [[ "${1:-}" == "--mode" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "Error: --mode requires a value." >&2
    exit 1
  fi
  MODE="$2"
  shift 2
fi

MODE="$(resolve_mode "$MODE")"
WINE_CMD="$(pick_wine)"
if ! EXE_PATH="$(find_exe "$MODE")"; then
  echo "Error: Could not find a usable xEdit executable." >&2
  echo "Searched in: ${XEDIT_BUILD_DIR}:${XEDIT_EXTRA_DIRS}" >&2
  echo "Set XEDIT_BUILD_DIR or XEDIT_EXTRA_DIRS to your xEdit binary directory." >&2
  exit 1
fi

mkdir -p "$WINEPREFIX"

exec env WINEPREFIX="$WINEPREFIX" "$WINE_CMD" "$EXE_PATH" "-${MODE}" "$@"
