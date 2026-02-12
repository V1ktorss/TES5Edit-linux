#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

RUN_XEDIT="${RUN_XEDIT:-1}"
RUN_XDUMP="${RUN_XDUMP:-1}"
BUILD_ONLY="${BUILD_ONLY:-0}"
HEADLESS_LOG="${HEADLESS_LOG:-/tmp/xedit-headless-current.log}"
HEADLESS_LOG_LEGACY="${HEADLESS_LOG_LEGACY:-/tmp/xedit-headless.log}"

if [[ -n "${HEADLESS_LOG}" ]]; then
  mkdir -p "$(dirname "${HEADLESS_LOG}")"
  : > "${HEADLESS_LOG}"
fi

log() {
  echo "[headless] $*"
  if [[ -n "${HEADLESS_LOG}" ]]; then
    echo "[headless] $*" >> "${HEADLESS_LOG}"
  fi
}

run_step() {
  local title="$1"
  shift
  log "${title}"
  if [[ -n "${HEADLESS_LOG}" ]]; then
    "$@" >> "${HEADLESS_LOG}" 2>&1
  else
    "$@"
  fi
}

if [[ "${RUN_XEDIT}" != "1" && "${RUN_XDUMP}" != "1" ]]; then
  log "Nothing to do. Set RUN_XEDIT=1 and/or RUN_XDUMP=1."
  exit 0
fi

log "Config: RUN_XEDIT=${RUN_XEDIT} RUN_XDUMP=${RUN_XDUMP} BUILD_ONLY=${BUILD_ONLY}"

if [[ "${RUN_XEDIT}" == "1" ]]; then
  run_step "Building xEdit headless" "${ROOT_DIR}/linux/native-port/build-xedit-headless.sh"
  if [[ "${BUILD_ONLY}" != "1" ]]; then
    run_step "xEdit headless smoke" "${ROOT_DIR}/linux/native-port/smoke-test-xedit-headless.sh"
  fi
fi

if [[ "${RUN_XDUMP}" == "1" ]]; then
  run_step "Building xDump headless" "${ROOT_DIR}/linux/native-port/build-xdump.sh"
  if [[ "${BUILD_ONLY}" != "1" ]]; then
    run_step "xDump headless smoke" "${ROOT_DIR}/linux/native-port/smoke-test-xdump-headless.sh"
  fi
fi

log "PASS"

# Keep the legacy path in sync for existing workflows.
if [[ -n "${HEADLESS_LOG}" && -n "${HEADLESS_LOG_LEGACY}" && "${HEADLESS_LOG}" != "${HEADLESS_LOG_LEGACY}" ]]; then
  cp -f "${HEADLESS_LOG}" "${HEADLESS_LOG_LEGACY}" || true
fi
