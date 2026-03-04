#!/bin/zsh

# Show hidden files in file manager (Nautilus for GNOME)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  gsettings set org.gnome.nautilus.preferences show-hidden-files true
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # MacOS System
  defaults write com.apple.finder AppleShowAllFiles YES
fi

# Check if Homebrew is installed, install if not
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install all packages from Brewfile
brew bundle --file="Brewfile"

# Install SDKMAN! if not installed
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

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

# Git configuration — select a profile (personal or work)
git_profile="${1:-}"
if [ -z "$git_profile" ]; then
  echo ""
  echo "Available git profiles:"
  for profile in git/profiles/*; do
    echo "  - $(basename "$profile")"
  done
  echo ""
  read "git_profile?Select git profile [personal]: "
  git_profile="${git_profile:-personal}"
fi

if [ ! -f "git/profiles/$git_profile" ]; then
  echo "Error: profile '$git_profile' not found in git/profiles/"
  exit 1
fi

cp "git/profiles/$git_profile" git/.gitconfig-profile
stow git -t "$HOME"/ --adopt

# Agent Skills — symlink the skills directory for Copilot CLI and Cursor IDE
# VS Code discovers skills via chat.agentSkillsLocations in vscode/settings.json
skills_src="$(cd agent-skills/skills && pwd)"
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
