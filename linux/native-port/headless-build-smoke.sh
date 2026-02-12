#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

RUN_XEDIT="${RUN_XEDIT:-1}"
RUN_XDUMP="${RUN_XDUMP:-1}"
BUILD_ONLY="${BUILD_ONLY:-0}"
HEADLESS_LOG="${HEADLESS_LOG:-/tmp/xedit-headless-current.log}"
HEADLESS_LOG_LEGACY="${HEADLESS_LOG_LEGACY:-/tmp/xedit-headless.log}"
FAIL_ON_HINTS="${FAIL_ON_HINTS:-1}"
HINT_ALLOWLIST_REGEX="${HINT_ALLOWLIST_REGEX:-Hint: Start of reading config file|Hint: End of reading config file|Hint: Variable \"wb(MODC|MODD|MODF|MODS|ENLM|ENLT|ENLS|AUUV|ModelXFLG)\" of a managed type does not seem to be initialized}"

if [[ -n "${HEADLESS_LOG}" ]]; then
  mkdir -p "$(dirname "${HEADLESS_LOG}")"
  : > "${HEADLESS_LOG}"
fi

log() {
  echo "[headless] $*"
  if [[ -n "${HEADLESS_LOG}" ]]; then
    echo "[headless] $*" >> "${HEADLESS_LOG}"
  fi
}

run_step() {
  local title="$1"
  shift
  log "${title}"
  if [[ -n "${HEADLESS_LOG}" ]]; then
    "$@" >> "${HEADLESS_LOG}" 2>&1
  else
    "$@"
  fi
}

check_hints() {
  if [[ "${FAIL_ON_HINTS}" != "1" ]]; then
    log "Hint gate disabled (FAIL_ON_HINTS=${FAIL_ON_HINTS})"
    return 0
  fi

  if [[ -z "${HEADLESS_LOG}" || ! -f "${HEADLESS_LOG}" ]]; then
    log "Hint gate skipped (no headless log available)"
    return 0
  fi

  local hint_lines
  local filtered_hints
  local hint_count

  hint_lines="$(rg -n "Hint:" "${HEADLESS_LOG}" || true)"
  filtered_hints="${hint_lines}"
  if [[ -n "${HINT_ALLOWLIST_REGEX}" ]]; then
    filtered_hints="$(printf "%s\n" "${hint_lines}" | rg -v "${HINT_ALLOWLIST_REGEX}" || true)"
  fi

  hint_count="$(printf "%s\n" "${filtered_hints}" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
  if [[ "${hint_count}" != "0" ]]; then
    log "FAILED: found ${hint_count} non-allowlisted hint lines in ${HEADLESS_LOG}"
    printf "%s\n" "${filtered_hints}" | head -n 40 >&2 || true
    exit 1
  fi

  log "Hint gate passed (no non-allowlisted Hint lines)"
}

summarize_warnings() {
  if [[ -z "${HEADLESS_LOG}" || ! -f "${HEADLESS_LOG}" ]]; then
    return 0
  fi

  local warning_count
  warning_count="$(rg -n "Warning:" "${HEADLESS_LOG}" | wc -l | tr -d '[:space:]')"
  log "Warning lines: ${warning_count}"

  if [[ "${warning_count}" != "0" ]]; then
    local top_warnings
    log "Top warning types:"
    top_warnings="$(
      awk -F'Warning: ' '/\.pas\([0-9]+,[0-9]+\) Warning:/{w[$2]++} END{for(k in w) printf "  %6d %s\n", w[k], k}' "${HEADLESS_LOG}" \
        | sort -nr \
        | head -n 10
    )"
    if [[ -n "${top_warnings}" ]]; then
      while IFS= read -r line; do
        log "${line}"
      done <<< "${top_warnings}"
    fi
  fi
}

if [[ "${RUN_XEDIT}" != "1" && "${RUN_XDUMP}" != "1" ]]; then
  log "Nothing to do. Set RUN_XEDIT=1 and/or RUN_XDUMP=1."
  exit 0
fi

log "Config: RUN_XEDIT=${RUN_XEDIT} RUN_XDUMP=${RUN_XDUMP} BUILD_ONLY=${BUILD_ONLY}"

if [[ "${RUN_XEDIT}" == "1" ]]; then
  run_step "Building xEdit headless" "${ROOT_DIR}/linux/native-port/build-xedit-headless.sh"
  if [[ "${BUILD_ONLY}" != "1" ]]; then
    run_step "xEdit headless smoke" "${ROOT_DIR}/linux/native-port/smoke-test-xedit-headless.sh"
  fi
fi

if [[ "${RUN_XDUMP}" == "1" ]]; then
  run_step "Building xDump headless" "${ROOT_DIR}/linux/native-port/build-xdump.sh"
  if [[ "${BUILD_ONLY}" != "1" ]]; then
    run_step "xDump headless smoke" "${ROOT_DIR}/linux/native-port/smoke-test-xdump-headless.sh"
  fi
fi

check_hints
summarize_warnings

log "PASS"

# Keep the legacy path in sync for existing workflows.
if [[ -n "${HEADLESS_LOG}" && -n "${HEADLESS_LOG_LEGACY}" && "${HEADLESS_LOG}" != "${HEADLESS_LOG_LEGACY}" ]]; then
  cp -f "${HEADLESS_LOG}" "${HEADLESS_LOG_LEGACY}" || true
fi
