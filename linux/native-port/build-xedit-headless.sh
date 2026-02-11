#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/linux/bin"
OUT_BIN="${OUT_DIR}/xedit-core"
FPC_BIN="${FPC:-fpc}"
LOCK_FILE="${OUT_DIR}/.xedit-core.build.lock"

log() {
  echo "[xedit-build] $*"
}

if ! command -v "$FPC_BIN" >/dev/null 2>&1; then
  log "fpc not found. Install FreePascal (fpc) and try again."
  exit 1
fi

mkdir -p "$OUT_DIR"

UNIT_PATHS=(
  "${ROOT_DIR}"
  "${ROOT_DIR}/Core"
  "${ROOT_DIR}/xEdit"
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
  "${ROOT_DIR}/External/VirtualTrees/Source"
  "${ROOT_DIR}/External/jvcl/jvcl/run"
  "${ROOT_DIR}/External/jvcl/jvcl/common"
  "${ROOT_DIR}/External/jcl/jcl/source"
)

FPC_FLAGS=(
  -Mdelphi
  -Sc
  -B
  -O2
  -g
  -vewnhi
  -dXEDIT_HEADLESS
  "-FE${OUT_DIR}"
)

UNIT_ARGS=()
for p in "${UNIT_PATHS[@]}"; do
  UNIT_ARGS+=("-Fu${p}")
done

build_impl() {
  log "Building xEdit headless (output: ${OUT_BIN})"
  log "Unit paths: ${UNIT_PATHS[*]}"
  "$FPC_BIN" "${FPC_FLAGS[@]}" "${UNIT_ARGS[@]}" \
    -Fi"${ROOT_DIR}" \
    -Fi"${ROOT_DIR}/Core" \
    -Fi"${ROOT_DIR}/xEdit" \
    "${ROOT_DIR}/xEdit/xedit-core.dpr"
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

if [[ -x "$OUT_BIN" ]]; then
  log "Build ok: ${OUT_BIN}"
else
  log "Build failed: ${OUT_BIN} not found"
  exit 1
fi
