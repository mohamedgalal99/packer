#!/usr/bin/env bash

set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

if [ ! -r /etc/os-release ]; then
  echo "Error: /etc/os-release is unavailable"
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

if [ "${ID:-}" != "debian" ]; then
  echo "Error: update-debian.sh can only run on Debian (detected: ${ID:-unknown})"
  exit 1
fi

case "${VERSION_ID:-}" in
  11|12)
    ;;
  *)
    echo "Error: Unsupported Debian version: ${VERSION_ID:-unknown}"
    exit 1
    ;;
esac

apt_options=(
  -o Acquire::Retries=5
  -o Acquire::http::Timeout=30
)
dpkg_options=(
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

# Wait for cloud-init and any unattended apt activity to release locks.
if command -v cloud-init >/dev/null 2>&1; then
  sudo cloud-init status --wait || true
fi
while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 \
  || sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 \
  || sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
  || sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
  echo "Waiting for apt/dpkg locks to be released..."
  sleep 3
done

sudo apt-get clean
sudo -E apt-get update "${apt_options[@]}"

# Keep the guest tools and Debian cloud-kernel meta-package current.
kernel_package="linux-image-cloud-$(dpkg --print-architecture)"
sudo -E apt-get install -y "${apt_options[@]}" qemu-guest-agent "${kernel_package}"

sudo -E apt-get dist-upgrade -y "${apt_options[@]}" "${dpkg_options[@]}"
sudo -E apt-get autoremove --purge -y "${apt_options[@]}"
sudo systemctl reboot
