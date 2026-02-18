#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

REPORT_DIR="${ROOT_DIR}/linux/native-port/reports"
REPORT_FILE="${REPORT_DIR}/fpc-fallback-surface.txt"

mkdir -p "${REPORT_DIR}"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

all_matches="$(rg -n -F '{$IFDEF FPC}' Core xEdit xDump --glob '*.{pas,dpr,inc}' || true)"
def_matches="$(rg -n -F '{$IFDEF FPC}' Core/wbDefinitions*.pas || true)"

all_total=0
if [[ -n "${all_matches}" ]]; then
  all_total="$(printf '%s\n' "${all_matches}" | wc -l | tr -d ' ')"
fi

def_total=0
if [[ -n "${def_matches}" ]]; then
  def_total="$(printf '%s\n' "${def_matches}" | wc -l | tr -d ' ')"
fi

{
  echo "# FPC Fallback Surface Audit"
  echo
  echo "Generated: ${timestamp}"
  echo
  echo "## Totals"
  echo "- Total \`{\$IFDEF FPC}\` markers (Core+xEdit+xDump): ${all_total}"
  echo "- Total \`{\$IFDEF FPC}\` markers (Core/wbDefinitions*.pas): ${def_total}"
  echo
  echo "## Top Files (Core+xEdit+xDump)"
  if [[ -n "${all_matches}" ]]; then
    printf '%s\n' "${all_matches}" \
      | awk -F: '{c[$1]++} END{for (f in c) printf("- %s: %d\n", f, c[f])}' \
      | sort -t: -k2,2nr
  else
    echo "- none"
  fi
  echo
  echo "## Definition Files (Core/wbDefinitions*.pas)"
  if [[ -n "${def_matches}" ]]; then
    printf '%s\n' "${def_matches}" \
      | awk -F: '{c[$1]++} END{for (f in c) printf("- %s: %d\n", f, c[f])}' \
      | sort -t: -k2,2nr
  else
    echo "- none"
  fi
} > "${REPORT_FILE}"

echo "Wrote: ${REPORT_FILE}"
