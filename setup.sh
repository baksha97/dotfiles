#!/bin/zsh

# MacOS System
# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles YES

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
rm $HOME/.zshrc
stow zsh -t $HOME --adopt
stow powerlevel10k -t $HOME --adopt
stow vscode -t $HOME --adopt
ln -sf "$HOME/dotfiles/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

# Git configuration
stow git -t $HOME/ --adopt
git config --global core.excludesfile $HOME/.gitignore

# Source .zshrc
source ~/.zshrc

echo "Dotfiles installation complete!"
