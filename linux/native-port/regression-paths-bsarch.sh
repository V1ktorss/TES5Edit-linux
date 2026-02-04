#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CORE_BIN="${ROOT_DIR}/linux/bin/bsarch-core"
ENTRY_BIN="${ROOT_DIR}/BSArch-linux"

log() {
  echo "[paths] $*"
}

fail() {
  echo "[paths][error] $*" >&2
  exit 1
}

[[ -x "${CORE_BIN}" ]] || fail "Missing core binary: ${CORE_BIN}"
[[ -x "${ENTRY_BIN}" ]] || fail "Missing entry binary: ${ENTRY_BIN}"

WORK_DIR="$(mktemp -d /tmp/bsarch-paths-XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

SRC_DIR="${WORK_DIR}/src"
UNPACK_DIR="${WORK_DIR}/unpacked"
mkdir -p "${SRC_DIR}/misc" "${SRC_DIR}/meshes/actors/dragon" "${SRC_DIR}/textures/armor/iron"
mkdir -p "${UNPACK_DIR}"

cat >"${SRC_DIR}/misc/ReadmeRoot.txt" <<'EOF'
misc-entry
EOF
cat >"${SRC_DIR}/meshes/actors/dragon/body.nif" <<'EOF'
dragon-body
EOF
cat >"${SRC_DIR}/textures/armor/iron/ironarmor.dds" <<'EOF'
iron-armor
EOF

ARCHIVE="${WORK_DIR}/paths.bsa"

log "Packing archive with mixed folder buckets and nested entries"
"${CORE_BIN}" pack "${SRC_DIR}" "${ARCHIVE}" -tes5 >/dev/null
[[ -f "${ARCHIVE}" ]] || fail "Archive was not created"

log "Checking list output for expected entry paths"
LIST_OUT="$("${CORE_BIN}" "${ARCHIVE}" -list)"
echo "${LIST_OUT}" | rg -q "misc[/\\\\]readmeroot.txt" || fail "Missing misc file in list output"
echo "${LIST_OUT}" | rg -q "meshes[/\\\\]actors[/\\\\]dragon[/\\\\]body.nif" || fail "Missing nested NIF in list output"
echo "${LIST_OUT}" | rg -q "textures[/\\\\]armor[/\\\\]iron[/\\\\]ironarmor.dds" || fail "Missing nested DDS in list output"

log "Unpacking and validating normalized output paths"
"${CORE_BIN}" unpack "${ARCHIVE}" "${UNPACK_DIR}" -q >/dev/null
[[ -f "${UNPACK_DIR}/misc/readmeroot.txt" ]] || fail "Misc file missing after unpack"
[[ -f "${UNPACK_DIR}/meshes/actors/dragon/body.nif" ]] || fail "Nested NIF missing after unpack"
[[ -f "${UNPACK_DIR}/textures/armor/iron/ironarmor.dds" ]] || fail "Nested DDS missing after unpack"

cmp -s "${SRC_DIR}/misc/ReadmeRoot.txt" "${UNPACK_DIR}/misc/readmeroot.txt" || fail "Misc file content mismatch"
cmp -s "${SRC_DIR}/meshes/actors/dragon/body.nif" "${UNPACK_DIR}/meshes/actors/dragon/body.nif" || fail "NIF content mismatch"
cmp -s "${SRC_DIR}/textures/armor/iron/ironarmor.dds" "${UNPACK_DIR}/textures/armor/iron/ironarmor.dds" || fail "DDS content mismatch"

log "Checking launcher passthrough for list command"
"${ENTRY_BIN}" "${ARCHIVE}" -list >/dev/null || fail "Launcher passthrough failed for list command"

log "Path regression checks passed"
