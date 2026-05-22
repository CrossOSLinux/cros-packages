#!/bin/bash
set -e

echo "Removing GitHub Desktop..."

if [ ! -d /usr/lib/github-desktop ]; then
  echo "GitHub Desktop is not installed."
  exit 0
fi

sudo rm -rf /usr/lib/github-desktop
sudo rm -f /usr/bin/github-desktop
sudo rm -f /usr/share/applications/github-desktop.desktop
sudo rm -rf /usr/share/doc/github-desktop
sudo rm -f /usr/share/lintian/overrides/github-desktop
sudo rm -f /usr/share/icons/hicolor/*/apps/github-desktop.png
