#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="${SCRIPT_DIR}/bsarch-ui.sh"

BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"

mkdir -p "$BIN_DIR" "$APP_DIR"
chmod +x "$LAUNCHER"

ln -sf "$LAUNCHER" "${BIN_DIR}/BSArch-UI"

cat > "${APP_DIR}/BSArch-UI.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=BSArchSE
Comment=BSArchSE
Exec=${BIN_DIR}/BSArch-UI
Terminal=false
Categories=Utility;Game;
StartupNotify=true
EOF

echo "Installed: ${BIN_DIR}/BSArch-UI"
echo "Desktop entry: ${APP_DIR}/BSArch-UI.desktop"
