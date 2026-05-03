#!/bin/bash
# setup-macos.sh — macOS bootstrap using Homebrew.

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
LIB="$DOTFILES_DIR/meta/scripts/lib"
INSTALL_D="$DOTFILES_DIR/meta/scripts/install.d"

source "$LIB/args.sh"
source "$LIB/profile.sh"

setup_parse_args "$@"

profile="$(resolve_profile "$SETUP_PROFILE_ARG")"
if [ ! -f "$DOTFILES_DIR/stow/git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in stow/git/profiles/"
  exit 1
fi
echo "Using profile: $profile"

source "$LIB/sudo.sh"
source "$LIB/arch.sh"
source "$LIB/github.sh"
source "$LIB/homebrew.sh"
source "$LIB/installers.sh"
source "$LIB/npm.sh"

# Make already-installed Homebrew tools available without installing anything.
homebrew_load_shellenv

# Show hidden files in Finder
if [ "$SETUP_DRY_RUN" = true ]; then
  echo "Dry run: would show hidden files in Finder"
else
  defaults write com.apple.finder AppleShowAllFiles YES
fi

if [ "$SETUP_SKIP_PLATFORM_PACKAGES" = true ]; then
  echo "Skipping Homebrew install/update/bundle"
else
  homebrew_install_if_missing

  if command -v brew &>/dev/null; then
    # Eval shellenv for current session — required on Apple Silicon where Homebrew
    # lands in /opt/homebrew (not on PATH by default until shell profile is sourced)
    homebrew_load_shellenv
    homebrew_run "Homebrew update" brew update
    homebrew_bundle_install "$DOTFILES_DIR/meta/homebrew/Brewfile.core" "Homebrew core bundle"
    homebrew_bundle_install "$DOTFILES_DIR/meta/homebrew/Brewfile.$profile" "Homebrew $profile bundle"
  else
    homebrew_record_failure "Homebrew unavailable"
    echo "  Warning: Homebrew unavailable; continuing without brew bundle."
  fi
fi

if [ "$SETUP_SKIP_INSTALLERS" = true ]; then
  echo "Skipping install.d installers"
else
  setup_source_installers "$INSTALL_D/shared" "$INSTALL_D/macos"
fi

source "$DOTFILES_DIR/meta/scripts/setup-common.sh"
homebrew_print_summary
