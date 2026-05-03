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
source "$LIB/npm.sh"

load_homebrew_shellenv() {
  local brew_bin=""
  local shellenv_output=""

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    brew_bin="/usr/local/bin/brew"
  fi

  if [ -n "$brew_bin" ] && shellenv_output="$("$brew_bin" shellenv 2>/dev/null)"; then
    eval "$shellenv_output"
  fi
}

# Make already-installed Homebrew tools available without installing anything.
load_homebrew_shellenv

# Show hidden files in Finder
if [ "$SETUP_DRY_RUN" = true ]; then
  echo "Dry run: would show hidden files in Finder"
else
  defaults write com.apple.finder AppleShowAllFiles YES
fi

if [ "$SETUP_SKIP_PLATFORM_PACKAGES" = true ]; then
  echo "Skipping Homebrew install/update/bundle"
else
  # Install Homebrew if missing
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found, installing..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Eval shellenv for current session — required on Apple Silicon where Homebrew
  # lands in /opt/homebrew (not on PATH by default until shell profile is sourced)
  load_homebrew_shellenv

  brew update
  brew bundle --verbose --file="$DOTFILES_DIR/meta/homebrew/Brewfile.$profile"
fi

if [ "$SETUP_SKIP_INSTALLERS" = true ]; then
  echo "Skipping shared installers"
else
  # Install tools that use native installers.
  # Each file in install.d/shared/ installs one tool (works on all platforms).
  shopt -s nullglob
  for f in "$INSTALL_D/shared/"*.sh; do
    source "$f"
  done
  shopt -u nullglob
fi

source "$DOTFILES_DIR/meta/scripts/setup-common.sh"
