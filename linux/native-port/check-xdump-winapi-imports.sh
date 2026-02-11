#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

IMPORT_PATTERN='^[[:space:]]*(Winapi\.(Windows|Messages|ShellAPI)|Windows|Messages|ShellAPI|Registry)\b'
CALL_PATTERN='Windows\.(AlphaBlend|LockWindowUpdate)|(^|[^.[:alnum:]_])(GetKeyState|CreateProcess|ShellExecute|MessageBox|SendMessage|PostMessage)\s*\('

import_matches="$(rg -n -e "${IMPORT_PATTERN}" xDump.dpr || true)"
call_matches="$(rg -n -e "${CALL_PATTERN}" xDump.dpr || true)"

if [[ -n "${import_matches}" ]]; then
  echo "xDump Winapi import regressions found." >&2
  printf '%s\n' "${import_matches}" >&2
  exit 1
fi

if [[ -n "${call_matches}" ]]; then
  echo "xDump direct Winapi call regressions found." >&2
  printf '%s\n' "${call_matches}" >&2
  exit 1
fi

echo "xDump Winapi import guard passed."
