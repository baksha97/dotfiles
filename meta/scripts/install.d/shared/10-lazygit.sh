#!/bin/bash
# lazygit — terminal UI for git
LG_VERSION="$(gh_latest_version jesseduffield lazygit)"
if [[ -z "$LG_VERSION" ]]; then
  echo "  Warning: could not determine lazygit version, skipping." >&2
  return 0
fi
if command -v lazygit &>/dev/null; then
  current_version="$(lazygit --version | grep -oE 'version=[^, ]+' | head -1 | cut -d= -f2)"
  version_eq "$current_version" "$LG_VERSION" && return 0
fi
echo "Installing/updating lazygit..."
# lazygit uses lowercase os and x86_64/arm64 naming
LG_OS="linux"
LG_ARCH="$ARCH_MUSL"
[[ "$(uname)" == "Darwin" ]] && LG_OS="darwin"
# lazygit uses arm64 (not aarch64) on Linux
[[ "$LG_ARCH" == "aarch64" ]] && LG_ARCH="arm64"
curl -fsSLo /tmp/lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_${LG_OS}_${LG_ARCH}.tar.gz"
tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
$SUDO install /tmp/lazygit /usr/local/bin/lazygit
rm /tmp/lazygit /tmp/lazygit.tar.gz
