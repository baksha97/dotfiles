#!/bin/bash
# Android Studio — Android IDE
[[ -d /opt/android-studio ]] && return 0
echo "  Installing Android Studio..."
AS_URL=$(curl -s "https://jb.gg/ide/index.xml" \
  | grep -oP 'https://[^"]+android-studio[^"]+linux\.tar\.gz' | head -1)
if [[ -z "$AS_URL" ]]; then
  echo "  Warning: Could not determine Android Studio download URL, skipping."
  return 0
fi
curl -fsSLo /tmp/android-studio.tar.gz "$AS_URL"
$SUDO tar -xf /tmp/android-studio.tar.gz -C /opt
rm /tmp/android-studio.tar.gz
