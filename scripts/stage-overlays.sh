#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Stage overlay files for flake git-tree visibility (do not commit).
git add -- meta-asteroidix-sandbox meta-asteroidix-bsp meta-asteroidix-custom

echo "=== STAGED ==="
git diff --cached --stat meta-asteroidix-sandbox/ meta-asteroidix-bsp/ meta-asteroidix-custom/
