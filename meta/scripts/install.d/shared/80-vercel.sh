#!/bin/bash
# vercel — Vercel deployment CLI
command -v vercel &>/dev/null && return 0
command -v npm &>/dev/null || { echo "  Skipped vercel (npm not found)"; return 0; }
echo "Installing vercel..."
# Avoid unnecessary sudo when npm global prefix is user-writable (e.g. Homebrew node)
NPM_PREFIX="$(npm prefix -g 2>/dev/null)"
if [[ -w "$NPM_PREFIX" ]]; then
  npm install -g vercel
else
  $SUDO npm install -g vercel
fi
