#!/bin/bash
set -e

echo "Fetching latest sccache version..."
LATEST=$(curl -s https://api.github.com/repos/mozilla/sccache/releases/latest \
  | grep '"tag_name"' \
  | cut -d'"' -f4 \
  | sed 's/^v//')

if [ -z "$LATEST" ]; then
  echo "Error: Could not fetch latest version."
  exit 1
fi

if command -v sccache &>/dev/null; then
  INSTALLED=$(sccache --version 2>/dev/null | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1)
  if [ "$INSTALLED" = "$LATEST" ]; then
    echo "sccache $INSTALLED is already up to date."
    exit 0
  fi
  echo "Updating sccache $INSTALLED -> $LATEST..."
else
  echo "Installing sccache $LATEST..."
fi

TARBALL="sccache-v${LATEST}-aarch64-unknown-linux-musl.tar.gz"
URL="https://github.com/mozilla/sccache/releases/download/v${LATEST}/${TARBALL}"

echo "Downloading $TARBALL..."
curl -L -o "/tmp/${TARBALL}" "$URL"

echo "Extracting..."
tar -xzf "/tmp/${TARBALL}" -C /tmp/

echo "Installing..."
sudo install -Dm755 "/tmp/sccache-v${LATEST}-aarch64-unknown-linux-musl/sccache" /usr/bin/sccache

rm -rf "/tmp/${TARBALL}" "/tmp/sccache-v${LATEST}-aarch64-unknown-linux-musl"

echo "Done. sccache $LATEST installed."
