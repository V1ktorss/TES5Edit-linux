#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

HISTORY_FILE="${HISTORY_FILE:-linux/native-port/reports/headless-warning-history.tsv}"
TREND_FILE="${TREND_FILE:-linux/native-port/reports/headless-warning-trend.txt}"
MAX_ROWS="${MAX_ROWS:-20}"

if [[ ! -f "${HISTORY_FILE}" ]]; then
  echo "[warning-trend] Missing ${HISTORY_FILE}"
  exit 1
fi

mkdir -p "$(dirname "${TREND_FILE}")"

{
  echo "# Headless Warning Trend"
  echo "# generated: $(date -Iseconds)"
  echo
  echo "Showing last ${MAX_ROWS} entries from: ${HISTORY_FILE}"
  echo
  printf "%-26s %8s %8s %8s %8s | %8s %8s %8s %8s\n" \
    "timestamp" "warn" "uniq" "act" "uact" "d_warn" "d_uniq" "d_act" "d_uact"
  printf "%-26s %8s %8s %8s %8s | %8s %8s %8s %8s\n" \
    "--------------------------" "--------" "--------" "--------" "--------" "--------" "--------" "--------" "--------"
} > "${TREND_FILE}"

tail -n +2 "${HISTORY_FILE}" | tail -n "${MAX_ROWS}" | awk -F'\t' '
  function fmt_delta(v) {
    if (v > 0) return "+" v;
    return v;
  }
  {
    ts=$1; w=$2; u=$3; a=$4; ua=$5;
    if (NR==1) {
      dw=0; du=0; da=0; dua=0;
    } else {
      dw=w-pw; du=u-pu; da=a-pa; dua=ua-pua;
    }
    printf "%-26s %8d %8d %8d %8d | %8s %8s %8s %8s\n",
      ts, w, u, a, ua, fmt_delta(dw), fmt_delta(du), fmt_delta(da), fmt_delta(dua);
    pw=w; pu=u; pa=a; pua=ua;
  }
' >> "${TREND_FILE}"

echo "[warning-trend] Wrote ${TREND_FILE}"
