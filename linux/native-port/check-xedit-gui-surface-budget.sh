#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT="${ROOT_DIR}/linux/native-port/reports/xedit-gui-surface.txt"
BASELINE="${ROOT_DIR}/linux/native-port/baselines/xedit-gui-surface-budget.env"

if [[ ! -f "${BASELINE}" ]]; then
  echo "[gui-budget] Missing baseline: ${BASELINE}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${BASELINE}"

"${ROOT_DIR}/linux/native-port/audit-xedit-gui-surface.sh" >/dev/null

extract_metric() {
  local label="$1"
  rg -n "^- ${label}: " "${REPORT}" \
    | sed -E 's/^.*: ([0-9]+)$/\1/' \
    | head -n 1
}

DFM_FORM_FILES="$(extract_metric "DFM form files")"
TFORM_DESCENDANTS="$(extract_metric "TForm descendants")"
VCL_GUI_IMPORT_MATCHES="$(extract_metric "VCL/gui import matches")"
VCL_GUI_IMPORT_FILES="$(extract_metric "VCL/gui import files")"
WINAPI_GUI_IMPORT_MATCHES="$(extract_metric "WinAPI import matches in GUI units")"
WINAPI_GUI_IMPORT_FILES="$(extract_metric "WinAPI import files in GUI units")"

fail_if_over() {
  local name="$1"
  local value="$2"
  local max="$3"
  if [[ -z "${value}" ]]; then
    echo "[gui-budget] Missing metric: ${name}" >&2
    exit 1
  fi
  if (( value > max )); then
    echo "[gui-budget] FAILED: ${name}=${value} exceeds max ${max}" >&2
    exit 1
  fi
}

fail_if_over "DFM form files" "${DFM_FORM_FILES}" "${MAX_DFM_FORM_FILES}"
fail_if_over "TForm descendants" "${TFORM_DESCENDANTS}" "${MAX_TFORM_DESCENDANTS}"
fail_if_over "VCL/gui import matches" "${VCL_GUI_IMPORT_MATCHES}" "${MAX_VCL_GUI_IMPORT_MATCHES}"
fail_if_over "VCL/gui import files" "${VCL_GUI_IMPORT_FILES}" "${MAX_VCL_GUI_IMPORT_FILES}"
fail_if_over "WinAPI import matches in GUI units" "${WINAPI_GUI_IMPORT_MATCHES}" "${MAX_WINAPI_GUI_IMPORT_MATCHES}"
fail_if_over "WinAPI import files in GUI units" "${WINAPI_GUI_IMPORT_FILES}" "${MAX_WINAPI_GUI_IMPORT_FILES}"

echo "[gui-budget] DFM form files=${DFM_FORM_FILES} max=${MAX_DFM_FORM_FILES}"
echo "[gui-budget] TForm descendants=${TFORM_DESCENDANTS} max=${MAX_TFORM_DESCENDANTS}"
echo "[gui-budget] VCL/gui import matches=${VCL_GUI_IMPORT_MATCHES} max=${MAX_VCL_GUI_IMPORT_MATCHES}"
echo "[gui-budget] VCL/gui import files=${VCL_GUI_IMPORT_FILES} max=${MAX_VCL_GUI_IMPORT_FILES}"
echo "[gui-budget] WinAPI import matches in GUI units=${WINAPI_GUI_IMPORT_MATCHES} max=${MAX_WINAPI_GUI_IMPORT_MATCHES}"
echo "[gui-budget] WinAPI import files in GUI units=${WINAPI_GUI_IMPORT_FILES} max=${MAX_WINAPI_GUI_IMPORT_FILES}"
echo "[gui-budget] PASS"
