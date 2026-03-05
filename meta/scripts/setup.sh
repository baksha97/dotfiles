#!/bin/zsh

set -e

profile="${1:-personal}"

# Validate profile
if [ ! -f "stow/git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in stow/git/profiles/"
  exit 1
fi

# Show hidden files in file manager
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  command -v gsettings &>/dev/null && gsettings set org.gnome.nautilus.preferences show-hidden-files true || true
elif [[ "$OSTYPE" == "darwin"* ]]; then
  defaults write com.apple.finder AppleShowAllFiles YES
fi

# Check if Homebrew is installed, install if not
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add Homebrew to PATH for the current session on Linux (installer doesn't do this automatically)
if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Install packages for the selected profile
brew update
brew bundle --verbose --file="meta/homebrew/Brewfile.$profile"

# Install Tailscale on Linux via the official install script (Homebrew formula requires systemd)
if [[ "$OSTYPE" == "linux-gnu"* ]] && ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# Install Nerd Fonts on Linux (macOS handles this via Brewfile casks)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  nerd_fonts_version="v3.3.0"
  nerd_fonts=(
    DroidSansMono
    FiraCode
    JetBrainsMono
    Meslo
    Mononoki
    RobotoMono
    SourceCodePro
    NerdFontsSymbolsOnly
  )
  font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"
  echo "Installing Nerd Fonts..."
  fonts_changed=false
  for font in "${nerd_fonts[@]}"; do
    marker="$font_dir/.installed-${font}-${nerd_fonts_version}"
    if [[ -f "$marker" ]]; then
      echo "  Skipped $font (already installed)"
      continue
    fi
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${nerd_fonts_version}/${font}.tar.xz" \
      | tar -xJ -C "$font_dir"
    touch "$marker"
    echo "  Installed $font"
    fonts_changed=true
  done
  if [[ "$fonts_changed" == true ]]; then
    fc-cache -f "$font_dir"
    echo "  Font cache updated"
  fi
fi

# Install SDKMAN! if not installed
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
      # Skip if it's the tracked alacritty config (managed by stow/alacritty/.config/alacritty)
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

stow -d stow zsh -t "$HOME" --adopt
stow -d stow powerlevel10k -t "$HOME" --adopt
stow -d stow tmux -t "$HOME" --adopt
stow -d stow alacritty -t "$HOME" --adopt --no-folding

# VSCode settings — platform-specific path
if [[ "$OSTYPE" == "darwin"* ]]; then
  vscode_dir="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  vscode_dir="$HOME/.config/Code/User"
fi

if [ -n "$vscode_dir" ]; then
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

# Agent Skills — symlink the skills directory for Copilot CLI and Cursor IDE
# VS Code discovers skills via chat.agentSkillsLocations in vscode/settings.json
skills_src="$(cd meta/.ai-agent/skills && pwd)"
for target in "$HOME/.copilot/skills" "$HOME/.cursor/skills"; do
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    rm -rf "$target"
  fi
  ln -s "$skills_src" "$target"
  echo "  Linked $target -> $skills_src"
done

echo "Dotfiles installation complete! Open a new shell to pick up changes."
