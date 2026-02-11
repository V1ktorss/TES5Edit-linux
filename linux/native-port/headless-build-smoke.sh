#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

RUN_XEDIT="${RUN_XEDIT:-1}"
RUN_XDUMP="${RUN_XDUMP:-1}"
BUILD_ONLY="${BUILD_ONLY:-0}"

log() {
  echo "[headless] $*"
}

run_step() {
  local title="$1"
  shift
  log "${title}"
  "$@"
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
