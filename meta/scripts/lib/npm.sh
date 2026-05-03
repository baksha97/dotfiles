#!/bin/bash
# npm.sh — helpers for idempotent global npm CLI installs.

npm_use_default_node() {
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
    nvm use default >/dev/null
  fi
  return 0
}

npm_cache_dir() {
  echo "${XDG_CACHE_HOME:-$HOME/.cache}/npm"
}

npm_sudo_cache_dir() {
  echo "/tmp/npm-cache-${USER:-user}"
}

npm_global_package_version() {
  local package="$1"
  local cache="$2"
  local json

  json="$(npm --cache "$cache" list -g "$package" --depth=0 --json 2>/dev/null || true)"
  if command -v jq &>/dev/null; then
    printf '%s' "$json" | jq -r --arg package "$package" '.dependencies[$package].version // empty'
  else
    PACKAGE="$package" node -e 'let data = ""; process.stdin.on("data", c => data += c); process.stdin.on("end", () => { try { const json = JSON.parse(data || "{}"); const dep = json.dependencies && json.dependencies[process.env.PACKAGE]; if (dep && dep.version) process.stdout.write(dep.version); } catch (_) {} });' <<<"$json"
  fi
}

npm_global_package_writable() {
  local package="$1"
  local cache="$2"
  local npm_root package_dir package_parent

  npm_root="$(npm --cache "$cache" root -g 2>/dev/null)"
  [ -n "$npm_root" ] || return 1
  package_dir="$npm_root/$package"
  package_parent="$(dirname "$package_dir")"

  [[ ! -d "$package_dir" || ( -w "$package_dir" && -w "$package_parent" ) ]]
}

npm_global_prefix_writable() {
  local prefix bin modules

  prefix="$(npm prefix -g 2>/dev/null)"
  bin="$prefix/bin"
  modules="$prefix/lib/node_modules"

  [[ -w "$prefix" || ( -w "$bin" && -w "$modules" ) ]]
}

npm_install_global_if_needed() {
  local package="$1"
  local binary="$2"
  local label="${3:-$package}"
  local cache sudo_cache current_version latest_version

  npm_use_default_node
  command -v npm &>/dev/null || { echo "  Skipped $label (npm not found)"; return 0; }

  cache="$(npm_cache_dir)"
  sudo_cache="$(npm_sudo_cache_dir)"
  mkdir -p "$cache"

  current_version="$(npm_global_package_version "$package" "$cache")"
  latest_version="$(npm --cache "$cache" view "$package" version 2>/dev/null || true)"

  if [[ -z "$current_version" ]] && command -v "$binary" &>/dev/null; then
    echo "  Skipped $label (already installed outside npm global packages)"
    return 0
  fi

  if [[ -n "$current_version" && -n "$latest_version" ]] && version_eq "$current_version" "$latest_version"; then
    return 0
  fi

  if [[ -n "$current_version" ]] && ! npm_global_package_writable "$package" "$cache"; then
    echo "  Skipped $label update (global npm package is not user-writable)"
    return 0
  fi

  echo "Installing/updating $label..."
  if npm_global_prefix_writable; then
    npm --cache "$cache" install -g "$package"
  else
    $SUDO npm --cache "$sudo_cache" install -g "$package"
  fi
}
