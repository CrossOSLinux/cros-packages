#!/bin/bash
# cros-packages: flutter — uninstall
# Removes the Flutter SDK and all associated caches/config.
# User project files and source code are never touched.
set -e

FLUTTER_DIR="$HOME/.flutter-sdk"

echo "==> Removing Flutter SDK..."

# Remove the core SDK
if [ -d "$FLUTTER_DIR" ]; then
    echo "==> Removing Flutter SDK directory: $FLUTTER_DIR"
    rm -rf "$FLUTTER_DIR"
else
    echo "==> Flutter SDK not found at $FLUTTER_DIR, skipping."
fi

# Remove all Flutter/Dart footprints from home directory
echo "==> Purging Flutter and Dart caches and config..."
ARTIFACTS=(
    "$HOME/.flutter"
    "$HOME/.config/flutter"
    "$HOME/.dart"
    "$HOME/.dart-tool"
    "$HOME/.pub-cache"
    "$HOME/.flutter-devtools"
    "$HOME/.cache/flutter"
)

for path in "${ARTIFACTS[@]}"; do
    if [ -e "$path" ]; then
        echo "    Removing: $path"
        rm -rf "$path"
    fi
done

# Remove from Fish universal path if Fish is present
if command -v fish &>/dev/null; then
    echo "==> Removing Flutter from Fish shell paths..."
    fish -c "set -U fish_user_paths (string match -v \"$HOME/.flutter-sdk/bin\" \$fish_user_paths)" || true
fi

echo "==> Flutter SDK and all caches removed."
echo "    Note: System packages (cmake, ninja, etc.) were not removed."
