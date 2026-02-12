#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

HEADLESS_LOG="${HEADLESS_LOG:-/tmp/xedit-headless-current.log}"
REPORT_FILE="${REPORT_FILE:-linux/native-port/reports/headless-warning-summary.txt}"
RUN_SMOKE_IF_MISSING="${RUN_SMOKE_IF_MISSING:-1}"
BASELINE_FILE="${BASELINE_FILE:-linux/native-port/baselines/headless-warning-budget.env}"

if [[ ! -f "${HEADLESS_LOG}" ]]; then
  if [[ "${RUN_SMOKE_IF_MISSING}" == "1" ]]; then
    echo "[warning-report] Missing ${HEADLESS_LOG}; running headless smoke to generate it"
    linux/native-port/headless-build-smoke.sh >/dev/null
  else
    echo "[warning-report] Missing ${HEADLESS_LOG} and RUN_SMOKE_IF_MISSING=0"
    exit 1
  fi
fi

mkdir -p "$(dirname "${REPORT_FILE}")"

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
project_warning_lines="$(
  {
    rg -n "Warning:" "${HEADLESS_LOG}" \
      | sed -E 's/^[0-9]+://' \
      | rg "\.pas\([0-9]+,[0-9]+\) Warning:" || true
  } \
    | wc -l \
    | tr -d '[:space:]'
)"
project_unique_warning_lines="$(
  {
    rg -n "Warning:" "${HEADLESS_LOG}" \
      | sed -E 's/^[0-9]+://' \
      | rg "\.pas\([0-9]+,[0-9]+\) Warning:" || true
  } \
    | sort -u \
    | wc -l \
    | tr -d '[:space:]'
)"

if [[ -z "${warning_lines}" || -z "${unique_warning_lines}" || -z "${actionable_lines}" || -z "${unique_actionable_lines}" || -z "${project_warning_lines}" || -z "${project_unique_warning_lines}" ]]; then
  echo "[warning-report] Could not parse counters from ${HEADLESS_LOG}"
  exit 1
fi

baseline_warning_lines=""
baseline_unique_warning_lines=""
baseline_actionable_lines=""
baseline_unique_actionable_lines=""
baseline_project_warning_lines=""
baseline_project_unique_warning_lines=""
if [[ -f "${BASELINE_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${BASELINE_FILE}"
  baseline_warning_lines="${MAX_WARNING_LINES:-}"
  baseline_unique_warning_lines="${MAX_UNIQUE_WARNING_LINES:-}"
  baseline_actionable_lines="${MAX_ACTIONABLE_WARNING_LINES:-}"
  baseline_unique_actionable_lines="${MAX_UNIQUE_ACTIONABLE_WARNING_LINES:-}"
  baseline_project_warning_lines="${MAX_PROJECT_WARNING_LINES:-}"
  baseline_project_unique_warning_lines="${MAX_PROJECT_UNIQUE_WARNING_LINES:-}"
fi

calc_delta() {
  local current="$1"
  local baseline="$2"
  if [[ -z "${baseline}" ]]; then
    echo "n/a"
    return 0
  fi

  local delta=$((current - baseline))
  if (( delta > 0 )); then
    echo "+${delta}"
  else
    echo "${delta}"
  fi
}

{
  echo "# Headless Warning Summary"
  echo "# generated: $(date -Iseconds)"
  echo
  echo "## Counters"
  echo "- Warning lines: ${warning_lines}"
  echo "- Unique warning lines: ${unique_warning_lines}"
  echo "- Project warning lines (.pas): ${project_warning_lines}"
  echo "- Project unique warning lines (.pas): ${project_unique_warning_lines}"
  echo "- Actionable warning lines: ${actionable_lines}"
  echo "- Unique actionable warning lines: ${unique_actionable_lines}"
  echo
  echo "## Baseline Delta (current - baseline)"
  echo "- Warning lines: $(calc_delta "${warning_lines}" "${baseline_warning_lines}")"
  echo "- Unique warning lines: $(calc_delta "${unique_warning_lines}" "${baseline_unique_warning_lines}")"
  echo "- Project warning lines (.pas): $(calc_delta "${project_warning_lines}" "${baseline_project_warning_lines}")"
  echo "- Project unique warning lines (.pas): $(calc_delta "${project_unique_warning_lines}" "${baseline_project_unique_warning_lines}")"
  echo "- Actionable warning lines: $(calc_delta "${actionable_lines}" "${baseline_actionable_lines}")"
  echo "- Unique actionable warning lines: $(calc_delta "${unique_actionable_lines}" "${baseline_unique_actionable_lines}")"
  echo
  echo "## Top warning files"
  awk '
    BEGIN {in_files=0}
    /^\[headless\] Top warning files:/ {in_files=1; next}
    /^\[headless\] Top unique warning files:/ {if (in_files==1) exit}
    {
      if (in_files==1 && $0 ~ /^\[headless\] +[0-9]+ /) {
        sub(/^\[headless\] /, "- ");
        print;
      }
    }
  ' "${HEADLESS_LOG}"
  echo
  echo "## Top warning types"
  awk '
    BEGIN {in_types=0}
    /^\[headless\] Top warning types:/ {in_types=1; next}
    /^\[headless\] Top unique warning types:/ {if (in_types==1) exit}
    {
      if (in_types==1 && $0 ~ /^\[headless\] +[0-9]+ /) {
        sub(/^\[headless\] /, "- ");
        print;
      }
    }
  ' "${HEADLESS_LOG}"
  echo
  echo "## Top unique warning types"
  awk '
    BEGIN {in_types=0}
    /^\[headless\] Top unique warning types:/ {in_types=1; next}
    /^\[headless\] Actionable warning lines:/ {if (in_types==1) exit}
    {
      if (in_types==1 && $0 ~ /^\[headless\] +[0-9]+ /) {
        sub(/^\[headless\] /, "- ");
        print;
      }
    }
  ' "${HEADLESS_LOG}"
  echo
  echo "## Top actionable warning types"
  actionable_block="$(
  awk '
    BEGIN {in_types=0}
    /^\[headless\] Top actionable warning types:/ {in_types=1; next}
    /^\[headless\] PASS$/ {if (in_types==1) exit}
    {
      if (in_types==1 && $0 ~ /^\[headless\] +[0-9]+ /) {
        sub(/^\[headless\] /, "- ");
        print;
      }
    }
  ' "${HEADLESS_LOG}"
  )"
  if [[ -n "${actionable_block}" ]]; then
    printf "%s\n" "${actionable_block}"
  else
    echo "- none"
  fi
} > "${REPORT_FILE}"

echo "[warning-report] Wrote ${REPORT_FILE}"
