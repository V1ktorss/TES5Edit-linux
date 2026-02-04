#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/linux/native-port/reports"
OUT_FILE="${OUT_DIR}/windows-deps.txt"

mkdir -p "$OUT_DIR"

{
  echo "# Windows/VCL dependency audit"
  echo "# generated: $(date -Iseconds)"
  echo
  echo "## Matches (unit imports and direct refs)"
  rg -n --no-heading \
    -e "\\bWinapi\\." \
    -e "\\bWindows\\b" \
    -e "\\bVcl\\." \
    -e "\\bRegistry\\b" \
    -e "\\bShellAPI\\b" \
    -e "\\bShlObj\\b" \
    "${ROOT_DIR}/Core" "${ROOT_DIR}/xEdit" "${ROOT_DIR}/BSArch" "${ROOT_DIR}/Sniff" "${ROOT_DIR}/xDump"
  echo
  echo "## Project files tied to Delphi toolchain"
  rg -n --no-heading \
    -e "Delphi.Personality" \
    -e "CodeGear.Delphi.Targets" \
    "${ROOT_DIR}/xEdit.dproj" "${ROOT_DIR}/BSArch.dproj" "${ROOT_DIR}/Sniff.dproj" "${ROOT_DIR}/xDump.dproj"
} > "$OUT_FILE"

echo "Wrote: $OUT_FILE"
