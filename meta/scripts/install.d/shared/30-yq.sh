#!/bin/bash
# yq — YAML/JSON/TOML processor
command -v yq &>/dev/null && return 0
echo "Installing yq..."
YQ_VERSION="$(gh_latest_version mikefarah yq)"
if [[ -z "$YQ_VERSION" ]]; then
  echo "  Warning: could not determine yq version, skipping." >&2
  return 0
fi
YQ_OS="linux"
[[ "$(uname)" == "Darwin" ]] && YQ_OS="darwin"
$SUDO curl -fsSLo /usr/local/bin/yq \
  "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_${YQ_OS}_${ARCH_GO}"
$SUDO chmod +x /usr/local/bin/yq
