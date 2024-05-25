#!/bin/bash

# MacOS System
# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles YES

# Setup GH token here
# https://github.com/settings/tokens/new?scopes=gist,public_repo&description=Homebrew
# and then set the token as: export HOMEBREW_GITHUB_API_TOKEN="your_new_token"

# Check if Homebrew is installed, install if not
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Create Brewfile if not exists
BREWFILE_PATH="$HOME/Brewfile"
if [ ! -f "$BREWFILE_PATH" ]; then
  echo "Creating Brewfile..."
  touch "$BREWFILE_PATH"
fi

# Install all packages from Brewfile
brew bundle --file="Brewfile"

# Install Oh My Zsh if not installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Powerlevel10k theme if not installed
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH/custom/themes/powerlevel10k
fi

# Install Zsh plugins if not installed
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

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
