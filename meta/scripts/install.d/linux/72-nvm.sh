#!/bin/bash
# nvm — Node Version Manager
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

NVM_VERSION="$(gh_latest_version nvm-sh nvm)"
current_nvm_version="$(nvm --version 2>/dev/null || true)"
if [[ -z "$current_nvm_version" || -z "$NVM_VERSION" ]] || ! version_eq "$current_nvm_version" "$NVM_VERSION"; then
  echo "Installing/updating nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
fi

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  echo "  Warning: nvm install completed but $NVM_DIR/nvm.sh was not found." >&2
  return 0
fi

latest_node_version="$(nvm version-remote node 2>/dev/null || true)"
if [[ -n "$latest_node_version" && "$(nvm version "$latest_node_version")" != "$latest_node_version" ]]; then
  echo "Installing latest Node.js via nvm..."
  nvm install node
fi
nvm alias default node
nvm use default
