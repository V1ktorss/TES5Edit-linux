#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="/tmp"
LOG_FILE="${LOG_DIR}/xdump-headless-smoke.log"
TIMEOUT_SECONDS="${XDUMP_HEADLESS_TIMEOUT:-20}"
HEADLESS_ARGS="${XDUMP_HEADLESS_ARGS:--h}"

find_xdump_bin() {
  if [[ -n "${XDUMP_BIN:-}" && -x "${XDUMP_BIN}" ]]; then
    echo "${XDUMP_BIN}"
    return 0
  fi

  local candidates=(
    "${ROOT_DIR}/linux/bin/xdump-core"
    "${ROOT_DIR}/linux/bin/xDump"
    "${ROOT_DIR}/xDump/xdump-core"
    "${ROOT_DIR}/xDump/xDump"
    "${ROOT_DIR}/xDump/xdump"
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

XDUMP_BIN_PATH="$(find_xdump_bin || true)"
if [[ -z "${XDUMP_BIN_PATH}" ]]; then
  echo "[xdump-smoke] No xDump native binary found. Skipping."
  exit 0
fi

echo "[xdump-smoke] Using binary: ${XDUMP_BIN_PATH}"
echo "[xdump-smoke] Running: ${XDUMP_BIN_PATH} ${HEADLESS_ARGS}"

set +e
timeout "${TIMEOUT_SECONDS}"s "${XDUMP_BIN_PATH}" ${HEADLESS_ARGS} >"${LOG_FILE}" 2>&1
exit_code=$?
set -e

if [[ "${exit_code}" -eq 124 ]]; then
  echo "[xdump-smoke] FAILED: command timed out after ${TIMEOUT_SECONDS}s"
  echo "[xdump-smoke] Log: ${LOG_FILE}"
  exit 1
fi

echo "[xdump-smoke] Exit code: ${exit_code}"
echo "[xdump-smoke] Log: ${LOG_FILE}"
echo "[xdump-smoke] PASS (process started and returned without hanging)"
