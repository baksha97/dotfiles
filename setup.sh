# MacOS System
# Remove Message of the day prompt
touch $HOME/.hushlogin
# Show hidden files in finder
defaults write com.apple.finder AppleShowAllFiles YES

# setup GH token here
# https://github.com/settings/tokens/new?scopes=gist,public_repo&description=Homebrew
#and then set the token as: export HOMEBREW_GITHUB_API_TOKEN="your_new_token"

# Install all homebrew packages
# TODO: use a brewfile https://github.com/ahmedelgabri/dotfiles/blob/master/homebrew/Brewfile
while IFS='' read -r line || [[ -n "$line" ]]; do
    brew install "$line"
done < "./brew.txt"

# SSH config
stow ssh -t $HOME/

stow bash -t $HOME
rm $HOME/.zshrc
stow zsh -t $HOME

stow vscode -t $HOME
ln -s "$HOME/dotfiles/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

# git
stow git -t $HOME/
git config --global core.excludesfile $HOME/.gitignore
