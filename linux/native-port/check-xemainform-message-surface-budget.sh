#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT="${ROOT_DIR}/linux/native-port/reports/xemainform-message-surface.txt"
BASELINE="${ROOT_DIR}/linux/native-port/baselines/xemainform-message-surface-budget.env"

if [[ ! -f "${BASELINE}" ]]; then
  echo "[xemainform-budget] Missing baseline: ${BASELINE}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${BASELINE}"

"${ROOT_DIR}/linux/native-port/audit-xemainform-message-surface.sh" >/dev/null

extract_metric() {
  local label="$1"
  rg -n "^- ${label}: " "${REPORT}" \
    | sed -E 's/^.*: ([0-9]+)$/\1/' \
    | head -n 1
}

HANDLER_BINDINGS="$(extract_metric "Handler declarations using message WM_\\*")"
TMESSAGE_USAGES="$(extract_metric "TMessage parameter usages")"
RAW_WM_REFS="$(extract_metric "WM_\\* references \\(raw\\)")"

fail_if_over() {
  local name="$1"
  local value="$2"
  local max="$3"
  if [[ -z "${value}" ]]; then
    echo "[xemainform-budget] Missing metric: ${name}" >&2
    exit 1
  fi
  if (( value > max )); then
    echo "[xemainform-budget] FAILED: ${name}=${value} exceeds max ${max}" >&2
    exit 1
  fi
}

fail_if_over "handler bindings" "${HANDLER_BINDINGS}" "${MAX_HANDLER_BINDINGS}"
fail_if_over "TMessage usages" "${TMESSAGE_USAGES}" "${MAX_TMESSAGE_USAGES}"
fail_if_over "raw WM refs" "${RAW_WM_REFS}" "${MAX_RAW_WM_REFS}"

echo "[xemainform-budget] handler bindings=${HANDLER_BINDINGS} max=${MAX_HANDLER_BINDINGS}"
echo "[xemainform-budget] TMessage usages=${TMESSAGE_USAGES} max=${MAX_TMESSAGE_USAGES}"
echo "[xemainform-budget] raw WM refs=${RAW_WM_REFS} max=${MAX_RAW_WM_REFS}"
echo "[xemainform-budget] PASS"
