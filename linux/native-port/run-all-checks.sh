#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

RUN_READINESS="${RUN_READINESS:-1}"
RUN_BSARCH="${RUN_BSARCH:-1}"
RUN_BSARCH_STRESS="${RUN_BSARCH_STRESS:-1}"
RUN_XEDIT_HEADLESS="${RUN_XEDIT_HEADLESS:-1}"
RUN_XDUMP_HEADLESS="${RUN_XDUMP_HEADLESS:-1}"
ENFORCE_STYLE="${ENFORCE_STYLE:-1}"
RUN_XEDIT_INLINE_GUARD="${RUN_XEDIT_INLINE_GUARD:-1}"
RUN_XEDIT_WINAPI_GUARD="${RUN_XEDIT_WINAPI_GUARD:-1}"
RUN_XEDIT_GUI_AUDIT="${RUN_XEDIT_GUI_AUDIT:-1}"
RUN_XEDIT_GUI_BUDGET_GUARD="${RUN_XEDIT_GUI_BUDGET_GUARD:-1}"
RUN_XEDIT_GUI_LASTMILE_GUARD="${RUN_XEDIT_GUI_LASTMILE_GUARD:-1}"
RUN_XEMAINFORM_MESSAGE_AUDIT="${RUN_XEMAINFORM_MESSAGE_AUDIT:-1}"
RUN_XEMAINFORM_MESSAGE_BUDGET_GUARD="${RUN_XEMAINFORM_MESSAGE_BUDGET_GUARD:-1}"
RUN_CORE_WINAPI_GUARD="${RUN_CORE_WINAPI_GUARD:-1}"
RUN_XDUMP_WINAPI_GUARD="${RUN_XDUMP_WINAPI_GUARD:-1}"
RUN_WARNING_BUDGET_GUARD="${RUN_WARNING_BUDGET_GUARD:-1}"
RUN_WARNING_SUMMARY_REPORT="${RUN_WARNING_SUMMARY_REPORT:-1}"
RUN_WARNING_HISTORY_APPEND="${RUN_WARNING_HISTORY_APPEND:-1}"
RUN_WARNING_TREND_REPORT="${RUN_WARNING_TREND_REPORT:-1}"
RUN_WARNING_HOTSPOT_REPORT="${RUN_WARNING_HOTSPOT_REPORT:-1}"
XEDIT_ENV_OVERRIDE_TEST="${XEDIT_ENV_OVERRIDE_TEST:-0}"
XEDIT_ENV_OVERRIDE_PATH="${XEDIT_ENV_OVERRIDE_PATH:-}"
XEDIT_ENV_OVERRIDE_ARGS="${XEDIT_ENV_OVERRIDE_ARGS:--dummy}"
XEDIT_CLI_OVERRIDE_TEST="${XEDIT_CLI_OVERRIDE_TEST:-0}"
XEDIT_CLI_OVERRIDE_PATH="${XEDIT_CLI_OVERRIDE_PATH:-}"
XEDIT_CLI_OVERRIDE_ARGS="${XEDIT_CLI_OVERRIDE_ARGS:--dummy}"
XEDIT_INVALID_D_TEST="${XEDIT_INVALID_D_TEST:-1}"
XEDIT_INVALID_D_PATH="${XEDIT_INVALID_D_PATH:-/definitely/not/here}"
XEDIT_INVALID_D_ARGS="${XEDIT_INVALID_D_ARGS:--dummy}"
XDUMP_ENV_OVERRIDE_TEST="${XDUMP_ENV_OVERRIDE_TEST:-0}"
XDUMP_ENV_OVERRIDE_PATH="${XDUMP_ENV_OVERRIDE_PATH:-}"
XDUMP_ENV_OVERRIDE_ARGS="${XDUMP_ENV_OVERRIDE_ARGS:--dummy}"
XDUMP_CLI_OVERRIDE_TEST="${XDUMP_CLI_OVERRIDE_TEST:-0}"
XDUMP_CLI_OVERRIDE_PATH="${XDUMP_CLI_OVERRIDE_PATH:-}"
XDUMP_CLI_OVERRIDE_ARGS="${XDUMP_CLI_OVERRIDE_ARGS:--dummy}"
XDUMP_MODE_SANITY_TEST="${XDUMP_MODE_SANITY_TEST:-1}"
XDUMP_MODE_SANITY_ARGS="${XDUMP_MODE_SANITY_ARGS:--TES5 -Dump Missing.esm}"
XDUMP_INVALID_D_TEST="${XDUMP_INVALID_D_TEST:-1}"
XDUMP_INVALID_D_PATH="${XDUMP_INVALID_D_PATH:-/definitely/not/here}"
XDUMP_INVALID_D_ARGS="${XDUMP_INVALID_D_ARGS:--TES5 -Dump Missing.esm}"

