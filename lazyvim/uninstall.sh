#!/bin/bash
set -e

echo "Removing LazyVim..."

rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

# Restore backups if they exist
if [ -d ~/.config/nvim.bak ]; then
  echo "Restoring previous neovim config..."
  mv ~/.config/nvim.bak ~/.config/nvim
fi

[ -d ~/.local/share/nvim.bak ] && mv ~/.local/share/nvim.bak ~/.local/share/nvim
[ -d ~/.local/state/nvim.bak ] && mv ~/.local/state/nvim.bak ~/.local/state/nvim
[ -d ~/.cache/nvim.bak ] && mv ~/.cache/nvim.bak ~/.cache/nvim

echo "Done. LazyVim removed."
