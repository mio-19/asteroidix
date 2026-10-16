#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: run-emulator [options]

Run the AsteroidOS emulator via QEMU with Virgil3D hardware acceleration.
If no local build image is found, automatically downloads upstream prebuilt nightlies.

Options:
  -k, --kernel <path>        Path to bzImage-emulator.bin (default: auto-detect)
  -r, --rootfs <path>        Path to asteroid-image-emulator.rootfs.ext4 (default: auto-detect)
  -p, --port <port>          Host SSH port to forward to guest port 22 (default: 2222)
  -m, --memory <size>        Memory size allocated for QEMU (default: 512M)
  -d, --display <backend>    Display backend (default: sdl,gl=on; alternatives: gtk,gl=on)
  --res, --resolution <WxH>  Screen resolution (default: 800x800)
  -s, --snapshot             Do not write changes back to the rootfs disk image
  --no-kvm                   Force disable KVM hardware acceleration
  --fetch-nightly            Force re-downloading upstream AsteroidOS nightly image
  -h, --help                 Show this help message

Examples:
  # Run out-of-the-box (uses ./result or downloads prebuilt nightly to cache)
  run-emulator

  # Run with custom images from a nix build
  run-emulator --kernel ./result/images/bzImage-emulator.bin --rootfs ./result/images/asteroid-image-emulator.rootfs.ext4

  # Run in snapshot mode (disposable session) on port 2223
  run-emulator --snapshot --port 2223
USAGE
  exit 0
}

KERNEL=""
ROOTFS=""
SSH_PORT="2222"
MEM_SIZE="512M"
DISPLAY_OPT="sdl,gl=on"
RESOLUTION="800x800"
SNAPSHOT_FLAG=()
ENABLE_KVM=1
FORCE_FETCH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -k|--kernel)
      KERNEL="$2"
      shift 2
      ;;
    -r|--rootfs)
      ROOTFS="$2"
      shift 2
      ;;
    -p|--port)
      SSH_PORT="$2"
      shift 2
      ;;
    -m|--memory)
      MEM_SIZE="$2"
      shift 2
      ;;
    -d|--display)
      DISPLAY_OPT="$2"
      shift 2
      ;;
    --res|--resolution)
      RESOLUTION="$2"
      shift 2
      ;;
    -s|--snapshot)
      SNAPSHOT_FLAG=( "-snapshot" )
      shift 1
      ;;
    --no-kvm)
      ENABLE_KVM=0
      shift 1
      ;;
    --fetch-nightly)
      FORCE_FETCH=1
      shift 1
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      usage
      ;;
  esac
done

REPO_ROOT="${REPO_ROOT:-$PWD}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/asteroidix/emulator"

find_image_file() {
  local pattern="$1"
  local dir="$2"
  if [ -d "$dir" ]; then
    find "$dir" -maxdepth 2 -type f -name "$pattern" 2>/dev/null | head -n 1 || true
  fi
}

