#!/usr/bin/env bash

set -Eeuo pipefail

if [ ! -r /etc/os-release ]; then
  echo "Error: /etc/os-release is unavailable"
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

if [ "${ID:-}" != "rocky" ]; then
  echo "Error: update-rocky.sh can only run on Rocky Linux (detected: ${ID:-unknown})"
  exit 1
fi

major_version="${VERSION_ID%%.*}"
case "${major_version}" in
  8|9)
    ;;
  *)
    echo "Error: Unsupported Rocky Linux version: ${VERSION_ID:-unknown}"
    exit 1
    ;;
esac

dnf_options=(
  --setopt=retries=5
  --setopt=timeout=30
)

if command -v cloud-init >/dev/null 2>&1; then
  sudo cloud-init status --wait || true
fi

sudo dnf -y --refresh "${dnf_options[@]}" upgrade
sudo dnf -y "${dnf_options[@]}" install qemu-guest-agent
sudo dnf clean all
sudo systemctl reboot
