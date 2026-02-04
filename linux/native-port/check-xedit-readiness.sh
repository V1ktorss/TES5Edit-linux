#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_FILE="${ROOT_DIR}/linux/native-port/reports/xedit-readiness.txt"
ENFORCE_STYLE="${ENFORCE_STYLE:-0}"

"${ROOT_DIR}/linux/native-port/xedit-readiness-audit.sh" >/dev/null

if [[ ! -f "${REPORT_FILE}" ]]; then
  echo "Readiness report missing: ${REPORT_FILE}" >&2
  exit 1
fi

core_matches="$(awk -F': ' '/^- Core blocker matches:/ {print $2}' "${REPORT_FILE}" | tail -n1)"
core_files="$(awk -F': ' '/^- Core blocker files:/ {print $2}' "${REPORT_FILE}" | tail -n1)"
style_matches="$(awk -F': ' '/^- Style namespace matches \(informational\):/ {print $2}' "${REPORT_FILE}" | tail -n1)"
style_files="$(awk -F': ' '/^- Style namespace files \(informational\):/ {print $2}' "${REPORT_FILE}" | tail -n1)"

if [[ -z "${core_matches}" || -z "${core_files}" || -z "${style_matches}" || -z "${style_files}" ]]; then
  echo "Could not parse readiness summary from ${REPORT_FILE}" >&2
  exit 1
fi

echo "xEdit readiness summary:"
echo "- Core blocker matches: ${core_matches}"
echo "- Core blocker files: ${core_files}"
echo "- Style namespace matches: ${style_matches}"
echo "- Style namespace files: ${style_files}"

if [[ "${core_matches}" != "0" || "${core_files}" != "0" ]]; then
  echo "Core readiness blockers remain. See ${REPORT_FILE}" >&2
  exit 1
fi

if [[ "${ENFORCE_STYLE}" == "1" ]]; then
  if [[ "${style_matches}" != "0" || "${style_files}" != "0" ]]; then
    echo "Style namespace usage remains but ENFORCE_STYLE=1 was requested." >&2
    echo "See ${REPORT_FILE}" >&2
    exit 1
  fi
fi

echo "Readiness check passed."
