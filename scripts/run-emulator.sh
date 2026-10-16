#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/asteroidix/emulator"
NIGHTLY_BASE_URL="https://release.asteroidos.org/nightlies/emulator"

usage() {
  cat <<'USAGE'
Usage: run-emulator [options]

Run the AsteroidOS emulator inside QEMU with cross-platform support for macOS (Darwin) and Linux.
If no local build image is found, automatically uses or downloads upstream prebuilt nightlies.

Options:
  -k, --kernel <path>        Path to bzImage-emulator.bin (default: auto-detect)
  -r, --rootfs <path>        Path to asteroid-image-emulator.rootfs.ext4 (default: auto-detect)
  -i, --image-dir <path>     Directory containing kernel and rootfs (e.g. ./result/images)
  -p, --port <port>          Host SSH port to forward to guest port 22 (default: 2222)
  -c, --cpus <count>         Virtual CPU cores allocated for QEMU (default: auto, up to 4)
  -m, --memory <size>        Memory size allocated for QEMU (default: 512M)
  -d, --display <backend>    QEMU display backend: cocoa, sdl, default, none, curses (default: auto)
  -v, --video <device>       QEMU video device: virtio-vga, virtio-vga-gl, virtio-gpu-pci (default: auto)
  -a, --accel <accel>        QEMU accelerator: tcg, hvf, kvm (default: auto)
  -s, --snapshot             Do not write changes back to the rootfs disk image
      --no-kvm               Disable KVM acceleration (use TCG)
      --res, --resolution <WxH>  Screen resolution passed to kernel (default: 800x800)
      --nographic            Disable graphical display and run serial console in terminal only
      --download, --fetch-nightly Force downloading upstream AsteroidOS nightly image
  -h, --help                 Show this help message

Examples:
  # Run out-of-the-box (uses ./result/images or cached nightly):
  run-emulator

  # Run with custom images from a nix build
  run-emulator --image-dir ./result/images

  # Run in snapshot mode (disposable session) on port 2223
  run-emulator --snapshot --port 2223

  # Run headless (serial console in terminal only)
  run-emulator --nographic

  # Connect to the running emulator via SSH:
  ssh -p 2222 ceres@localhost
  # or as root:
  ssh -p 2222 root@localhost

  # Push an application to the running emulator:
  push-app --emulator --package asteroid-findphone
USAGE
  exit 0
}

KERNEL=""
ROOTFS=""
IMAGE_DIR=""
SSH_PORT="2222"
CPUS=""
MEM_SIZE="512M"
DISPLAY_OPT=""
VIDEO_DEVICE=""
ACCEL=""
RESOLUTION="800x800"
SNAPSHOT=0
NOGRAPHIC=0
ENABLE_KVM=1
FORCE_DOWNLOAD=0

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
    -i|--image-dir)
      IMAGE_DIR="$2"
      shift 2
      ;;
    -p|--port)
      SSH_PORT="$2"
      shift 2
      ;;
    -c|--cpus)
      CPUS="$2"
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
    -v|--video)
      VIDEO_DEVICE="$2"
      shift 2
      ;;
    -a|--accel)
      ACCEL="$2"
      shift 2
      ;;
    -s|--snapshot)
      SNAPSHOT=1
      shift 1
      ;;
    --no-kvm)
      ENABLE_KVM=0
      ACCEL="tcg"
      shift 1
      ;;
    --res|--resolution)
      RESOLUTION="$2"
      shift 2
      ;;
    --nographic)
      NOGRAPHIC=1
      shift 1
      ;;
    --download|--fetch-nightly)
      FORCE_DOWNLOAD=1
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

# Ensure qemu-system-x86_64 is available
QEMU_BIN="${QEMU_BIN:-qemu-system-x86_64}"
if ! command -v "$QEMU_BIN" >/dev/null 2>&1; then
  echo "Error: '$QEMU_BIN' not found in PATH." >&2
  echo "Tip: Run via Nix ('nix run .#emulator') or install QEMU." >&2
  exit 1
fi

# Detect Host Platform & Architecture
HOST_OS="$(uname -s)"
HOST_ARCH="$(uname -m)"

# Auto-detect Host CPU count
HOST_CPUS=1
if command -v nproc >/dev/null 2>&1; then
  HOST_CPUS="$(nproc)"
elif [ "$HOST_OS" = "Darwin" ]; then
  HOST_CPUS="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
fi

if [ -z "$CPUS" ]; then
  if [ "$HOST_CPUS" -ge 4 ]; then
    CPUS=4
  else
    CPUS="$HOST_CPUS"
  fi
fi

find_file() {
  local dir="$1"
  local pattern="$2"
  if [ -d "$dir" ]; then
    find "$dir" -maxdepth 2 -type f -name "$pattern" 2>/dev/null | head -n 1 || true
  fi
}

