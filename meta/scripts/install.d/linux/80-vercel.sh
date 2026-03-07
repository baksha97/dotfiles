#!/bin/bash
# vercel — Vercel deployment CLI
command -v vercel &>/dev/null && return 0
echo "Installing vercel..."
$SUDO npm install -g vercel
