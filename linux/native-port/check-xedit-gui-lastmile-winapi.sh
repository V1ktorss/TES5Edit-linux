#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT="${ROOT_DIR}/linux/native-port/reports/xedit-gui-surface.txt"
EXPECTED_FILE="${ROOT_DIR}/xEdit/xeMainForm.pas"

"${ROOT_DIR}/linux/native-port/audit-xedit-gui-surface.sh" >/dev/null

raw_matches="$(
  awk '
    BEGIN{in_section=0}
    /^## Raw WinAPI import matches$/ {in_section=1; next}
    /^## / && in_section==1 {in_section=0}
    in_section==1 {print}
  ' "${REPORT}" | sed '/^$/d'
)"

if [[ -z "${raw_matches}" ]]; then
  echo "[gui-lastmile] PASS: no GUI WinAPI import matches remain."
  exit 0
fi

bad=0
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  file="${line%%:*}"
  if [[ "${file}" != "${EXPECTED_FILE}" ]]; then
    echo "[gui-lastmile] FAILED: unexpected GUI WinAPI import file: ${file}" >&2
    bad=1
    continue
  fi
  if [[ "${line}" != *"Messages,"* ]]; then
    echo "[gui-lastmile] FAILED: unexpected WinAPI import shape: ${line}" >&2
    bad=1
  fi
done <<< "${raw_matches}"

if [[ "${bad}" -ne 0 ]]; then
  exit 1
fi

echo "[gui-lastmile] PASS: only expected remaining GUI WinAPI import is in xeMainForm."
