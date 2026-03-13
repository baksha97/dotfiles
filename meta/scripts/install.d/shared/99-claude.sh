#!/bin/bash
# claude — Claude Code CLI
command -v claude &>/dev/null && return 0
echo "Installing claude..."
curl -fsSL https://claude.ai/install.sh | bash
