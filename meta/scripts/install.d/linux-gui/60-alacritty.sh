#!/bin/bash
# Alacritty — GPU-accelerated terminal emulator
command -v alacritty &>/dev/null && return 0
echo "  Installing Alacritty..."
if ! grep -q aslatter /etc/apt/sources.list.d/*.list 2>/dev/null; then
  $SUDO add-apt-repository -y ppa:aslatter/ppa
  $SUDO apt-get update -qq
fi
$SUDO apt-get install -y alacritty
