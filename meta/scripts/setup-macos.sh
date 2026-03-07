#!/bin/zsh
# setup-macos.sh — macOS bootstrap using Homebrew.

set -e

profile="${1:-personal}"

if [ ! -f "$DOTFILES_DIR/stow/git/profiles/$profile" ]; then
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

# Eval shellenv for current session — required on Apple Silicon where Homebrew
# lands in /opt/homebrew (not on PATH by default until shell profile is sourced)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

brew update
brew bundle --verbose --file="$DOTFILES_DIR/meta/homebrew/Brewfile.$profile"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/setup-common.sh"
