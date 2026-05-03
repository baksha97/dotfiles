#!/bin/bash
# args.sh — shared setup argument parsing.

setup_args_usage() {
  cat <<EOF
Setup usage: ./main.sh setup [profile] [flags]

Flags:
  --adopt                   Let Stow adopt remaining unhandled conflicts
  --dry-run, -n             Print setup actions without mutating files
  --skip-platform-packages  Skip Homebrew/apt package installation
  --skip-brew, --no-brew    macOS alias for --skip-platform-packages
  --skip-installers         Skip install.d tool installers
  --skip-sdkman             Skip SDKMAN! install and SDK package installs
  --skip-stow               Skip stow.d package linking
EOF
}

setup_parse_args() {
  SETUP_PROFILE_ARG=""
  SETUP_STOW_ADOPT=false
  SETUP_DRY_RUN=false
  SETUP_SKIP_PLATFORM_PACKAGES=false
  SETUP_SKIP_BREW=false
  SETUP_SKIP_INSTALLERS=false
  SETUP_SKIP_SDKMAN=false
  SETUP_SKIP_STOW=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --adopt)
        SETUP_STOW_ADOPT=true
        ;;
      --dry-run|-n)
        SETUP_DRY_RUN=true
        ;;
      --skip-platform-packages)
        SETUP_SKIP_PLATFORM_PACKAGES=true
        ;;
      --skip-brew|--no-brew)
        SETUP_SKIP_BREW=true
        SETUP_SKIP_PLATFORM_PACKAGES=true
        ;;
      --skip-installers)
        SETUP_SKIP_INSTALLERS=true
        ;;
      --skip-sdkman)
        SETUP_SKIP_SDKMAN=true
        ;;
      --skip-stow)
        SETUP_SKIP_STOW=true
        ;;
      --help|-h)
        setup_args_usage
        exit 0
        ;;
      -*)
        echo "Error: unknown setup option '$1'"
        setup_args_usage
        exit 1
        ;;
      *)
        if [ -n "$SETUP_PROFILE_ARG" ]; then
          echo "Error: multiple profiles provided ('$SETUP_PROFILE_ARG' and '$1')"
          exit 1
        fi
        SETUP_PROFILE_ARG="$1"
        ;;
    esac
    shift
  done

  if [ "$SETUP_DRY_RUN" = true ]; then
    SETUP_SKIP_PLATFORM_PACKAGES=true
    SETUP_SKIP_INSTALLERS=true
    SETUP_SKIP_SDKMAN=true
  fi

  export SETUP_PROFILE_ARG
  export SETUP_STOW_ADOPT
  export SETUP_DRY_RUN
  export SETUP_SKIP_PLATFORM_PACKAGES
  export SETUP_SKIP_BREW
  export SETUP_SKIP_INSTALLERS
  export SETUP_SKIP_SDKMAN
  export SETUP_SKIP_STOW
}
