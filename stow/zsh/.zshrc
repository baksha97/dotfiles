# Source all configs from ~/.zshrc.d/
for conf in "$HOME/.zshrc.d/"*.zsh(N); do
  source "$conf"
done
