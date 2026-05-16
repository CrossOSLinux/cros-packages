#!/bin/bash
# cros-packages: godot
# Installs the latest stable Godot Engine binary.
# Binary is installed to /opt/godot, launcher wrapper at /usr/bin/godot.
# Official icon is fetched from the Godot source repo and installed
# into the hicolor icon theme for use with Fuzzel and other launchers.
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

INSTALL_DIR="/opt/godot"
BIN_PATH="/usr/bin/godot"
DESKTOP_PATH="/usr/share/applications/godot.desktop"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> Godot Engine installer (arch: $GODOT_ARCH)"

# Dependencies: librsvg provides rsvg-convert for icon rendering
sudo pacman -S --needed --noconfirm wget curl librsvg

# Fetch latest stable version tag from GitHub API
echo "==> Checking latest version..."
VERSION=$(curl -sf https://api.github.com/repos/godotengine/godot/releases/latest \
    | grep '"tag_name"' \
    | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
    echo "ERROR: Failed to fetch latest version. Check your internet connection."
    exit 1
fi
echo "==> Latest version: $VERSION"

# Check if already installed and up to date
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

# Build asset filename and URL
# GitHub tag is e.g. "4.4.1-stable", release asset uses same format
ASSET="Godot_v${VERSION}_linux.${GODOT_ARCH}.zip"
DOWNLOAD_URL="https://github.com/godotengine/godot/releases/download/${VERSION}/${ASSET}"

echo "==> Downloading $ASSET..."
wget -q --show-progress -O "$TMP_DIR/$ASSET" "$DOWNLOAD_URL"

# Extract — zip contains a single file: Godot_v<version>_linux.<arch>
echo "==> Installing..."
unzip -q "$TMP_DIR/$ASSET" -d "$TMP_DIR/godot"

# Find the extracted binary (name varies by version)
BINARY=$(find "$TMP_DIR/godot" -maxdepth 1 -type f | head -1)
if [ -z "$BINARY" ]; then
    echo "ERROR: Could not find binary in extracted archive."
    exit 1
fi

sudo mkdir -p "$INSTALL_DIR"
sudo cp "$BINARY" "$INSTALL_DIR/godot-bin"
sudo chmod +x "$INSTALL_DIR/godot-bin"

# Store installed version for future update checks
echo "$VERSION" | sudo tee "$INSTALL_DIR/version" > /dev/null

# Install launcher wrapper at /usr/bin/godot
echo "==> Installing launcher..."
sudo tee "$BIN_PATH" > /dev/null << 'EOF'
#!/bin/bash
exec /opt/godot/godot-bin "$@"
EOF
sudo chmod +x "$BIN_PATH"

# Fetch and install the official Godot icon
# Source: https://github.com/godotengine/godot/blob/master/icon.svg
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
        sudo mkdir -p "$ICON_DIR"
        rsvg-convert -w "$SIZE" -h "$SIZE" "$ICON_SVG" \
            | sudo tee "$ICON_DIR/godot.png" > /dev/null
    done
    sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi

# Install desktop entry
echo "==> Installing desktop entry..."
sudo tee "$DESKTOP_PATH" > /dev/null << 'EOF'
[Desktop Entry]
Name=Godot Engine
Comment=Multi-platform 2D and 3D game engine
Exec=godot
Icon=godot
Type=Application
Categories=Development;IDE;GameDevelopment;
StartupNotify=true
Terminal=false
Keywords=game;engine;development;2D;3D;GDScript;
EOF

# Rebuild desktop database so fuzzel and other launchers pick up the new entry immediately
sudo update-desktop-database /usr/share/applications 2>/dev/null || true

echo ""
echo "==> Godot Engine $VERSION installed."
echo "    Run with: godot"
