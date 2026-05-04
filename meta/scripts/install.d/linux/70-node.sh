#!/bin/bash
# node — Node.js LTS via NodeSource
command -v node &>/dev/null && return 0
echo "Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO bash -
apt_install nodejs
