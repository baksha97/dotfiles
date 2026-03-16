# Initialize Homebrew
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

brewfile-sync() {
  local src="${funcsourcetrace[1]%:*}"
  local dotfiles_dir="${src:A:h:h:h:h}"
  local profile="personal"
  local current="$dotfiles_dir/stow/git/.gitconfig-profile"
  if [[ -f "$current" ]]; then
    for p in "$dotfiles_dir"/stow/git/profiles/*; do
      if cmp -s "$current" "$p"; then
        profile="$(basename "$p")"
        break
      fi
    done
  fi
  command brew bundle dump --force --file="$dotfiles_dir/meta/homebrew/Brewfile.$profile"
}

brew() {
  command brew "$@"
  if [[ "$1" == "install" || "$1" == "uninstall" ]]; then
    brewfile-sync
  fi
}