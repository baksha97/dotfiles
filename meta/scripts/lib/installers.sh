#!/bin/bash
# installers.sh — source install.d scripts in deterministic filename order.

setup_source_installers() {
  local dir
  local f
  local script

  while IFS=$'\t' read -r _ script; do
    [ -n "$script" ] || continue
    source "$script"
  done < <(
    for dir in "$@"; do
      for f in "$dir/"*.sh; do
        [ -e "$f" ] || continue
        printf '%s\t%s\n' "$(basename "$f")" "$f"
      done
    done | sort
  )
}
