#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

PATTERN='^[[:space:]]*(Winapi\.(Windows|ShellAPI)|Windows|ShellAPI|Registry)\b'
ALLOWLIST='^(Core/(wbPlatform|wbHelpers|MSHeap)\.pas):'
CALL_PATTERN='Windows\.(AlphaBlend|LockWindowUpdate)|(^|[^.[:alnum:]_])(GetKeyState|CreateProcess|ShellExecute|MessageBox|SendMessage|PostMessage)\s*\('
CALL_ALLOWLIST='^(Core/wbPlatform\.pas):'

matches="$(rg -n --glob '*.pas' -e "${PATTERN}" Core || true)"
violations="$(printf '%s\n' "${matches}" | rg -v -e "${ALLOWLIST}" || true)"
call_matches="$(rg -n --glob '*.pas' -e "${CALL_PATTERN}" Core || true)"
call_violations="$(printf '%s\n' "${call_matches}" | rg -v -e "${CALL_ALLOWLIST}" || true)"

if [[ -n "${violations}" ]]; then
  echo "Unexpected Core Winapi import regressions found." >&2
  printf '%s\n' "${violations}" >&2
  exit 1
fi

if [[ -n "${call_violations}" ]]; then
  echo "Unexpected direct Core Winapi call regressions found." >&2
  printf '%s\n' "${call_violations}" >&2
  exit 1
fi

echo "Core Winapi import guard passed."
