#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="/tmp"
TIMEOUT_SECONDS="${XDUMP_HEADLESS_TIMEOUT:-20}"
HEADLESS_ARGS="${XDUMP_HEADLESS_ARGS:-}"
HEADLESS_CASES="${XDUMP_HEADLESS_CASES:--h|-dummy}"

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

cases=()
if [[ -n "${HEADLESS_ARGS}" ]]; then
  cases+=("${HEADLESS_ARGS}")
else
  IFS='|' read -r -a cases <<< "${HEADLESS_CASES}"
fi

for case_args in "${cases[@]}"; do
  safe_name="$(echo "${case_args}" | tr -cs '[:alnum:]' '_' | sed 's/^_//; s/_$//')"
  [[ -z "${safe_name}" ]] && safe_name="default"
  log_file="${LOG_DIR}/xdump-headless-smoke-${safe_name}.log"

  echo "[xdump-smoke] Running: ${XDUMP_BIN_PATH} ${case_args}"
  set +e
  # shellcheck disable=SC2206
  cmd_args=( ${case_args} )
  timeout "${TIMEOUT_SECONDS}"s "${XDUMP_BIN_PATH}" "${cmd_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xdump-smoke] FAILED: command timed out after ${TIMEOUT_SECONDS}s (${case_args})"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -ne 0 ]]; then
    echo "[xdump-smoke] FAILED: non-zero exit code ${exit_code} (${case_args})"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  echo "[xdump-smoke] Exit code: ${exit_code}"
  echo "[xdump-smoke] Log: ${log_file}"
done

echo "[xdump-smoke] PASS (all cases completed successfully)"
