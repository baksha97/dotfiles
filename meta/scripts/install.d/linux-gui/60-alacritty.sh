#!/bin/bash
# Alacritty — GPU-accelerated terminal emulator
if ! grep -q aslatter /etc/apt/sources.list.d/*.list 2>/dev/null; then
  $SUDO add-apt-repository -y ppa:aslatter/ppa
  $SUDO apt-get update -qq
fi
apt_package_current alacritty && return 0
echo "  Installing/updating Alacritty..."
$SUDO apt-get install -y alacritty
