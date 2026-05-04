#!/bin/bash
# Google Chrome (amd64 only)
[[ "$ARCH_GO" == "amd64" ]] || return 0
command -v google-chrome-stable &>/dev/null && return 0
echo "  Installing Google Chrome..."
curl -fsSLo /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt_install /tmp/google-chrome.deb
rm /tmp/google-chrome.deb
