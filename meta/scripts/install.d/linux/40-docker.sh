#!/bin/bash
# docker — container runtime
command -v docker &>/dev/null && return 0
echo "Installing Docker..."
curl -fsSL https://get.docker.com | bash
