#!/bin/bash
# gh — GitHub CLI
install_gh_from_release() {
  local version tmp arch url
  version="$(gh_latest_version cli cli)"
  if [[ -z "$version" || "$version" == "null" ]]; then
    echo "  Warning: could not determine latest gh version, skipping release fallback." >&2
    return 1
  fi

  arch="$ARCH_GO"
  tmp="$(mktemp --suffix=.deb)"
  url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${arch}.deb"

  echo "Installing/updating gh CLI from GitHub release..."
  if ! curl -fL --retry 3 --connect-timeout 15 -o "$tmp" "$url"; then
    rm -f "$tmp"
    return 1
  fi

  if ! $SUDO dpkg -i "$tmp"; then
    apt_install -f
  fi
  rm -f "$tmp"
}

gh_apt_ready=false
gh_key_tmp="$(mktemp)"
if curl -fsSL --retry 3 --connect-timeout 15 \
  -o "$gh_key_tmp" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && [[ -s "$gh_key_tmp" ]]; then
  $SUDO mkdir -p -m 755 /etc/apt/keyrings
  $SUDO install -m 0644 "$gh_key_tmp" /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  apt_update && gh_apt_ready=true
else
  echo "  Warning: could not download GitHub CLI apt keyring." >&2
fi
rm -f "$gh_key_tmp"

apt_package_current gh && return 0
echo "Installing/updating gh CLI..."
if [[ "$gh_apt_ready" == "true" ]] && apt_install gh; then
  return 0
fi

install_gh_from_release || {
  command -v gh &>/dev/null && {
    echo "  Warning: keeping existing gh because update failed." >&2
    return 0
  }
  return 1
}
