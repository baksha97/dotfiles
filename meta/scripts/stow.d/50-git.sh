#!/bin/bash
# git — version control config and profiles
stow_backup "$HOME/.gitconfig"
stow_backup "$HOME/.gitignore"
stow_backup "$HOME/.gitconfig-profile"
if ! cmp -s "$DOTFILES_DIR/stow/git/profiles/$profile" "$DOTFILES_DIR/stow/git/.gitconfig-profile"; then
  if [ "$SETUP_DRY_RUN" = true ]; then
    echo "Dry run: would set git profile to '$profile'"
  else
    cp "$DOTFILES_DIR/stow/git/profiles/$profile" "$DOTFILES_DIR/stow/git/.gitconfig-profile"
  fi
fi
stow_package git
if [ "$SETUP_DRY_RUN" = true ]; then
  echo "Dry run: git profile would be '$profile'"
else
  echo "  Git profile set to '$profile'"
fi
