#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

PATTERN='^\s*for\s+var\b|^\s*var\s+[A-Za-z_][A-Za-z0-9_]*\s*:='

if rg -n -e "${PATTERN}" Core xEdit xEdit.dpr; then
  echo "Inline-variable regressions found in xEdit/Core sources." >&2
  exit 1
fi

echo "xEdit inline-var guard passed."
