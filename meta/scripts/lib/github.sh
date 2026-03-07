#!/bin/bash
# github.sh — helpers for fetching GitHub release versions and downloading binaries.

# gh_latest_version OWNER REPO
# Prints the latest release tag stripped of a leading 'v' (e.g. "1.2.3").
# Uses jq when available; falls back to grep/sed for environments without jq.
gh_latest_version() {
  local owner="$1" repo="$2"
  local url="https://api.github.com/repos/${owner}/${repo}/releases/latest"
  if command -v jq &>/dev/null; then
    curl -s "$url" | jq -r .tag_name | sed 's/^v//'
  else
    curl -s "$url" | grep -o '"tag_name": "v[^"]*"' | grep -o '[0-9][^"]*'
  fi
}
