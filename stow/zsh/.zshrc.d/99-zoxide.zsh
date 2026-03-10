# zoxide — must run after compinit
# Only init zoxide if NOT on WSL
if command -v zoxide &>/dev/null; then
  if [[ ! "$(uname -r)" == *[mM]icrosoft* ]]; then
    eval "$(zoxide init --cmd cd zsh)"
  fi
fi
