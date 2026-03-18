#!/bin/bash
# agent-browser — Browser automation CLI for AI agents
command -v agent-browser &>/dev/null && return 0
command -v npm &>/dev/null || { echo "  Skipped agent-browser (npm not found)"; return 0; }
echo "Installing agent-browser..."
# Avoid unnecessary sudo when npm global prefix is user-writable (e.g. Homebrew node)
NPM_PREFIX="$(npm prefix -g 2>/dev/null)"
if [[ -w "$NPM_PREFIX" ]]; then
  npm install -g agent-browser
else
  $SUDO npm install -g agent-browser
fi
