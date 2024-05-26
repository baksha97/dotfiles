#!bin/bash

sudo apt-get update

# Install colima dependencies and colima via GitHub
sudo apt-get install -y curl docker.io fzf stow tmux unbound zsh git
curl -sS https://webinstall.dev/zoxide | bash
curl -sS https://webinstall.dev/colima | bash

# Install Nerd Fonts
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
fonts=("DroidSansMono" "FiraCode" "JetBrainsMono" "Mononoki" "RobotoMono" "SauceCodePro" "SymbolsOnly")
for font in "${fonts[@]}"; do
  wget "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip"
  unzip -o "$font.zip" -d "$font"
  rm "$font.zip"
done
fc-cache -fv

# Install git-credential-manager
curl -LO https://github.com/GitCredentialManager/git-credential-manager/releases/latest/download/gcm-linux_amd64.deb
sudo dpkg -i gcm-linux_amd64.deb
rm gcm-linux_amd64.deb

apt install fzf
apt install zoxide