download_file_if_needed() {
  local url="$1"
  local dest="$2"
  local name="$3"

  if [ "$FORCE_DOWNLOAD" -eq 1 ] || [ ! -f "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    echo "==> Downloading upstream $name to $dest..."
    if command -v curl >/dev/null 2>&1; then
      curl -fL --progress-bar "$url" -o "$dest.tmp"
      mv "$dest.tmp" "$dest"
    elif command -v wget >/dev/null 2>&1; then
      wget --progress=bar:force "$url" -O "$dest.tmp"
      mv "$dest.tmp" "$dest"
    else
      echo "Error: Neither curl nor wget found in PATH." >&2
      exit 1
    fi
  fi
}

# 1. Search in user-specified --image-dir if provided
if [ -n "$IMAGE_DIR" ] && [ -d "$IMAGE_DIR" ]; then
  if [ -z "$KERNEL" ]; then
    KERNEL="$(find_file "$IMAGE_DIR" "*bzImage*")"
  fi
  if [ -z "$ROOTFS" ]; then
    ROOTFS="$(find_file "$IMAGE_DIR" "*emulator*.ext4")"
    if [ -z "$ROOTFS" ]; then
      ROOTFS="$(find_file "$IMAGE_DIR" "*.rootfs.ext4")"
    fi
  fi
fi

# 2. Search in local build outputs (./result/images or ./result)
SEARCH_DIRS=(
  "$REPO_ROOT/result/images"
  "$REPO_ROOT/result"
  "./result/images"
  "./result"
  "$CACHE_DIR"
)

if [ -z "$KERNEL" ] && [ "$FORCE_DOWNLOAD" -eq 0 ]; then
  for d in "${SEARCH_DIRS[@]}"; do
    found="$(find_file "$d" "*bzImage*")"
    if [ -n "$found" ] && [ -f "$found" ]; then
      KERNEL="$found"
      echo "==> Using local kernel: $KERNEL"
      break
    fi
  done
fi

if [ -z "$ROOTFS" ] && [ "$FORCE_DOWNLOAD" -eq 0 ]; then
  for d in "${SEARCH_DIRS[@]}"; do
    found="$(find_file "$d" "*emulator*.ext4")"
    if [ -z "$found" ]; then
      found="$(find_file "$d" "*.rootfs.ext4")"
    fi
    if [ -n "$found" ] && [ -f "$found" ]; then
      ROOTFS="$found"
      echo "==> Using local rootfs: $ROOTFS"
      break
    fi
  done
fi

# 3. If files are still missing, check cache or download upstream nightly
CACHED_KERNEL="$CACHE_DIR/bzImage-emulator.bin"
CACHED_ROOTFS="$CACHE_DIR/asteroid-image-emulator.rootfs.ext4"

if [ -z "$KERNEL" ]; then
  download_file_if_needed "$NIGHTLY_BASE_URL/bzImage-emulator.bin" "$CACHED_KERNEL" "kernel"
  KERNEL="$CACHED_KERNEL"
fi

if [ -z "$ROOTFS" ]; then
  download_file_if_needed "$NIGHTLY_BASE_URL/asteroid-image-emulator.rootfs.ext4" "$CACHED_ROOTFS" "rootfs"
  ROOTFS="$CACHED_ROOTFS"
fi

if [ ! -f "$KERNEL" ]; then
  echo "Error: Kernel file not found: $KERNEL" >&2
  exit 1
fi

if [ ! -f "$ROOTFS" ]; then
  echo "Error: Rootfs file not found: $ROOTFS" >&2
  exit 1
fi

# Configure Accelerator
ACCEL_ARGS=()
if [ -n "$ACCEL" ]; then
  ACCEL_ARGS=( -accel "$ACCEL" )
elif [ "$HOST_OS" = "Darwin" ]; then
  if [ "$HOST_ARCH" = "arm64" ] || [ "$HOST_ARCH" = "aarch64" ]; then
    # Multi-threaded TCG on Apple Silicon provides ~3-4x speedup for LLVMpipe software rendering
    ACCEL_ARGS=( -accel tcg,thread=multi )
  elif [ "$HOST_ARCH" = "x86_64" ]; then
    # Intel Mac can accelerate x86_64 guests via HVF
    ACCEL_ARGS=( -accel hvf -accel tcg,thread=multi )
  else
    ACCEL_ARGS=( -accel tcg,thread=multi )
  fi
elif [ "$HOST_OS" = "Linux" ]; then
  if [ "$ENABLE_KVM" -eq 1 ] && [ -w /dev/kvm ] 2>/dev/null; then
    ACCEL_ARGS=( -enable-kvm )
  else
    echo "Notice: /dev/kvm is not accessible. Running with multi-threaded TCG emulation."
    ACCEL_ARGS=( -accel tcg,thread=multi )
  fi
else
  ACCEL_ARGS=( -accel tcg,thread=multi )
fi

# Parse Resolution
XRES="800"
YRES="800"
if [[ "$RESOLUTION" =~ ^([0-9]+)x([0-9]+)$ ]]; then
  XRES="${BASH_REMATCH[1]}"
  YRES="${BASH_REMATCH[2]}"
fi

# Configure Display and Video Device
DISPLAY_ARGS=()
VIDEO_ARGS=()

if [ "$NOGRAPHIC" -eq 1 ]; then
  DISPLAY_ARGS=( -display none )
  VIDEO_ARGS=()
else
  if [ -n "$DISPLAY_OPT" ]; then
    DISPLAY_ARGS=( -display "$DISPLAY_OPT" )
  elif [ "$HOST_OS" = "Darwin" ]; then
    # Cocoa is the native macOS GUI frontend for QEMU
    DISPLAY_ARGS=( -display cocoa )
  elif [ "$HOST_OS" = "Linux" ]; then
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
      if "$QEMU_BIN" -display help 2>&1 | grep -q sdl; then
        DISPLAY_ARGS=( -display sdl )
      elif "$QEMU_BIN" -display help 2>&1 | grep -q gtk; then
        DISPLAY_ARGS=( -display gtk )
      fi
    fi
  fi

  if [ -n "$VIDEO_DEVICE" ]; then
    VIDEO_ARGS=( -device "$VIDEO_DEVICE" )
  elif [ "$HOST_OS" = "Darwin" ]; then
    # virtio-vga with custom EDID xres/yres sizes the Cocoa window and prevents DRM mode rejection
    VIDEO_ARGS=( -device "virtio-vga,xres=$XRES,yres=$YRES" )
  elif [ "$HOST_OS" = "Linux" ]; then
    # Check if virtio-vga-gl is available in the QEMU binary
    if "$QEMU_BIN" -device help 2>&1 | grep -q "virtio-vga-gl"; then
      VIDEO_ARGS=( -device virtio-vga-gl )
      DISPLAY_ARGS=( -display "sdl,gl=on" )
    else
      VIDEO_ARGS=( -device "virtio-vga,xres=$XRES,yres=$YRES" )
    fi
  else
    VIDEO_ARGS=( -device "virtio-vga,xres=$XRES,yres=$YRES" )
  fi
fi

# Configure Drive / Rootfs
DRIVE_ARGS=( -drive "format=raw,file=$ROOTFS" )
if [ "$SNAPSHOT" -eq 1 ]; then
  DRIVE_ARGS+=( -snapshot )
fi

# Kernel Command Line
# Include systemd.default_timeout_start_sec=300s to allow software rasterizer (LLVMpipe)
# enough time to initialize and compile QML watchfaces on cold start without hitting timeout
KERNEL_CMDLINE="verbose root=/dev/sda rw mem=$MEM_SIZE video=$RESOLUTION console=ttyS0 systemd.default_timeout_start_sec=300s"

echo "=========================================================="
echo " Starting AsteroidOS Emulator"
echo " Host OS:       $HOST_OS ($HOST_ARCH)"
echo " CPUs:          $CPUS vCPU(s)"
echo " Memory:        $MEM_SIZE"
echo " Resolution:    ${RESOLUTION} (display: ${DISPLAY_ARGS[*]:-default})"
echo " Video Device:  ${VIDEO_ARGS[*]:-none}"
echo " Accelerator:   ${ACCEL_ARGS[*]:-default}"
echo " Kernel:        $KERNEL"
echo " Rootfs:        $ROOTFS"
echo " SSH Forward:   localhost:$SSH_PORT -> guest:22"
echo " Snapshot Mode: $([ "$SNAPSHOT" -eq 1 ] && echo 'enabled (temporary copy)' || echo 'disabled (persistent writes)')"
echo "=========================================================="
echo "Tips:"
echo " - GUI Window:       AsteroidOS watchface will appear in the QEMU GUI window."
if [ "$HOST_OS" = "Darwin" ] && [ "$HOST_ARCH" = "arm64" ] && [ "$NOGRAPHIC" -eq 0 ]; then
echo "                     Note: Software rasterization (LLVMpipe) renders the watchface in ~10-20s."
fi
echo " - Log in via SSH:   ssh -p $SSH_PORT ceres@localhost (no password)"
echo " - Or as root:       ssh -p $SSH_PORT root@localhost"
echo " - Deploy packages:  nix run .#push-app -- --emulator --package <name>"
echo " - Serial console:   Active in this terminal."
echo " - To exit QEMU:     Ctrl-A X (terminal) or Cmd-Q (GUI window)"
echo "=========================================================="

exec "$QEMU_BIN" \
  "${ACCEL_ARGS[@]}" \
  -smp "$CPUS" \
  -kernel "$KERNEL" \
  "${VIDEO_ARGS[@]}" \
  "${DISPLAY_ARGS[@]}" \
  -m "$MEM_SIZE" \
  -cpu qemu64,+ssse3,+sse4.1,+sse4.2 \
  -net nic -net "user,hostfwd=tcp::${SSH_PORT}-:22" \
  -usb \
  -device usb-tablet \
  -serial mon:stdio \
  "${DRIVE_ARGS[@]}" \
  --append "$KERNEL_CMDLINE"
