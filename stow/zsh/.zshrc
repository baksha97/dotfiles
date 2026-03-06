# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -t 1 && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -t 1 && -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Source all configs from ~/.zshrc.d/
for conf in "$HOME/.zshrc.d/"*.zsh(N); do
  source "$conf"
done

# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# zoxide — must be at the very end of .zshrc
if [[ -t 1 ]] && command -v zoxide &>/dev/null; then
  eval "$(zoxide init --cmd cd zsh)"
fi
