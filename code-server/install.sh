#!/bin/bash
set -e

echo "Fetching latest code-server version..."
LATEST=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest \
  | grep '"tag_name"' \
  | cut -d'"' -f4 \
  | sed 's/^v//')

if [ -z "$LATEST" ]; then
  echo "Error: Could not fetch latest version."
  exit 1
fi

if command -v code-server &>/dev/null; then
  INSTALLED=$(code-server --version 2>/dev/null | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1)
  if [ "$INSTALLED" = "$LATEST" ]; then
    echo "code-server $INSTALLED is already up to date."
    exit 0
  fi
  echo "Updating code-server $INSTALLED -> $LATEST..."
else
  echo "Installing code-server $LATEST..."
fi

TARBALL="code-server-${LATEST}-linux-arm64.tar.gz"
URL="https://github.com/coder/code-server/releases/download/v${LATEST}/${TARBALL}"

echo "Downloading $TARBALL..."
curl -L -o "/tmp/${TARBALL}" "$URL"

echo "Extracting..."
tar -xzf "/tmp/${TARBALL}" -C /tmp/

echo "Installing..."
sudo rm -rf /opt/code-server
sudo mv "/tmp/code-server-${LATEST}-linux-arm64" /opt/code-server

sudo tee /usr/bin/code-server > /dev/null << 'EOF'
#!/bin/sh
exec /opt/code-server/bin/code-server "$@"
EOF
sudo chmod +x /usr/bin/code-server

echo "Enabling systemd service..."
sudo tee /etc/systemd/system/code-server.service > /dev/null << EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/opt/code-server/bin/code-server --bind-addr 0.0.0.0:8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable code-server
sudo systemctl start code-server

rm -f "/tmp/${TARBALL}"

echo "Done. code-server $LATEST installed."
echo "Access it at http://localhost:8080"
echo "Password is in ~/.config/code-server/config.yaml"
