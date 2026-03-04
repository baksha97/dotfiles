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
  gsettings set org.gnome.nautilus.preferences show-hidden-files true
elif [[ "$OSTYPE" == "darwin"* ]]; then
  defaults write com.apple.finder AppleShowAllFiles YES
fi

# Check if Homebrew is installed, install if not
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Determine Homebrew path for different platforms
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  BREW_PATH="/opt/homebrew/bin/brew"
elif [[ -x "/usr/local/bin/brew" ]]; then
  BREW_PATH="/usr/local/bin/brew"
elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
else
  BREW_PATH="$(command -v brew)"
fi

echo >> "$HOME/.zprofile"
echo "eval \"\$(${BREW_PATH} shellenv)\"" >> "$HOME/.zprofile"
eval "$(${BREW_PATH} shellenv)"

# Install packages for the selected profile
brew bundle --file="meta/homebrew/Brewfile.$profile"

# Install SDKMAN! if not installed
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Clean up .DS_Store files that cause stow conflicts on macOS
find . -name .DS_Store -delete

# Back up real files (not symlinks) before removing, then clean up all targets
backup_dir="backup/$(date +%Y-%m-%d_%H-%M-%S)"
stow_targets=(
  "$HOME/.zshrc"
  "$HOME/.p10k.zsh"
  "$HOME/.tmux.conf"
  "$HOME/.gitconfig"
  "$HOME/.gitignore"
  "$HOME/.gitconfig-profile"
  "$HOME/profiles"
)

backed_up=false
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

# Alacritty icon
if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$DOTFILES_DIR/meta/scripts/alacritty-icon.sh"
else
  echo "  Warning: Alacritty icon replacement not supported on this OS ($OSTYPE)"
fi

echo "Dotfiles installation complete! Open a new shell to pick up changes."
