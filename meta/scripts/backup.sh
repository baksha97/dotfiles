#!/bin/bash

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$DOTFILES_DIR"

profile="${1:-personal}"
core_file="meta/homebrew/Brewfile.core"
profile_file="meta/homebrew/Brewfile.$profile"
vscode_file="meta/homebrew/vscode.$profile"
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

if [ ! -f "$DOTFILES_DIR/stow/git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in stow/git/profiles/" >&2
  return 1 2>/dev/null || exit 1
fi

brew bundle dump --file="$tmp_file" --force --no-vscode
grep -Fvx -f "$core_file" "$tmp_file" > "$profile_file" || true
echo "  $profile_file updated"

if command -v code &>/dev/null; then
  code --list-extensions | sort > "$vscode_file"
  echo "  $vscode_file updated"
else
  echo "  Skipped $vscode_file (code not found)"
fi
