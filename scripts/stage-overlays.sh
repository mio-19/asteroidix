#!/usr/bin/env bash
set -euo pipefail
cd /home/dev/Documents/asteroidix

# Stage overlay files for flake git-tree visibility (do not commit).
git add \
  meta-asteroidix-local/recipes-nemomobile/lipstick/lipstick_git.bbappend \
  meta-asteroidix-local/recipes-asteroid/asteroid-launcher/asteroid-launcher_git.bbappend \
  meta-asteroidix-local/recipes-asteroid/qml-asteroid/qml-asteroid_git.bbappend \
  meta-asteroidix-local/recipes-core/systemd/systemd-systemctl-native_257.6.bbappend \
  meta-asteroidix-local/recipes-core/systemd/systemd_%.bbappend \
  meta-asteroidix-local/recipes-core/systemd/systemd-systemctl-native/0001-errno-list-filter-out-EFSBADCRC-and-EFSCORRUPTED.patch \
  meta-asteroidix-local/recipes-core/systemd/systemd/0003-errno-list-filter-out-EFSBADCRC-and-EFSCORRUPTED.patch \
  meta-asteroidix-local/recipes-devtools/rust/rust_1.84.1.bbappend \
  meta-asteroidix-local/recipes-devtools/perl/perl_%.bbappend \
  meta-asteroidix-local/recipes-devtools/perl/files/0001-errno-fallback-to-dM-when-header-scan-finds-nothing.patch

echo "=== STAGED ==="
git diff --cached --stat meta-asteroidix-local/
