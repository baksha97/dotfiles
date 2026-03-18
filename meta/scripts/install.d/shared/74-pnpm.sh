#!/bin/bash
# pnpm — fast, disk space efficient package manager
command -v pnpm &>/dev/null && return 0
[ -f "$HOME/.local/share/pnpm/pnpm" ] && return 0
echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | bash -
