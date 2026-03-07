#!/bin/bash
# opencode — AI coding agent CLI
command -v opencode &>/dev/null && return 0
[ -f "$HOME/.opencode/bin/opencode" ] && return 0
echo "Installing opencode..."
curl -fsSL https://opencode.ai/install | bash
