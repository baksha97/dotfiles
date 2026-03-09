#!/bin/bash
# setup-linux.sh — Linux (Debian/Ubuntu) bootstrap.
# Adding a new CLI tool: create meta/scripts/install.d/linux/<NN>-toolname.sh
# Adding a shared tool (Linux + Alpine): create meta/scripts/install.d/shared/<NN>-toolname.sh
# Adding a GUI app: create meta/scripts/install.d/linux-gui/<NN>-appname.sh

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
LIB="$DOTFILES_DIR/meta/scripts/lib"
INSTALL_D="$DOTFILES_DIR/meta/scripts/install.d"

source "$LIB/profile.sh"

profile="$(resolve_profile "${1:-}")"
if [ ! -f "$DOTFILES_DIR/stow/git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in stow/git/profiles/"
  exit 1
fi
echo "Using profile: $profile"

source "$LIB/sudo.sh"
source "$LIB/arch.sh"
source "$LIB/github.sh"

# Show hidden files in GNOME Files if available
command -v gsettings &>/dev/null && gsettings set org.gnome.nautilus.preferences show-hidden-files true || true

# ── apt packages ─────────────────────────────────────────────────────────────
$SUDO apt-get update -qq
mapfile -t pkgs < <(grep -v '^\s*#' "$DOTFILES_DIR/meta/packages/linux.packages" | grep -v '^\s*$')
$SUDO apt-get install -y "${pkgs[@]}"

# ── Change default shell to zsh ──────────────────────────────────────────────
if [[ "$SHELL" != *"/zsh" ]]; then
  echo "Changing default shell to zsh..."
  $SUDO chsh -s "$(which zsh)" "$USER"
fi

# ── CLI tool installers ───────────────────────────────────────────────────────
# Each file in install.d/shared/ and install.d/linux/ installs one tool.
shopt -s nullglob
for f in "$INSTALL_D/shared/"*.sh "$INSTALL_D/linux/"*.sh; do
  source "$f"
done

# ── GUI apps (headful environments only) ─────────────────────────────────────
if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" || -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
  echo "Headful environment detected — installing GUI apps..."
  for f in "$INSTALL_D/linux-gui/"*.sh; do
    source "$f"
  done
fi
shopt -u nullglob

# ── Dotfiles stow, git, and agent skills ─────────────────────────────────────
source "$DOTFILES_DIR/meta/scripts/setup-common.sh"

# ── SDKMAN packages ───────────────────────────────────────────────────────────
if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
  set +e
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  set -e
  command -v gradle  &>/dev/null || SDKMAN_AUTO_ANSWER=true sdk install gradle  < /dev/null || true
  command -v kotlinc &>/dev/null || SDKMAN_AUTO_ANSWER=true sdk install kotlin  < /dev/null || true
fi
