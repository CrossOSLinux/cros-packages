#!/bin/bash
# cros-packages: android-sdk
# Installs the Android SDK, NDK, and build tools.
# SDK is installed to ~/.android-sdk.
# Intended for use with Flutter on ARM64/x86_64.
set -e

ARCH="${CROS_ARCH:-$(uname -m)}"

case "$ARCH" in
    arm64|aarch64|x86_64) ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

ANDROID_HOME="$HOME/.android-sdk"
CMDLINE_TOOLS_DIR="$ANDROID_HOME/cmdline-tools"
SDKMANAGER="$CMDLINE_TOOLS_DIR/latest/bin/sdkmanager"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> Android SDK installer (arch: $ARCH)"

# Install system dependencies
# Note: android-tools provides native adb/fastboot; jdk17 is required by sdkmanager
echo "==> Installing dependencies..."
sudo pacman -Syu --needed --noconfirm android-tools jdk17-openjdk unzip wget

# Export JAVA_HOME into this shell session so sdkmanager can find it
# (Fish shell env vars are not inherited by bash subprocesses)
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
export PATH="$JAVA_HOME/bin:$PATH"

echo "==> Using Java: $(java -version 2>&1 | head -1)"

# Fetch the latest cmdline-tools build number dynamically
echo "==> Fetching latest cmdline-tools version..."
REPO_XML=$(wget -q -O - "https://dl.google.com/android/repository/repository2-3.xml" 2>/dev/null || true)

# Parse the latest linux cmdline-tools URL from the repository manifest
CMD_TOOLS_URL=$(echo "$REPO_XML" \
    | grep -o 'https://dl.google.com/android/repository/commandlinetools-linux-[0-9]*_latest.zip' \
    | tail -1)

# Fallback to known-good version if manifest fetch fails
if [ -z "$CMD_TOOLS_URL" ]; then
    echo "==> Warning: Could not fetch manifest, using fallback version."
    CMD_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip"
fi

echo "==> Downloading: $CMD_TOOLS_URL"

# Prepare SDK directory
mkdir -p "$CMDLINE_TOOLS_DIR"

# Remove any existing latest/ to avoid mv nesting on reinstall
rm -rf "$CMDLINE_TOOLS_DIR/latest"
mkdir -p "$CMDLINE_TOOLS_DIR/latest"

# Download and extract cmdline-tools
wget -q --show-progress -O "$TMP_DIR/cmdline-tools.zip" "$CMD_TOOLS_URL"
unzip -q "$TMP_DIR/cmdline-tools.zip" -d "$TMP_DIR"

# The zip extracts to cmdline-tools/ — move its contents into latest/
mv "$TMP_DIR/cmdline-tools/"* "$CMDLINE_TOOLS_DIR/latest/"

echo "==> Installing SDK packages via sdkmanager..."
echo "    (This may take several minutes)"

# Run sdkmanager with explicit sdk_root and JAVA_HOME in environment
# 'yes' pipes 'y' to accept any prompts; --sdk_root avoids ambiguity
JAVA_HOME="$JAVA_HOME" yes | "$SDKMANAGER" \
    --sdk_root="$ANDROID_HOME" \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" \
    "ndk;27.2.12479018"

echo "==> Accepting SDK licenses..."
JAVA_HOME="$JAVA_HOME" yes | "$SDKMANAGER" \
    --sdk_root="$ANDROID_HOME" \
    --licenses || true

# Accept Flutter Android licenses if Flutter is present
if command -v flutter &>/dev/null; then
    echo "==> Accepting Flutter Android licenses..."
    yes | flutter doctor --android-licenses || true
fi

# Configure Fish shell environment if present
if command -v fish &>/dev/null; then
    echo "==> Configuring Fish shell environment..."
    fish -c "set -Ux ANDROID_HOME $ANDROID_HOME"
    fish -c "set -Ux JAVA_HOME $JAVA_HOME"
    fish -c "fish_add_path $CMDLINE_TOOLS_DIR/latest/bin"
    fish -c "fish_add_path $ANDROID_HOME/platform-tools"
fi

echo ""
echo "==> Android SDK installed to: $ANDROID_HOME"
echo "    For non-Fish shells, add to your profile:"
echo "      export ANDROID_HOME=\"$ANDROID_HOME\""
echo "      export JAVA_HOME=\"$JAVA_HOME\""
echo "      export PATH=\"\$PATH:$ANDROID_HOME/platform-tools:$CMDLINE_TOOLS_DIR/latest/bin\""
echo "    Verify with: flutter doctor"
