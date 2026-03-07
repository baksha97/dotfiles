#!/bin/bash
# sudo.sh — detect whether sudo is needed (no-op when running as root).

if [ "$EUID" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi
export SUDO
