#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
LAUNCHER="${SCRIPT_DIR}/xedit-linux-launcher.sh"

BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"

declare -a APPS=(
  "TES5Edit:TES5:skyrim"
  "SSEEdit:SSE:skyrimspecialedition"
  "FO4Edit:FO4:fallout4"
)

if [[ ! -x "$LAUNCHER" ]]; then
  chmod +x "$LAUNCHER"
fi

mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_DIR"

for app in "${APPS[@]}"; do
  IFS=':' read -r NAME MODE ICON <<<"$app"

  ln -sf "$LAUNCHER" "${BIN_DIR}/${NAME}"

  cat > "${APP_DIR}/${NAME}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${NAME}
Comment=Run xEdit in ${MODE} mode via Wine
Exec=${BIN_DIR}/${NAME}
Terminal=false
Categories=Game;Utility;
StartupNotify=true
Icon=${ICON}
EOF

done

echo "Installed launchers in ${BIN_DIR}:"
printf '  - %s\n' "${APPS[@]%%:*}"
echo
echo "Desktop entries installed in ${APP_DIR}."
echo "Run with: TES5Edit, SSEEdit, or FO4Edit"
