# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Initialize Homebrew
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

# Ensure plugins are correctly loaded
zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias c='clear'

# Usage: gct <branch-name>
# e.g.   gct travis/CATCH-123/sample
# If <branch-name> exists on origin, creates a worktree tracking that remote branch.
# Otherwise, creates a new branch from origin/main, pushes it, and cd's into the worktree.
# Safe to run from any worktree or the main repo checkout.
gct() {
  local branch="$1"

  local common_dir=$(git rev-parse --git-common-dir)
  [[ "$common_dir" = /* ]] || common_dir="$(git rev-parse --show-toplevel)/$common_dir"
  local repo_root=$(dirname "$common_dir")
  local repo_name=$(basename "$repo_root")

  local safe_branch="${branch//\//-}"
  local worktree_path="$(dirname "$repo_root")/${repo_name}-${safe_branch}"

  if git fetch origin "$branch" 2>/dev/null; then
    git worktree add --track -b "$branch" "$worktree_path" "origin/$branch" && \
    cd "$worktree_path"
  else
    git fetch origin main && \
    git worktree add --no-track -b "$branch" "$worktree_path" origin/main && \
    cd "$worktree_path" && \
    git push -u origin HEAD
  fi
}

# Usage: grmt [<worktree-path>]
# With no args, removes the worktree you're currently in.
# With a path arg, removes that worktree instead.
# Either way, cd's to the main repo root afterwards.
grmt() {
  local target="${1:-$(git rev-parse --show-toplevel)}"
  target="${target:A}"  # resolve to absolute/canonical path

  local common_dir=$(git -C "$target" rev-parse --git-common-dir)
  [[ "$common_dir" = /* ]] || common_dir="${target}/$common_dir"
  local repo_root=$(dirname "$common_dir")

  if [[ "${target:A}" = "${repo_root:A}" ]]; then
    echo "grmt: '$target' is the main repo checkout, not a worktree" >&2
    return 1
  fi

  cd "$repo_root" && git worktree remove "$target"
}

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
# bindkey '^I' autosuggest-accept  # Ensure this is after plugin loading

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "/opt/homebrew/anaconda3/bin" ]] && export PATH="/opt/homebrew/anaconda3/bin:$PATH"

[[ -d "$HOME/Library/Android/sdk" ]] && export ANDROID_HOME="$HOME/Library/Android/sdk"

unset JAVA_HOME

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
