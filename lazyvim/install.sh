#!/bin/bash
set -e

# Check neovim is installed
if ! command -v nvim &>/dev/null; then
  echo "Neovim is not installed. Installing via pacman..."
  sudo pacman -S --noconfirm neovim
fi

# Backup existing nvim config if it exists
if [ -d ~/.config/nvim ]; then
  echo "Backing up existing neovim config..."
  mv ~/.config/nvim ~/.config/nvim.bak
fi

# Backup optional dirs if they exist
[ -d ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim.bak
[ -d ~/.local/state/nvim ] && mv ~/.local/state/nvim ~/.local/state/nvim.bak
[ -d ~/.cache/nvim ] && mv ~/.cache/nvim ~/.cache/nvim.bak

echo "Installing LazyVim..."
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo "Done. Run 'nvim' to finish LazyVim setup."
