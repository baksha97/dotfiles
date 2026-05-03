alias ls='ls --color'
alias vim='nvim'
alias c='clear'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gac='ga . && gc'
gacp() { git add . && git commit -m "$1" && git push; }
alias clauded="claude --dangerously-skip-permissions"
alias codexd="codex --dangerously-bypass-approvals-and-sandbox"
