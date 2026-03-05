#!/bin/zsh
# setup-macos.sh — macOS bootstrap using Homebrew.

set -e

profile="${1:-personal}"

if [ ! -f "stow/git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in stow/git/profiles/"
  exit 1
fi

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles YES

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
  echo "Homebrew not found, installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update
brew bundle --verbose --file="meta/homebrew/Brewfile.$profile"

source "$DOTFILES_DIR/meta/scripts/setup-common.sh"
