#!/bin/bash
set -e

echo "Fetching latest DBeaver version..."
LATEST=$(curl -s https://api.github.com/repos/dbeaver/dbeaver/releases/latest \
  | grep '"tag_name"' \
  | cut -d'"' -f4 \
  | sed 's/^v//')

if [ -z "$LATEST" ]; then
  echo "Error: Could not fetch latest version."
  exit 1
fi

if command -v dbeaver &>/dev/null; then
  INSTALLED=$(dbeaver -version 2>/dev/null | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1)
  if [ "$INSTALLED" = "$LATEST" ]; then
    echo "DBeaver $INSTALLED is already up to date."
    exit 0
  fi
  echo "Updating DBeaver $INSTALLED -> $LATEST..."
else
  echo "Installing DBeaver $LATEST..."
fi

TARBALL="dbeaver-ce-${LATEST}-linux-aarch64.tar.gz"
URL="https://github.com/dbeaver/dbeaver/releases/download/${LATEST}/${TARBALL}"

echo "Downloading $TARBALL..."
curl -L -o "/tmp/${TARBALL}" "$URL"

echo "Extracting..."
tar -xzf "/tmp/${TARBALL}" -C /tmp/

echo "Installing..."
sudo rm -rf /opt/dbeaver
sudo mv /tmp/dbeaver /opt/dbeaver

sudo tee /usr/bin/dbeaver > /dev/null << 'EOF'
#!/bin/sh
exec /opt/dbeaver/dbeaver "$@"
EOF
sudo chmod +x /usr/bin/dbeaver

echo "Creating desktop entry..."
sudo tee /usr/share/applications/dbeaver.desktop > /dev/null << EOF
[Desktop Entry]
Name=DBeaver Community
Comment=Universal Database Manager
Exec=dbeaver
Icon=/opt/dbeaver/dbeaver.png
Terminal=false
Type=Application
Categories=Development;Database;
StartupNotify=true
EOF

rm -f "/tmp/${TARBALL}"

echo "Done. DBeaver $LATEST installed."
