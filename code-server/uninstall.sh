#!/bin/bash
set -e

echo "Removing code-server..."

if [ ! -d /opt/code-server ]; then
  echo "code-server is not installed."
  exit 0
fi

sudo systemctl stop code-server 2>/dev/null || true
sudo systemctl disable code-server 2>/dev/null || true
sudo rm -f /etc/systemd/system/code-server.service
sudo systemctl daemon-reload

sudo rm -rf /opt/code-server
sudo rm -f /usr/bin/code-server

echo "Done. code-server removed."
echo "Note: ~/.config/code-server was not removed."
