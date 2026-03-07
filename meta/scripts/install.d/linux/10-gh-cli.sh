#!/bin/bash
# gh — GitHub CLI
command -v gh &>/dev/null && return 0
echo "Installing gh CLI..."
$SUDO mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
$SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
$SUDO apt-get update -qq
$SUDO apt-get install -y gh
