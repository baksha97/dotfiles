#!/bin/bash
# codex — Codex CLI config only; auth, sessions, logs, and caches stay local.
mkdir -p "$HOME/.codex"
stow_backup "$HOME/.codex/config.toml"
stow_package codex --no-folding
