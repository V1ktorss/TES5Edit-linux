#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

BASELINE_FILE="linux/native-port/baselines/fpc-fallback-budget.env"

if [[ ! -f "${BASELINE_FILE}" ]]; then
  echo "[fpc-fallback-budget] Missing baseline: ${BASELINE_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${BASELINE_FILE}"

MAX_TOTAL_FPC_IFDEF="${MAX_TOTAL_FPC_IFDEF:-0}"
MAX_DEFINITION_FPC_IFDEF="${MAX_DEFINITION_FPC_IFDEF:-0}"

total_count="$(rg -n -F '{$IFDEF FPC}' Core xEdit xDump --glob '*.{pas,dpr,inc}' | wc -l | tr -d ' ')"
definition_count="$(rg -n -F '{$IFDEF FPC}' Core/wbDefinitions*.pas | wc -l | tr -d ' ')"

echo "[fpc-fallback-budget] total_ifdef=${total_count} max=${MAX_TOTAL_FPC_IFDEF}"
echo "[fpc-fallback-budget] definition_ifdef=${definition_count} max=${MAX_DEFINITION_FPC_IFDEF}"

if (( total_count > MAX_TOTAL_FPC_IFDEF )); then
  echo "[fpc-fallback-budget] FAIL: total FPC fallback markers regressed." >&2
  exit 1
fi

if (( definition_count > MAX_DEFINITION_FPC_IFDEF )); then
  echo "[fpc-fallback-budget] FAIL: definition FPC fallback markers regressed." >&2
  exit 1
fi

echo "[fpc-fallback-budget] PASS"
