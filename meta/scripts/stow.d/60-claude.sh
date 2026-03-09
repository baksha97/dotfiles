#!/bin/bash
# claude — Claude Code IDE settings (uses --no-folding to allow device-specific dirs)
STOW_TARGET="$HOME/.claude"
mkdir -p "$STOW_TARGET"
stow_package claude --no-folding
