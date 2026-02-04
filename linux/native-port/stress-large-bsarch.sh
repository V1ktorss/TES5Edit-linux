#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CORE_BIN="${ROOT_DIR}/linux/bin/bsarch-core"
ENTRY_BIN="${ROOT_DIR}/BSArch-linux"

log() {
  echo "[stress] $*"
}

fail() {
  echo "[stress][error] $*" >&2
  exit 1
}

[[ -x "${CORE_BIN}" ]] || fail "Missing core binary: ${CORE_BIN}"
[[ -x "${ENTRY_BIN}" ]] || fail "Missing entry binary: ${ENTRY_BIN}"

WORK_DIR="$(mktemp -d /tmp/bsarch-stress-XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

SRC_DIR="${WORK_DIR}/src"
UNPACK_DIR="${WORK_DIR}/unpacked"
ARCHIVE="${WORK_DIR}/stress.bsa"
mkdir -p "${SRC_DIR}/meshes" "${SRC_DIR}/textures" "${UNPACK_DIR}"

log "Generating synthetic large dataset"
for i in $(seq 1 40); do
  dd if=/dev/zero of="${SRC_DIR}/meshes/file_${i}.nif" bs=64K count=4 status=none
done
for i in $(seq 1 40); do
  dd if=/dev/urandom of="${SRC_DIR}/textures/file_${i}.dds" bs=64K count=4 status=none
done

SRC_COUNT="$(find "${SRC_DIR}" -type f | wc -l)"
[[ "${SRC_COUNT}" -eq 80 ]] || fail "Unexpected source file count: ${SRC_COUNT}"

log "Packing stress archive"
"${CORE_BIN}" pack "${SRC_DIR}" "${ARCHIVE}" -tes5 >/dev/null
[[ -s "${ARCHIVE}" ]] || fail "Archive was not created"

log "Listing stress archive"
LIST_OUT="$("${CORE_BIN}" "${ARCHIVE}" -list)"
LIST_COUNT="$(echo "${LIST_OUT}" | rg -c '\.(nif|dds)$')"
[[ "${LIST_COUNT}" -eq 80 ]] || fail "List count mismatch: ${LIST_COUNT}"

log "Unpacking stress archive"
"${CORE_BIN}" unpack "${ARCHIVE}" "${UNPACK_DIR}" -q >/dev/null
UNPACK_COUNT="$(find "${UNPACK_DIR}" -type f | wc -l)"
[[ "${UNPACK_COUNT}" -eq 80 ]] || fail "Unpacked file count mismatch: ${UNPACK_COUNT}"

cmp -s "${SRC_DIR}/meshes/file_1.nif" "${UNPACK_DIR}/meshes/file_1.nif" || fail "Mesh sample mismatch"
cmp -s "${SRC_DIR}/textures/file_1.dds" "${UNPACK_DIR}/textures/file_1.dds" || fail "Texture sample mismatch"

log "Checking launcher passthrough in stress case"
"${ENTRY_BIN}" "${ARCHIVE}" -list >/dev/null || fail "Launcher passthrough failed"

log "Stress checks passed (80 files, mixed compressibility)"
