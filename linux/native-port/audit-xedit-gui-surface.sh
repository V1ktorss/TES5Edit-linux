#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/linux/native-port/reports"
OUT_FILE="${OUT_DIR}/xedit-gui-surface.txt"
TMP_FILE="${OUT_FILE}.tmp"

mkdir -p "${OUT_DIR}"

GUI_GLOB="${ROOT_DIR}/xEdit/xe*.pas"
DFM_GLOB="${ROOT_DIR}/xEdit/xe*.dfm"

VCL_IMPORT_PATTERN='^[[:space:]]*(Vcl\.[A-Za-z0-9_.]+|Forms|Controls|ExtCtrls|ComCtrls|StdCtrls|ActnList|Menus|Dialogs|Graphics|Buttons|Mask|CheckLst|Grids|ValEdit|ToolWin|ImgList|Spin|CategoryButtons|Clipbrd|Themes|Styles)[[:space:]]*[,;]'
WINAPI_IMPORT_PATTERN='^[[:space:]]*(Winapi\.(Windows|Messages|ShellAPI)|Windows|Messages|ShellAPI|Registry|ShlObj)[[:space:]]*[,;]'
INHERIT_PATTERN='=[[:space:]]*class[[:space:]]*\([[:space:]]*TForm[[:space:]]*\)'

collect_matches() {
  local pattern="$1"
  rg -n --no-heading -e "${pattern}" ${GUI_GLOB} 2>/dev/null || true
}

vcl_matches="$(collect_matches "${VCL_IMPORT_PATTERN}")"
winapi_matches="$(collect_matches "${WINAPI_IMPORT_PATTERN}")"
form_inherit_matches="$(collect_matches "${INHERIT_PATTERN}")"
dfm_count="$(ls ${DFM_GLOB} 2>/dev/null | wc -l | tr -d '[:space:]')"

{
  echo "# xEdit GUI Surface Audit"
  echo
  echo "## Summary"
  echo "- DFM form files: ${dfm_count}"
  echo "- VCL/gui import matches: $(printf "%s\n" "${vcl_matches}" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  echo "- VCL/gui import files: $(printf "%s\n" "${vcl_matches}" | awk -F: '{print $1}' | sort -u | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  echo "- WinAPI import matches in GUI units: $(printf "%s\n" "${winapi_matches}" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  echo "- WinAPI import files in GUI units: $(printf "%s\n" "${winapi_matches}" | awk -F: '{print $1}' | sort -u | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  echo "- TForm descendants: $(printf "%s\n" "${form_inherit_matches}" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  echo

  echo "## Top GUI units by VCL/gui import count"
  printf "%s\n" "${vcl_matches}" \
    | awk -F: '{count[$1]++} END{for (f in count) print count[f] "\t" f}' \
    | sort -rn \
    | sed -n '1,25p'
  echo

  echo "## Top GUI units by WinAPI import count"
  printf "%s\n" "${winapi_matches}" \
    | awk -F: '{count[$1]++} END{for (f in count) print count[f] "\t" f}' \
    | sort -rn \
    | sed -n '1,25p'
  echo

  echo "## Raw VCL/gui import matches"
  printf "%s\n" "${vcl_matches}"
  echo

  echo "## Raw WinAPI import matches"
  printf "%s\n" "${winapi_matches}"
  echo

  echo "## Raw TForm descendants"
  printf "%s\n" "${form_inherit_matches}"
} > "${TMP_FILE}"

if [[ -f "${OUT_FILE}" ]] && cmp -s "${TMP_FILE}" "${OUT_FILE}"; then
  rm -f "${TMP_FILE}"
  echo "Unchanged: ${OUT_FILE}"
  exit 0
fi

mv -f "${TMP_FILE}" "${OUT_FILE}"
echo "Wrote: ${OUT_FILE}"
