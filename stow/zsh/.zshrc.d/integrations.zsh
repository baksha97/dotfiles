# fzf
if fzf --help 2>&1 | grep -q -- "--zsh"; then
  eval "$(fzf --zsh)"
fi
