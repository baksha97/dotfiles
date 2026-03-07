#!/bin/bash
# alacritty — terminal emulator config (uses --no-folding to allow device-specific overrides)

# Handle ~/.config edge cases from the old flat stow layout:
# - Stale ~/.config symlink: remove it so stow can create the real directory tree.
# - Stale ~/.config/alacritty symlink: same.
# - Real ~/.config/alacritty dir with no symlinks inside: not stow-managed, back it up.
# - Real ~/.config/alacritty dir with symlinks inside: already stow-managed, leave it.
if [ -L "$HOME/.config" ]; then
  rm "$HOME/.config"
elif [ -L "$HOME/.config/alacritty" ]; then
  rm "$HOME/.config/alacritty"
elif [ -d "$HOME/.config/alacritty" ]; then
  if ! find "$HOME/.config/alacritty" -maxdepth 2 -type l -print -quit | grep -q .; then
    if [ "$backed_up" = false ]; then
      mkdir -p "$backup_dir"
      backed_up=true
    fi
    cp -R "$HOME/.config/alacritty" "$backup_dir/"
    rm -rf "$HOME/.config/alacritty"
  fi
fi

stow_package alacritty --no-folding
