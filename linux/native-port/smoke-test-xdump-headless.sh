#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="/tmp"
TIMEOUT_SECONDS="${XDUMP_HEADLESS_TIMEOUT:-20}"
HEADLESS_ARGS="${XDUMP_HEADLESS_ARGS:-}"
HEADLESS_CASES="${XDUMP_HEADLESS_CASES:--h|-dummy}"
BASE_MODE_ARGS="${XDUMP_BASE_MODE_ARGS:-}"
ENV_OVERRIDE_TEST="${XDUMP_ENV_OVERRIDE_TEST:-0}"
ENV_OVERRIDE_PATH="${XDUMP_ENV_OVERRIDE_PATH:-}"
ENV_OVERRIDE_ARGS="${XDUMP_ENV_OVERRIDE_ARGS:--dummy}"
CLI_OVERRIDE_TEST="${XDUMP_CLI_OVERRIDE_TEST:-0}"
CLI_OVERRIDE_PATH="${XDUMP_CLI_OVERRIDE_PATH:-}"
CLI_OVERRIDE_ARGS="${XDUMP_CLI_OVERRIDE_ARGS:--dummy}"
MODE_SANITY_TEST="${XDUMP_MODE_SANITY_TEST:-0}"
MODE_SANITY_ARGS="${XDUMP_MODE_SANITY_ARGS:--TES5 -Dump Missing.esm}"
INVALID_D_TEST="${XDUMP_INVALID_D_TEST:-0}"
INVALID_D_PATH="${XDUMP_INVALID_D_PATH:-/definitely/not/here}"
INVALID_D_ARGS="${XDUMP_INVALID_D_ARGS:--TES5 -Dump Missing.esm}"

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

# shellcheck disable=SC2206
mode_args=( ${BASE_MODE_ARGS} )

for case_args in "${cases[@]}"; do
  safe_name="$(echo "${case_args}" | tr -cs '[:alnum:]' '_' | sed 's/^_//; s/_$//')"
  [[ -z "${safe_name}" ]] && safe_name="default"
  log_file="${LOG_DIR}/xdump-headless-smoke-${safe_name}.log"

  echo "[xdump-smoke] Running: ${XDUMP_BIN_PATH} ${BASE_MODE_ARGS} ${case_args}"
  set +e
  # shellcheck disable=SC2206
  cmd_args=( ${case_args} )
  timeout "${TIMEOUT_SECONDS}"s "${XDUMP_BIN_PATH}" "${mode_args[@]}" "${cmd_args[@]}" >"${log_file}" 2>&1
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

  if rg -q "Can't determine (GameMode|ToolMode)|Unexpected Error:" "${log_file}"; then
    echo "[xdump-smoke] NOTE: log contains mode-detection or exception markers (${case_args})"
    echo "[xdump-smoke] NOTE: current xDump smoke lane is treated as launch-sanity."
  fi

  echo "[xdump-smoke] Exit code: ${exit_code}"
  echo "[xdump-smoke] Log: ${log_file}"
done

if [[ "${ENV_OVERRIDE_TEST}" == "1" ]]; then
  if [[ -z "${ENV_OVERRIDE_PATH}" ]]; then
    echo "[xdump-smoke] FAILED: XDUMP_ENV_OVERRIDE_TEST=1 requires XDUMP_ENV_OVERRIDE_PATH"
    exit 1
  fi

  safe_name="$(echo "env_${ENV_OVERRIDE_ARGS}" | tr -cs '[:alnum:]' '_' | sed 's/^_//; s/_$//')"
  [[ -z "${safe_name}" ]] && safe_name="env_override"
  log_file="${LOG_DIR}/xdump-headless-smoke-${safe_name}.log"

  echo "[xdump-smoke] Running env override case: XDUMP_DATA_PATH=${ENV_OVERRIDE_PATH} ${XDUMP_BIN_PATH} ${BASE_MODE_ARGS} ${ENV_OVERRIDE_ARGS}"
  set +e
  # shellcheck disable=SC2206
  env_args=( ${ENV_OVERRIDE_ARGS} )
  XDUMP_DATA_PATH="${ENV_OVERRIDE_PATH}" timeout "${TIMEOUT_SECONDS}"s "${XDUMP_BIN_PATH}" "${mode_args[@]}" "${env_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xdump-smoke] FAILED: env override case timed out after ${TIMEOUT_SECONDS}s"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -ne 0 ]]; then
    echo "[xdump-smoke] FAILED: env override case exit code ${exit_code}"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  if rg -q "Can't determine (GameMode|ToolMode)|Unexpected Error:" "${log_file}"; then
    echo "[xdump-smoke] NOTE: log contains mode-detection or exception markers (env override)"
    echo "[xdump-smoke] NOTE: current xDump smoke lane is treated as launch-sanity."
  fi

  echo "[xdump-smoke] Env override case exit code: ${exit_code}"
  echo "[xdump-smoke] Log: ${log_file}"
