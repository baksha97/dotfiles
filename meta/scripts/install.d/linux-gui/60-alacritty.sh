#!/bin/bash
# Alacritty — GPU-accelerated terminal emulator
if ! grep -q aslatter /etc/apt/sources.list.d/*.list 2>/dev/null; then
  $SUDO add-apt-repository -y ppa:aslatter/ppa
  apt_update
fi
apt_package_current alacritty && return 0
echo "  Installing/updating Alacritty..."
apt_install alacritty
