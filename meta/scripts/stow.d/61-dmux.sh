#!/bin/bash
# dmux — dmux settings, agents, and personas
STOW_TARGET="$HOME/.dmux"
mkdir -p "$STOW_TARGET"
stow_package dmux --no-folding
