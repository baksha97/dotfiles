# fzf
if fzf --help 2>&1 | grep -q -- "--zsh"; then
  eval "$(fzf --zsh)"
fi

# zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init --cmd cd zsh)"
fi
