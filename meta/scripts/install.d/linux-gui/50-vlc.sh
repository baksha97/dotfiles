#!/bin/bash
# VLC — media player
apt_package_current vlc && return 0
echo "  Installing/updating VLC..."
apt_install vlc
