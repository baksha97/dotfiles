#!/bin/bash
# docker-compose — Docker Compose plugin
DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
mkdir -p "$DOCKER_CONFIG/cli-plugins"
DC_VERSION="$(gh_latest_version docker compose)"
if [[ -z "$DC_VERSION" ]]; then
  echo "  Warning: could not determine docker compose version, skipping." >&2
  return 0
fi
if docker compose version &>/dev/null 2>&1; then
  current_version="$(docker compose version --short 2>/dev/null | sed 's/^v//')"
  version_eq "$current_version" "$DC_VERSION" && return 0
fi
echo "Installing/updating Docker Compose plugin..."
curl -fsSLo "$DOCKER_CONFIG/cli-plugins/docker-compose" \
  "https://github.com/docker/compose/releases/download/v${DC_VERSION}/docker-compose-linux-$(uname -m)"
chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
