#!/bin/bash
# codex — OpenAI Codex CLI
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" && nvm use default >/dev/null
command -v npm &>/dev/null || { echo "  Skipped codex (npm not found)"; return 0; }

current_version="$(npm list -g @openai/codex --depth=0 --json 2>/dev/null | jq -r '.dependencies["@openai/codex"].version // empty')"
latest_version="$(npm view @openai/codex version 2>/dev/null || true)"
[[ -n "$current_version" && -n "$latest_version" ]] && version_eq "$current_version" "$latest_version" && return 0

echo "Installing/updating codex cli..."
NPM_PREFIX="$(npm prefix -g 2>/dev/null)"
if [[ -w "$NPM_PREFIX" ]]; then
  npm install -g @openai/codex
else
  $SUDO npm install -g @openai/codex
fi
