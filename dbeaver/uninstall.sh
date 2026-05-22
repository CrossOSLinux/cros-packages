#!/bin/bash
set -e

echo "Removing DBeaver..."

if [ ! -d /opt/dbeaver ]; then
  echo "DBeaver is not installed."
  exit 0
fi

sudo rm -rf /opt/dbeaver
sudo rm -f /usr/bin/dbeaver
sudo rm -f /usr/share/applications/dbeaver.desktop

echo "Done. DBeaver removed."
