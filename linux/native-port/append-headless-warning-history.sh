#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

HEADLESS_LOG="${HEADLESS_LOG:-/tmp/xedit-headless-current.log}"
HISTORY_FILE="${HISTORY_FILE:-linux/native-port/reports/headless-warning-history.tsv}"
RUN_SMOKE_IF_MISSING="${RUN_SMOKE_IF_MISSING:-1}"

if [[ ! -f "${HEADLESS_LOG}" ]]; then
  if [[ "${RUN_SMOKE_IF_MISSING}" == "1" ]]; then
    echo "[warning-history] Missing ${HEADLESS_LOG}; running headless smoke to generate it"
    linux/native-port/headless-build-smoke.sh >/dev/null
  else
    echo "[warning-history] Missing ${HEADLESS_LOG} and RUN_SMOKE_IF_MISSING=0"
    exit 1
  fi
fi

extract_last_metric() {
  local label="$1"
  rg -n "\\[headless\\] ${label}:" "${HEADLESS_LOG}" \
    | tail -n 1 \
    | sed -E "s/.*${label}: ([0-9]+).*/\\1/" \
    | tr -d '[:space:]'
}

warning_lines="$(extract_last_metric "Warning lines")"
unique_warning_lines="$(extract_last_metric "Unique warning lines")"
actionable_lines="$(extract_last_metric "Actionable warning lines")"
unique_actionable_lines="$(extract_last_metric "Unique actionable warning lines")"

if [[ -z "${warning_lines}" || -z "${unique_warning_lines}" || -z "${actionable_lines}" || -z "${unique_actionable_lines}" ]]; then
  echo "[warning-history] Could not parse counters from ${HEADLESS_LOG}"
  exit 1
fi

mkdir -p "$(dirname "${HISTORY_FILE}")"
if [[ ! -f "${HISTORY_FILE}" ]]; then
  echo -e "timestamp\twarning_lines\tunique_warning_lines\tactionable_lines\tunique_actionable_lines" > "${HISTORY_FILE}"
fi

echo -e "$(date -Iseconds)\t${warning_lines}\t${unique_warning_lines}\t${actionable_lines}\t${unique_actionable_lines}" >> "${HISTORY_FILE}"
echo "[warning-history] Appended ${HISTORY_FILE}"
