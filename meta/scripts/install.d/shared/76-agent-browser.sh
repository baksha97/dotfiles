#!/bin/bash
# agent-browser — Browser automation CLI for AI agents
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" && nvm use default >/dev/null
command -v npm &>/dev/null || { echo "  Skipped agent-browser (npm not found)"; return 0; }
current_version="$(npm list -g agent-browser --depth=0 --json 2>/dev/null | jq -r '.dependencies["agent-browser"].version // empty')"
latest_version="$(npm view agent-browser version 2>/dev/null || true)"
[[ -n "$current_version" && -n "$latest_version" ]] && version_eq "$current_version" "$latest_version" && return 0
echo "Installing/updating agent-browser..."
# Avoid unnecessary sudo when npm global prefix is user-writable (e.g. Homebrew node)
NPM_PREFIX="$(npm prefix -g 2>/dev/null)"
if [[ -w "$NPM_PREFIX" ]]; then
  npm install -g agent-browser
else
  $SUDO npm install -g agent-browser
fi
