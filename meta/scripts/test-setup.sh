#!/bin/bash
# test-setup.sh — local smoke checks for setup scripts.

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

echo "Checking shell syntax..."
bash -n "$DOTFILES_DIR/main.sh"
while IFS= read -r script; do
  bash -n "$script"
done < <(find "$DOTFILES_DIR/meta/scripts" -type f -name '*.sh' | sort)

if command -v shellcheck &>/dev/null; then
  echo "Running shellcheck..."
  shellcheck "$DOTFILES_DIR/main.sh"
  while IFS= read -r script; do
    shellcheck "$script"
  done < <(find "$DOTFILES_DIR/meta/scripts" -type f -name '*.sh' | sort)
else
  echo "Skipping shellcheck (not installed)"
fi

if command -v stow &>/dev/null; then
  echo "Running setup-common dry-run against a temporary HOME..."
  tmp_home="$(mktemp -d)"
  trap 'rm -rf "$tmp_home"' EXIT

  (
    export HOME="$tmp_home"
    export DOTFILES_DIR
    export profile="personal"
    export SETUP_STOW_ADOPT=false
    export SETUP_DRY_RUN=true
    export SETUP_SKIP_SDKMAN=true
    export SETUP_SKIP_STOW=false

    source "$DOTFILES_DIR/meta/scripts/setup-common.sh"
  )
else
  echo "Skipping stow dry-run (stow not installed)"
fi

echo "Setup smoke checks passed."
