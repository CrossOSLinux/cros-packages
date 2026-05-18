#!/bin/bash
# cros-packages: godot
# Installs the latest stable Godot Engine binary.
# Binary is installed to /opt/godot, launcher wrapper at /usr/bin/godot.
set -e

ARCH="${CROS_ARCH:-$(uname -m)}"

case "$ARCH" in
    arm64|aarch64) GODOT_ARCH="arm64"  ;;
    x86_64)        GODOT_ARCH="x86_64" ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

launcher_path="/home/crossfire/cros-packages/godot/godot.desktop"
INSTALL_DIR="/opt/godot"
BIN_PATH="/usr/bin/godot"
DESKTOP_PATH="/usr/share/applications"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> Godot Engine installer (arch: $GODOT_ARCH)"

sudo pacman -S --needed --noconfirm wget curl librsvg

echo "==> Checking latest version..."
VERSION=$(curl -sf https://api.github.com/repos/godotengine/godot/releases/latest \
    | grep '"tag_name"' \
    | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
    echo "ERROR: Failed to fetch latest version. Check your internet connection."
    exit 1
fi
echo "==> Latest version: $VERSION"

if [ -f "$INSTALL_DIR/version" ]; then
    INSTALLED=$(cat "$INSTALL_DIR/version")
    echo "==> Installed version: $INSTALLED"
    if [ "$INSTALLED" = "$VERSION" ]; then
        echo "==> Already on latest version. Nothing to do."
        exit 0
    fi
    echo "==> Updating $INSTALLED -> $VERSION"
    sudo rm -rf "$INSTALL_DIR"
fi

ASSET="Godot_v${VERSION}_linux.${GODOT_ARCH}.zip"
DOWNLOAD_URL="https://github.com/godotengine/godot/releases/download/${VERSION}/${ASSET}"

echo "==> Downloading $ASSET..."
wget -q --show-progress -O "$TMP_DIR/$ASSET" "$DOWNLOAD_URL"

echo "==> Installing..."
unzip -q "$TMP_DIR/$ASSET" -d "$TMP_DIR/godot"

BINARY=$(find "$TMP_DIR/godot" -maxdepth 1 -type f | head -1)
if [ -z "$BINARY" ]; then
    echo "ERROR: Could not find binary in extracted archive."
    exit 1
fi

sudo mkdir -p "$INSTALL_DIR"
sudo cp "$BINARY" "$INSTALL_DIR/godot-bin"
sudo chmod +x "$INSTALL_DIR/godot-bin"

# Store version
printf '%s\n' "$VERSION" > "$TMP_DIR/version"
sudo mv -f "$TMP_DIR/version" "$INSTALL_DIR/version"

# Write launcher using printf — no heredoc, no sudo tee, no pipe
echo "==> Installing launcher..."
sudo cp "$launcher_path" "$DESKTOP_PATH" 

# Fetch and install icon
echo "==> Fetching official Godot icon..."
ICON_SVG="$TMP_DIR/godot.svg"
wget -q -O "$ICON_SVG" \
    "https://raw.githubusercontent.com/godotengine/godot/master/icon.svg"

if [ ! -s "$ICON_SVG" ]; then
    echo "==> Warning: Could not fetch icon, skipping icon installation."
else
    echo "==> Installing icons..."
    for SIZE in 16 32 48 64 128 256; do
        ICON_DIR="/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps"
        ICON_TMP="$TMP_DIR/godot-${SIZE}.png"
        sudo mkdir -p "$ICON_DIR"
        rsvg-convert -w "$SIZE" -h "$SIZE" "$ICON_SVG" -o "$ICON_TMP"
        sudo mv -f "$ICON_TMP" "$ICON_DIR/godot.png"
    done
    sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi

# Copy desktop entry from package folder
echo "==> Installing desktop entry..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sudo cp "$SCRIPT_DIR/godot.desktop" "$DESKTOP_PATH"

sudo update-desktop-database /usr/share/applications 2>/dev/null || true

echo ""
echo "==> Godot Engine $VERSION installed."
echo "    Run with: godot"
