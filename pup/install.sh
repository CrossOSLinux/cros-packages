#!/bin/bash
set -e

if command -v pup &>/dev/null; then
  echo "pup is already installed."
  exit 0
fi

echo "Installing pup..."
curl -L -o /tmp/pup.zip \
  "https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_arm64.zip"

unzip -o /tmp/pup.zip -d /tmp/pup_extract
sudo install -Dm755 /tmp/pup_extract/pup /usr/bin/pup

rm -rf /tmp/pup.zip /tmp/pup_extract

echo "Done. pup installed."
