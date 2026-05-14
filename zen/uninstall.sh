#!/bin/bash
# cros-packages: zen (Zen Browser) — uninstall
# Reverses everything install.sh placed on the system.
# User data in ~/.zen is never touched.
set -e

echo "==> Removing Zen Browser..."

# Remove binary and launcher
sudo rm -f /usr/bin/zen-browser

# Remove application bundle
sudo rm -rf /opt/zen-browser

# Remove desktop entry
sudo rm -f /usr/share/applications/zen-browser.desktop

# Remove icons
for SIZE in 16 32 48 64 128; do
    sudo rm -f "/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/zen-browser.png"
done

# Refresh icon cache if tool is available
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

echo "==> Zen Browser removed."
echo "    User data in ~/.zen has been left intact."
