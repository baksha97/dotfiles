#!/bin/bash
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
mapfile -t pkgs < <(grep -v '^\s*#' meta/packages/linux.packages | grep -v '^\s*$')
$SUDO apt-get install -y "${pkgs[@]}"

# ── Change default shell to zsh ──────────────────────────────────────────────
if [[ "$SHELL" != *"/zsh" ]]; then
  echo "Changing default shell to zsh..."
  $SUDO chsh -s "$(which zsh)" "$USER"
fi

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
  [[ -n "$LG_VERSION" ]] || { echo "Error: could not determine lazygit version" >&2; exit 1; }
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

# ── fzf ─────────────────────────────────────────────────────────────────────
if ! command -v fzf &>/dev/null || fzf --version | grep -q "(debian)"; then
  echo "Installing latest fzf..."
  FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" \
    | grep -o '"tag_name": "[^"]*"' | head -1 | tr -d '"' | sed 's/v//')
  [[ -n "$FZF_VERSION" ]] || { echo "Error: could not determine fzf version" >&2; exit 1; }
  curl -fsSLo /tmp/fzf.tar.gz \
    "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${ARCH_GO}.tar.gz"
  tar -xf /tmp/fzf.tar.gz -C /tmp fzf
  $SUDO install /tmp/fzf /usr/local/bin/fzf
  rm /tmp/fzf /tmp/fzf.tar.gz
fi

# ── yq ──────────────────────────────────────────────────────────────────────
if ! command -v yq &>/dev/null; then
  echo "Installing yq..."
  YQ_VERSION=$(curl -s "https://api.github.com/repos/mikefarah/yq/releases/latest" \
    | grep -o '"tag_name": "[^"]*"' | grep -o '"v[^"]*"' | tr -d '"')
  [[ -n "$YQ_VERSION" ]] || { echo "Error: could not determine yq version" >&2; exit 1; }
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
  curl -LsSf https://astral.sh/uv/install.sh | bash
fi

# ── Docker ──────────────────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | bash
fi

# ── Docker Compose plugin ────────────────────────────────────────────────────
if ! docker compose version &>/dev/null 2>&1; then
  echo "Installing Docker Compose plugin..."
  DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
  mkdir -p "$DOCKER_CONFIG/cli-plugins"
  DC_VERSION=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" \
    | grep -o '"tag_name": "v[^"]*"' | grep -o 'v[^"]*')
  [[ -n "$DC_VERSION" ]] || { echo "Error: could not determine docker compose version" >&2; exit 1; }
  curl -fsSLo "$DOCKER_CONFIG/cli-plugins/docker-compose" \
    "https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-linux-$(uname -m)"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
fi

# ── Tailscale ───────────────────────────────────────────────────────────────
if ! command -v tailscale &>/dev/null; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | bash
fi

# ── Node.js (LTS) ────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "Installing Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO bash -
  $SUDO apt-get install -y nodejs
fi

# ── vercel ───────────────────────────────────────────────────────────────────
if ! command -v vercel &>/dev/null; then
  echo "Installing vercel..."
  $SUDO npm install -g vercel
fi

# ── gemini cli ───────────────────────────────────────────────────────────────
if ! command -v gemini &>/dev/null; then
  echo "Installing gemini cli..."
  $SUDO npm install -g @google/gemini-cli
fi

# ── opencode ─────────────────────────────────────────────────────────────────
if ! command -v opencode &>/dev/null; then
  echo "Installing opencode..."
  curl -fsSL https://opencode.ai/install | bash
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

# ── Headful (GUI desktop) apps ───────────────────────────────────────────────
if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" || -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
  echo "Headful environment detected — installing GUI apps..."

  # VS Code
  if ! command -v code &>/dev/null; then
    echo "  Installing VS Code..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor | $SUDO tee /etc/apt/keyrings/microsoft.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      | $SUDO tee /etc/apt/sources.list.d/vscode.list > /dev/null
    $SUDO apt-get update -qq
    $SUDO apt-get install -y code
  fi

  # VS Code Insiders
  if ! command -v code-insiders &>/dev/null; then
    echo "  Installing VS Code Insiders..."
    # Key already added above if VS Code was just installed; ensure it exists
    if [[ ! -f /etc/apt/keyrings/microsoft.gpg ]]; then
      curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor | $SUDO tee /etc/apt/keyrings/microsoft.gpg > /dev/null
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | $SUDO tee /etc/apt/sources.list.d/vscode.list > /dev/null
      $SUDO apt-get update -qq
    fi
    $SUDO apt-get install -y code-insiders
  fi

  # Google Chrome (amd64 only)
  if [[ "$ARCH_GO" == "amd64" ]] && ! command -v google-chrome-stable &>/dev/null; then
    echo "  Installing Google Chrome..."
    curl -fsSLo /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    $SUDO apt-get install -y /tmp/google-chrome.deb
    rm /tmp/google-chrome.deb
  fi

  # Firefox
  if ! command -v firefox &>/dev/null; then
    echo "  Installing Firefox..."
    $SUDO apt-get install -y firefox
  fi

  # VLC
  if ! command -v vlc &>/dev/null; then
    echo "  Installing VLC..."
    $SUDO apt-get install -y vlc
  fi

  # Alacritty
  if ! command -v alacritty &>/dev/null; then
    echo "  Installing Alacritty..."
    $SUDO add-apt-repository -y ppa:aslatter/ppa
    $SUDO apt-get update -qq
    $SUDO apt-get install -y alacritty
  fi

  # Android Studio
  if [[ ! -d /opt/android-studio ]]; then
    echo "  Installing Android Studio..."
    AS_URL=$(curl -s "https://jb.gg/ide/index.xml" \
      | grep -oP 'https://[^"]+android-studio[^"]+linux\.tar\.gz' | head -1)
    if [[ -n "$AS_URL" ]]; then
      curl -fsSLo /tmp/android-studio.tar.gz "$AS_URL"
      $SUDO tar -xf /tmp/android-studio.tar.gz -C /opt
      rm /tmp/android-studio.tar.gz
    else
      echo "  Warning: Could not determine Android Studio download URL, skipping."
    fi
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/setup-common.sh"

# ── SDKMAN packages ───────────────────────────────────────────────────────────
if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
  set +e
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  set -e
  command -v gradle  &>/dev/null || SDKMAN_AUTO_ANSWER=true sdk install gradle  < /dev/null || true
  command -v kotlinc &>/dev/null || SDKMAN_AUTO_ANSWER=true sdk install kotlin  < /dev/null || true
fi
