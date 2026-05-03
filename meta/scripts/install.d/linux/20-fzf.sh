#!/bin/bash
# fzf — fuzzy finder (install latest from GitHub; Debian's version is stale)
FZF_VERSION="$(gh_latest_version junegunn fzf)"
if [[ -z "$FZF_VERSION" ]]; then
  echo "  Warning: could not determine fzf version, skipping." >&2
  return 0
fi
if command -v fzf &>/dev/null; then
  current_version="$(fzf --version | awk '{print $1}')"
  version_eq "$current_version" "$FZF_VERSION" && return 0
fi
echo "Installing/updating latest fzf..."
curl -fsSLo /tmp/fzf.tar.gz \
  "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${ARCH_GO}.tar.gz"
tar -xf /tmp/fzf.tar.gz -C /tmp fzf
$SUDO install /tmp/fzf /usr/local/bin/fzf
rm /tmp/fzf /tmp/fzf.tar.gz