echo "[checks] Starting native-port checks"
echo "[checks] Config: RUN_READINESS=${RUN_READINESS} RUN_BSARCH=${RUN_BSARCH} RUN_BSARCH_STRESS=${RUN_BSARCH_STRESS} RUN_XEDIT_HEADLESS=${RUN_XEDIT_HEADLESS} RUN_XDUMP_HEADLESS=${RUN_XDUMP_HEADLESS} ENFORCE_STYLE=${ENFORCE_STYLE} RUN_XEDIT_INLINE_GUARD=${RUN_XEDIT_INLINE_GUARD} RUN_XEDIT_WINAPI_GUARD=${RUN_XEDIT_WINAPI_GUARD} RUN_XEDIT_GUI_AUDIT=${RUN_XEDIT_GUI_AUDIT} RUN_XEDIT_GUI_BUDGET_GUARD=${RUN_XEDIT_GUI_BUDGET_GUARD} RUN_XEDIT_GUI_LASTMILE_GUARD=${RUN_XEDIT_GUI_LASTMILE_GUARD} RUN_XEMAINFORM_MESSAGE_AUDIT=${RUN_XEMAINFORM_MESSAGE_AUDIT} RUN_XEMAINFORM_MESSAGE_BUDGET_GUARD=${RUN_XEMAINFORM_MESSAGE_BUDGET_GUARD} RUN_CORE_WINAPI_GUARD=${RUN_CORE_WINAPI_GUARD} RUN_XDUMP_WINAPI_GUARD=${RUN_XDUMP_WINAPI_GUARD} RUN_WARNING_BUDGET_GUARD=${RUN_WARNING_BUDGET_GUARD} RUN_WARNING_SUMMARY_REPORT=${RUN_WARNING_SUMMARY_REPORT} RUN_WARNING_HISTORY_APPEND=${RUN_WARNING_HISTORY_APPEND} RUN_WARNING_TREND_REPORT=${RUN_WARNING_TREND_REPORT} RUN_WARNING_HOTSPOT_REPORT=${RUN_WARNING_HOTSPOT_REPORT} XEDIT_ENV_OVERRIDE_TEST=${XEDIT_ENV_OVERRIDE_TEST} XEDIT_ENV_OVERRIDE_ARGS=${XEDIT_ENV_OVERRIDE_ARGS} XEDIT_CLI_OVERRIDE_TEST=${XEDIT_CLI_OVERRIDE_TEST} XEDIT_CLI_OVERRIDE_ARGS=${XEDIT_CLI_OVERRIDE_ARGS} XEDIT_INVALID_D_TEST=${XEDIT_INVALID_D_TEST} XEDIT_INVALID_D_ARGS=${XEDIT_INVALID_D_ARGS} XDUMP_ENV_OVERRIDE_TEST=${XDUMP_ENV_OVERRIDE_TEST} XDUMP_ENV_OVERRIDE_ARGS=${XDUMP_ENV_OVERRIDE_ARGS} XDUMP_CLI_OVERRIDE_TEST=${XDUMP_CLI_OVERRIDE_TEST} XDUMP_CLI_OVERRIDE_ARGS=${XDUMP_CLI_OVERRIDE_ARGS} XDUMP_MODE_SANITY_TEST=${XDUMP_MODE_SANITY_TEST} XDUMP_MODE_SANITY_ARGS=${XDUMP_MODE_SANITY_ARGS} XDUMP_INVALID_D_TEST=${XDUMP_INVALID_D_TEST} XDUMP_INVALID_D_ARGS=${XDUMP_INVALID_D_ARGS}"

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
  if [[ "${ENFORCE_STYLE}" == "1" ]]; then
    echo "[checks] Readiness (strict)"
  else
    echo "[checks] Readiness (core-only)"
  fi
  ENFORCE_STYLE="${ENFORCE_STYLE}" linux/native-port/check-xedit-readiness.sh
else
  echo "[checks] Skipping readiness check (RUN_READINESS=${RUN_READINESS})"
fi

if [[ "${RUN_XEDIT_INLINE_GUARD}" == "1" ]]; then
  echo "[checks] xEdit inline-var guard"
  linux/native-port/check-xedit-inline-vars.sh
else
  echo "[checks] Skipping xEdit inline-var guard (RUN_XEDIT_INLINE_GUARD=${RUN_XEDIT_INLINE_GUARD})"
