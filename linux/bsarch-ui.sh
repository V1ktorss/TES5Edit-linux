#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CPP_DIR="${SCRIPT_DIR}/bsarch_ui_cpp"
BUILD_DIR="${SCRIPT_DIR}/.build-bsarch-ui"
UI_BIN="${BUILD_DIR}/bsarch-ui"
PRO_FILE="${CPP_DIR}/bsarch_ui_cpp.pro"
LOG_FILE="${BSARCH_UI_LOG:-/tmp/bsarchse-launch.log}"

show_error() {
  local msg="$1"
  if command -v kdialog >/dev/null 2>&1; then
    kdialog --error "$msg" 2>/dev/null || true
  fi
  echo "$msg" >&2
}

rotate_log() {
  local dir
  dir="$(dirname "$LOG_FILE")"
  mkdir -p "$dir"
  if [[ -f "$LOG_FILE" ]]; then
    local size
    size="$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)"
    if [[ "$size" -gt 1048576 ]]; then
      mv -f "$LOG_FILE" "${LOG_FILE}.1" 2>/dev/null || true
      : >"$LOG_FILE"
    fi
  fi
}

if [[ ! -f "$PRO_FILE" ]]; then
  show_error "UI project not found: $PRO_FILE"
  exit 1
fi

if [[ -z "${BSARCH_BIN:-}" ]]; then
  if [[ -x "${REPO_ROOT}/linux/bin/bsarch-core" ]]; then
    export BSARCH_BIN="${REPO_ROOT}/linux/bin/bsarch-core"
  else
    export BSARCH_BIN="${REPO_ROOT}/BSArch-linux"
  fi
fi

rotate_log
{
  echo "=== $(date -Iseconds) bsarch-ui.sh start ==="
  echo "BSARCH_BIN=${BSARCH_BIN}"
  echo "DISPLAY=${DISPLAY:-<empty>} WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<empty>}"
} >>"$LOG_FILE"

# Use existing binary directly for reliable GUI launch from file managers.
if [[ -x "$UI_BIN" ]]; then
  "$UI_BIN" >>"$LOG_FILE" 2>&1
  ec=$?
  echo "=== $(date -Iseconds) bsarch-ui.sh exit code ${ec} ===" >>"$LOG_FILE"
  if [[ "$ec" -ne 0 ]]; then
    show_error "BSArchSE failed to start. See log: $LOG_FILE"
  fi
  exit "$ec"
fi

if ! command -v qmake >/dev/null 2>&1; then
  show_error "qmake is missing and no prebuilt UI binary exists.\nInstall Qt base development tools."
  exit 1
fi

if [[ ! -x "$UI_BIN" ]]; then
  mkdir -p "$BUILD_DIR"
  if ! qmake -o "${BUILD_DIR}/Makefile" "$PRO_FILE"; then
    show_error "qmake failed while preparing BSArchSE UI."
    exit 1
  fi
  if ! make -C "$BUILD_DIR" -j"$(nproc)"; then
    show_error "Build failed while compiling BSArchSE UI."
    exit 1
  fi
fi

"$UI_BIN" >>"$LOG_FILE" 2>&1
ec=$?
echo "=== $(date -Iseconds) bsarch-ui.sh exit code ${ec} ===" >>"$LOG_FILE"
if [[ "$ec" -ne 0 ]]; then
  show_error "BSArchSE failed to start. See log: $LOG_FILE"
fi
exit "$ec"
