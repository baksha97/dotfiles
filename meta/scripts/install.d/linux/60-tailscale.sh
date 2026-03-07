#!/bin/bash
# tailscale — mesh VPN
command -v tailscale &>/dev/null && return 0
echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | bash
