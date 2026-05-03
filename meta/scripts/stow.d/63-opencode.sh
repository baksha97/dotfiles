#!/bin/bash
# opencode — core config and oh-my-opencode-slim plugin config.
mkdir -p "$HOME/.config/opencode"
stow_backup "$HOME/.config/opencode/opencode.json"
stow_backup "$HOME/.config/opencode/oh-my-opencode-slim.json"
stow_package opencode --no-folding
