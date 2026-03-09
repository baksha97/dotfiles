#!/bin/bash
# profile.sh — resolve the active profile name.
#
# If an explicit argument is given, use it. Otherwise detect the current
# profile by comparing .gitconfig-profile against stow/git/profiles/*.
# Falls back to "personal" on a fresh machine with no prior setup.

resolve_profile() {
  local explicit="$1"
  local profiles_dir="$DOTFILES_DIR/stow/git/profiles"
  local current="$DOTFILES_DIR/stow/git/.gitconfig-profile"

  if [ -n "$explicit" ]; then
    echo "$explicit"
    return
  fi

  if [ -f "$current" ]; then
    for p in "$profiles_dir"/*; do
      if cmp -s "$current" "$p"; then
        echo "$(basename "$p")"
        return
      fi
    done
  fi

  echo "personal"
}
