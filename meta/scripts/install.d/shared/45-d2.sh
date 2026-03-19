#!/bin/bash
# d2 — declarative diagramming language
command -v d2 &>/dev/null && return 0
[ -f "$HOME/.local/bin/d2" ] && return 0
echo "Installing d2..."
curl -fsSL https://d2lang.com/install.sh | sh -s --
