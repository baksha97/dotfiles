#!/bin/bash
# agent-browser — browser automation CLI for AI agents
command -v agent-browser &>/dev/null && return 0
echo "Installing agent-browser..."
npm install -g agent-browser
agent-browser install
mkdir -p "$HOME/.agent-browser"
cat > "$HOME/.agent-browser/config.json" <<'EOF'
{ "args": ["--no-sandbox"] }
EOF