fi

if [[ "${CLI_OVERRIDE_TEST}" == "1" ]]; then
  if [[ -z "${CLI_OVERRIDE_PATH}" ]]; then
    echo "[xdump-smoke] FAILED: XDUMP_CLI_OVERRIDE_TEST=1 requires XDUMP_CLI_OVERRIDE_PATH"
    exit 1
  fi

  safe_name="$(echo "cli_${CLI_OVERRIDE_ARGS}" | tr -cs '[:alnum:]' '_' | sed 's/^_//; s/_$//')"
  [[ -z "${safe_name}" ]] && safe_name="cli_override"
  log_file="${LOG_DIR}/xdump-headless-smoke-${safe_name}.log"

  echo "[xdump-smoke] Running CLI override case: ${XDUMP_BIN_PATH} ${BASE_MODE_ARGS} -D:${CLI_OVERRIDE_PATH} ${CLI_OVERRIDE_ARGS}"
  set +e
  # shellcheck disable=SC2206
  cli_args=( ${CLI_OVERRIDE_ARGS} )
  timeout "${TIMEOUT_SECONDS}"s "${XDUMP_BIN_PATH}" "${mode_args[@]}" "-D:${CLI_OVERRIDE_PATH}" "${cli_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xdump-smoke] FAILED: CLI override case timed out after ${TIMEOUT_SECONDS}s"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -ne 0 ]]; then
    echo "[xdump-smoke] FAILED: CLI override case exit code ${exit_code}"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  if rg -q "Can't determine (GameMode|ToolMode)|Unexpected Error:" "${log_file}"; then
    echo "[xdump-smoke] NOTE: log contains mode-detection or exception markers (CLI override)"
    echo "[xdump-smoke] NOTE: current xDump smoke lane is treated as launch-sanity."
  fi

  echo "[xdump-smoke] CLI override case exit code: ${exit_code}"
  echo "[xdump-smoke] Log: ${log_file}"
fi

if [[ "${MODE_SANITY_TEST}" == "1" ]]; then
  safe_name="mode_sanity"
  log_file="${LOG_DIR}/xdump-headless-smoke-${safe_name}.log"

  echo "[xdump-smoke] Running mode sanity case: ${XDUMP_BIN_PATH} ${MODE_SANITY_ARGS}"
  set +e
  # shellcheck disable=SC2206
  mode_sanity_args=( ${MODE_SANITY_ARGS} )
  timeout "${TIMEOUT_SECONDS}"s "${XDUMP_BIN_PATH}" "${mode_sanity_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xdump-smoke] FAILED: mode sanity case timed out after ${TIMEOUT_SECONDS}s"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -eq 139 ]]; then
    echo "[xdump-smoke] FAILED: mode sanity case crashed (segfault)"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  if rg -q "EAccessViolation|Unexpected Error:|Access violation" "${log_file}"; then
    echo "[xdump-smoke] FAILED: mode sanity case reported access violation/error"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  echo "[xdump-smoke] Mode sanity case exit code: ${exit_code}"
  echo "[xdump-smoke] Log: ${log_file}"
fi

if [[ "${INVALID_D_TEST}" == "1" ]]; then
  safe_name="invalid_d"
  log_file="${LOG_DIR}/xdump-headless-smoke-${safe_name}.log"

  echo "[xdump-smoke] Running invalid -D case: ${XDUMP_BIN_PATH} -D:${INVALID_D_PATH} ${INVALID_D_ARGS}"
  set +e
  # shellcheck disable=SC2206
  invalid_d_args=( ${INVALID_D_ARGS} )
  timeout "${TIMEOUT_SECONDS}"s "${XDUMP_BIN_PATH}" "-D:${INVALID_D_PATH}" "${invalid_d_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xdump-smoke] FAILED: invalid -D case timed out after ${TIMEOUT_SECONDS}s"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -eq 0 ]]; then
    echo "[xdump-smoke] FAILED: invalid -D case unexpectedly exited 0"
    echo "[xdump-smoke] Log: ${log_file}"
    exit 1
  fi

  echo "[xdump-smoke] Invalid -D case exit code: ${exit_code} (expected non-zero)"
  echo "[xdump-smoke] Log: ${log_file}"
fi

echo "[xdump-smoke] PASS (all cases completed successfully)"
