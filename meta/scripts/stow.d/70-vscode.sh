#!/bin/bash
# vscode — VS Code / Cursor editor settings (only stow if VS Code is installed)
command -v code &>/dev/null || return 0
if [[ "$OSTYPE" == "darwin"* ]]; then
  STOW_TARGET="$HOME/Library/Application Support/Code/User"
else
  STOW_TARGET="$HOME/.config/Code/User"
fi

mkdir -p "$STOW_TARGET"
for f in .vscode keybindings.json settings.json; do
  stow_backup "$STOW_TARGET/$f"
done
stow_package vscode
