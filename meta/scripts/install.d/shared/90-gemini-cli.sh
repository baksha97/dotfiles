#!/bin/bash
# gemini — Google Gemini CLI
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" && nvm use default >/dev/null
command -v npm &>/dev/null || { echo "  Skipped gemini-cli (npm not found)"; return 0; }
current_version="$(npm list -g @google/gemini-cli --depth=0 --json 2>/dev/null | jq -r '.dependencies["@google/gemini-cli"].version // empty')"
latest_version="$(npm view @google/gemini-cli version 2>/dev/null || true)"
[[ -n "$current_version" && -n "$latest_version" ]] && version_eq "$current_version" "$latest_version" && return 0
echo "Installing/updating gemini cli..."
# Avoid unnecessary sudo when npm global prefix is user-writable (e.g. Homebrew node)
NPM_PREFIX="$(npm prefix -g 2>/dev/null)"
if [[ -w "$NPM_PREFIX" ]]; then
  npm install -g @google/gemini-cli
else
  $SUDO npm install -g @google/gemini-cli
fi
