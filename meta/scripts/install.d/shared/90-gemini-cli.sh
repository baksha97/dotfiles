#!/bin/bash
# gemini — Google Gemini CLI
command -v gemini &>/dev/null && return 0
command -v npm &>/dev/null || { echo "  Skipped gemini-cli (npm not found)"; return 0; }
echo "Installing gemini cli..."
# Avoid unnecessary sudo when npm global prefix is user-writable (e.g. Homebrew node)
NPM_PREFIX="$(npm prefix -g 2>/dev/null)"
if [[ -w "$NPM_PREFIX" ]]; then
  npm install -g @google/gemini-cli
else
  $SUDO npm install -g @google/gemini-cli
fi
