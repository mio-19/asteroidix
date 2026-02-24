#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
Usage: update-layers [layer-name ...]

Updates modules/layers.nix by bumping rev/hash for pinned GitHub layers.
If layer names are provided, only those layers are updated.
EOF
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

layers_file="${repo_root}/modules/layers.nix"
tmp_json="$(mktemp)"
tmp_out="$(mktemp)"
trap 'rm -f "$tmp_json" "$tmp_out"' EXIT

if [ ! -f "$layers_file" ]; then
  echo "layers file not found: ${layers_file}" >&2
  exit 1
fi

nix eval --json --file "$layers_file" > "$tmp_json"

declare -A selected=()
if [ "$#" -gt 0 ]; then
  for name in "$@"; do
    selected["$name"]=1
  done
fi

contains_key() {
  local key="$1"
  local found
  found="$(jq -r --arg k "$key" 'has($k)' "$tmp_json")"
  [ "$found" = "true" ]
}

resolve_rev() {
  local owner="$1"
  local repo="$2"
  local ref="$3"
  local url="https://github.com/${owner}/${repo}.git"
  local rev=""

  for candidate in "refs/heads/${ref}" "refs/tags/${ref}^{}" "refs/tags/${ref}" "${ref}"; do
    rev="$(git ls-remote "$url" "$candidate" | awk 'NR==1 { print $1 }')"
    if [ -n "$rev" ]; then
      printf '%s\n' "$rev"
      return 0
    fi
  done

  return 1
}

prefetch_hash() {
  local owner="$1"
  local repo="$2"
  local rev="$3"
  nix-prefetch-github "$owner" "$repo" --rev "$rev" --quiet | jq -r '.sha256 // .hash'
}

if [ "$#" -gt 0 ]; then
  for name in "$@"; do
    if ! contains_key "$name"; then
      echo "unknown layer: ${name}" >&2
      exit 1
    fi
  done
fi

mapfile -t layer_names < <(sed -n 's/^  \([[:alnum:]-]\+\) = {.*/\1/p' "$layers_file")
layer_count="${#layer_names[@]}"

{
  echo "{"
  for i in "${!layer_names[@]}"; do
    name="${layer_names[$i]}"
    owner="$(jq -r --arg n "$name" '.[$n].owner' "$tmp_json")"
    repo="$(jq -r --arg n "$name" '.[$n].repo' "$tmp_json")"
    ref="$(jq -r --arg n "$name" '.[$n].ref' "$tmp_json")"
    relpath="$(jq -r --arg n "$name" '.[$n].relpath' "$tmp_json")"
    rev="$(jq -r --arg n "$name" '.[$n].rev' "$tmp_json")"
    hash="$(jq -r --arg n "$name" '.[$n].hash' "$tmp_json")"

    update_this=0
    if [ "$#" -eq 0 ] || [ "${selected[$name]+x}" = "x" ]; then
      update_this=1
    fi

    if [ "$update_this" -eq 1 ]; then
      echo "Updating ${name} (${owner}/${repo} @ ${ref})" >&2
      new_rev="$(resolve_rev "$owner" "$repo" "$ref")" || {
        echo "failed to resolve rev for ${name} (${owner}/${repo} ref=${ref})" >&2
        exit 1
      }
      new_hash="$(prefetch_hash "$owner" "$repo" "$new_rev")"
      if [[ ! "$new_hash" =~ ^sha256- ]]; then
        echo "failed to prefetch ${name}: unexpected hash '${new_hash}'" >&2
        exit 1
      fi
      rev="$new_rev"
      hash="$new_hash"
    fi

    cat <<EOF
  ${name} = {
    owner = "${owner}";
    repo = "${repo}";
    ref = "${ref}";
    rev = "${rev}";
    hash = "${hash}";
    relpath = "${relpath}";
  };
EOF
    if [ "$i" -lt $((layer_count - 1)) ]; then
      echo
    fi
  done
  echo "}"
} > "$tmp_out"

mv "$tmp_out" "$layers_file"
echo "Updated ${layers_file}"
