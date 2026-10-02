#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Stage overlay files for flake git-tree visibility (do not commit).
git add -- meta-asteroidix-local

echo "=== STAGED ==="
git diff --cached --stat meta-asteroidix-local/
