# Persist and restore last working directory across sessions.
# Saves $PWD on every directory change; restores on shells that start in $HOME
# (e.g., SSH login, new terminal tab).

_last_dir_file="$HOME/.last_dir"

_last_dir_save() { print -r -- "$PWD" > "$_last_dir_file" }
chpwd_functions+=(_last_dir_save)

if [[ "$PWD" == "$HOME" && -r "$_last_dir_file" ]]; then
  _last_dir="$(<$_last_dir_file)"
  [[ -d "$_last_dir" ]] && cd "$_last_dir"
  unset _last_dir
fi
