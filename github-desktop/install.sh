#!/bin/bash
set -e

echo "Fetching latest GitHub Desktop version..."
LATEST=$(curl -s https://api.github.com/repos/shiftkey/desktop/releases/latest \
  | grep '"tag_name"' \
  | cut -d'"' -f4 \
  | sed 's/release-//')

if [ -z "$LATEST" ]; then
  echo "Error: Could not fetch latest version."
  exit 1
fi

# Check if already installed and up to date
if command -v github-desktop &>/dev/null; then
  INSTALLED=$(github-desktop --version 2>/dev/null | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1)
  LATEST_VER=$(echo "$LATEST" | grep -oP '[\d]+\.[\d]+\.[\d]+')
  if [ "$INSTALLED" = "$LATEST_VER" ]; then
    echo "GitHub Desktop $INSTALLED is already up to date."
    exit 0
  fi
  echo "Updating GitHub Desktop $INSTALLED -> $LATEST_VER..."
else
  echo "Installing GitHub Desktop $LATEST..."
fi

DEB="GitHubDesktop-linux-arm64-${LATEST}.deb"
URL="https://github.com/shiftkey/desktop/releases/download/release-${LATEST}/${DEB}"

echo "Downloading $DEB..."
curl -L -o "/tmp/${DEB}" "$URL"

echo "Extracting .deb..."
mkdir -p /tmp/github-desktop-extract
cd /tmp/github-desktop-extract
ar x "/tmp/${DEB}"

# Extract data archive (may be .tar.xz or .tar.zst)
if [ -f data.tar.xz ]; then
  tar -xf data.tar.xz
elif [ -f data.tar.zst ]; then
  tar -xf data.tar.zst
else
  echo "Error: Unknown data archive format."
  exit 1
fi

echo "Installing files..."
[ -d /tmp/github-desktop-extract/usr ] && sudo cp -r /tmp/github-desktop-extract/usr /
[ -d /tmp/github-desktop-extract/opt ] && sudo cp -r /tmp/github-desktop-extract/opt /



# Cleanup
cd /
rm -rf /tmp/github-desktop-extract "/tmp/${DEB}"

echo "Done. GitHub Desktop $LATEST installed."
