#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/asteroidix/emulator-aarch64"

usage() {
  cat <<'USAGE'
Usage: run-emulator-aarch64 [options]

Run the AsteroidOS AArch64 (ARM64) emulator inside QEMU with native hardware
virtualization acceleration on Apple Silicon macOS (Darwin via Apple Hypervisor
framework - hvf) and Linux (via KVM).

Options:
  -k, --kernel <path>        Path to kernel Image (default: auto-detect)
  -r, --rootfs <path>        Path to asteroid-image-emulator-aarch64.rootfs.ext4 (default: auto-detect)
  -i, --image-dir <path>     Directory containing kernel and rootfs (e.g. ./result/images)
  -p, --port <port>          Host SSH port to forward to guest port 22 (default: 2222)
  -c, --cpus <count>         Virtual CPU cores allocated for QEMU (default: auto, up to 4)
  -m, --memory <size>        Memory size allocated for QEMU (default: 1G)
  -d, --display <backend>    QEMU display backend: cocoa, sdl, default, none, curses (default: auto)
      --vnc [display]        Enable VNC display server (e.g. :0 for port 5900; open vnc://localhost:5900)
  -v, --video <device>       QEMU video device: virtio-gpu-pci (default: auto)
  -a, --accel <accel>        QEMU accelerator: hvf, kvm, tcg (default: auto)
  -s, --snapshot             Do not write changes back to the rootfs disk image
      --res, --resolution <WxH> Screen resolution (default: 800x800)
      --nographic            Disable graphical display and run serial console in terminal only
  -h, --help                 Show this help message

Examples:
  # Run out-of-the-box (uses ./result/images or cached images):
  run-emulator-aarch64

  # Run with custom images from a nix build
  run-emulator-aarch64 --image-dir ./result/images

  # Run in snapshot mode (disposable session) on port 2223
  run-emulator-aarch64 --snapshot --port 2223

  # Run headless (serial console in terminal only)
  run-emulator-aarch64 --nographic

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
MEM_SIZE="1G"
DISPLAY_OPT=""
VNC_OPT=""
VIDEO_DEVICE=""
ACCEL=""
CPU_MODEL=""
RESOLUTION="800x800"
SNAPSHOT=0
NOGRAPHIC=0

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
    --vnc)
      if [[ $# -ge 2 && "$2" != -* ]]; then
        VNC_OPT="$2"
        shift 2
      else
        VNC_OPT=":0"
        shift 1
      fi
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
    --res|--resolution)
      RESOLUTION="$2"
      shift 2
      ;;
    --nographic)
      NOGRAPHIC=1
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

# Ensure qemu-system-aarch64 is available
QEMU_BIN="${QEMU_BIN:-qemu-system-aarch64}"
if ! command -v "$QEMU_BIN" >/dev/null 2>&1; then
  echo "Error: '$QEMU_BIN' not found in PATH." >&2
  echo "Tip: Run via Nix ('nix run .#emulator-aarch64') or install QEMU." >&2
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

# 1. Search in user-specified --image-dir if provided
if [ -n "$IMAGE_DIR" ] && [ -d "$IMAGE_DIR" ]; then
  if [ -z "$KERNEL" ]; then
    KERNEL="$(find_file "$IMAGE_DIR" "*Image*" | grep -v '\.ext4' | head -n 1 || true)"
  fi
  if [ -z "$ROOTFS" ]; then
    ROOTFS="$(find_file "$IMAGE_DIR" "*emulator-aarch64*.ext4")"
    if [ -z "$ROOTFS" ]; then
      ROOTFS="$(find_file "$IMAGE_DIR" "*qemuarm64*.ext4")"
    fi
    if [ -z "$ROOTFS" ]; then
      ROOTFS="$(find_file "$IMAGE_DIR" "*.rootfs.ext4")"
    fi
  fi
fi

# 2. Search in local build outputs (./result/images or ./result) and cache
SEARCH_DIRS=(
  "$REPO_ROOT/result/images"
  "$REPO_ROOT/result"
  "./result/images"
  "./result"
  "$CACHE_DIR"
)

if [ -z "$KERNEL" ]; then
  for d in "${SEARCH_DIRS[@]}"; do
    found="$(find_file "$d" "Image*")"
    if [ -z "$found" ]; then
      found="$(find_file "$d" "*Image.bin*")"
    fi
    if [ -n "$found" ] && [ -f "$found" ]; then
      KERNEL="$found"
      echo "==> Using local kernel: $KERNEL"
      break
    fi
  done
fi

if [ -z "$ROOTFS" ]; then
  for d in "${SEARCH_DIRS[@]}"; do
    found="$(find_file "$d" "*emulator-aarch64*.ext4")"
    if [ -z "$found" ]; then
      found="$(find_file "$d" "*qemuarm64*.ext4")"
    fi
    if [ -z "$found" ]; then
      found="$(find_file "$d" "*asteroid-image*.rootfs.ext4")"
    fi
    if [ -n "$found" ] && [ -f "$found" ]; then
      ROOTFS="$found"
      echo "==> Using local rootfs: $ROOTFS"
      break
    fi
  done
fi

if [ -z "$KERNEL" ] || [ ! -e "$KERNEL" ] || [ -z "$ROOTFS" ] || [ ! -e "$ROOTFS" ]; then
  cat <<EOF >&2
==========================================================
AsteroidOS AArch64 Image Not Found
==========================================================
Upstream AsteroidOS only provides official nightly prebuilts for x86 (the legacy emulator).
For native AArch64 hardware virtualization on Apple Silicon Darwin or AArch64 Linux:

1. Build an AArch64 AsteroidOS image using Nix:
     nix build .#emulator-aarch64-img
   or:
     nix build .#emulator-aarch64-nightly-patched-img

   (Outputs kernel 'Image' and rootfs 'asteroid-image-emulator-aarch64.rootfs.ext4' into ./result/images/)

2. Or point to existing custom kernel and rootfs:
     nix run .#emulator-aarch64 -- --kernel ./path/to/Image --rootfs ./path/to/rootfs.ext4

3. Or place the images into:
     $CACHE_DIR/Image
     $CACHE_DIR/asteroid-image-emulator-aarch64.rootfs.ext4

Note: To run the legacy x86 emulator with auto-downloaded upstream nightlies, run:
     nix run .#emulator
==========================================================
EOF
  exit 1
fi

# Patch rootfs if needed (ensure systemd user timeout is extended and KMS matches DRM)
patch_rootfs_if_needed() {
  local rootfs_path="$1"
  if command -v debugfs >/dev/null 2>&1 && [ -w "$rootfs_path" ]; then
    local timeout_check
    timeout_check="$(debugfs -R "cat /etc/systemd/user.conf.d/timeout.conf" "$rootfs_path" 2>/dev/null || true)"
    if ! echo "$timeout_check" | grep -q "DefaultTimeoutStartSec"; then
      echo "==> Configuring systemd user timeout in rootfs (relaxed for emulator)..."
      local tmp_conf
      tmp_conf="$(mktemp "${TMPDIR:-/tmp}/user-timeout.XXXXXX.conf")"
      printf "[Manager]\nDefaultTimeoutStartSec=600s\n" > "$tmp_conf"
      debugfs -w -R "mkdir /etc/systemd/user.conf.d" "$rootfs_path" >/dev/null 2>&1 || true
      debugfs -w -R "rm /etc/systemd/user.conf.d/timeout.conf" "$rootfs_path" >/dev/null 2>&1 || true
      debugfs -w -R "write $tmp_conf /etc/systemd/user.conf.d/timeout.conf" "$rootfs_path" >/dev/null 2>&1 || true
      rm -f "$tmp_conf"
    fi

    local kms_check
    kms_check="$(debugfs -R "cat /var/lib/environment/compositor/kms.json" "$rootfs_path" 2>/dev/null || true)"
    if ! echo "$kms_check" | grep -q "Virtual-1"; then
      local tmp_kms
      tmp_kms="$(mktemp "${TMPDIR:-/tmp}/kms.XXXXXX.json")"
      cat << 'EOF' > "$tmp_kms"
{
  "device": "/dev/dri/card0",
  "hwcursor": false,
  "outputs": [
    { "name": "Virtual-1", "mode": "800x800" },
    { "name": "Virtual1", "mode": "800x800" },
    { "name": "card0", "mode": "800x800" }
  ]
}
EOF
      debugfs -w -R "rm /var/lib/environment/compositor/kms.json" "$rootfs_path" >/dev/null 2>&1 || true
      debugfs -w -R "write $tmp_kms /var/lib/environment/compositor/kms.json" "$rootfs_path" >/dev/null 2>&1 || true
      rm -f "$tmp_kms"
    fi
  fi
}

patch_rootfs_if_needed "$ROOTFS"

# Configure Accelerator & CPU Model
ACCEL_ARGS=()
if [ -n "$ACCEL" ]; then
  ACCEL_ARGS=( -accel "$ACCEL" )
  CPU_MODEL="${CPU_MODEL:-host}"
elif [ "$HOST_OS" = "Darwin" ]; then
  if [ "$HOST_ARCH" = "arm64" ] || [ "$HOST_ARCH" = "aarch64" ]; then
    # Native hardware virtualization via Apple Hypervisor Framework (HVF)
    ACCEL_ARGS=( -accel hvf )
    CPU_MODEL="host"
  else
    # Intel Mac emulating AArch64 via multi-threaded TCG
    ACCEL_ARGS=( -accel tcg,thread=multi )
    CPU_MODEL="cortex-a57"
  fi
elif [ "$HOST_OS" = "Linux" ]; then
  if [ "$HOST_ARCH" = "aarch64" ] && [ -w /dev/kvm ] 2>/dev/null; then
    ACCEL_ARGS=( -enable-kvm )
    CPU_MODEL="host"
  else
    ACCEL_ARGS=( -accel tcg,thread=multi )
    CPU_MODEL="cortex-a57"
  fi
else
  ACCEL_ARGS=( -accel tcg,thread=multi )
  CPU_MODEL="cortex-a57"
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
elif [ -n "$VNC_OPT" ]; then
  DISPLAY_ARGS=( -vnc "$VNC_OPT" )
  VIDEO_ARGS=( -device "virtio-gpu-pci,xres=$XRES,yres=$YRES" )
else
  if [ -n "$DISPLAY_OPT" ]; then
    DISPLAY_ARGS=( -display "$DISPLAY_OPT" )
  elif [ "$HOST_OS" = "Darwin" ]; then
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
  else
    VIDEO_ARGS=( -device "virtio-gpu-pci,xres=$XRES,yres=$YRES" )
  fi
fi

# Configure Drive / Rootfs (VirtIO block device)
DRIVE_ARGS=( -drive "if=none,file=$ROOTFS,id=hd0,format=raw" -device "virtio-blk-pci,drive=hd0" )
if [ "$SNAPSHOT" -eq 1 ]; then
  DRIVE_ARGS+=( -snapshot )
fi

# Kernel Command Line
# Serial on ARM virt is ttyAMA0; also redirect to tty0 for GUI console
KERNEL_CMDLINE="verbose root=/dev/vda rw mem=$MEM_SIZE video=$RESOLUTION console=ttyAMA0 console=tty0 systemd.default_timeout_start_sec=300s"

echo "=========================================================="
echo " Starting AsteroidOS AArch64 Emulator"
echo " Host OS:       $HOST_OS ($HOST_ARCH)"
echo " Machine:       virt,highmem=on"
echo " CPU Model:     $CPU_MODEL"
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
if [ -n "$VNC_OPT" ]; then
echo " - VNC Server:       Listening on $VNC_OPT"
if [ "$HOST_OS" = "Darwin" ]; then
echo "                     Open in macOS Screen Sharing: open vnc://localhost:5900"
fi
else
echo " - GUI Window:       AsteroidOS watchface will appear in the QEMU GUI window."
echo "                     (Early boot displays on screen; watchface draws after ~10-20s)"
fi
echo " - Log in via SSH:   ssh -p $SSH_PORT ceres@localhost (no password)"
echo " - Or as root:       ssh -p $SSH_PORT root@localhost"
echo " - Deploy packages:  nix run .#push-app -- --emulator --package <name>"
echo " - Serial console:   Active in this terminal."
echo " - To exit QEMU:     Cmd-Q (GUI window) or Ctrl-A X (terminal)"
echo "=========================================================="

# On macOS, bring the QEMU Cocoa window to front
if [ "$HOST_OS" = "Darwin" ] && [ "$NOGRAPHIC" -eq 0 ] && [ -z "$VNC_OPT" ]; then
  (
    sleep 1
    osascript -e 'tell application "System Events" to set frontmost of first process whose name contains "qemu" to true' >/dev/null 2>&1 || true
  ) &
fi

exec "$QEMU_BIN" \
  -M virt,highmem=on \
  "${ACCEL_ARGS[@]}" \
  -cpu "$CPU_MODEL" \
  -smp "$CPUS" \
  -m "$MEM_SIZE" \
  -kernel "$KERNEL" \
  "${VIDEO_ARGS[@]}" \
  "${DISPLAY_ARGS[@]}" \
  -device qemu-xhci \
  -device usb-tablet \
  -device virtio-net-pci,netdev=net0 \
  -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22" \
  -serial mon:stdio \
  "${DRIVE_ARGS[@]}" \
  --append "$KERNEL_CMDLINE"
