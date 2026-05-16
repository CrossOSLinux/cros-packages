#!/bin/bash
# cros-packages: godot — uninstall
# Removes the Godot Engine binary, launcher, icons, and desktop entry.
# User projects are never touched.
set -e

echo "==> Removing Godot Engine..."

# Remove application directory
sudo rm -rf /opt/godot

# Remove launcher wrapper
sudo rm -f /usr/bin/godot

# Remove desktop entry
sudo rm -f /usr/share/applications/godot.desktop

# Remove icons
for SIZE in 16 32 48 64 128 256; do
    sudo rm -f "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/godot.png"
done

gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
sudo update-desktop-database /usr/share/applications 2>/dev/null || true

echo "==> Godot Engine removed."
echo "    User projects have been left intact."
