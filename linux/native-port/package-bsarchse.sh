#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_ROOT="${ROOT_DIR}/linux/dist"
PKG_NAME="${1:-bsarchse-linux-x86_64}"
PKG_DIR="${DIST_ROOT}/${PKG_NAME}"
ARCHIVE_PATH="${DIST_ROOT}/${PKG_NAME}.tar.gz"

CORE_BIN="${ROOT_DIR}/linux/bin/bsarch-core"
ENTRY_BIN="${ROOT_DIR}/BSArch-linux"
UI_SCRIPT="${ROOT_DIR}/linux/bsarch-ui.sh"
INSTALL_SCRIPT="${ROOT_DIR}/linux/install-bsarch-ui.sh"
UI_BIN="${ROOT_DIR}/linux/.build-bsarch-ui/bsarch-ui"
UI_PRO="${ROOT_DIR}/linux/bsarch_ui_cpp/bsarch_ui_cpp.pro"

log() {
  echo "[package] $*"
}

fail() {
  echo "[package][error] $*" >&2
  exit 1
}

mkdir -p "${DIST_ROOT}"

[[ -x "${CORE_BIN}" ]] || fail "Missing core binary: ${CORE_BIN}"
[[ -x "${ENTRY_BIN}" ]] || fail "Missing entry binary: ${ENTRY_BIN}"
[[ -x "${UI_SCRIPT}" ]] || fail "Missing UI script: ${UI_SCRIPT}"
[[ -x "${INSTALL_SCRIPT}" ]] || fail "Missing install script: ${INSTALL_SCRIPT}"

if [[ ! -x "${UI_BIN}" ]]; then
  log "UI binary missing; attempting build"
  command -v qmake >/dev/null 2>&1 || fail "qmake not found"
  mkdir -p "${ROOT_DIR}/linux/.build-bsarch-ui"
  qmake -o "${ROOT_DIR}/linux/.build-bsarch-ui/Makefile" "${UI_PRO}"
  make -C "${ROOT_DIR}/linux/.build-bsarch-ui" -j"$(nproc)"
fi

[[ -x "${UI_BIN}" ]] || fail "UI binary not available after build"

rm -rf "${PKG_DIR}"
mkdir -p "${PKG_DIR}/linux/bin" "${PKG_DIR}/linux/.build-bsarch-ui"

cp -a "${ENTRY_BIN}" "${PKG_DIR}/BSArch-linux"
cp -a "${UI_SCRIPT}" "${PKG_DIR}/linux/bsarch-ui.sh"
cp -a "${INSTALL_SCRIPT}" "${PKG_DIR}/linux/install-bsarch-ui.sh"
cp -a "${CORE_BIN}" "${PKG_DIR}/linux/bin/bsarch-core"
cp -a "${UI_BIN}" "${PKG_DIR}/linux/.build-bsarch-ui/bsarch-ui"
cp -a "${ROOT_DIR}/README.linux.md" "${PKG_DIR}/README.linux.md"

cat > "${PKG_DIR}/RUNME.txt" <<'EOF'
BSArchSE Linux package

Quick start:
1. ./BSArch-linux
2. Optional user install: ./linux/install-bsarch-ui.sh
EOF

tar -C "${DIST_ROOT}" -czf "${ARCHIVE_PATH}" "${PKG_NAME}"
log "Created package: ${ARCHIVE_PATH}"
