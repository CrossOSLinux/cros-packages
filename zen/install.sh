#!/bin/bash
# cros-packages: zen (Zen Browser)
# Handles fresh install and updates. User data in ~/.zen is never touched.
set -e

ARCH="${CROS_ARCH:-$(uname -m)}"

# Map cros arch labels to Zen's release asset naming
case "$ARCH" in
    arm64|aarch64) ZEN_ARCH="aarch64" ;;
    x86_64)        ZEN_ARCH="x86_64"  ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

INSTALL_DIR="/opt/zen-browser"
BIN_PATH="/usr/bin/zen-browser"
DESKTOP_PATH="/usr/share/applications/zen-browser.desktop"
POLICY_DIR="$INSTALL_DIR/distribution"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> Zen Browser installer (arch: $ZEN_ARCH)"

# Ensure runtime dependencies
sudo pacman -S --noconfirm --needed curl wget

# Fetch latest version from GitHub API
echo "==> Checking latest version..."
VERSION=$(curl -sf https://api.github.com/repos/zen-browser/desktop/releases/latest \
    | grep '"tag_name"' \
    | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
    echo "ERROR: Failed to fetch latest version. Check your internet connection."
    exit 1
fi
echo "==> Latest version: $VERSION"

# Skip if already up to date
if [ -f "$INSTALL_DIR/application.ini" ]; then
    INSTALLED=$(grep "^Version" "$INSTALL_DIR/application.ini" 2>/dev/null | cut -d= -f2 || true)
    echo "==> Installed version: ${INSTALLED:-unknown}"
    if [ "$INSTALLED" = "$VERSION" ]; then
        echo "==> Already on latest version. Nothing to do."
        exit 0
    fi
    echo "==> Updating $INSTALLED -> $VERSION"
    sudo rm -rf "$INSTALL_DIR"
else
    echo "==> No existing installation found. Fresh install..."
fi

# Download tarball
TARBALL="zen.linux-${ZEN_ARCH}.tar.xz"
DOWNLOAD_URL="https://github.com/zen-browser/desktop/releases/download/${VERSION}/${TARBALL}"

echo "==> Downloading $TARBALL..."
wget -q --show-progress -O "$TMP_DIR/$TARBALL" "$DOWNLOAD_URL"

# Extract and install
echo "==> Installing to $INSTALL_DIR..."
sudo tar xf "$TMP_DIR/$TARBALL" -C /opt
sudo mv -f /opt/zen "$INSTALL_DIR"

# Write launcher wrapper (handles Wayland + KDE/GNOME native messaging)
echo "==> Installing launcher..."
sudo tee "$BIN_PATH" > /dev/null << 'EOF'
#!/usr/bin/bash

# Enable Wayland if available
[ -z "$MOZ_DISABLE_WAYLAND" ] && {
    { [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] && [ -n "$WAYLAND_DISPLAY" ]; } ||
    [ "$XDG_SESSION_TYPE" = "wayland" ]
} && export MOZ_ENABLE_WAYLAND=1 && export MOZ_DBUS_REMOTE=1

# KDE native messaging
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] && \
   [ ! -e "${HOME}/.zen/native-messaging-hosts/org.kde.plasma.browser_integration.json" ]; then
    mkdir -p "${HOME}/.zen/native-messaging-hosts"
    [ -r /usr/lib64/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json ] && \
        ln -sf /usr/lib64/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json \
               "${HOME}/.zen/native-messaging-hosts/org.kde.plasma.browser_integration.json"
fi

# GNOME native messaging
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] && {
    [ ! -e "${HOME}/.zen/native-messaging-hosts/org.gnome.browser_connector.json" ] ||
    [ ! -e "${HOME}/.zen/native-messaging-hosts/org.gnome.chrome_gnome_shell.json" ]
}; then
    mkdir -p "${HOME}/.zen/native-messaging-hosts"
    [ -r /usr/lib64/mozilla/native-messaging-hosts/org.gnome.browser_connector.json ] && \
        ln -sf /usr/lib64/mozilla/native-messaging-hosts/org.gnome.browser_connector.json \
               "${HOME}/.zen/native-messaging-hosts/org.gnome.browser_connector.json"
    [ -r /usr/lib64/mozilla/native-messaging-hosts/org.gnome.chrome_gnome_shell.json ] && \
        ln -sf /usr/lib64/mozilla/native-messaging-hosts/org.gnome.chrome_gnome_shell.json \
               "${HOME}/.zen/native-messaging-hosts/org.gnome.chrome_gnome_shell.json"
fi

export MOZ_APP_LAUNCHER="$0"
exec /opt/zen-browser/zen-bin "$@"
EOF
sudo chmod +x "$BIN_PATH"

# Write desktop entry
echo "==> Installing desktop entry..."
sudo tee "$DESKTOP_PATH" > /dev/null << 'EOF'
[Desktop Entry]
Name=Zen Browser
Comment=Experience tranquillity while browsing the web without people tracking you!
Exec=zen-browser %u
Icon=zen-browser
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;application/x-xpinstall;application/pdf;application/json;
StartupWMClass=zen-beta
Categories=Network;WebBrowser;
StartupNotify=true
Terminal=false
X-MultipleArgs=false
Keywords=Internet;WWW;Browser;Web;Explorer;
Actions=new-window;new-private-window;profile-manager-window;
GenericName=Web Browser

[Desktop Action new-window]
Name=Open a New Window
Exec=zen-browser --new-window %u

[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=zen-browser --private-window %u

[Desktop Action profile-manager-window]
Name=Open the Profile Manager
Exec=zen-browser --ProfileManager %u
EOF

# Disable Zen's built-in update notifications (cros handles updates)
echo "==> Applying update policy..."
sudo mkdir -p "$POLICY_DIR"
sudo tee "$POLICY_DIR/policies.json" > /dev/null << 'EOF'
{
  "policies": {
    "DisableAppUpdate": true
  }
}
EOF

# Install icons from the extracted bundle
echo "==> Installing icons..."
for SIZE in 16 32 48 64 128; do
    ICON_DIR="/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps"
    sudo mkdir -p "$ICON_DIR"
    sudo cp "$INSTALL_DIR/browser/chrome/icons/default/default${SIZE}.png" \
        "$ICON_DIR/zen-browser.png" 2>/dev/null || true
done

# Refresh icon cache if tool is available
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

echo ""
echo "==> Zen Browser $VERSION installed."
echo "    User data in ~/.zen is untouched."
echo "    Run with: zen-browser"
