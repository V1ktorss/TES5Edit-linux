#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="/tmp"
TIMEOUT_SECONDS="${XEDIT_HEADLESS_TIMEOUT:-20}"
HEADLESS_ARGS="${XEDIT_HEADLESS_ARGS:-}"
HEADLESS_CASES="${XEDIT_HEADLESS_CASES:--h|-dummy}"
ENV_OVERRIDE_TEST="${XEDIT_ENV_OVERRIDE_TEST:-0}"
ENV_OVERRIDE_PATH="${XEDIT_ENV_OVERRIDE_PATH:-}"
ENV_OVERRIDE_ARGS="${XEDIT_ENV_OVERRIDE_ARGS:--dummy}"
CLI_OVERRIDE_TEST="${XEDIT_CLI_OVERRIDE_TEST:-0}"
CLI_OVERRIDE_PATH="${XEDIT_CLI_OVERRIDE_PATH:-}"
CLI_OVERRIDE_ARGS="${XEDIT_CLI_OVERRIDE_ARGS:--dummy}"
INVALID_D_TEST="${XEDIT_INVALID_D_TEST:-0}"
INVALID_D_PATH="${XEDIT_INVALID_D_PATH:-/definitely/not/here}"
INVALID_D_ARGS="${XEDIT_INVALID_D_ARGS:--dummy}"

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

cases=()
if [[ -n "${HEADLESS_ARGS}" ]]; then
  cases+=("${HEADLESS_ARGS}")
else
  IFS='|' read -r -a cases <<< "${HEADLESS_CASES}"
fi

for case_args in "${cases[@]}"; do
  safe_name="$(echo "${case_args}" | tr -cs '[:alnum:]' '_' | sed 's/^_//; s/_$//')"
  [[ -z "${safe_name}" ]] && safe_name="default"
  log_file="${LOG_DIR}/xedit-headless-smoke-${safe_name}.log"

  echo "[xedit-smoke] Running: ${XEDIT_BIN_PATH} ${case_args}"
  set +e
  # shellcheck disable=SC2206
  cmd_args=( ${case_args} )
  timeout "${TIMEOUT_SECONDS}"s "${XEDIT_BIN_PATH}" "${cmd_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xedit-smoke] FAILED: command timed out after ${TIMEOUT_SECONDS}s (${case_args})"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -ne 0 ]]; then
    echo "[xedit-smoke] FAILED: non-zero exit code ${exit_code} (${case_args})"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  echo "[xedit-smoke] Exit code: ${exit_code}"
  echo "[xedit-smoke] Log: ${log_file}"
done

if [[ "${ENV_OVERRIDE_TEST}" == "1" ]]; then
  if [[ -z "${ENV_OVERRIDE_PATH}" ]]; then
    echo "[xedit-smoke] FAILED: XEDIT_ENV_OVERRIDE_TEST=1 requires XEDIT_ENV_OVERRIDE_PATH"
    exit 1
  fi

  safe_name="$(echo "env_${ENV_OVERRIDE_ARGS}" | tr -cs '[:alnum:]' '_' | sed 's/^_//; s/_$//')"
  [[ -z "${safe_name}" ]] && safe_name="env_override"
  log_file="${LOG_DIR}/xedit-headless-smoke-${safe_name}.log"

  echo "[xedit-smoke] Running env override case: XEDIT_DATA_PATH=${ENV_OVERRIDE_PATH} ${XEDIT_BIN_PATH} ${ENV_OVERRIDE_ARGS}"
  set +e
  # shellcheck disable=SC2206
  env_args=( ${ENV_OVERRIDE_ARGS} )
  XEDIT_DATA_PATH="${ENV_OVERRIDE_PATH}" timeout "${TIMEOUT_SECONDS}"s "${XEDIT_BIN_PATH}" "${env_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xedit-smoke] FAILED: env override case timed out after ${TIMEOUT_SECONDS}s"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -ne 0 ]]; then
    echo "[xedit-smoke] FAILED: env override case exit code ${exit_code}"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  echo "[xedit-smoke] Env override case exit code: ${exit_code}"
  echo "[xedit-smoke] Log: ${log_file}"
fi

if [[ "${CLI_OVERRIDE_TEST}" == "1" ]]; then
  if [[ -z "${CLI_OVERRIDE_PATH}" ]]; then
    echo "[xedit-smoke] FAILED: XEDIT_CLI_OVERRIDE_TEST=1 requires XEDIT_CLI_OVERRIDE_PATH"
    exit 1
  fi

  safe_name="$(echo "cli_${CLI_OVERRIDE_ARGS}" | tr -cs '[:alnum:]' '_' | sed 's/^_//; s/_$//')"
  [[ -z "${safe_name}" ]] && safe_name="cli_override"
  log_file="${LOG_DIR}/xedit-headless-smoke-${safe_name}.log"

  echo "[xedit-smoke] Running CLI override case: ${XEDIT_BIN_PATH} -D:${CLI_OVERRIDE_PATH} ${CLI_OVERRIDE_ARGS}"
  set +e
  # shellcheck disable=SC2206
  cli_args=( ${CLI_OVERRIDE_ARGS} )
  timeout "${TIMEOUT_SECONDS}"s "${XEDIT_BIN_PATH}" "-D:${CLI_OVERRIDE_PATH}" "${cli_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xedit-smoke] FAILED: CLI override case timed out after ${TIMEOUT_SECONDS}s"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -ne 0 ]]; then
    echo "[xedit-smoke] FAILED: CLI override case exit code ${exit_code}"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  echo "[xedit-smoke] CLI override case exit code: ${exit_code}"
  echo "[xedit-smoke] Log: ${log_file}"
fi

if [[ "${INVALID_D_TEST}" == "1" ]]; then
  safe_name="$(echo "invalid_d_${INVALID_D_ARGS}" | tr -cs '[:alnum:]' '_' | sed 's/^_//; s/_$//')"
  [[ -z "${safe_name}" ]] && safe_name="invalid_d"
  log_file="${LOG_DIR}/xedit-headless-smoke-${safe_name}.log"

  echo "[xedit-smoke] Running invalid -D case (expect failure): ${XEDIT_BIN_PATH} -D:${INVALID_D_PATH} ${INVALID_D_ARGS}"
  set +e
  # shellcheck disable=SC2206
  invalid_args=( ${INVALID_D_ARGS} )
  timeout "${TIMEOUT_SECONDS}"s "${XEDIT_BIN_PATH}" "-D:${INVALID_D_PATH}" "${invalid_args[@]}" >"${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ "${exit_code}" -eq 124 ]]; then
    echo "[xedit-smoke] FAILED: invalid -D case timed out after ${TIMEOUT_SECONDS}s"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  if [[ "${exit_code}" -eq 0 ]]; then
    echo "[xedit-smoke] FAILED: invalid -D case unexpectedly succeeded"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  if ! rg -q "Data path does not exist" "${log_file}"; then
    echo "[xedit-smoke] FAILED: invalid -D case did not report missing data path"
    echo "[xedit-smoke] Log: ${log_file}"
    exit 1
  fi

  echo "[xedit-smoke] Invalid -D case exit code (expected non-zero): ${exit_code}"
  echo "[xedit-smoke] Log: ${log_file}"
fi

echo "[xedit-smoke] PASS (all cases completed successfully)"
