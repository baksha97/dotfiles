#!/bin/zsh

set -e

profile="${1:-personal}"

brew bundle dump --file="meta/homebrew/Brewfile.$profile" --force
echo "  meta/homebrew/Brewfile.$profile updated"
