#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: push-app [--target <target>] [--method <adb|ssh>] [--package <name>] [--path <path-or-ipk>]

Push and install an AsteroidOS application package (.ipk) or directory to a watch.
Follows AsteroidOS OpenEmbedded app deployment guidelines (ADB and SSH/opkg methods).

Options:
  -t, --target <target>     Target watch address/specifier:
                            - For SSH: [user@]host (e.g. root@192.168.2.15 or 192.168.2.15)
                            - For ADB: device serial (optional, passed to adb -s <serial>)
  -m, --method <method>     Deployment method: 'adb', 'ssh', or 'auto' (default: auto)
  -p, --package <name>      Package name to deploy (e.g. asteroid-findphone)
                            Searches for matching .ipk in ./result/packages or ./result/ipk,
                            or custom path if specified.
  -f, --file <file>         Direct path to .ipk package file to install
  -d, --dir <dir>           Directory of app assets to sync directly onto watch
  -h, --help                Show this help message

Examples:
  # Push findphone IPK via ADB (USB / adb connection)
  push-app --package asteroid-findphone --method adb

  # Push findphone IPK via SSH / Wi-Fi
  push-app --package asteroid-findphone --target root@192.168.2.15

  # Push arbitrary .ipk package directly
  push-app --file path/to/asteroid-findphone_1.0-r0_armv7vehf-neon.ipk --method adb
USAGE
  exit 0
}

TARGET=""
METHOD="auto"
PACKAGE=""
FILE=""
APP_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)
      TARGET="$2"
      shift 2
      ;;
    -m|--method)
      METHOD="$2"
      shift 2
      ;;
    -p|--package)
      PACKAGE="$2"
      shift 2
      ;;
    -f|--file)
      FILE="$2"
      shift 2
      ;;
    -d|--dir)
      APP_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [ -z "$FILE" ] && [[ "$1" == *.ipk ]]; then
        FILE="$1"
        shift
      elif [ -z "$PACKAGE" ]; then
        PACKAGE="$1"
        shift
      else
        echo "Unknown option: $1" >&2
        usage
      fi
      ;;
  esac
done

# If no file specified, search for package ipk
if [ -z "$FILE" ] && [ -n "$PACKAGE" ]; then
  # Check common locations: result/packages, result/ipk, or anywhere in result
  SEARCH_DIRS=("./result/packages" "./result/ipk" "./result")
  for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
      FOUND=$(find "$dir" -type f -name "${PACKAGE}_*.ipk" ! -name "*-dbg*" ! -name "*-dev*" ! -name "*-src*" | head -n 1 || true)
      if [ -n "$FOUND" ]; then
        FILE="$FOUND"
        break
      fi
    fi
  done
  if [ -z "$FILE" ]; then
    # Look for any matching ipk without restricting suffix
    for dir in "${SEARCH_DIRS[@]}"; do
      if [ -d "$dir" ]; then
        FOUND=$(find "$dir" -type f -name "${PACKAGE}*.ipk" ! -name "*-dbg*" ! -name "*-dev*" ! -name "*-src*" | head -n 1 || true)
        if [ -n "$FOUND" ]; then
          FILE="$FOUND"
          break
        fi
      fi
    done
  fi
fi

# Detect method if auto
if [ "$METHOD" = "auto" ]; then
  if [ -n "$TARGET" ] && [[ "$TARGET" =~ (@|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
    METHOD="ssh"
  elif command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
    METHOD="adb"
  elif [ -n "$TARGET" ]; then
    METHOD="ssh"
  else
    METHOD="adb"
  fi
fi

deploy_ipk_adb() {
  local ipk="$1"
  local ipk_basename
  ipk_basename="$(basename "$ipk")"

  echo "==> Deploying $ipk via ADB..."
  ADB_CMD=(adb)
  if [ -n "$TARGET" ] && [[ ! "$TARGET" =~ (@|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
    ADB_CMD+=( -s "$TARGET" )
  fi

  echo "--> Pushing $ipk_basename to /tmp on watch..."
  "${ADB_CMD[@]}" push "$ipk" "/tmp/$ipk_basename"

  echo "--> Installing with opkg --force-reinstall..."
  "${ADB_CMD[@]}" shell "opkg --force-reinstall install /tmp/$ipk_basename && rm -f /tmp/$ipk_basename"
  echo "==> Successfully installed $ipk_basename via ADB!"
}

deploy_ipk_ssh() {
  local ipk="$1"
  local dest_host="$TARGET"
  local ipk_basename
  ipk_basename="$(basename "$ipk")"

  if [ -z "$dest_host" ]; then
    dest_host="root@192.168.2.15"
  elif [[ ! "$dest_host" =~ ^.*@.*$ ]]; then
    dest_host="root@$dest_host"
  fi

  echo "==> Deploying $ipk via SSH to $dest_host..."
  echo "--> Copying package..."
  scp "$ipk" "$dest_host:/tmp/$ipk_basename"

  echo "--> Installing package on watch via opkg..."
  ssh "$dest_host" "opkg --force-reinstall install /tmp/$ipk_basename && rm -f /tmp/$ipk_basename"
  echo "==> Successfully installed $ipk_basename via SSH!"
}

deploy_dir_adb() {
  local dir="$1"
  echo "==> Syncing directory $dir to watch via ADB..."
  ADB_CMD=(adb)
  if [ -n "$TARGET" ] && [[ ! "$TARGET" =~ (@|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
    ADB_CMD+=( -s "$TARGET" )
  fi
  "${ADB_CMD[@]}" push "$dir/." /
  echo "==> Directory synced successfully."
}

if [ -n "$FILE" ]; then
  if [ ! -f "$FILE" ]; then
    echo "Error: file '$FILE' not found." >&2
    exit 1
  fi

  if [ "$METHOD" = "adb" ]; then
    deploy_ipk_adb "$FILE"
  elif [ "$METHOD" = "ssh" ]; then
    deploy_ipk_ssh "$FILE"
  else
    echo "Error: unknown method '$METHOD'. Must be 'adb' or 'ssh'." >&2
    exit 1
  fi
elif [ -n "$APP_DIR" ]; then
  if [ ! -d "$APP_DIR" ]; then
    echo "Error: directory '$APP_DIR' not found." >&2
    exit 1
  fi
  if [ "$METHOD" = "adb" ]; then
    deploy_dir_adb "$APP_DIR"
  else
    echo "Error: directory sync only supported via adb." >&2
    exit 1
  fi
else
  echo "Error: No package or .ipk file specified or found." >&2
  echo "You can build the package first or pass --file <path/to/package.ipk>" >&2
  usage
fi
