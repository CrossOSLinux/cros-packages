#!/bin/bash
set -e

echo "Removing Godot..."

if [ ! -f /usr/bin/godot ]; then
  echo "Godot is not installed."
  exit 0
fi

sudo rm -f /usr/bin/godot
sudo rm -f /usr/share/applications/godot.desktop
sudo rm -f /usr/share/icons/hicolor/scalable/apps/godot.png
sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true

echo "Done. Godot removed."
