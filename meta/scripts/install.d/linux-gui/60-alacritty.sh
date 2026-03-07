#!/bin/bash
# Alacritty — GPU-accelerated terminal emulator
command -v alacritty &>/dev/null && return 0
echo "  Installing Alacritty..."
$SUDO add-apt-repository -y ppa:aslatter/ppa
$SUDO apt-get update -qq
$SUDO apt-get install -y alacritty
