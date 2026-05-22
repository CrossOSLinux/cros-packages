#!/bin/bash
set -e

echo "Removing VSCodium..."

if [ ! -d /opt/codium ]; then
  echo "VSCodium is not installed."
  exit 0
fi

sudo rm -rf /opt/codium
sudo rm -f /usr/bin/codium
sudo rm -f /usr/share/applications/codium.desktop
sudo rm -f /usr/share/icons/hicolor/256x256/apps/codium.png
sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true

echo "Done. VSCodium removed."
echo "Note: ~/.config/VSCodium was not removed."