fi

if [[ "${RUN_XEDIT_WINAPI_GUARD}" == "1" ]]; then
  echo "[checks] xEdit Winapi import guard"
  linux/native-port/check-xedit-winapi-imports.sh
else
  echo "[checks] Skipping xEdit Winapi import guard (RUN_XEDIT_WINAPI_GUARD=${RUN_XEDIT_WINAPI_GUARD})"
fi

if [[ "${RUN_XEDIT_GUI_AUDIT}" == "1" ]]; then
  echo "[checks] xEdit GUI surface audit"
  linux/native-port/audit-xedit-gui-surface.sh
else
  echo "[checks] Skipping xEdit GUI surface audit (RUN_XEDIT_GUI_AUDIT=${RUN_XEDIT_GUI_AUDIT})"
fi

if [[ "${RUN_XEDIT_GUI_BUDGET_GUARD}" == "1" ]]; then
  echo "[checks] xEdit GUI surface budget guard"
  linux/native-port/check-xedit-gui-surface-budget.sh
else
  echo "[checks] Skipping xEdit GUI surface budget guard (RUN_XEDIT_GUI_BUDGET_GUARD=${RUN_XEDIT_GUI_BUDGET_GUARD})"
fi

if [[ "${RUN_XEDIT_GUI_LASTMILE_GUARD}" == "1" ]]; then
  echo "[checks] xEdit GUI last-mile WinAPI guard"
  linux/native-port/check-xedit-gui-lastmile-winapi.sh
else
  echo "[checks] Skipping xEdit GUI last-mile WinAPI guard (RUN_XEDIT_GUI_LASTMILE_GUARD=${RUN_XEDIT_GUI_LASTMILE_GUARD})"
fi

if [[ "${RUN_XEMAINFORM_MESSAGE_AUDIT}" == "1" ]]; then
  echo "[checks] xeMainForm message surface audit"
  linux/native-port/audit-xemainform-message-surface.sh
else
  echo "[checks] Skipping xeMainForm message surface audit (RUN_XEMAINFORM_MESSAGE_AUDIT=${RUN_XEMAINFORM_MESSAGE_AUDIT})"
fi

if [[ "${RUN_XEMAINFORM_MESSAGE_BUDGET_GUARD}" == "1" ]]; then
  echo "[checks] xeMainForm message surface budget guard"
  linux/native-port/check-xemainform-message-surface-budget.sh
else
  echo "[checks] Skipping xeMainForm message surface budget guard (RUN_XEMAINFORM_MESSAGE_BUDGET_GUARD=${RUN_XEMAINFORM_MESSAGE_BUDGET_GUARD})"
fi

if [[ "${RUN_CORE_WINAPI_GUARD}" == "1" ]]; then
  echo "[checks] Core Winapi import guard"
  linux/native-port/check-core-winapi-imports.sh
else
  echo "[checks] Skipping Core Winapi import guard (RUN_CORE_WINAPI_GUARD=${RUN_CORE_WINAPI_GUARD})"
fi

if [[ "${RUN_XDUMP_WINAPI_GUARD}" == "1" ]]; then
  echo "[checks] xDump Winapi import guard"
  linux/native-port/check-xdump-winapi-imports.sh
else
  echo "[checks] Skipping xDump Winapi import guard (RUN_XDUMP_WINAPI_GUARD=${RUN_XDUMP_WINAPI_GUARD})"
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
  if [[ -x "linux/native-port/build-xedit-headless.sh" ]]; then
    linux/native-port/build-xedit-headless.sh
  fi
  XEDIT_ENV_OVERRIDE_TEST="${XEDIT_ENV_OVERRIDE_TEST}" \
  XEDIT_ENV_OVERRIDE_PATH="${XEDIT_ENV_OVERRIDE_PATH}" \
  XEDIT_ENV_OVERRIDE_ARGS="${XEDIT_ENV_OVERRIDE_ARGS}" \
  XEDIT_CLI_OVERRIDE_TEST="${XEDIT_CLI_OVERRIDE_TEST}" \
  XEDIT_CLI_OVERRIDE_PATH="${XEDIT_CLI_OVERRIDE_PATH}" \
  XEDIT_CLI_OVERRIDE_ARGS="${XEDIT_CLI_OVERRIDE_ARGS}" \
  XEDIT_INVALID_D_TEST="${XEDIT_INVALID_D_TEST}" \
  XEDIT_INVALID_D_PATH="${XEDIT_INVALID_D_PATH}" \
  XEDIT_INVALID_D_ARGS="${XEDIT_INVALID_D_ARGS}" \
  linux/native-port/smoke-test-xedit-headless.sh
