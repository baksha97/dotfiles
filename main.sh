#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES_DIR
cd "$DOTFILES_DIR"

usage() {
  cat <<EOF
Usage: ./main.sh <command> [options]

Commands:
  setup [profile] [flags]  Bootstrap the system (auto-detects OS and profile on re-run)
  brew backup [profile]    Dump current Homebrew state to meta/homebrew/Brewfile.<profile>
  test                     Run local setup smoke checks
  alacritty-icon           Replace the Alacritty app icon

Profiles:
  Profiles control git identity (and Homebrew packages on macOS).
  Available profiles are defined in stow/git/profiles/.
  On macOS each profile has a matching meta/homebrew/Brewfile.<profile>.
  On re-runs the active profile is auto-detected; pass a name to switch.

Setup flags:
  --adopt                   Let Stow adopt remaining unhandled conflicts
  --dry-run, -n             Print setup actions without mutating files
  --skip-platform-packages  Skip Homebrew/apt package installation
  --skip-brew, --no-brew    macOS alias for --skip-platform-packages
  --skip-installers         Skip install.d tool installers
  --skip-sdkman             Skip SDKMAN! install and SDK package installs
  --skip-stow               Skip stow.d package linking

Examples:
  ./main.sh setup                    # normal rerun using existing stow links
  ./main.sh setup --adopt            # first setup or explicit conflict adoption
  ./main.sh setup work --skip-brew   # work profile without Homebrew install/update/bundle
  ./main.sh setup --dry-run          # dry-run stow/setup planning
  ./main.sh test                     # run setup smoke checks
  ./main.sh brew backup              # dump Homebrew state to meta/homebrew/Brewfile.personal
  ./main.sh brew backup work         # dump Homebrew state to meta/homebrew/Brewfile.work
  ./main.sh alacritty-icon           # replace Alacritty icon
EOF
}

command="${1:-}"
shift 2>/dev/null || true

case "$command" in
  setup)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      source "$DOTFILES_DIR/meta/scripts/setup-macos.sh" "$@"
    elif command -v apt-get &>/dev/null; then
      source "$DOTFILES_DIR/meta/scripts/setup-linux.sh" "$@"
    else
      echo "Unsupported OS: $OSTYPE"; exit 1
    fi
    ;;
  brew)
    subcommand="${1:-}"
    shift 2>/dev/null || true
    case "$subcommand" in
      backup) source "$DOTFILES_DIR/meta/scripts/backup.sh" "$@" ;;
      *)      echo "Unknown brew subcommand: $subcommand"; usage; exit 1 ;;
    esac
    ;;
  test)           source "$DOTFILES_DIR/meta/scripts/test-setup.sh" "$@" ;;
  alacritty-icon) source "$DOTFILES_DIR/meta/scripts/alacritty-icon.sh" "$@" ;;
  *)              usage; exit 1 ;;
esac
