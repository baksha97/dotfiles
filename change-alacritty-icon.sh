#!/bin/bash

set -eo pipefail

icon_path=/Applications/Alacritty.app/Contents/Resources/alacritty.icns
if [ ! -f "$icon_path" ]; then
  echo "Can't find existing icon, make sure Alacritty is installed"
  exit 1
fi

expected_hash="68de1ddce6"
icon_url=https://github.com/hmarr/dotfiles/files/8549877/alacritty.icns.gz

current_hash="$(shasum "$icon_path" | head -c 10)"
if [ "$current_hash" = "$expected_hash" ]; then
  echo "Icon already replaced, nothing to do"
  exit 0
fi

if [ ! -f "$icon_path.backup" ]; then
  echo "Backing up existing icon"
  cp "$icon_path" "$icon_path.backup"
fi

echo "Downloading replacement icon"
curl -sL "$icon_url" | gunzip > "$icon_path"

touch /Applications/Alacritty.app
killall Finder
killall Dock