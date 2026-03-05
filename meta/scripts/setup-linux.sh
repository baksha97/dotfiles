#!/bin/zsh
# setup-linux.sh — Linux bootstrap using apt and official install scripts.

set -e

profile="${1:-personal}"

if [ ! -f "stow/git/profiles/$profile" ]; then
  echo "Error: profile '$profile' not found in stow/git/profiles/"
  exit 1
fi

# When running as root (e.g. LXC), sudo is a no-op prefix
if [ "$EUID" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# Architecture for binary downloads
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_GO="amd64"; ARCH_MUSL="x86_64" ;;
  aarch64) ARCH_GO="arm64"; ARCH_MUSL="aarch64" ;;
  *)        echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Show hidden files in GNOME Files if available
command -v gsettings &>/dev/null && gsettings set org.gnome.nautilus.preferences show-hidden-files true || true

# ── apt packages ────────────────────────────────────────────────────────────
$SUDO apt-get update -qq
$SUDO apt-get install -y $(grep -v '^\s*#' meta/packages/linux.packages | grep -v '^\s*$' | xargs)

# ── gh CLI ──────────────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  echo "Installing gh CLI..."
  $SUDO mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  $SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  $SUDO apt-get update -qq
  $SUDO apt-get install -y gh
fi

# ── lazygit ─────────────────────────────────────────────────────────────────
if ! command -v lazygit &>/dev/null; then
  echo "Installing lazygit..."
  LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep -o '"tag_name": "v[^"]*"' | grep -o 'v[^"]*' | sed 's/v//')
  curl -fsSLo /tmp/lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_Linux_${ARCH_MUSL}.tar.gz"
  tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
  $SUDO install /tmp/lazygit /usr/local/bin/lazygit
  rm /tmp/lazygit /tmp/lazygit.tar.gz
fi

# ── zoxide ──────────────────────────────────────────────────────────────────
if ! command -v zoxide &>/dev/null; then
  echo "Installing zoxide..."
  curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# ── yq ──────────────────────────────────────────────────────────────────────
if ! command -v yq &>/dev/null; then
  echo "Installing yq..."
  YQ_VERSION=$(curl -s "https://api.github.com/repos/mikefarah/yq/releases/latest" \
    | grep -o '"tag_name": "[^"]*"' | grep -o '"v[^"]*"' | tr -d '"')
  $SUDO curl -fsSLo /usr/local/bin/yq \
    "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH_GO}"
  $SUDO chmod +x /usr/local/bin/yq
fi

# ── just ────────────────────────────────────────────────────────────────────
if ! command -v just &>/dev/null; then
  echo "Installing just..."
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
    | $SUDO bash -s -- --to /usr/local/bin
fi

# ── uv ──────────────────────────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ── typos ───────────────────────────────────────────────────────────────────
if ! command -v typos &>/dev/null; then
  echo "Installing typos..."
  TYPOS_VERSION=$(curl -s "https://api.github.com/repos/crate-ci/typos/releases/latest" \
    | grep -o '"tag_name": "[^"]*"' | grep -o '"v[^"]*"' | tr -d '"')
  curl -fsSLo /tmp/typos.tar.gz \
    "https://github.com/crate-ci/typos/releases/download/${TYPOS_VERSION}/typos-${TYPOS_VERSION}-${ARCH_MUSL}-unknown-linux-musl.tar.gz"
  tar -xf /tmp/typos.tar.gz -C /tmp ./typos
  $SUDO install /tmp/typos /usr/local/bin/typos
  rm /tmp/typos /tmp/typos.tar.gz
fi

# ── Docker ──────────────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
fi

# ── Tailscale ───────────────────────────────────────────────────────────────
if ! command -v tailscale &>/dev/null; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# ── Nerd Fonts ──────────────────────────────────────────────────────────────
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
if [[ "$fonts_changed" == true ]]; then
  fc-cache -f "$font_dir"
  echo "  Font cache updated"
fi

source "$DOTFILES_DIR/meta/scripts/setup-common.sh"
