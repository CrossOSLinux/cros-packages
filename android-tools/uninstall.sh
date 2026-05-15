#!/bin/bash
# cros-packages: android-sdk — uninstall
# Removes the Android SDK and all associated config.
# User project files are never touched.
set -e

ANDROID_HOME="$HOME/.android-sdk"

echo "==> Removing Android SDK..."

# Remove the SDK directory
if [ -d "$ANDROID_HOME" ]; then
    echo "==> Removing SDK directory: $ANDROID_HOME"
    rm -rf "$ANDROID_HOME"
else
    echo "==> SDK directory not found at $ANDROID_HOME, skipping."
fi

# Remove the hidden .android folder (AVD config, debug keys, etc.)
if [ -d "$HOME/.android" ]; then
    echo "==> Removing: $HOME/.android"
    rm -rf "$HOME/.android"
fi

# Clean up Fish universal variables and paths if Fish is present
if command -v fish &>/dev/null; then
    echo "==> Cleaning Fish shell environment..."
    fish -c "set -Ue ANDROID_HOME" 2>/dev/null || true
    fish -c "set -Ue JAVA_HOME" 2>/dev/null || true
    fish -c "set -U fish_user_paths (string match -v \"$ANDROID_HOME/cmdline-tools/latest/bin\" \$fish_user_paths)" || true
    fish -c "set -U fish_user_paths (string match -v \"$ANDROID_HOME/platform-tools\" \$fish_user_paths)" || true
fi

echo "==> Android SDK removed."
echo "    Note: System packages (android-tools, jdk17-openjdk) were not removed."
