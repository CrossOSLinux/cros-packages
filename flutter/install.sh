#!/bin/bash
# cros-packages: flutter
# Installs the Flutter SDK (stable) natively for ARM64/x86_64.
# SDK is installed to ~/.flutter-sdk.
# User projects and pub-cache are never touched on reinstall.
set -e

ARCH="${CROS_ARCH:-$(uname -m)}"

case "$ARCH" in
    arm64|aarch64|x86_64) ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

FLUTTER_DIR="$HOME/.flutter-sdk"

echo "==> Flutter SDK installer (arch: $ARCH)"

# Install system dependencies
echo "==> Installing toolchain dependencies..."
sudo pacman -Syu --needed --noconfirm base-devel cmake clang ninja pkg-config gtk3 curl unzip xz git

# Clone stable Flutter SDK
if [ -d "$FLUTTER_DIR" ]; then
    echo "==> Flutter SDK already exists at $FLUTTER_DIR."
    echo "==> Pulling latest stable..."
    git -C "$FLUTTER_DIR" pull --ff-only
else
    echo "==> Cloning Flutter stable branch to $FLUTTER_DIR..."
    git clone -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

# Trigger precache to download native ARM64/x86_64 Dart SDK and engine binaries
echo "==> Running flutter precache (downloads native engine binaries)..."
echo "    This may take a few minutes on first install."
"$FLUTTER_DIR/bin/flutter" precache

echo ""
echo "==> Flutter SDK installed to: $FLUTTER_DIR"
echo "    Add to PATH: export PATH=\"\$PATH:$FLUTTER_DIR/bin\""
echo "    Verify install with: flutter doctor"
