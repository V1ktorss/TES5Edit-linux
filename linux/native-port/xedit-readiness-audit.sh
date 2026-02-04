#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/linux/native-port/reports"
OUT_FILE="${OUT_DIR}/xedit-readiness.txt"

mkdir -p "${OUT_DIR}"

PATTERN='\bWinapi\.|\bWindows\b|\bVcl\.|\bRegistry\b|\bShellAPI\b|\bShlObj\b'
EXCLUDE_PATTERN="AddConst\\('Windows'|AddFunction\\('Windows'|AddFunction\\('ShellApi'|AddFunction\\('Vcl\\.Clipbrd'|AddClass\\('Registry'"

collect_matches() {
  rg -n --no-heading -e "${PATTERN}" "$1" 2>/dev/null \
    | rg -v -e "${EXCLUDE_PATTERN}" || true
}

{
  echo "# xEdit Native Readiness Audit"
  echo "# generated: $(date -Iseconds)"
  echo
  echo "## Summary"
  total_matches="$(collect_matches "${ROOT_DIR}/xEdit" | wc -l)"
  total_files="$(collect_matches "${ROOT_DIR}/xEdit" | awk -F: '{print $1}' | sort -u | wc -l)"
  echo "- Match count: ${total_matches}"
  echo "- Files with matches: ${total_files}"
  echo

  echo "## Top files by match count"
  collect_matches "${ROOT_DIR}/xEdit" \
    | awk -F: '{count[$1]++} END{for (f in count) print count[f] "\t" f}' \
    | sort -rn \
    | sed -n '1,25p'
  echo

  echo "## Script host hotspot (JvI adapters)"
  collect_matches "${ROOT_DIR}/xEdit/JvI"
  echo

  echo "## Main form hotspot"
  collect_matches "${ROOT_DIR}/xEdit/xeMainForm.pas"
  echo

  echo "## Raw matches"
  collect_matches "${ROOT_DIR}/xEdit"
} > "${OUT_FILE}"

echo "Wrote: ${OUT_FILE}"
