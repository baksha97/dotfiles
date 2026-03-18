# fzf
if fzf --help 2>&1 | grep -q -- "--zsh"; then
  eval "$(fzf --zsh)"
fi

# direnv
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"