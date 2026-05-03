#!/bin/bash
# vercel — Vercel deployment CLI
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" && nvm use default >/dev/null
command -v npm &>/dev/null || { echo "  Skipped vercel (npm not found)"; return 0; }
current_version="$(npm list -g vercel --depth=0 --json 2>/dev/null | jq -r '.dependencies.vercel.version // empty')"
latest_version="$(npm view vercel version 2>/dev/null || true)"
[[ -n "$current_version" && -n "$latest_version" ]] && version_eq "$current_version" "$latest_version" && return 0
echo "Installing/updating vercel..."
# Avoid unnecessary sudo when npm global prefix is user-writable (e.g. Homebrew node)
NPM_PREFIX="$(npm prefix -g 2>/dev/null)"
if [[ -w "$NPM_PREFIX" ]]; then
  npm install -g vercel
else
  $SUDO npm install -g vercel
fi
