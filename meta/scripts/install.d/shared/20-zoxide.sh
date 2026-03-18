#!/bin/bash
# zoxide — smarter cd command
command -v zoxide &>/dev/null && return 0
[ -f "$HOME/.local/bin/zoxide" ] && return 0
echo "Installing zoxide..."
curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