else
  echo "[checks] Skipping xEdit headless smoke (RUN_XEDIT_HEADLESS=${RUN_XEDIT_HEADLESS})"
fi

if [[ "${RUN_XDUMP_HEADLESS}" == "1" ]]; then
  echo "[checks] xDump headless smoke"
  should_run_xdump_smoke=1
  if command -v "${FPC:-fpc}" >/dev/null 2>&1 && [[ -x "linux/native-port/build-xdump.sh" ]]; then
    linux/native-port/build-xdump.sh
  elif [[ ! -x "linux/bin/xdump-core" && ! -x "linux/bin/xDump" ]]; then
    echo "[checks] Skipping xDump headless smoke (missing fpc and no prebuilt xDump binary)"
    should_run_xdump_smoke=0
  fi

  if [[ "${should_run_xdump_smoke}" == "1" ]]; then
    XDUMP_ENV_OVERRIDE_TEST="${XDUMP_ENV_OVERRIDE_TEST}" \
    XDUMP_ENV_OVERRIDE_PATH="${XDUMP_ENV_OVERRIDE_PATH}" \
    XDUMP_ENV_OVERRIDE_ARGS="${XDUMP_ENV_OVERRIDE_ARGS}" \
    XDUMP_CLI_OVERRIDE_TEST="${XDUMP_CLI_OVERRIDE_TEST}" \
    XDUMP_CLI_OVERRIDE_PATH="${XDUMP_CLI_OVERRIDE_PATH}" \
    XDUMP_CLI_OVERRIDE_ARGS="${XDUMP_CLI_OVERRIDE_ARGS}" \
    XDUMP_MODE_SANITY_TEST="${XDUMP_MODE_SANITY_TEST}" \
    XDUMP_MODE_SANITY_ARGS="${XDUMP_MODE_SANITY_ARGS}" \
    XDUMP_INVALID_D_TEST="${XDUMP_INVALID_D_TEST}" \
    XDUMP_INVALID_D_PATH="${XDUMP_INVALID_D_PATH}" \
    XDUMP_INVALID_D_ARGS="${XDUMP_INVALID_D_ARGS}" \
    linux/native-port/smoke-test-xdump-headless.sh
  fi
else
  echo "[checks] Skipping xDump headless smoke (RUN_XDUMP_HEADLESS=${RUN_XDUMP_HEADLESS})"
fi

if [[ "${RUN_WARNING_BUDGET_GUARD}" == "1" ]]; then
  echo "[checks] Headless warning budget guard"
  RUN_SMOKE_IF_MISSING=1 linux/native-port/check-headless-warning-budget.sh
else
  echo "[checks] Skipping headless warning budget guard (RUN_WARNING_BUDGET_GUARD=${RUN_WARNING_BUDGET_GUARD})"
fi

if [[ "${RUN_WARNING_SUMMARY_REPORT}" == "1" ]]; then
  echo "[checks] Headless warning summary report"
  RUN_SMOKE_IF_MISSING=1 linux/native-port/report-headless-warning-summary.sh
else
  echo "[checks] Skipping headless warning summary report (RUN_WARNING_SUMMARY_REPORT=${RUN_WARNING_SUMMARY_REPORT})"
fi

if [[ "${RUN_WARNING_HISTORY_APPEND}" == "1" ]]; then
  echo "[checks] Headless warning history append"
  RUN_SMOKE_IF_MISSING=1 linux/native-port/append-headless-warning-history.sh
else
  echo "[checks] Skipping headless warning history append (RUN_WARNING_HISTORY_APPEND=${RUN_WARNING_HISTORY_APPEND})"
fi

if [[ "${RUN_WARNING_TREND_REPORT}" == "1" ]]; then
  echo "[checks] Headless warning trend report"
  linux/native-port/report-headless-warning-trend.sh
else
  echo "[checks] Skipping headless warning trend report (RUN_WARNING_TREND_REPORT=${RUN_WARNING_TREND_REPORT})"
fi

if [[ "${RUN_WARNING_HOTSPOT_REPORT}" == "1" ]]; then
  echo "[checks] Headless warning hotspot report"
  RUN_SMOKE_IF_MISSING=1 linux/native-port/report-headless-warning-hotspots.sh
else
  echo "[checks] Skipping headless warning hotspot report (RUN_WARNING_HOTSPOT_REPORT=${RUN_WARNING_HOTSPOT_REPORT})"
fi

echo "[checks] All requested checks finished"
