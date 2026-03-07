#!/bin/bash
# git — version control config and profiles
stow_backup "$HOME/.gitconfig"
stow_backup "$HOME/.gitignore"
stow_backup "$HOME/.gitconfig-profile"
stow_backup "$HOME/profiles"
cp "stow/git/profiles/$profile" stow/git/.gitconfig-profile
stow_package git
echo "  Git profile set to '$profile'"
