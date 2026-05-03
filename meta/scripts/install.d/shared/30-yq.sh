#!/bin/bash
# yq — YAML/JSON/TOML processor
YQ_VERSION="$(gh_latest_version mikefarah yq)"
if [[ -z "$YQ_VERSION" ]]; then
  echo "  Warning: could not determine yq version, skipping." >&2
  return 0
fi
if command -v yq &>/dev/null; then
  current_version="$(yq --version | grep -oE 'v?[0-9]+(\.[0-9]+)+' | head -1 | sed 's/^v//')"
  version_eq "$current_version" "$YQ_VERSION" && return 0
fi
echo "Installing/updating yq..."
YQ_OS="linux"
[[ "$(uname)" == "Darwin" ]] && YQ_OS="darwin"
$SUDO curl -fsSLo /usr/local/bin/yq \
  "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_${YQ_OS}_${ARCH_GO}"
$SUDO chmod +x /usr/local/bin/yq
