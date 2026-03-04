#!/bin/bash

set -eo pipefail

icon_path=/Applications/Alacritty.app/Contents/Resources/alacritty.icns
if [ ! -f "$icon_path" ]; then
  echo "Can't find existing icon, make sure Alacritty is installed"
  exit 1
fi

icon_url=https://s3.macosicons.com/macosicons/icons/UcDQMJkqVL/icnsFile_e80a1d3cbed491f9c073079d794c0f78_UcDQMJkqVL.icns

tmp_icon="$(mktemp)"
echo "Downloading replacement icon"
curl -sL "$icon_url" -o "$tmp_icon"

current_hash="$(shasum "$icon_path" | head -c 40)"
new_hash="$(shasum "$tmp_icon" | head -c 40)"
if [ "$current_hash" = "$new_hash" ]; then
  echo "Icon already replaced, nothing to do"
  rm -f "$tmp_icon"
  exit 0
fi

if [ ! -f "$icon_path.backup" ]; then
  echo "Backing up existing icon"
  cp "$icon_path" "$icon_path.backup"
fi

mv "$tmp_icon" "$icon_path"

touch /Applications/Alacritty.app
killall Finder
killall Dock