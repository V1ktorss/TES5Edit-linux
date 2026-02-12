#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

HEADLESS_LOG="${HEADLESS_LOG:-/tmp/xedit-headless-current.log}"
BASELINE_FILE="${BASELINE_FILE:-linux/native-port/baselines/headless-warning-budget.env}"
ALLOW_INCREASE="${ALLOW_INCREASE:-0}"

if [[ ! -f "${HEADLESS_LOG}" ]]; then
  echo "[warning-budget-update] Missing ${HEADLESS_LOG}"
  echo "[warning-budget-update] Run linux/native-port/headless-build-smoke.sh first"
  exit 1
fi

new_warning_lines="$(
  rg -n "\\[headless\\] Warning lines:" "${HEADLESS_LOG}" \
    | tail -n 1 \
    | sed -E 's/.*Warning lines: ([0-9]+).*/\1/' \
    | tr -d '[:space:]'
)"
new_actionable_lines="$(
  rg -n "\\[headless\\] Actionable warning lines:" "${HEADLESS_LOG}" \
    | tail -n 1 \
    | sed -E 's/.*Actionable warning lines: ([0-9]+).*/\1/' \
    | tr -d '[:space:]'
)"

if [[ -z "${new_warning_lines}" || -z "${new_actionable_lines}" ]]; then
  echo "[warning-budget-update] Could not parse counters from ${HEADLESS_LOG}"
  exit 1
fi

old_warning_lines=""
old_actionable_lines=""
if [[ -f "${BASELINE_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${BASELINE_FILE}"
  old_warning_lines="${MAX_WARNING_LINES:-}"
  old_actionable_lines="${MAX_ACTIONABLE_WARNING_LINES:-}"
fi

if [[ "${ALLOW_INCREASE}" != "1" ]]; then
  if [[ -n "${old_warning_lines}" ]] && (( new_warning_lines > old_warning_lines )); then
    echo "[warning-budget-update] Refusing increase: warning lines ${old_warning_lines} -> ${new_warning_lines}"
    echo "[warning-budget-update] Re-run with ALLOW_INCREASE=1 to override"
    exit 1
  fi
  if [[ -n "${old_actionable_lines}" ]] && (( new_actionable_lines > old_actionable_lines )); then
    echo "[warning-budget-update] Refusing increase: actionable lines ${old_actionable_lines} -> ${new_actionable_lines}"
    echo "[warning-budget-update] Re-run with ALLOW_INCREASE=1 to override"
    exit 1
  fi
fi

cat > "${BASELINE_FILE}" <<EOF
MAX_WARNING_LINES=${new_warning_lines}
MAX_ACTIONABLE_WARNING_LINES=${new_actionable_lines}
EOF

echo "[warning-budget-update] Updated ${BASELINE_FILE}"
echo "[warning-budget-update] warning_lines=${new_warning_lines}"
echo "[warning-budget-update] actionable_lines=${new_actionable_lines}"
