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

# Add brew to the path for the brewfile installation 
echo >> $HOME/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install all packages from Brewfile
brew bundle --file="Brewfile"

# Install SDKMAN! if not installed
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Remove existing .zshrc and adopt new configurations
rm "$HOME"/.zshrc
stow zsh -t "$HOME" --adopt
stow powerlevel10k -t "$HOME" --adopt
stow tmux -t "$HOME" --adopt
stow vscode -t "$HOME" --adopt
stow alacritty -t "$HOME" --adopt

# Different path for VSCode settings on macOS and Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
  stow vscode -t "$HOME/Library/Application Support/Code/User" --adopt
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  stow vscode -t "$HOME/.config/Code/User" --adopt
fi

# Git configuration
stow git -t "$HOME"/ --adopt
git config --global core.excludesfile "$HOME"/.gitignore

# Source .zshrc
source ~/.zshrc

echo "Dotfiles installation complete!"
