# Source all configs from ~/.zshrc.d/
for conf in "$HOME/.zshrc.d/"*.zsh(N); do
  source "$conf"
done

# bun completions
[ -s "/home/proxmox/.bun/_bun" ] && source "/home/proxmox/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
