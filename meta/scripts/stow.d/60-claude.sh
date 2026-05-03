#!/bin/bash
# claude — Claude Code IDE settings (uses --no-folding to allow device-specific dirs)
STOW_TARGET="$HOME/.claude"
setup_mkdir_p "$STOW_TARGET"
stow_package claude --no-folding
