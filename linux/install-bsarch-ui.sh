#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ENTRY_BIN="${REPO_ROOT}/BSArch-linux"
UI_LAUNCHER="${SCRIPT_DIR}/bsarch-ui.sh"

BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"

mkdir -p "$BIN_DIR" "$APP_DIR"
chmod +x "$UI_LAUNCHER"

if [[ ! -x "$ENTRY_BIN" ]]; then
  echo "Missing entry binary: $ENTRY_BIN" >&2
  exit 1
fi

ln -sf "$ENTRY_BIN" "${BIN_DIR}/BSArch-linux"
ln -sf "$UI_LAUNCHER" "${BIN_DIR}/BSArch-UI"

cat > "${APP_DIR}/BSArchSE.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=BSArchSE
Comment=BSArchSE
Exec=${BIN_DIR}/BSArch-linux
Terminal=false
Categories=Utility;Game;
StartupNotify=true
EOF

cat > "${APP_DIR}/BSArch-UI.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=BSArchSE
Comment=BSArchSE
Exec=${BIN_DIR}/BSArch-linux
Terminal=false
Categories=Utility;Game;
StartupNotify=true
EOF

echo "Installed: ${BIN_DIR}/BSArch-linux"
echo "Alias: ${BIN_DIR}/BSArch-UI"
echo "Desktop entries: ${APP_DIR}/BSArchSE.desktop, ${APP_DIR}/BSArch-UI.desktop"
