#!/bin/bash
# zsh — shell configuration
stow_backup "$HOME/.zshrc"
stow_backup "$HOME/.zshrc.d"
stow_package zsh
