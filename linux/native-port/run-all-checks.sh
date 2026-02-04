#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

echo "[checks] Starting native-port checks"

run_if_exists() {
  local label="$1"
  local bin_path="$2"
  shift 2

  if [[ -x "${bin_path}" ]]; then
    echo "[checks] ${label}"
    "$@"
  else
    echo "[checks] Skipping ${label} (missing: ${bin_path})"
  fi
}

echo "[checks] Readiness (strict)"
ENFORCE_STYLE=1 linux/native-port/check-xedit-readiness.sh

run_if_exists \
  "BSArch smoke/regression/stress" \
  "linux/bin/bsarch-core" \
  bash -lc "linux/native-port/smoke-test-bsarch.sh && linux/native-port/regression-paths-bsarch.sh && linux/native-port/stress-large-bsarch.sh"

echo "[checks] xEdit headless smoke"
linux/native-port/smoke-test-xedit-headless.sh

echo "[checks] All requested checks finished"
