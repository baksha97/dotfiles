#!/bin/bash
# VS Code Insiders — pre-release channel of VS Code
# Microsoft GPG key is shared with VS Code (10-vscode.sh adds it if needed)
if [[ ! -f /etc/apt/keyrings/microsoft.gpg ]] || [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor | $SUDO tee /etc/apt/keyrings/microsoft.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | $SUDO tee /etc/apt/sources.list.d/vscode.list > /dev/null
  $SUDO apt-get update -qq
fi
apt_package_current code-insiders && return 0
echo "  Installing/updating VS Code Insiders..."
$SUDO apt-get install -y code-insiders
