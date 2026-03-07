#!/bin/bash
# setup-alpine.sh — Alpine Linux bootstrap (iSH, Alpine on Termux, minimal containers).
# Adding a new shared tool (Linux + Alpine): create meta/scripts/install.d/shared/<NN>-toolname.sh

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
LIB="$DOTFILES_DIR/meta/scripts/lib"
INSTALL_D="$DOTFILES_DIR/meta/scripts/install.d"

profile="${1:-personal}"
if [ ! -f "stow/git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in stow/git/profiles/"
  exit 1
fi

source "$LIB/sudo.sh"
source "$LIB/arch.sh"
source "$LIB/github.sh"

# ── Ensure Alpine community repo is enabled ───────────────────────────────────
ALPINE_VERSION=$(. /etc/os-release 2>/dev/null && echo "$VERSION_ID" | grep -oE '^\d+\.\d+' || echo "edge")
COMMUNITY_REPO="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community"
[[ "$ALPINE_VERSION" == "edge" ]] && COMMUNITY_REPO="https://dl-cdn.alpinelinux.org/alpine/edge/community"
if ! grep -qF "$COMMUNITY_REPO" /etc/apk/repositories 2>/dev/null; then
  echo "Adding Alpine community repository..."
  echo "$COMMUNITY_REPO" | $SUDO tee -a /etc/apk/repositories > /dev/null
fi

# ── apk packages ─────────────────────────────────────────────────────────────
$SUDO apk update
mapfile -t pkgs < <(grep -v '^\s*#' "$DOTFILES_DIR/meta/packages/alpine.packages" | grep -v '^\s*$')
$SUDO apk add --no-cache "${pkgs[@]}"
# ansible is in Alpine's community repo — skip silently if unavailable
$SUDO apk add --no-cache ansible 2>/dev/null || echo "  Skipped ansible (not available)"

# ── Change default shell to zsh ──────────────────────────────────────────────
if [[ "$SHELL" != *"/zsh" ]]; then
  echo "Changing default shell to zsh..."
  $SUDO chsh -s "$(which zsh)" "$USER"
fi

echo "  Skipped scrcpy (not applicable on phone)"

# ── Shared CLI tool installers ────────────────────────────────────────────────
# Each file in install.d/shared/ installs one tool (works on both Linux and Alpine).
shopt -s nullglob
for f in "$INSTALL_D/shared/"*.sh; do
  source "$f"
done
shopt -u nullglob

# ── Dotfiles stow, git, and agent skills ─────────────────────────────────────
source "$DOTFILES_DIR/meta/scripts/setup-common.sh"
