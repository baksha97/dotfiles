#!/bin/zsh
# setup-common.sh — platform-agnostic stow, git, and skills setup.
# Expects $profile and $DOTFILES_DIR to be set by the calling script.

set -e

# Install SDKMAN! if not present
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Clean up .DS_Store files that cause stow conflicts on macOS
find . -name .DS_Store -delete

backup_dir="backup/$(date +%Y-%m-%d_%H-%M-%S)"
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

# Back up real files (not symlinks) before removing, then clean up all targets
stow_targets=(
  "$HOME/.zshrc"
  "$HOME/.zshrc.d"
  "$HOME/.p10k.zsh"
  "$HOME/.tmux.conf"
  "$HOME/.gitconfig"
  "$HOME/.gitignore"
  "$HOME/.gitconfig-profile"
  "$HOME/profiles"
)

for target in "${stow_targets[@]}"; do
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    if [ "$backed_up" = false ]; then
      mkdir -p "$backup_dir"
      backed_up=true
    fi
    cp -R "$target" "$backup_dir/"
  fi
  rm -rf "$target"
done

# Handle ~/.config separately: if it's a stale symlink (from old flat layout), remove it.
# If it's a real directory, only remove the alacritty subdirectory inside it.
if [ -L "$HOME/.config" ]; then
  rm "$HOME/.config"
elif [ -d "$HOME/.config/alacritty" ] && [ ! -L "$HOME/.config/alacritty" ]; then
  if [ "$backed_up" = false ]; then
    mkdir -p "$backup_dir"
    backed_up=true
  fi
  cp -R "$HOME/.config/alacritty" "$backup_dir/"
  rm -rf "$HOME/.config/alacritty"
else
  rm -rf "$HOME/.config/alacritty"
fi

if [ "$backed_up" = true ]; then
  echo "  Backed up existing configs to $backup_dir/"
fi

stow -d stow zsh -t "$HOME" --adopt --no-folding
stow -d stow powerlevel10k -t "$HOME" --adopt
stow -d stow tmux -t "$HOME" --adopt
stow -d stow alacritty -t "$HOME" --adopt --no-folding

# VSCode settings — only stow if VSCode/Cursor is actually installed
if [[ "$OSTYPE" == "darwin"* ]]; then
  vscode_dir="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "linux-gnu"* ]] && command -v code &>/dev/null; then
  vscode_dir="$HOME/.config/Code/User"
fi

if [ -n "$vscode_dir" ]; then
  mkdir -p "$vscode_dir"
  vscode_stow_files=(.vscode keybindings.json settings.json)
  for f in "${vscode_stow_files[@]}"; do
    target="$vscode_dir/$f"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      if [ "$backed_up" = false ]; then
        mkdir -p "$backup_dir"
        backed_up=true
      fi
      cp -R "$target" "$backup_dir/"
    fi
    rm -rf "$target"
  done
  stow -d stow vscode -t "$vscode_dir" --adopt
fi

# Git configuration
cp "stow/git/profiles/$profile" stow/git/.gitconfig-profile
stow -d stow git -t "$HOME"/ --adopt
echo "  Git profile set to '$profile'"

# GitHub CLI authentication setup
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "  Ensuring GitHub CLI git-credential helper is linked..."
  gh auth setup-git
fi

# Agent Skills — symlink the skills directory for Copilot CLI, Cursor IDE, and others
skills_src="$(cd meta/.ai-agent/skills && pwd)"
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