download_file_if_needed() {
  local url="$1"
  local dest="$2"
  local name="$3"

  if [ "$FORCE_FETCH" -eq 1 ] || [ ! -f "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    echo "==> Downloading upstream $name to $dest..."
    if command -v curl &>/dev/null; then
      curl -fL --progress-bar "$url" -o "$dest.tmp"
      mv "$dest.tmp" "$dest"
    elif command -v wget &>/dev/null; then
      wget --progress=bar:force "$url" -O "$dest.tmp"
      mv "$dest.tmp" "$dest"
    else
      echo "Error: Neither curl nor wget found in PATH." >&2
      exit 1
    fi
  fi
}

# Auto-detect kernel if not provided
if [ -z "$KERNEL" ]; then
  # 1. Check local build result
  if [ "$FORCE_FETCH" -eq 0 ]; then
    CANDIDATE=$(find_image_file "bzImage*emulator*" "$REPO_ROOT/result/images")
    if [ -n "$CANDIDATE" ] && [ -f "$CANDIDATE" ]; then
      KERNEL="$CANDIDATE"
      echo "==> Using local build kernel: $KERNEL"
    fi
  fi

  # 2. Check cache or download upstream nightly
  if [ -z "$KERNEL" ]; then
    CACHE_KERNEL="$CACHE_DIR/bzImage-emulator.bin"
    download_file_if_needed "https://release.asteroidos.org/nightlies/emulator/bzImage-emulator.bin" "$CACHE_KERNEL" "kernel"
    KERNEL="$CACHE_KERNEL"
  fi
fi

# Auto-detect rootfs if not provided
if [ -z "$ROOTFS" ]; then
  # 1. Check local build result
  if [ "$FORCE_FETCH" -eq 0 ]; then
    CANDIDATE=$(find_image_file "*emulator*.rootfs.ext4" "$REPO_ROOT/result/images")
    if [ -z "$CANDIDATE" ]; then
      CANDIDATE=$(find_image_file "*emulator*.ext4" "$REPO_ROOT/result/images")
    fi
    if [ -n "$CANDIDATE" ] && [ -f "$CANDIDATE" ]; then
      ROOTFS="$CANDIDATE"
      echo "==> Using local build rootfs: $ROOTFS"
    fi
  fi

  # 2. Check cache or download upstream nightly
  if [ -z "$ROOTFS" ]; then
    CACHE_ROOTFS="$CACHE_DIR/asteroid-image-emulator.rootfs.ext4"
    download_file_if_needed "https://release.asteroidos.org/nightlies/emulator/asteroid-image-emulator.rootfs.ext4" "$CACHE_ROOTFS" "rootfs"
    ROOTFS="$CACHE_ROOTFS"
  fi
fi

if [ ! -f "$KERNEL" ]; then
  echo "Error: Kernel file not found: $KERNEL" >&2
  exit 1
fi

if [ ! -f "$ROOTFS" ]; then
  echo "Error: Rootfs file not found: $ROOTFS" >&2
  exit 1
fi

# Check KVM availability
KVM_ARGS=()
if [ "$ENABLE_KVM" -eq 1 ]; then
  if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_ARGS=( "-enable-kvm" )
  else
    echo "Notice: /dev/kvm is not accessible. Running without KVM acceleration (may be slower)."
    echo "        To enable KVM, ensure virtualization is enabled in BIOS and user is in the kvm group."
  fi
fi

# Check Wayland session
if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
  echo "Notice: Current session is X11. Virgil3D / OpenGL acceleration works best in a Wayland session."
fi

# Locate qemu-system-x86_64
QEMU_BIN="${QEMU_BIN:-qemu-system-x86_64}"
if ! command -v "$QEMU_BIN" &>/dev/null; then
  echo "Error: $QEMU_BIN not found in PATH." >&2
  echo "Run via Nix: nix run .#emulator" >&2
  exit 1
fi

echo "=========================================================="
echo " Starting AsteroidOS Emulator"
echo " Kernel:     $KERNEL"
echo " Rootfs:     $ROOTFS"
echo " SSH Port:   localhost:$SSH_PORT -> guest:22"
echo " Display:    $DISPLAY_OPT"
echo " Resolution: $RESOLUTION"
echo "=========================================================="
echo "Tip: To connect via SSH:"
echo "     ssh -p $SSH_PORT ceres@localhost"
echo "Tip: To deploy apps via push-app:"
echo "     ./scripts/push-app.sh --target root@localhost --method ssh --package <app>"
echo "=========================================================="

QEMU_CMD=(
  "$QEMU_BIN"
  "${KVM_ARGS[@]}"
  "-kernel" "$KERNEL"
  "-device" "virtio-vga-gl"
  "-net" "nic"
  "-net" "user,hostfwd=tcp::$SSH_PORT-:22"
  "-drive" "format=raw,file=$ROOTFS"
  "-m" "$MEM_SIZE"
  "-display" "$DISPLAY_OPT"
  "-cpu" "qemu64,+ssse3,+sse4.1,+sse4.2"
  "-usb"
  "-device" "usb-tablet"
  "${SNAPSHOT_FLAG[@]}"
  "--append" "verbose root=/dev/sda rw mem=$MEM_SIZE video=$RESOLUTION"
)

exec "${QEMU_CMD[@]}"
