#!/bin/zsh
# setup-common.sh — platform-agnostic stow, git, and skills setup.
# Expects $profile and $DOTFILES_DIR to be set by the calling script.

set -e

# Load helper functions
source "$DOTFILES_DIR/meta/scripts/merge-helpers.sh"

# DRY_RUN handling
run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would run: $*"
  else
    "$@"
  fi
}

STOW_OPTS=("-d" "stow" "-t" "$HOME" "--adopt")
if [[ "$DRY_RUN" == "true" ]]; then
  STOW_OPTS+=("--simulate")
fi

# Install SDKMAN! if not present and mise is not managing JVM tools
install_sdkman=true
if command -v mise &>/dev/null; then
  if mise ls java &>/dev/null || mise ls gradle &>/dev/null || mise ls kotlin &>/dev/null; then
    echo "  Detected mise managing JVM tools, skipping SDKMAN! installation."
    install_sdkman=false
  fi
fi

if [[ "$install_sdkman" == true ]] && [ ! -d "$HOME/.sdkman" ]; then
  echo "  Installing SDKMAN!..."
  if [[ "$DRY_RUN" != "true" ]]; then
    curl -s "https://get.sdkman.io" | bash
    # Note: we don't source it here as it needs a new shell or manual source later
  else
    echo "[DRY RUN] Would install SDKMAN!"
  fi
fi

# Clean up .DS_Store files that cause stow conflicts on macOS
if [[ "$DRY_RUN" != "true" ]]; then
  find . -name .DS_Store -delete
fi

backup_dir="backup/$(date +%Y-%m-%d_%H-%M-%S)"
backed_up=false

# Migrate old layout: root alacritty/ folder was the former stow package
if [ -d "$DOTFILES_DIR/alacritty" ] && [ ! -L "$DOTFILES_DIR/alacritty" ]; then
  echo "  Detected old alacritty/ layout — migrating device-specific configs..."
  old_config="$DOTFILES_DIR/alacritty/.config"
  new_config="$DOTFILES_DIR/stow/alacritty/.config"
  if [ -d "$old_config" ]; then
    if [[ "$DRY_RUN" != "true" ]]; then
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
    else
      echo "[DRY RUN] Would migrate configs from $old_config to $new_config"
    fi
  fi
  run_cmd rm -rf "$DOTFILES_DIR/alacritty"
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
)

for target in "${stow_targets[@]}"; do
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    if [[ "$DRY_RUN" != "true" ]]; then
      if [ "$backed_up" = false ]; then
        mkdir -p "$backup_dir"
        backed_up=true
      fi
      cp -R "$target" "$backup_dir/"
    else
      echo "[DRY RUN] Would backup $target"
    fi
  fi
  run_cmd rm -rf "$target"
done

# Handle ~/.config separately
if [ -L "$HOME/.config" ]; then
  run_cmd rm "$HOME/.config"
elif [ -d "$HOME/.config/alacritty" ] && [ ! -L "$HOME/.config/alacritty" ]; then
  if [[ "$DRY_RUN" != "true" ]]; then
    if [ "$backed_up" = false ]; then
      mkdir -p "$backup_dir"
      backed_up=true
    fi
    cp -R "$HOME/.config/alacritty" "$backup_dir/"
  else
    echo "[DRY RUN] Would backup $HOME/.config/alacritty"
  fi
  run_cmd rm -rf "$HOME/.config/alacritty"
else
  run_cmd rm -rf "$HOME/.config/alacritty"
fi

if [ "$backed_up" = true ]; then
  echo "  Backed up existing configs to $backup_dir/"
fi

stow "${STOW_OPTS[@]}" zsh
stow "${STOW_OPTS[@]}" powerlevel10k
stow "${STOW_OPTS[@]}" tmux
stow "${STOW_OPTS[@]}" alacritty --no-folding

# VSCode settings — only stow if VSCode/Cursor is actually installed
if [[ "$OSTYPE" == "darwin"* ]]; then
  vscode_dir="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "linux-gnu"* ]] && command -v code &>/dev/null; then
  vscode_dir="$HOME/.config/Code/User"
fi

if [ -n "$vscode_dir" ]; then
  run_cmd mkdir -p "$vscode_dir"
  
  # Merge VSCode settings
  settings_json="$vscode_dir/settings.json"
  if [ -f "$settings_json" ] && [ ! -L "$settings_json" ]; then
    echo "  Merging existing VSCode settings..."
    if [[ "$DRY_RUN" != "true" ]]; then
      backup_if_exists "$settings_json"
      merge_json_preserve_keys "$settings_json" "stow/vscode/settings.json" "meta/config/merge-keys-vscode.txt" "stow/vscode/settings.json"
    else
      echo "[DRY RUN] Would merge existing VSCode settings into stow/vscode/settings.json"
    fi
    run_cmd rm "$settings_json"
  fi

  # Merge VSCode keybindings
  keybindings_json="$vscode_dir/keybindings.json"
  if [ -f "$keybindings_json" ] && [ ! -L "$keybindings_json" ]; then
    echo "  Backing up existing VSCode keybindings..."
    if [[ "$DRY_RUN" != "true" ]]; then
      backup_if_exists "$keybindings_json"
    fi
    run_cmd rm "$keybindings_json"
  fi

  stow -d stow vscode -t "$vscode_dir" --adopt $([[ "$DRY_RUN" == "true" ]] && echo "--simulate")
fi

# Git configuration
if [[ "$DRY_RUN" != "true" ]]; then
  cp "stow/git/profiles/$profile" stow/git/.gitconfig-profile
else
  echo "[DRY RUN] Would copy stow/git/profiles/$profile to stow/git/.gitconfig-profile"
fi
stow "${STOW_OPTS[@]}" git
echo "  Git profile set to '$profile'"

# Agent Skills — symlink the skills directory for Copilot CLI and Cursor IDE
skills_src="$(cd meta/.ai-agent/skills && pwd)"
for target in "$HOME/.copilot/skills" "$HOME/.cursor/skills"; do
  if [ -L "$target" ]; then
    run_cmd rm "$target"
  elif [ -d "$target" ]; then
    run_cmd rm -rf "$target"
  fi
  run_cmd mkdir -p "$(dirname "$target")"
  run_cmd ln -s "$skills_src" "$target"
done

# Change login shell to zsh if needed
current_shell=$(basename "$SHELL")
if [[ "$current_shell" != "zsh" ]] && [[ -t 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
  echo -n "  Current shell is $current_shell. Change login shell to zsh? [y/N] "
  read -r opt
  if [[ "$opt" =~ ^[Yy]$ ]]; then
    zsh_path=$(which zsh)
    echo "  Changing shell to $zsh_path..."
    chsh -s "$zsh_path"
  fi
elif [[ "$DRY_RUN" == "true" ]] && [[ "$current_shell" != "zsh" ]]; then
  echo "[DRY RUN] Would prompt to change login shell to zsh"
fi

echo "Dotfiles installation complete! Open a new shell to pick up changes."
