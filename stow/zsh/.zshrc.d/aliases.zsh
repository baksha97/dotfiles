alias ls='ls --color'
alias vim='nvim'
alias c='clear'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gac='ga . && gc'
gacp() { ga . && gc -m "$1" && git push; }
