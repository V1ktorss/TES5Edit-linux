#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/linux/native-port/reports"
OUT_FILE="${OUT_DIR}/xedit-readiness.txt"

mkdir -p "${OUT_DIR}"

CORE_PATTERN='\bWinapi\.|\bWindows\b|\bRegistry\b|\bShellAPI\b|\bShlObj\b|\bLockWindowUpdate\s*\(|(^|[^.[:alnum:]_])SendMessage\s*\(|(^|[^.[:alnum:]_])PostMessage\s*\('
STYLE_PATTERN='\bVcl\.Styles\.|\bVcl\.Themes\b|\bVcl\.Samples\.'
EXCLUDE_PATTERN="AddConst\\('Windows'|AddFunction\\('Windows'|AddFunction\\('ShellApi'|AddFunction\\('Vcl\\.Clipbrd'|AddClass\\('Registry'|CurrentVersion\\\\Uninstall"

collect_core_matches() {
  rg -n --no-heading -e "${CORE_PATTERN}" "$1" 2>/dev/null \
    | rg -v -e "${EXCLUDE_PATTERN}" || true
}

collect_style_matches() {
  rg -n --no-heading -e "${STYLE_PATTERN}" "$1" 2>/dev/null || true
}

{
  echo "# xEdit Native Readiness Audit"
  echo "# generated: $(date -Iseconds)"
  echo
  echo "## Summary"
  total_core_matches="$(collect_core_matches "${ROOT_DIR}/xEdit" | wc -l)"
  total_core_files="$(collect_core_matches "${ROOT_DIR}/xEdit" | awk -F: '{print $1}' | sort -u | wc -l)"
  total_style_matches="$(collect_style_matches "${ROOT_DIR}/xEdit" | wc -l)"
  total_style_files="$(collect_style_matches "${ROOT_DIR}/xEdit" | awk -F: '{print $1}' | sort -u | wc -l)"
  echo "- Core blocker matches: ${total_core_matches}"
  echo "- Core blocker files: ${total_core_files}"
  echo "- Style namespace matches (informational): ${total_style_matches}"
  echo "- Style namespace files (informational): ${total_style_files}"
  echo

  echo "## Top files by core blocker count"
  collect_core_matches "${ROOT_DIR}/xEdit" \
    | awk -F: '{count[$1]++} END{for (f in count) print count[f] "\t" f}' \
    | sort -rn \
    | sed -n '1,25p'
  echo

  echo "## Script host hotspot (JvI adapters)"
  collect_core_matches "${ROOT_DIR}/xEdit/JvI"
  echo

  echo "## Main form core hotspot"
  collect_core_matches "${ROOT_DIR}/xEdit/xeMainForm.pas"
  echo

  echo "## Raw core blocker matches"
  collect_core_matches "${ROOT_DIR}/xEdit"
  echo

  echo "## Raw style namespace matches (informational)"
  collect_style_matches "${ROOT_DIR}/xEdit"
} > "${OUT_FILE}"

echo "Wrote: ${OUT_FILE}"
