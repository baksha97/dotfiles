#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

# Default flag values
DRY_RUN=false
WITH_GUI=false
WITH_FONTS=false

usage() {
  cat <<EOF
Usage: ./main.sh <command> [options]

Commands:
  setup [profile]          Bootstrap the system (auto-detects OS, default profile: personal)
  brew backup [profile]    Dump current Homebrew state to meta/homebrew/Brewfile.<profile>
  alacritty-icon           Replace the Alacritty app icon

Options:
  --dry-run                Show what would be done without making changes
  --with-gui               Install GUI applications (VS Code, Chrome, etc.)
  --with-fonts             Install all Nerd Fonts (can be slow)
  --verbose                Enable verbose output

Profiles:
  Profiles control git identity (and Homebrew packages on macOS).
  Available profiles are defined in stow/git/profiles/.
  On macOS each profile has a matching meta/homebrew/Brewfile.<profile>.

Examples:
  ./main.sh setup              # full setup with "personal" profile
  ./main.sh setup work         # full setup with "work" profile
  ./main.sh setup --with-gui   # setup with GUI apps
  ./main.sh brew backup        # dump Homebrew state to meta/homebrew/Brewfile.personal
EOF
}

command="${1:-}"
[[ -n "$command" ]] && shift

# Parse flags
profile="personal"
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --with-gui)
      WITH_GUI=true
      shift
      ;;
    --with-fonts)
      WITH_FONTS=true
      shift
      ;;
    --verbose)
      set -x
      shift
      ;;
    -*)
      echo "Unknown option $1"
      usage
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"
profile="${1:-personal}"

# Export flags for sub-scripts
export DRY_RUN WITH_GUI WITH_FONTS DOTFILES_DIR

case "$command" in
  setup)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      source "$DOTFILES_DIR/meta/scripts/setup-macos.sh" "$profile"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      source "$DOTFILES_DIR/meta/scripts/setup-linux.sh" "$profile"
    else
      echo "Unsupported OS: $OSTYPE"; exit 1
    fi
    ;;
  brew)
    subcommand="${1:-}"
    [[ -n "$subcommand" ]] && shift
    case "$subcommand" in
      backup) source "$DOTFILES_DIR/meta/scripts/backup.sh" "$@" ;;
      *)      echo "Unknown brew subcommand: $subcommand"; usage; exit 1 ;;
    esac
    ;;
  alacritty-icon) source "$DOTFILES_DIR/meta/scripts/alacritty-icon.sh" "$@" ;;
  *)              usage; exit 1 ;;
esac
