#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

RUN_READINESS="${RUN_READINESS:-1}"
RUN_BSARCH="${RUN_BSARCH:-1}"
RUN_BSARCH_STRESS="${RUN_BSARCH_STRESS:-1}"
RUN_XEDIT_HEADLESS="${RUN_XEDIT_HEADLESS:-1}"

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

if [[ "${RUN_READINESS}" == "1" ]]; then
  echo "[checks] Readiness (strict)"
  ENFORCE_STYLE=1 linux/native-port/check-xedit-readiness.sh
else
  echo "[checks] Skipping readiness check (RUN_READINESS=${RUN_READINESS})"
fi

if [[ "${RUN_BSARCH}" == "1" ]]; then
  if [[ "${RUN_BSARCH_STRESS}" == "1" ]]; then
    run_if_exists \
      "BSArch smoke/regression/stress" \
      "linux/bin/bsarch-core" \
      bash -lc "linux/native-port/smoke-test-bsarch.sh && linux/native-port/regression-paths-bsarch.sh && linux/native-port/stress-large-bsarch.sh"
  else
    run_if_exists \
      "BSArch smoke/regression" \
      "linux/bin/bsarch-core" \
      bash -lc "linux/native-port/smoke-test-bsarch.sh && linux/native-port/regression-paths-bsarch.sh"
  fi
else
  echo "[checks] Skipping BSArch checks (RUN_BSARCH=${RUN_BSARCH})"
fi

if [[ "${RUN_XEDIT_HEADLESS}" == "1" ]]; then
  echo "[checks] xEdit headless smoke"
  linux/native-port/smoke-test-xedit-headless.sh
else
  echo "[checks] Skipping xEdit headless smoke (RUN_XEDIT_HEADLESS=${RUN_XEDIT_HEADLESS})"
fi

echo "[checks] All requested checks finished"
