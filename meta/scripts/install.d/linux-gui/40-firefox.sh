#!/bin/bash
# Firefox — web browser
command -v firefox &>/dev/null && return 0
echo "  Installing Firefox..."
$SUDO apt-get install -y firefox
