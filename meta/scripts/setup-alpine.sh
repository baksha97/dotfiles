#!/bin/bash
# setup-alpine.sh — Alpine Linux bootstrap using apk.
# Intended for phone/tablet terminal environments (e.g. iSH, Alpine on Termux).

set -e

profile="${1:-personal}"

if [ ! -f "stow/git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in stow/git/profiles/"
  exit 1
fi

# When running as root, sudo is a no-op prefix
if [ "$EUID" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_GO="amd64"; ARCH_MUSL="x86_64" ;;
  aarch64) ARCH_GO="arm64"; ARCH_MUSL="aarch64" ;;
  armv7l)  ARCH_GO="arm"; ARCH_MUSL="armv7" ;;
  *)        echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ── Ensure Alpine community repo is enabled ───────────────────────────────────
ALPINE_VERSION=$(. /etc/os-release 2>/dev/null && echo "$VERSION_ID" | grep -oE '^\d+\.\d+' || echo "edge")
COMMUNITY_REPO="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community"
# Fall back to edge if version parsing failed
[[ "$ALPINE_VERSION" == "edge" ]] && COMMUNITY_REPO="https://dl-cdn.alpinelinux.org/alpine/edge/community"
if ! grep -qF "$COMMUNITY_REPO" /etc/apk/repositories 2>/dev/null; then
  echo "Adding Alpine community repository..."
  echo "$COMMUNITY_REPO" | $SUDO tee -a /etc/apk/repositories > /dev/null
fi

# ── apk packages ─────────────────────────────────────────────────────────────
$SUDO apk update
$SUDO apk add --no-cache \
  ca-certificates \
  curl \
  git \
  git-lfs \
  stow \
  zsh \
  tmux \
  fzf \
  jq \
  rclone \
  fontconfig \
  unzip \
  zip \
  aria2 \
  ffmpeg \
  perl-image-exiftool

# ansible is in Alpine's community repo — skip silently if unavailable
$SUDO apk add --no-cache ansible 2>/dev/null || echo "  Skipped ansible (not available)"

# ── Change default shell to zsh ──────────────────────────────────────────────
if [[ "$SHELL" != *"/zsh" ]]; then
  echo "Changing default shell to zsh..."
  $SUDO chsh -s "$(which zsh)" "$USER"
fi

# scrcpy is desktop-only — skip on phone
echo "  Skipped scrcpy (not applicable on phone)"

# ── lazygit ──────────────────────────────────────────────────────────────────
if ! command -v lazygit &>/dev/null; then
  echo "Installing lazygit..."
  LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep -o '"tag_name": "v[^"]*"' | grep -o 'v[^"]*' | sed 's/v//')
  if [[ -n "$LG_VERSION" ]]; then
    curl -fsSLo /tmp/lazygit.tar.gz \
      "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_Linux_${ARCH_MUSL}.tar.gz"
    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
    $SUDO install /tmp/lazygit /usr/local/bin/lazygit
    rm /tmp/lazygit /tmp/lazygit.tar.gz
  else
    echo "  Warning: could not determine lazygit version, skipping."
  fi
fi

# ── zoxide ────────────────────────────────────────────────────────────────────
if ! command -v zoxide &>/dev/null; then
  echo "Installing zoxide..."
  curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# ── yq ───────────────────────────────────────────────────────────────────────
if ! command -v yq &>/dev/null; then
  echo "Installing yq..."
  YQ_VERSION=$(curl -s "https://api.github.com/repos/mikefarah/yq/releases/latest" \
    | grep -o '"tag_name": "[^"]*"' | grep -o '"v[^"]*"' | tr -d '"')
  if [[ -n "$YQ_VERSION" ]]; then
    $SUDO curl -fsSLo /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH_GO}"
    $SUDO chmod +x /usr/local/bin/yq
  else
    echo "  Warning: could not determine yq version, skipping."
  fi
fi

# ── uv ───────────────────────────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ── Nerd Fonts ────────────────────────────────────────────────────────────────
nerd_fonts_version="v3.3.0"
nerd_fonts=(
  DroidSansMono
  FiraCode
  JetBrainsMono
  Meslo
  Mononoki
  RobotoMono
  SourceCodePro
  NerdFontsSymbolsOnly
)
font_dir="$HOME/.local/share/fonts"
mkdir -p "$font_dir"
echo "Installing Nerd Fonts..."
fonts_changed=false
for font in "${nerd_fonts[@]}"; do
  marker="$font_dir/.installed-${font}-${nerd_fonts_version}"
  if [[ -f "$marker" ]]; then
    echo "  Skipped $font (already installed)"
    continue
  fi
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${nerd_fonts_version}/${font}.tar.xz" \
    | tar -xJ -C "$font_dir"
  touch "$marker"
  echo "  Installed $font"
  fonts_changed=true
done
if [[ "$fonts_changed" == true ]] && command -v fc-cache &>/dev/null; then
  fc-cache -f "$font_dir"
  echo "  Font cache updated"
fi

source "$DOTFILES_DIR/meta/scripts/setup-common.sh"
