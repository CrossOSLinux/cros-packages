#!/bin/bash
set -e

echo "Fetching latest Godot version..."
LATEST=$(curl -s https://api.github.com/repos/godotengine/godot/releases/latest \
  | grep '"tag_name"' \
  | cut -d'"' -f4)

if [ -z "$LATEST" ]; then
  echo "Error: Could not fetch latest Godot version."
  exit 1
fi

# Check if already on latest
if command -v godot &>/dev/null; then
  INSTALLED=$(godot --version 2>/dev/null | head -1 | grep -oP '[\d]+\.[\d]+\.[\d]+')
  LATEST_VER=$(echo "$LATEST" | grep -oP '[\d]+\.[\d]+\.[\d]+')
  if [ "$INSTALLED" = "$LATEST_VER" ]; then
    echo "Godot $INSTALLED is already up to date."
    exit 0
  fi
  echo "Updating Godot $INSTALLED -> $LATEST_VER..."
else
  echo "Installing Godot $LATEST..."
fi

FILENAME="Godot_v${LATEST}_linux.arm64"
ZIP="${FILENAME}.zip"
URL="https://github.com/godotengine/godot/releases/download/${LATEST}/${ZIP}"

echo "Downloading $ZIP..."
curl -L -o "/tmp/${ZIP}" "$URL"

echo "Extracting..."
unzip -o "/tmp/${ZIP}" -d /tmp/godot_extract

echo "Installing binary..."
sudo install -Dm755 "/tmp/godot_extract/${FILENAME}" /usr/bin/godot

echo "Downloading icon..."

curl -L -o /tmp/godot.png "https://github.com/godotengine.png"

if [ ! -s /tmp/godot.png ]; then
  echo "Warning: Icon download failed, skipping icon install."
else
  sudo install -Dm644 /tmp/godot.png /usr/share/icons/hicolor/scalable/apps/godot.png
  sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true
fi

rm -f /tmp/godot.png
echo "Creating desktop entry..."
sudo tee /usr/share/applications/godot.desktop > /dev/null << EOF
[Desktop Entry]
Name=Godot Engine
Comment=Multi-platform 2D and 3D game engine
Exec=godot
Icon=godot
Terminal=false
Type=Application
Categories=Development;GameDevelopment;
StartupNotify=true
EOF

# Cleanup
rm -rf /tmp/godot_extract "/tmp/${ZIP}" /tmp/godot.png
echo "Done. Godot $LATEST installed."
