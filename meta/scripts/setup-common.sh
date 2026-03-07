#!/bin/bash
# setup-common.sh — platform-agnostic stow, git, and skills setup.
# Expects $profile and $DOTFILES_DIR to be set by the calling script.

set -e

# Install SDKMAN! if not present
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Clean up .DS_Store files that cause stow conflicts on macOS
find "$DOTFILES_DIR" -name .DS_Store -delete

backup_dir="$DOTFILES_DIR/backup/$(date +%Y-%m-%d_%H-%M-%S)"
backed_up=false

# Migrate old layout: root alacritty/ folder was the former stow package, which caused
# ~/.config to be symlinked entirely. Device-specific configs accumulated inside it.
# Move them to stow/alacritty/.config/ (gitignored) and remove the old folder.
if [ -d "$DOTFILES_DIR/alacritty" ] && [ ! -L "$DOTFILES_DIR/alacritty" ]; then
  echo "  Detected old alacritty/ layout — migrating device-specific configs..."
  old_config="$DOTFILES_DIR/alacritty/.config"
  new_config="$DOTFILES_DIR/stow/alacritty/.config"
  if [ -d "$old_config" ]; then
    mkdir -p "$backup_dir"
    backed_up=true
    cp -R "$old_config/" "$backup_dir/config-from-alacritty/"
    for d in "$old_config"/*/; do
      name="$(basename "$d")"
      [ "$name" = "alacritty" ] && continue
      if [ ! -e "$new_config/$name" ]; then
        cp -R "$d" "$new_config/$name"
        echo "    Migrated: $name"
      else
        echo "    Skipped (already in stow): $name"
      fi
    done
  fi
  rm -rf "$DOTFILES_DIR/alacritty"
  echo "  Removed old alacritty/ folder"
fi

# ── Stow helpers ─────────────────────────────────────────────────────────────

# stow_backup TARGET
# If TARGET is a real file/dir (not a symlink), back it up and remove it.
# If TARGET is a symlink, just remove it (no backup needed — already managed).
stow_backup() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    if [ "$backed_up" = false ]; then
      mkdir -p "$backup_dir"
      backed_up=true
    fi
    cp -R "$target" "$backup_dir/"
  fi
  rm -rf "$target"
}

# stow_package PKG [FLAGS...]
# Run stow for PKG against STOW_TARGET (defaults to $HOME).
# Callers set STOW_TARGET before calling when a non-$HOME target is needed.
stow_package() {
  local pkg="$1"; shift
  local target="${STOW_TARGET:-$HOME}"
  stow -d "$DOTFILES_DIR/stow" "$pkg" -t "$target" --adopt "$@"
}

# ── Stow packages ─────────────────────────────────────────────────────────────
# Each file in stow.d/ installs one stow package. Adding a new package = add one file.
STOW_D="$DOTFILES_DIR/meta/scripts/stow.d"
for f in "$STOW_D/"*.sh; do
  unset STOW_TARGET
  [ -f "$f" ] && source "$f"
done

if [ "$backed_up" = true ]; then
  echo "  Backed up existing configs to $backup_dir/"
fi

# ── GitHub CLI credential helper ──────────────────────────────────────────────
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "  Ensuring GitHub CLI git-credential helper is linked..."
  gh auth setup-git
fi

# ── Agent Skills ──────────────────────────────────────────────────────────────
# Symlink the skills directory for Copilot CLI, Cursor IDE, and others.
skills_src="$(cd "$DOTFILES_DIR/meta/.ai-agent/skills" && pwd)"
for target in "$HOME/.copilot/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills"; do
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    rm -rf "$target"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$skills_src" "$target"
  echo "  Linked $target -> $skills_src"
done

echo "Dotfiles installation complete! Open a new shell to pick up changes."
