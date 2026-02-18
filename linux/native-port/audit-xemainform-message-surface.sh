#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="${ROOT_DIR}/xEdit/xeMainForm.pas"
OUT_DIR="${ROOT_DIR}/linux/native-port/reports"
OUT_FILE="${OUT_DIR}/xemainform-message-surface.txt"
TMP_FILE="${OUT_FILE}.tmp"

mkdir -p "${OUT_DIR}"

HANDLER_PATTERN='message[[:space:]]+WM_[A-Z0-9_+ ]+'
MESSAGE_TYPE_PATTERN='\bTMessage\b'
WM_USE_PATTERN='(^|[^[:alnum:]_])WM_[A-Z0-9_]+([[:space:]]*\\+[[:space:]]*[0-9]+)?'

handlers="$(rg -n --no-heading -e "${HANDLER_PATTERN}" "${TARGET}" || true)"
message_type_uses="$(rg -n --no-heading -e "${MESSAGE_TYPE_PATTERN}" "${TARGET}" || true)"
wm_uses="$(rg -n --no-heading -e "${WM_USE_PATTERN}" "${TARGET}" || true)"

{
  echo "# xeMainForm Message Surface Audit"
  echo
  echo "## Summary"
  echo "- Handler declarations using message WM_*: $(printf "%s\n" "${handlers}" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  echo "- TMessage parameter usages: $(printf "%s\n" "${message_type_uses}" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  echo "- WM_* references (raw): $(printf "%s\n" "${wm_uses}" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  echo

  echo "## Handler Declarations"
  printf "%s\n" "${handlers}"
  echo

  echo "## TMessage Usages"
  printf "%s\n" "${message_type_uses}"
  echo

  echo "## WM_* References"
  printf "%s\n" "${wm_uses}"
} > "${TMP_FILE}"

if [[ -f "${OUT_FILE}" ]] && cmp -s "${TMP_FILE}" "${OUT_FILE}"; then
  rm -f "${TMP_FILE}"
  echo "Unchanged: ${OUT_FILE}"
  exit 0
fi

mv -f "${TMP_FILE}" "${OUT_FILE}"
echo "Wrote: ${OUT_FILE}"
