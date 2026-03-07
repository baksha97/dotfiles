#!/bin/bash
# VS Code — Microsoft's code editor
command -v code &>/dev/null && return 0
echo "  Installing VS Code..."
if [[ ! -f /etc/apt/keyrings/microsoft.gpg ]] || [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor | $SUDO tee /etc/apt/keyrings/microsoft.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | $SUDO tee /etc/apt/sources.list.d/vscode.list > /dev/null
  $SUDO apt-get update -qq
fi
$SUDO apt-get install -y code
