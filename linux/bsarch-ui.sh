#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CPP_DIR="${SCRIPT_DIR}/bsarch_ui_cpp"
BUILD_DIR="${SCRIPT_DIR}/.build-bsarch-ui"
UI_BIN="${BUILD_DIR}/bsarch-ui"
PRO_FILE="${CPP_DIR}/bsarch_ui_cpp.pro"
LOG_FILE="${BSARCH_UI_LOG:-/tmp/bsarchse-launch.log}"
DEBUG_UI="${BSARCH_UI_DEBUG:-0}"
DEFAULT_QT_PLUGIN_PATH=""

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
  echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-<empty>} XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<empty>} DESKTOP_SESSION=${DESKTOP_SESSION:-<empty>}"
  echo "QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-<empty>} QT_PLUGIN_PATH=${QT_PLUGIN_PATH:-<empty>} LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-<empty>}"
  if [[ "$DEBUG_UI" == "1" ]]; then
    echo "BSARCH_UI_DEBUG=1 (enabling QT_DEBUG_PLUGINS + qt.qpa.* logging)"
  fi
} >>"$LOG_FILE"

# Ensure Qt can find platform plugins when launched outside a full desktop environment.
if [[ -z "${QT_PLUGIN_PATH:-}" ]]; then
  if [[ -d "/usr/lib/qt/plugins" ]]; then
    DEFAULT_QT_PLUGIN_PATH="/usr/lib/qt/plugins"
  elif [[ -d "/usr/lib/qt5/plugins" ]]; then
    DEFAULT_QT_PLUGIN_PATH="/usr/lib/qt5/plugins"
  elif [[ -d "/usr/lib64/qt5/plugins" ]]; then
    DEFAULT_QT_PLUGIN_PATH="/usr/lib64/qt5/plugins"
  fi
  if [[ -n "$DEFAULT_QT_PLUGIN_PATH" ]]; then
    export QT_PLUGIN_PATH="$DEFAULT_QT_PLUGIN_PATH"
    echo "QT_PLUGIN_PATH set to ${QT_PLUGIN_PATH}" >>"$LOG_FILE"
  fi
fi
if [[ -n "${QT_PLUGIN_PATH:-}" && -d "${QT_PLUGIN_PATH}/platforms" ]]; then
  echo "QT platforms: $(ls -1 "${QT_PLUGIN_PATH}/platforms" 2>/dev/null | tr '\n' ' ')" >>"$LOG_FILE"
fi

# Optional verbose Qt plugin diagnostics when troubleshooting startup crashes.
if [[ "$DEBUG_UI" == "1" ]]; then
  export QT_DEBUG_PLUGINS=1
  export QT_LOGGING_RULES="qt.qpa.*=true"
fi

run_ui_attempt() {
  local platform="$1"
  local label="$2"
  if [[ -n "$platform" ]]; then
    echo "=== $(date -Iseconds) attempt ${label} (QT_QPA_PLATFORM=${platform}) ===" >>"$LOG_FILE"
    QT_QPA_PLATFORM="$platform" "$UI_BIN" >>"$LOG_FILE" 2>&1
  else
    echo "=== $(date -Iseconds) attempt ${label} (QT_QPA_PLATFORM=default) ===" >>"$LOG_FILE"
    "$UI_BIN" >>"$LOG_FILE" 2>&1
  fi
  return $?
}

run_ui_with_fallbacks() {
  local ec=0
  set +e
  if [[ -n "${QT_QPA_PLATFORM:-}" ]]; then
    run_ui_attempt "" "explicit-env"
    ec=$?
  else
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
      run_ui_attempt "wayland" "wayland"
      ec=$?
      if [[ "$ec" -ne 0 ]]; then
        run_ui_attempt "xcb" "xcb-fallback"
        ec=$?
      fi
    else
      run_ui_attempt "xcb" "xcb"
      ec=$?
    fi
  fi
  set -e
  echo "=== $(date -Iseconds) bsarch-ui.sh exit code ${ec} ===" >>"$LOG_FILE"
  if [[ "$ec" -ne 0 ]]; then
    show_error "BSArchSE failed to start. See log: $LOG_FILE\nIf this repeats, ensure Qt platform plugins are installed (e.g. qt5-wayland and/or xcb) and try QT_QPA_PLATFORM=wayland or xcb."
  fi
  return "$ec"
}

# Use existing binary directly for reliable GUI launch from file managers.
if [[ -x "$UI_BIN" ]]; then
  run_ui_with_fallbacks
  exit $?
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

run_ui_with_fallbacks
exit $?
