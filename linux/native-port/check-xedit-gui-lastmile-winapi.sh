#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT="${ROOT_DIR}/linux/native-port/reports/xedit-gui-surface.txt"
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

echo "[gui-lastmile] FAILED: GUI WinAPI imports reintroduced:" >&2
echo "${raw_matches}" >&2
exit 1
