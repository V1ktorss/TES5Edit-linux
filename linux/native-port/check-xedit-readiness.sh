#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_FILE="${ROOT_DIR}/linux/native-port/reports/xedit-readiness.txt"

"${ROOT_DIR}/linux/native-port/xedit-readiness-audit.sh" >/dev/null

if [[ ! -f "${REPORT_FILE}" ]]; then
  echo "Readiness report missing: ${REPORT_FILE}" >&2
  exit 1
fi

core_matches="$(awk -F': ' '/^- Core blocker matches:/ {print $2}' "${REPORT_FILE}" | tail -n1)"
core_files="$(awk -F': ' '/^- Core blocker files:/ {print $2}' "${REPORT_FILE}" | tail -n1)"

if [[ -z "${core_matches}" || -z "${core_files}" ]]; then
  echo "Could not parse core readiness summary from ${REPORT_FILE}" >&2
  exit 1
fi

echo "xEdit readiness summary:"
echo "- Core blocker matches: ${core_matches}"
echo "- Core blocker files: ${core_files}"

if [[ "${core_matches}" != "0" || "${core_files}" != "0" ]]; then
  echo "Core readiness blockers remain. See ${REPORT_FILE}" >&2
  exit 1
fi

echo "Core readiness check passed."
