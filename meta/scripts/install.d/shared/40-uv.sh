#!/bin/bash
# uv — fast Python package manager
command -v uv &>/dev/null && return 0
echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | bash
