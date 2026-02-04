#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CORE_BIN="${ROOT_DIR}/linux/bin/bsarch-core"
ENTRY_BIN="${ROOT_DIR}/BSArch-linux"
UI_LAUNCHER="${ROOT_DIR}/linux/bsarch-ui.sh"

log() {
  echo "[smoke] $*"
}

fail() {
  echo "[smoke][error] $*" >&2
  exit 1
}

[[ -x "${CORE_BIN}" ]] || fail "Missing core binary: ${CORE_BIN}"
[[ -x "${ENTRY_BIN}" ]] || fail "Missing entry binary: ${ENTRY_BIN}"
[[ -x "${UI_LAUNCHER}" ]] || fail "Missing UI launcher: ${UI_LAUNCHER}"

WORK_DIR="$(mktemp -d /tmp/bsarch-smoke-XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

SRC_DIR="${WORK_DIR}/src"
UNPACK_DIR="${WORK_DIR}/unpacked"
mkdir -p "${SRC_DIR}/meshes/a" "${SRC_DIR}/textures/t" "${UNPACK_DIR}"

cat >"${SRC_DIR}/meshes/a/test.nif" <<'EOF'
nif-smoke-test
EOF
cat >"${SRC_DIR}/textures/t/test.dds" <<'EOF'
dds-smoke-test
EOF

ARCHIVE="${WORK_DIR}/smoke.bsa"

log "Packing test archive"
"${CORE_BIN}" pack "${SRC_DIR}" "${ARCHIVE}" -tes5 >/dev/null
[[ -f "${ARCHIVE}" ]] || fail "Archive was not created"

log "Listing archive"
LIST_OUT="$("${CORE_BIN}" "${ARCHIVE}" -list)"
echo "${LIST_OUT}" | rg -q "meshes[/\\\\]a[/\\\\]test.nif" || fail "Expected NIF entry missing in list output"
echo "${LIST_OUT}" | rg -q "textures[/\\\\]t[/\\\\]test.dds" || fail "Expected DDS entry missing in list output"

log "Unpacking archive"
"${CORE_BIN}" unpack "${ARCHIVE}" "${UNPACK_DIR}" -q >/dev/null
cmp -s "${SRC_DIR}/meshes/a/test.nif" "${UNPACK_DIR}/meshes/a/test.nif" || fail "Unpacked NIF differs from source"
cmp -s "${SRC_DIR}/textures/t/test.dds" "${UNPACK_DIR}/textures/t/test.dds" || fail "Unpacked DDS differs from source"

log "Checking single-entry launcher CLI passthrough"
"${ENTRY_BIN}" -help >/dev/null || fail "Launcher CLI passthrough failed"

log "Automated checks passed"
echo
echo "Manual BSArchSE GUI checklist:"
echo "1. Start ${ENTRY_BIN} in desktop session."
echo "2. Open one .bsa/.ba2 via Archives Browse."
echo "3. Verify list loads and Asset Name sorting works."
echo "4. Right-click: Unpack Selected, Pack Selected, Archiv-Info."
echo "5. Double-click one file to extract/open via ./Tmp."
