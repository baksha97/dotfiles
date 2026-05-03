# Auto-attach tmux for interactive SSH sessions on headless machines.
[[ -o interactive ]] || return 0
[[ -t 0 && -t 1 ]] || return 0
[[ "${DOTFILES_AUTO_TMUX:-1}" == "0" ]] && return 0
[[ -n "${TMUX:-}" ]] && return 0
if [[ -z "${SSH_CONNECTION:-}${SSH_TTY:-}" ]]; then
  [[ "$(ps -o comm= -p "$PPID" 2>/dev/null)" == "sshd" ]] || return 0
fi
[[ -n "${SSH_ORIGINAL_COMMAND:-}" ]] && return 0
[[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && return 0
[[ "${TERM:-}" == "dumb" ]] && return 0
[[ "${TERM_PROGRAM:-}" == "vscode" ]] && return 0
command -v tmux >/dev/null 2>&1 || return 0

exec tmux new-session -A -s "${DOTFILES_AUTO_TMUX_SESSION:-main}"
