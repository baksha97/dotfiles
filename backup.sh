#!/bin/zsh

BREWFILE="Brewfile"
brew bundle dump --file=$BREWFILE --force
#sort $BREWFILE