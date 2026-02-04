#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/linux/native-port/reports"
OUT_FILE="${OUT_DIR}/xedit-readiness.txt"

mkdir -p "${OUT_DIR}"

PATTERN='\bWinapi\.|\bWindows\b|\bVcl\.|\bRegistry\b|\bShellAPI\b|\bShlObj\b'

{
  echo "# xEdit Native Readiness Audit"
  echo "# generated: $(date -Iseconds)"
  echo
  echo "## Summary"
  total_matches="$( (rg -n --no-heading -e "${PATTERN}" "${ROOT_DIR}/xEdit" || true) | wc -l )"
  total_files="$( (rg -l -e "${PATTERN}" "${ROOT_DIR}/xEdit" || true) | wc -l )"
  echo "- Match count: ${total_matches}"
  echo "- Files with matches: ${total_files}"
  echo

  echo "## Top files by match count"
  (rg -n --no-heading -e "${PATTERN}" "${ROOT_DIR}/xEdit" || true) \
    | awk -F: '{count[$1]++} END{for (f in count) print count[f] "\t" f}' \
    | sort -rn \
    | sed -n '1,25p'
  echo

  echo "## Script host hotspot (JvI adapters)"
  rg -n --no-heading -e "${PATTERN}" "${ROOT_DIR}/xEdit/JvI" || true
  echo

  echo "## Main form hotspot"
  rg -n --no-heading -e "${PATTERN}" "${ROOT_DIR}/xEdit/xeMainForm.pas" || true
  echo

  echo "## Raw matches"
  rg -n --no-heading -e "${PATTERN}" "${ROOT_DIR}/xEdit"
} > "${OUT_FILE}"

echo "Wrote: ${OUT_FILE}"
