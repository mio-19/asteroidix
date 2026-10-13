#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<'EOF'
Usage: update-layers [nightly|stable] [layer-name ...]

Updates modules/layers/<channel>.nix by bumping rev/hash for pinned layers.
With no channel, both nightly and stable are updated.
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

channels=(nightly stable)
if [ "${1:-}" = "nightly" ] || [ "${1:-}" = "stable" ]; then
  channels=("$1")
  shift
fi

declare -A selected=()
if [ "$#" -gt 0 ]; then
  for name in "$@"; do
    selected["$name"]=1
  done
fi

resolve_rev() {
  local url="$1"
  local ref="$2"
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
  local url="$3"
  local rev="$4"
  local hash
  if [ -n "$url" ]; then
    hash="$(nix-prefetch-git --url "$url" --rev "$rev" --quiet | jq -r '.hash // .sha256')"
    nix hash convert --hash-algo sha256 --to sri "$hash"
  else
    nix-prefetch-github "$owner" "$repo" --rev "$rev" --quiet | jq -r '.hash // .sha256'
  fi
}

update_channel() {
  local channel="$1"
  local layers_file="${repo_root}/modules/layers/${channel}.nix"
  local tmp_json tmp_out
  tmp_json="$(mktemp)"
  tmp_out="$(mktemp)"

  if [ ! -f "$layers_file" ]; then
    echo "layers file not found: ${layers_file}" >&2
    exit 1
  fi

  nix eval --json --file "$layers_file" > "$tmp_json"

  local name matched=0
  if [ "${#selected[@]}" -gt 0 ]; then
    for name in "${!selected[@]}"; do
      if [ "$(jq -r --arg k "$name" 'has($k)' "$tmp_json")" = "true" ]; then
        matched=1
      fi
    done
    if [ "$matched" -eq 0 ]; then
      rm -f "$tmp_json" "$tmp_out"
      return 2
    fi
  fi

  mapfile -t layer_names < <(sed -n 's/^  \([[:alnum:]-]\+\) = {.*/\1/p' "$layers_file")
  local layer_count="${#layer_names[@]}"
  local layers_changed=0
  local i owner repo url ref relpath rev hash update_this new_rev new_hash

  {
    echo "{"
    for i in "${!layer_names[@]}"; do
      name="${layer_names[$i]}"
      owner="$(jq -r --arg n "$name" '.[$n].owner // ""' "$tmp_json")"
      repo="$(jq -r --arg n "$name" '.[$n].repo // ""' "$tmp_json")"
      url="$(jq -r --arg n "$name" '.[$n].url // ""' "$tmp_json")"
      ref="$(jq -r --arg n "$name" '.[$n].ref' "$tmp_json")"
      relpath="$(jq -r --arg n "$name" '.[$n].relpath' "$tmp_json")"
      rev="$(jq -r --arg n "$name" '.[$n].rev' "$tmp_json")"
      hash="$(jq -r --arg n "$name" '.[$n].hash' "$tmp_json")"

      update_this=0
      if [ "${#selected[@]}" -eq 0 ] || [ "${selected[$name]+x}" = "x" ]; then
        update_this=1
      fi

      if [ "$update_this" -eq 1 ]; then
        source_url="${url:-https://github.com/${owner}/${repo}.git}"
        echo "Updating ${channel}/${name} (${source_url} @ ${ref})" >&2
        new_rev="$(resolve_rev "$source_url" "$ref")" || {
          echo "failed to resolve rev for ${name} (${source_url} ref=${ref})" >&2
          exit 1
        }
        new_hash="$(prefetch_hash "$owner" "$repo" "$url" "$new_rev")"
        if [[ ! "$new_hash" =~ ^sha256- ]]; then
          echo "failed to prefetch ${name}: unexpected hash '${new_hash}'" >&2
          exit 1
        fi
        if [ "$rev" != "$new_rev" ] || [ "$hash" != "$new_hash" ]; then
          layers_changed=1
        fi
        rev="$new_rev"
        hash="$new_hash"
      fi

      cat <<EOF
  ${name} = {
EOF
      if [ -n "$url" ]; then
        printf '    url = "%s";\n' "$url"
      else
        cat <<EOF
    owner = "${owner}";
    repo = "${repo}";
EOF
      fi
      cat <<EOF
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
  rm -f "$tmp_json"
  echo "Updated ${layers_file}"

  if [ "$layers_changed" -eq 1 ]; then
    local lock_file="${repo_root}/prefetch-lock.json"
    local updated
    updated="$(jq --arg channel "$channel" '
      .[$channel + "-official"] = {}
      | .[$channel + "-patched"] = {}
    ' "$lock_file")"
    printf '%s\n' "$updated" > "$lock_file"
    echo "Cleared ${channel} prefetch locks; regenerate device hashes with update-prefetch-lock."
  fi
}

known=0
for channel in "${channels[@]}"; do
  if update_channel "$channel" "$@"; then
    known=1
  else
    status=$?
    if [ "$status" -ne 2 ]; then
      exit "$status"
    fi
  fi
done

if [ "$#" -gt 0 ] && [ "$known" -eq 0 ]; then
  echo "unknown layer: $*" >&2
  exit 1
fi
