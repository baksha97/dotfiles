#!/bin/bash
# just — command runner (make alternative)
command -v just &>/dev/null && return 0
echo "Installing just..."
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
  | $SUDO bash -s -- --to /usr/local/bin
