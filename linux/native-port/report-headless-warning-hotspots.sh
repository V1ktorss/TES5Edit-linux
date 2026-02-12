#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

HEADLESS_LOG="${HEADLESS_LOG:-/tmp/xedit-headless-current.log}"
REPORT_FILE="${REPORT_FILE:-linux/native-port/reports/headless-warning-hotspots.txt}"
RUN_SMOKE_IF_MISSING="${RUN_SMOKE_IF_MISSING:-1}"
MAX_ROWS="${MAX_ROWS:-200}"

if [[ ! -f "${HEADLESS_LOG}" ]]; then
  if [[ "${RUN_SMOKE_IF_MISSING}" == "1" ]]; then
    echo "[warning-hotspots] Missing ${HEADLESS_LOG}; running headless smoke to generate it"
    linux/native-port/headless-build-smoke.sh >/dev/null
  else
    echo "[warning-hotspots] Missing ${HEADLESS_LOG} and RUN_SMOKE_IF_MISSING=0"
    exit 1
  fi
fi

mkdir -p "$(dirname "${REPORT_FILE}")"

{
  echo "# Headless Warning Hotspots"
  echo "# generated: $(date -Iseconds)"
  echo
  echo "## Most frequent warning sites (file:line + message)"
  echo "(deduplicated by file:line:message, sorted by frequency in log)"
  echo
  set +o pipefail
  awk '
    match($0, /^([^()]+)\(([0-9]+),[0-9]+\) Warning: (.*)$/, m) {
      key=m[1] ":" m[2] " | " m[3];
      cnt[key]++
    }
    END {
      for (k in cnt) printf "%6d %s\n", cnt[k], k
    }
  ' "${HEADLESS_LOG}" | sort -nr 2>/dev/null | head -n "${MAX_ROWS}" | sed 's/^/- /'
  echo
  echo "## Most frequent uninitialized-field warning sites"
  awk '
    match($0, /^([^()]+)\(([0-9]+),[0-9]+\) Warning: (Some fields coming (after|before) ".*" were not initialized)$/, m) {
      key=m[1] ":" m[2] " | " m[3];
      cnt[key]++
    }
    END {
      for (k in cnt) printf "%6d %s\n", cnt[k], k
    }
  ' "${HEADLESS_LOG}" | sort -nr 2>/dev/null | head -n "${MAX_ROWS}" | sed 's/^/- /'
  set -o pipefail
} > "${REPORT_FILE}"

echo "[warning-hotspots] Wrote ${REPORT_FILE}"
