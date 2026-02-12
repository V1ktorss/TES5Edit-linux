#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

HEADLESS_LOG="${HEADLESS_LOG:-/tmp/xedit-headless-current.log}"
RUN_SMOKE_IF_MISSING="${RUN_SMOKE_IF_MISSING:-1}"
BASELINE_FILE="${BASELINE_FILE:-linux/native-port/baselines/headless-warning-budget.env}"

if [[ -f "${BASELINE_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${BASELINE_FILE}"
fi

MAX_WARNING_LINES="${MAX_WARNING_LINES:-5152}"
MAX_ACTIONABLE_WARNING_LINES="${MAX_ACTIONABLE_WARNING_LINES:-0}"
MAX_UNIQUE_WARNING_LINES="${MAX_UNIQUE_WARNING_LINES:-5152}"
MAX_UNIQUE_ACTIONABLE_WARNING_LINES="${MAX_UNIQUE_ACTIONABLE_WARNING_LINES:-0}"

if [[ ! -f "${HEADLESS_LOG}" ]]; then
  if [[ "${RUN_SMOKE_IF_MISSING}" == "1" ]]; then
    echo "[warning-budget] Missing ${HEADLESS_LOG}; running headless smoke to generate it"
    linux/native-port/headless-build-smoke.sh >/dev/null
  else
    echo "[warning-budget] Missing ${HEADLESS_LOG} and RUN_SMOKE_IF_MISSING=0"
    exit 1
  fi
fi

warning_lines="$(
  rg -n "\\[headless\\] Warning lines:" "${HEADLESS_LOG}" \
    | tail -n 1 \
    | sed -E 's/.*Warning lines: ([0-9]+).*/\1/' \
    | tr -d '[:space:]'
)"
actionable_lines="$(
  rg -n "\\[headless\\] Actionable warning lines:" "${HEADLESS_LOG}" \
    | tail -n 1 \
    | sed -E 's/.*Actionable warning lines: ([0-9]+).*/\1/' \
    | tr -d '[:space:]'
)"
unique_warning_lines="$(
  rg -n "\\[headless\\] Unique warning lines:" "${HEADLESS_LOG}" \
    | tail -n 1 \
    | sed -E 's/.*Unique warning lines: ([0-9]+).*/\1/' \
    | tr -d '[:space:]'
)"
unique_actionable_lines="$(
  rg -n "\\[headless\\] Unique actionable warning lines:" "${HEADLESS_LOG}" \
    | tail -n 1 \
    | sed -E 's/.*Unique actionable warning lines: ([0-9]+).*/\1/' \
    | tr -d '[:space:]'
)"

if [[ -z "${warning_lines}" || -z "${actionable_lines}" || -z "${unique_warning_lines}" || -z "${unique_actionable_lines}" ]]; then
  echo "[warning-budget] Could not parse warning counters from ${HEADLESS_LOG}"
  exit 1
fi

echo "[warning-budget] warning_lines=${warning_lines} max=${MAX_WARNING_LINES}"
echo "[warning-budget] actionable_lines=${actionable_lines} max=${MAX_ACTIONABLE_WARNING_LINES}"
echo "[warning-budget] unique_warning_lines=${unique_warning_lines} max=${MAX_UNIQUE_WARNING_LINES}"
echo "[warning-budget] unique_actionable_lines=${unique_actionable_lines} max=${MAX_UNIQUE_ACTIONABLE_WARNING_LINES}"

if (( warning_lines > MAX_WARNING_LINES )); then
  echo "[warning-budget] FAIL: warning line budget exceeded"
  exit 1
fi

if (( actionable_lines > MAX_ACTIONABLE_WARNING_LINES )); then
  echo "[warning-budget] FAIL: actionable warning budget exceeded"
  exit 1
fi

if (( unique_warning_lines > MAX_UNIQUE_WARNING_LINES )); then
  echo "[warning-budget] FAIL: unique warning line budget exceeded"
  exit 1
fi

if (( unique_actionable_lines > MAX_UNIQUE_ACTIONABLE_WARNING_LINES )); then
  echo "[warning-budget] FAIL: unique actionable warning budget exceeded"
  exit 1
fi

echo "[warning-budget] PASS"
