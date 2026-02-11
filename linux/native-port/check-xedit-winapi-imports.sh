#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

if rg -n -e '\bWinapi\.(Windows|Messages|ShellAPI)\b' Core xEdit; then
  echo "Winapi import regressions found in xEdit/Core sources." >&2
  exit 1
fi

echo "xEdit Winapi import guard passed."
