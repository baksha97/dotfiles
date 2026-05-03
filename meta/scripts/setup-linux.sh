#!/bin/bash
# setup-linux.sh — Linux (Debian/Ubuntu) bootstrap.
# Adding a new CLI tool: create meta/scripts/install.d/linux/<NN>-toolname.sh
# Adding a shared tool: create meta/scripts/install.d/shared/<NN>-toolname.sh
# Adding a GUI app: create meta/scripts/install.d/linux-gui/<NN>-appname.sh

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

# Show hidden files in GNOME Files if available
if [ "$SETUP_DRY_RUN" = true ]; then
  echo "Dry run: would show hidden files in GNOME Files if available"
else
  command -v gsettings &>/dev/null && gsettings set org.gnome.nautilus.preferences show-hidden-files true || true
fi

# ── apt packages ─────────────────────────────────────────────────────────────
if [ "$SETUP_SKIP_PLATFORM_PACKAGES" = true ]; then
  echo "Skipping apt package installation"
else
  $SUDO apt-get update -qq
  mapfile -t pkgs < <(grep -v '^\s*#' "$DOTFILES_DIR/meta/packages/linux.packages" | grep -v '^\s*$')
  $SUDO apt-get install -y "${pkgs[@]}"
fi

# ── Change default shell to zsh ──────────────────────────────────────────────
if [ "$SETUP_DRY_RUN" = true ]; then
  echo "Dry run: would change default shell to zsh if needed"
elif [ "$SETUP_SKIP_PLATFORM_PACKAGES" = true ]; then
  echo "Skipping default shell change"
elif [[ "$SHELL" != *"/zsh" ]]; then
  echo "Changing default shell to zsh..."
  $SUDO chsh -s "$(which zsh)" "$USER"
fi

# ── CLI tool installers ───────────────────────────────────────────────────────
if [ "$SETUP_SKIP_INSTALLERS" = true ]; then
  echo "Skipping install.d installers"
else
  # Merge shared/ and linux/ scripts, sorted by filename so numbering controls
  # global install order (e.g. linux/70-node runs before shared/80-vercel).
  shopt -s nullglob
  readarray -t install_scripts < <(
    for f in "$INSTALL_D/shared/"*.sh "$INSTALL_D/linux/"*.sh; do
      echo "$(basename "$f") $f"
    done | sort | cut -d' ' -f2-
  )
  for f in "${install_scripts[@]}"; do
    source "$f"
  done

  # ── GUI apps (headful environments only) ───────────────────────────────────
  if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" || -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
    echo "Headful environment detected — installing GUI apps..."
    for f in "$INSTALL_D/linux-gui/"*.sh; do
      source "$f"
    done
  fi
  shopt -u nullglob
fi

# ── Dotfiles stow, git, and agent skills ─────────────────────────────────────
source "$DOTFILES_DIR/meta/scripts/setup-common.sh"

# ── SDKMAN packages ───────────────────────────────────────────────────────────
if [ "$SETUP_SKIP_SDKMAN" = true ]; then
  echo "Skipping SDKMAN packages"
elif [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
  set +e
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  set -e
  command -v gradle  &>/dev/null || SDKMAN_AUTO_ANSWER=true sdk install gradle  < /dev/null || true
  command -v kotlinc &>/dev/null || SDKMAN_AUTO_ANSWER=true sdk install kotlin  < /dev/null || true
fi
