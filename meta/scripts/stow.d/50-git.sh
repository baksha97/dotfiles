#!/bin/bash
# git — version control config and profiles
stow_backup "$HOME/.gitconfig"
stow_backup "$HOME/.gitignore"
stow_backup "$HOME/.gitconfig-profile"
if ! cmp -s "$DOTFILES_DIR/stow/git/profiles/$profile" "$DOTFILES_DIR/stow/git/.gitconfig-profile"; then
  cp "$DOTFILES_DIR/stow/git/profiles/$profile" "$DOTFILES_DIR/stow/git/.gitconfig-profile"
fi
stow_package git
echo "  Git profile set to '$profile'"
