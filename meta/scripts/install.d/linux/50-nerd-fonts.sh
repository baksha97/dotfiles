#!/bin/bash
# nerd-fonts — patched fonts with icons for terminal use (macOS uses brew casks)
nerd_fonts_version="v3.3.0"
nerd_fonts=(
  DroidSansMono
  FiraCode
  JetBrainsMono
  Meslo
  Mononoki
  RobotoMono
  SourceCodePro
  NerdFontsSymbolsOnly
)
font_dir="$HOME/.local/share/fonts"
mkdir -p "$font_dir"
echo "Installing Nerd Fonts..."
fonts_changed=false
for font in "${nerd_fonts[@]}"; do
  # Marker file tracks installed version per font (no binary to command -v)
  marker="$font_dir/.installed-${font}-${nerd_fonts_version}"
  if [[ -f "$marker" ]]; then
    echo "  Skipped $font (already installed)"
    continue
  fi
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${nerd_fonts_version}/${font}.tar.xz" \
    | tar -xJ -C "$font_dir"
  touch "$marker"
  echo "  Installed $font"
  fonts_changed=true
done
if [[ "$fonts_changed" == true ]] && command -v fc-cache &>/dev/null; then
  fc-cache -f "$font_dir"
  echo "  Font cache updated"
fi
