#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="/tmp"
LOG_FILE="${LOG_DIR}/xedit-headless-smoke.log"
TIMEOUT_SECONDS="${XEDIT_HEADLESS_TIMEOUT:-20}"
HEADLESS_ARGS="${XEDIT_HEADLESS_ARGS:--h}"

find_xedit_bin() {
  if [[ -n "${XEDIT_BIN:-}" && -x "${XEDIT_BIN}" ]]; then
    echo "${XEDIT_BIN}"
    return 0
  fi

  local candidates=(
    "${ROOT_DIR}/linux/bin/xedit-core"
    "${ROOT_DIR}/xEdit/xedit-core"
    "${ROOT_DIR}/xEdit/xEdit"
    "${ROOT_DIR}/xEdit/xedit"
  )

  local c
  for c in "${candidates[@]}"; do
    if [[ -x "${c}" ]]; then
      echo "${c}"
      return 0
    fi
  done

  return 1
}

XEDIT_BIN_PATH="$(find_xedit_bin || true)"
if [[ -z "${XEDIT_BIN_PATH}" ]]; then
  echo "[xedit-smoke] No xEdit native binary found. Skipping."
  exit 0
fi

echo "[xedit-smoke] Using binary: ${XEDIT_BIN_PATH}"
echo "[xedit-smoke] Running: ${XEDIT_BIN_PATH} ${HEADLESS_ARGS}"

set +e
timeout "${TIMEOUT_SECONDS}"s "${XEDIT_BIN_PATH}" ${HEADLESS_ARGS} >"${LOG_FILE}" 2>&1
exit_code=$?
set -e

if [[ "${exit_code}" -eq 124 ]]; then
  echo "[xedit-smoke] FAILED: command timed out after ${TIMEOUT_SECONDS}s"
  echo "[xedit-smoke] Log: ${LOG_FILE}"
  exit 1
fi

echo "[xedit-smoke] Exit code: ${exit_code}"
echo "[xedit-smoke] Log: ${LOG_FILE}"
echo "[xedit-smoke] PASS (process started and returned without hanging)"
