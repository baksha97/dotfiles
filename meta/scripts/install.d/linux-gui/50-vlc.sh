#!/bin/bash
# VLC — media player
command -v vlc &>/dev/null && return 0
echo "  Installing VLC..."
$SUDO apt-get install -y vlc
