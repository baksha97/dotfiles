#!/bin/zsh

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

usage() {
  cat <<EOF
Usage: ./main.sh <command> [options]

Commands:
  setup [profile]          Bootstrap the system (default profile: personal)
  brew backup [profile]    Dump current Homebrew state to meta/homebrew/Brewfile.<profile>
  alacritty-icon           Replace the Alacritty app icon

Profiles:
  Profiles control git identity and Homebrew packages.
  Available profiles are defined in stow/git/profiles/.
  Each profile has a matching meta/homebrew/Brewfile.<profile>.

Examples:
  ./main.sh setup              # full setup with "personal" profile
  ./main.sh setup work         # full setup with "work" profile
  ./main.sh brew backup        # dump Homebrew state to meta/homebrew/Brewfile.personal
  ./main.sh brew backup work   # dump Homebrew state to meta/homebrew/Brewfile.work
  ./main.sh alacritty-icon     # replace Alacritty icon
EOF
}

command="${1:-}"
shift 2>/dev/null || true

case "$command" in
  setup)          source "$DOTFILES_DIR/meta/scripts/setup.sh" "$@" ;;
  brew)
    subcommand="${1:-}"
    shift 2>/dev/null || true
    case "$subcommand" in
      backup) source "$DOTFILES_DIR/meta/scripts/backup.sh" "$@" ;;
      *)      echo "Unknown brew subcommand: $subcommand"; usage; exit 1 ;;
    esac
    ;;
  alacritty-icon) source "$DOTFILES_DIR/meta/scripts/alacritty-icon.sh" "$@" ;;
  *)              usage; exit 1 ;;
esac
