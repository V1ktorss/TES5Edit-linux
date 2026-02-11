#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

IMPORT_PATTERN='^[[:space:]]*(Winapi\.(Windows|Messages|ShellAPI)|Windows|ShellAPI|Registry)\b'
IMPORT_ALLOWLIST='^(Core/(wbPlatform|wbHelpers|MSHeap)\.pas):'
CALL_PATTERN='Windows\.(AlphaBlend|LockWindowUpdate)|(^|[^.[:alnum:]_])(GetKeyState|CreateProcess|ShellExecute|MessageBox|SendMessage|PostMessage)\s*\('
CALL_ALLOWLIST='^(Core/wbPlatform\.pas):'

import_matches="$(rg -n --glob '*.pas' -e "${IMPORT_PATTERN}" Core xEdit || true)"
import_violations="$(printf '%s\n' "${import_matches}" | rg -v -e "${IMPORT_ALLOWLIST}" || true)"
call_matches="$(rg -n --glob '*.pas' -e "${CALL_PATTERN}" Core xEdit || true)"
call_violations="$(printf '%s\n' "${call_matches}" | rg -v -e "${CALL_ALLOWLIST}" || true)"

if [[ -n "${import_violations}" ]]; then
  echo "Winapi import regressions found in xEdit/Core sources." >&2
  printf '%s\n' "${import_violations}" >&2
  exit 1
fi

if [[ -n "${call_violations}" ]]; then
  echo "Direct Winapi call regressions found in xEdit/Core sources." >&2
  printf '%s\n' "${call_violations}" >&2
  exit 1
fi

echo "xEdit Winapi import guard passed."
