#!/bin/bash
# alacritty — terminal emulator config (uses --no-folding to allow device-specific overrides)

# Guard: old flat stow layout may have symlinked ~/.config itself as a directory.
# --no-folding needs a real directory to descend into, so remove the stale symlink.
# TODO: Remove once all legacy systems have run setup at least once.
if [ -L "$HOME/.config" ]; then
  rm "$HOME/.config"
fi

stow_package alacritty --no-folding
