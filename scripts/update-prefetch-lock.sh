#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <machine>" >&2
  exit 1
fi

machine="$1"

if [ "$machine" = "--help" ] || [ "$machine" = "-h" ]; then
  echo "Usage: $0 <machine>"
  exit 0
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

echo "Prefetching sources for machine: ${machine}"

nix build --print-build-logs --show-trace --impure --expr "
let
  flake = builtins.getFlake \"path:${repo_root}\";
  system = builtins.currentSystem;
  cfg = flake.lib.asteroidixSystem {
    inherit system;
    configuration = {
      machine = \"${machine}\";
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
  LOCK_FILE="$lock_file" MACHINE="$machine" HASH="$hash" \
    nix eval --impure --raw --expr '
      let
        locksPath = builtins.getEnv "LOCK_FILE";
        locks = builtins.fromJSON (builtins.readFile locksPath);
        machine = builtins.getEnv "MACHINE";
        hash = builtins.getEnv "HASH";
        updated = locks // (builtins.listToAttrs [
          {
            name = machine;
            value = hash;
          }
        ]);
      in
      builtins.toJSON updated
    '
)"

printf '%s\n' "$updated_json" > "$lock_file"
echo "Updated ${lock_file}: ${machine} -> ${hash}"
