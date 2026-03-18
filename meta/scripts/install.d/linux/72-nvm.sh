#!/bin/bash
# nvm — Node Version Manager
# nvm is a shell function, not a binary — check for the install directory
[ -s "$HOME/.nvm/nvm.sh" ] && return 0
echo "Installing nvm..."
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
