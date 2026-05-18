#!/bin/bash
# Cross OS - Zen Browser Installer
# Handles fresh install, updates, and reinstalls
# User data in ~/.zen is never touched
set -e

echo "================================"
echo "  Cross OS - Zen Browser"
echo "================================"

# Ensure dependencies
sudo pacman -S --noconfirm curl wget git gtk-update-icon-cache

# Fetch latest version from GitHub API
echo "Checking latest version..."
VERSION=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest \
    | grep '"tag_name"' \
    | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
    echo "Failed to fetch latest version. Check your internet connection."
    exit 1
fi

echo "Latest version: $VERSION"

# Check if already installed
if [ -f "/opt/zen-browser/application.ini" ]; then
    INSTALLED=$(grep "^Version" /opt/zen-browser/application.ini 2>/dev/null | cut -d= -f2)
    echo "Installed version: $INSTALLED"

    if [ "$INSTALLED" = "$VERSION" ]; then
        echo "Already on latest version. Nothing to do."
        exit 0
    fi

    echo "Updating from $INSTALLED to $VERSION..."
    sudo rm -rf /opt/zen-browser
else
    echo "No existing installation found. Fresh install..."
fi

# Clean up any leftover temp files
rm -rf /tmp/zen-browser-arm64-copr
rm -f /tmp/zen.linux-aarch64.tar.xz

# Download
echo "Downloading Zen Browser $VERSION..."
cd /tmp
wget "https://github.com/zen-browser/desktop/releases/download/${VERSION}/zen.linux-aarch64.tar.xz"

# Extract and install binary
echo "Installing..."
sudo tar xf zen.linux-aarch64.tar.xz -C /opt
sudo mv /opt/zen /opt/zen-browser
rm -f zen.linux-aarch64.tar.xz

# Wayland launcher fix
echo "Applying Wayland fix..."
git clone --depth 1 https://github.com/ArchitektApx/zen-browser-arm64-copr
sed -i 's+exec /opt/zen-browser/zen-bin+exec /opt/zen-browser/zen-bin --class zen-browser --name zen-browser+g' \
    zen-browser-arm64-copr/zen-browser
sudo mv -f zen-browser-arm64-copr/zen-browser /usr/bin/zen-browser
sudo chmod +x /usr/bin/zen-browser

# Desktop entry
sudo mv -f zen-browser-arm64-copr/zen-browser.desktop /usr/share/applications

# Disable built in update notifications
# Zen updates are handled by this script instead
sudo mkdir -p /opt/zen-browser/distribution
sudo mv -f zen-browser-arm64-copr/policies.json /opt/zen-browser/distribution

# Icons
echo "Installing icons..."
for i in 16x16 32x32 48x48 64x64 128x128; do
    sudo mkdir -p /usr/share/icons/hicolor/$i/apps/
    sudo cp /opt/zen-browser/browser/chrome/icons/default/default${i/x*}.png \
        /usr/share/icons/hicolor/$i/apps/zen-browser.png
done

# Cleanup
rm -rf /tmp/zen-browser-arm64-copr

echo ""
echo "================================"
echo "  Zen Browser $VERSION installed."
echo "  User data in ~/.zen is untouched."
echo "  Run with: zen-browser"
echo "================================"
