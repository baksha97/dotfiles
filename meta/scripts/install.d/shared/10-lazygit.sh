#!/bin/bash
# lazygit — terminal UI for git
command -v lazygit &>/dev/null && return 0
echo "Installing lazygit..."
LG_VERSION="$(gh_latest_version jesseduffield lazygit)"
if [[ -z "$LG_VERSION" ]]; then
  echo "  Warning: could not determine lazygit version, skipping." >&2
  return 0
fi
# lazygit release naming: Linux uses "Linux" + ARCH_MUSL (x86_64/aarch64),
# macOS uses "darwin" + raw uname -m (x86_64/arm64)
LG_OS="Linux"
LG_ARCH="$ARCH_MUSL"
if [[ "$(uname)" == "Darwin" ]]; then
  LG_OS="darwin"
  LG_ARCH="$(uname -m)"
fi
curl -fsSLo /tmp/lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_${LG_OS}_${LG_ARCH}.tar.gz"
tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
$SUDO install /tmp/lazygit /usr/local/bin/lazygit
rm /tmp/lazygit /tmp/lazygit.tar.gz
