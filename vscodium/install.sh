#!/bin/bash
set -e

echo "Fetching latest VSCodium version..."
LATEST=$(curl -s https://api.github.com/repos/VSCodium/vscodium/releases/latest \
  | grep '"tag_name"' \
  | cut -d'"' -f4)

if [ -z "$LATEST" ]; then
  echo "Error: Could not fetch latest version."
  exit 1
fi

if [ -d /opt/codium ]; then
  INSTALLED=$(cat /opt/codium/version 2>/dev/null)
  if [ "$INSTALLED" = "$LATEST" ]; then
    echo "VSCodium $INSTALLED is already up to date."
    exit 0
  fi
  echo "Updating VSCodium $INSTALLED -> $LATEST..."
else
  echo "Installing VSCodium $LATEST..."
fi

TARBALL="VSCodium-linux-arm64-${LATEST}.tar.gz"
URL="https://github.com/VSCodium/vscodium/releases/download/${LATEST}/${TARBALL}"

echo "Downloading $TARBALL..."
curl -L -o "/tmp/${TARBALL}" "$URL"

echo "Extracting..."
mkdir -p /tmp/codium-extract
tar -xzf "/tmp/${TARBALL}" -C /tmp/codium-extract

echo "Installing..."
sudo rm -rf /opt/codium
sudo mv /tmp/codium-extract /opt/codium
echo "$LATEST" | sudo tee /opt/codium/version > /dev/null

sudo tee /usr/bin/codium > /dev/null << 'EOF'
#!/bin/sh
exec /opt/codium/bin/codium --no-sandbox --disable-gpu "$@"
EOF
sudo chmod +x /usr/bin/codium

echo "Installing icon..."
curl -L -o /tmp/codium.png \
  "https://github.com/VSCodium.png" 2>/dev/null || true
if [ -s /tmp/codium.png ]; then
  sudo install -Dm644 /tmp/codium.png /usr/share/icons/hicolor/256x256/apps/codium.png
  sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true
  rm -f /tmp/codium.png
fi

echo "Creating desktop entry..."
sudo tee /usr/share/applications/codium.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=VSCodium
Comment=Code editing. Redefined.
Exec=codium --no-sandbox --disable-gpu
Icon=codium
Terminal=false
Type=Application
Categories=Development;TextEditor;
StartupNotify=true
MimeType=text/plain;
EOF

rm -f "/tmp/${TARBALL}"

echo "Done. VSCodium $LATEST installed."
