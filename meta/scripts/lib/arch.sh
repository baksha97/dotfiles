#!/bin/bash
# arch.sh — detect CPU architecture and export normalized forms used by binary downloads.

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_GO="amd64"; ARCH_MUSL="x86_64" ;;
  aarch64|arm64) ARCH_GO="arm64"; ARCH_MUSL="aarch64" ;;
  armv7l)  ARCH_GO="arm";   ARCH_MUSL="armv7"   ;;
  *)       echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac
export ARCH ARCH_GO ARCH_MUSL
