#!/bin/bash
# alacritty — terminal emulator config (uses --no-folding to allow device-specific overrides)
if [ -L "$HOME/.config/alacritty" ]; then
  stow_backup "$HOME/.config/alacritty"
fi
stow_package alacritty --no-folding
