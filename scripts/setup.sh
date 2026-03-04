#!/bin/zsh

set -e

profile="${1:-personal}"

# Validate profile
if [ ! -f "git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in git/profiles/"
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

# Install packages for the selected profile
brew bundle --file="homebrew/Brewfile.$profile"

# Install SDKMAN! if not installed
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Clean up .DS_Store files that cause stow conflicts on macOS
find . -name .DS_Store -delete

# Remove existing .zshrc and adopt new configurations
rm -f "$HOME"/.zshrc
stow zsh -t "$HOME" --adopt
stow powerlevel10k -t "$HOME" --adopt
stow tmux -t "$HOME" --adopt
stow alacritty -t "$HOME" --adopt

# VSCode settings — platform-specific path
if [[ "$OSTYPE" == "darwin"* ]]; then
  stow vscode -t "$HOME/Library/Application Support/Code/User" --adopt
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  stow vscode -t "$HOME/.config/Code/User" --adopt
fi

# Git configuration
cp "git/profiles/$profile" git/.gitconfig-profile
stow git -t "$HOME"/ --adopt
echo "  Git profile set to '$profile'"

# Agent Skills — symlink the skills directory for Copilot CLI and Cursor IDE
# VS Code discovers skills via chat.agentSkillsLocations in vscode/settings.json
skills_src="$(cd .ai-agent/skills && pwd)"
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
