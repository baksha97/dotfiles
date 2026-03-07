#!/bin/bash
# gemini — Google Gemini CLI
command -v gemini &>/dev/null && return 0
echo "Installing gemini cli..."
$SUDO npm install -g @google/gemini-cli
