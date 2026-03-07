#!/bin/bash
# vscode — VS Code / Cursor editor settings (only stow if VS Code is installed)
if [[ "$OSTYPE" == "darwin"* ]]; then
  STOW_TARGET="$HOME/Library/Application Support/Code/User"
elif command -v code &>/dev/null; then
  STOW_TARGET="$HOME/.config/Code/User"
else
  return 0
fi

mkdir -p "$STOW_TARGET"
for f in .vscode keybindings.json settings.json; do
  stow_backup "$STOW_TARGET/$f"
done
stow_package vscode
