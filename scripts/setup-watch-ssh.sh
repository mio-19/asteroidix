#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup-watch-ssh [device-serial]

Authorize your host SSH public key on the watch over ADB.
As documented in https://wiki.asteroidos.org/index.php/OpenEmbedded :
Starting with AsteroidOS 2.2+, root login via password is explicitly disabled by default,
so root access requires SSH public keys.

This script:
1. Locates or generates an SSH key (~/.ssh/id_ed25519.pub or ~/.ssh/id_rsa.pub)
2. Uses adb push to copy the public key to the watch
3. Installs the key in /home/root/.ssh/authorized_keys with correct permissions (0700 / 0600)
USAGE
  exit 0
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
fi

DEVICE_ARG=()
if [ -n "${1:-}" ]; then
  DEVICE_ARG=( -s "$1" )
fi

PUBKEY=""
for key in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
  if [ -f "$key" ]; then
    PUBKEY="$key"
    break
  fi
done

if [ -z "$PUBKEY" ]; then
  echo "No existing SSH public key found. Generating ~/.ssh/id_ed25519..."
  ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519"
  PUBKEY="$HOME/.ssh/id_ed25519.pub"
fi

echo "==> Using public key: $PUBKEY"
echo "==> Verifying adb connection to watch..."
adb "${DEVICE_ARG[@]}" wait-for-device

echo "==> Pushing public key to /home/root on watch..."
adb "${DEVICE_ARG[@]}" push "$PUBKEY" /home/root/id_host.pub

echo "==> Setting up /home/root/.ssh/authorized_keys..."
adb "${DEVICE_ARG[@]}" shell "mkdir -p /home/root/.ssh && chmod 700 /home/root/.ssh && cat /home/root/id_host.pub >> /home/root/.ssh/authorized_keys && chmod 600 /home/root/.ssh/authorized_keys && rm -f /home/root/id_host.pub"

echo "==> SSH access configured! You can now SSH to root@<watch-ip> or run push-app."
