#!/bin/bash
# homebrew.sh — best-effort Homebrew setup helpers.

HOMEBREW_FAILURES=()
HOMEBREW_LOG_FILE=""

homebrew_load_shellenv() {
  local brew_bin=""
  local shellenv_output=""

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    brew_bin="/usr/local/bin/brew"
  fi

  if [ -n "$brew_bin" ] && shellenv_output="$("$brew_bin" shellenv 2>/dev/null)"; then
    eval "$shellenv_output"
  fi
}

homebrew_init_log() {
  if [ -z "$HOMEBREW_LOG_FILE" ]; then
    local log_dir="$DOTFILES_DIR/backup/logs"
    mkdir -p "$log_dir"
    HOMEBREW_LOG_FILE="$log_dir/homebrew-$(date +%Y-%m-%d_%H-%M-%S).log"
    : > "$HOMEBREW_LOG_FILE"
  fi
}

homebrew_record_failure() {
  local label="$1"
  HOMEBREW_FAILURES+=("$label")
}

homebrew_run() {
  local label="$1"; shift
  local exit_status

  homebrew_init_log
  {
    echo
    echo "==> $label"
    printf '$'
    printf ' %q' "$@"
    echo
  } >> "$HOMEBREW_LOG_FILE"

  echo "Running $label..."
  if "$@" >> "$HOMEBREW_LOG_FILE" 2>&1; then
    echo "  $label complete"
    return 0
  else
    exit_status=$?
  fi

  homebrew_record_failure "$label"
  echo "  Warning: $label failed with exit $exit_status; continuing setup."
  echo "  Log: $HOMEBREW_LOG_FILE"
  return 0
}

homebrew_install_if_missing() {
  local install_script

  command -v brew &>/dev/null && return 0

  echo "Homebrew not found, installing..."
  homebrew_init_log
  if ! install_script="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh 2>> "$HOMEBREW_LOG_FILE")"; then
    homebrew_record_failure "Homebrew installer download"
    echo "  Warning: failed to download Homebrew installer; continuing setup."
    echo "  Log: $HOMEBREW_LOG_FILE"
    return 0
  fi

  homebrew_run "Homebrew install" env NONINTERACTIVE=1 /bin/bash -c "$install_script"
  homebrew_load_shellenv
}

homebrew_bundle_install() {
  local file="$1"
  local label="$2"
  local args=(bundle install --verbose "--file=$file")

  [ -f "$file" ] || return 0

  if [ "$SETUP_BREW_UPGRADE" = true ]; then
    args+=(--upgrade)
  else
    args+=(--no-upgrade)
  fi

  homebrew_run "$label" brew "${args[@]}"
}

homebrew_print_summary() {
  local failure

  [ "${#HOMEBREW_FAILURES[@]}" -gt 0 ] || return 0

  echo
  echo "Homebrew completed with warnings; setup continued."
  echo "Log: $HOMEBREW_LOG_FILE"
  for failure in "${HOMEBREW_FAILURES[@]}"; do
    echo "  - $failure"
  done
}
