#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 <machine> [nightly-official|nightly-patched|stable-official|stable-patched]"
  exit 0
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <machine> [nightly-official|nightly-patched|stable-official|stable-patched]" >&2
  exit 1
fi

machine="$1"
variant="${2:-nightly-patched}"

case "$variant" in
  official) variant="nightly-official" ;;
  patched) variant="nightly-patched" ;;
esac

if [[ ! "$machine" =~ ^[a-z0-9-]+$ ]]; then
  echo "Invalid machine: ${machine}" >&2
  exit 1
fi

if [[ ! "$variant" =~ ^(nightly-official|nightly-patched|stable-official|stable-patched)$ ]]; then
  echo "Invalid variant '${variant}'. Expected nightly-official, nightly-patched, stable-official, or stable-patched." >&2
  exit 1
fi

if [ -n "${REPO_ROOT:-}" ]; then
  repo_root="${REPO_ROOT}"
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
  repo_root="$(git rev-parse --show-toplevel)"
else
  repo_root="$(pwd)"
fi

cd "$repo_root"
lock_file="${repo_root}/prefetch-lock.json"
log_file="$(mktemp)"

trap 'rm -f "$log_file"' EXIT

echo "Prefetching sources for ${variant} ${machine}"

nix build --print-build-logs --show-trace --impure --expr "
let
  flake = builtins.getFlake \"path:${repo_root}\";
  system = builtins.currentSystem;
  cfg = flake.lib.asteroidixSystem {
    inherit system;
    configuration = {
      machine = \"${machine}\";
      variant = \"${variant}\";
      prefetch.enable = true;
      prefetch.hash = (import flake.inputs.nixpkgs { inherit system; }).lib.fakeHash;
    };
  };
in cfg.prefetchedSources" 2>&1 | tee "$log_file" || true

hash="$(sed -n 's/.*got:[[:space:]]*//p' "$log_file" | tail -n1)"

if [ -z "${hash}" ]; then
  echo "Failed to detect prefetch hash from build output." >&2
  exit 1
fi

if [[ ! "${hash}" =~ ^sha256- ]]; then
  echo "Detected hash has unexpected format: ${hash}" >&2
  exit 1
fi

updated_json="$(
  LOCK_FILE="$lock_file" MACHINE="$machine" VARIANT="$variant" HASH="$hash" \
    nix eval --impure --raw --expr '
      let
        locksPath = builtins.getEnv "LOCK_FILE";
        locks = builtins.fromJSON (builtins.readFile locksPath);
        machine = builtins.getEnv "MACHINE";
        variant = builtins.getEnv "VARIANT";
        hash = builtins.getEnv "HASH";
        base =
          if locks ? "nightly-patched" || locks ? "stable-patched" then
            locks
          else if locks ? patched then
            {
              "nightly-official" = locks.official or { };
              "nightly-patched" = locks.patched or { };
              "stable-official" = { };
              "stable-patched" = { };
            }
          else
            {
              "nightly-official" = { };
              "nightly-patched" = locks;
              "stable-official" = { };
              "stable-patched" = { };
            };
        variantLocks = base.${variant} or { };
        updated = base // {
          ${variant} = variantLocks // {
            ${machine} = hash;
          };
        };
      in
      builtins.toJSON updated
    '
)"

printf '%s\n' "$updated_json" > "$lock_file"
echo "Updated ${lock_file}: ${variant}.${machine} -> ${hash}"
