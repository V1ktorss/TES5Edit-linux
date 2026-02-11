#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/linux/bin"
OUT_BIN="${OUT_DIR}/xdump-core"
ALT_OUT_BIN="${OUT_DIR}/xDump"
FPC_BIN="${FPC:-fpc}"
LOCK_FILE="${OUT_DIR}/.xdump-core.build.lock"

log() {
  echo "[xdump-build] $*"
}

if ! command -v "$FPC_BIN" >/dev/null 2>&1; then
  log "fpc not found. Install FreePascal (fpc) and try again."
  exit 1
fi

mkdir -p "$OUT_DIR"

UNIT_PATHS=(
  "${ROOT_DIR}"
  "${ROOT_DIR}/Core"
  "${ROOT_DIR}/xDump"
  "${ROOT_DIR}/External/FileContainer"
  "${ROOT_DIR}/External/lz4/lib/delphi"
  "${ROOT_DIR}/External/lz4/common"
  "${ROOT_DIR}/External/ImagingLib/Source"
  "${ROOT_DIR}/External/ImagingLib/Source/ZLib"
  "${ROOT_DIR}/External/TForge/Source"
  "${ROOT_DIR}/External/TForge/Source/Shared"
  "${ROOT_DIR}/External/TForge/Source/Engine"
  "${ROOT_DIR}/External/TForge/Source/Engine/Forge"
  "${ROOT_DIR}/External/TForge/Source/Include"
  "${ROOT_DIR}/External/TForge/Source/Engine/Hashes"
)

FPC_FLAGS=(
  -Mdelphi
  -Sc
  -B
  -O2
  -g
  -vewnhi
  "-FE${OUT_DIR}"
)

UNIT_ARGS=()
for p in "${UNIT_PATHS[@]}"; do
  UNIT_ARGS+=("-Fu${p}")
done

build_impl() {
  log "Building xDump (output: ${OUT_BIN})"
  log "Unit paths: ${UNIT_PATHS[*]}"
  "$FPC_BIN" "${FPC_FLAGS[@]}" "${UNIT_ARGS[@]}" \
    "-Fu${ROOT_DIR}/xDump" \
    -Fi"${ROOT_DIR}/xDump" \
    -Fi"${ROOT_DIR}/Core" \
    -Fi"${ROOT_DIR}/External/ImagingLib/Source" \
    -Fi"${ROOT_DIR}/External/TForge/Source/Include" \
    "${ROOT_DIR}/xDump.dpr"
}

if command -v flock >/dev/null 2>&1; then
  exec 9>"${LOCK_FILE}"
  log "Acquiring build lock: ${LOCK_FILE}"
  flock 9
  build_impl
else
  log "flock not found, continuing without build lock"
  build_impl
fi

# FPC names the binary after the program identifier (`xDump`) by default.
# Normalize to the expected Linux artifact name.
if [[ -x "$ALT_OUT_BIN" && ! -x "$OUT_BIN" ]]; then
  cp -f "$ALT_OUT_BIN" "$OUT_BIN"
  chmod +x "$OUT_BIN"
fi

if [[ -x "$OUT_BIN" ]]; then
  log "Build ok: ${OUT_BIN}"
else
  log "Build failed: ${OUT_BIN} not found"
  exit 1
fi
