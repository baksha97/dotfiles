#!/bin/bash
# dmux — dmux settings, agents, and personas
STOW_TARGET="$HOME/.dmux"
setup_mkdir_p "$STOW_TARGET"
stow_package dmux --no-folding
