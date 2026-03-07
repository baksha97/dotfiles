#!/bin/bash
# claude — Claude Code IDE settings (uses --no-folding to allow device-specific dirs)
STOW_TARGET="$HOME/.claude"
mkdir -p "$STOW_TARGET"

# Back up real files (settings, status line, readme) before stow links them.
for f in settings.json status-line.sh README.md; do
  stow_backup "$STOW_TARGET/$f"
done

# For directories managed by stow --no-folding: only back up + remove if not already
# stow-managed (i.e. the dir exists but contains no symlinks yet).
for d in commands agents scripts; do
  target="$STOW_TARGET/$d"
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    if ! find "$target" -maxdepth 3 -type l -print -quit | grep -q .; then
      [ "$backed_up" = false ] && mkdir -p "$backup_dir" && backed_up=true
      cp -R "$target" "$backup_dir/"
      rm -rf "$target"
    fi
  fi
done

stow_package claude --no-folding
