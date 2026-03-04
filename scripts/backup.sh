#!/bin/zsh

set -e

profile="${1:-personal}"

brew bundle dump --file="homebrew/Brewfile.$profile" --force
echo "  homebrew/Brewfile.$profile updated"
