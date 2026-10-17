#!/usr/bin/env bash
set -euo pipefail

# test-ladybird-watch-ui.sh
# Test Ladybird rendering and UI behavior under smartwatch display constraints (e.g. 416x416 or 454x454).

DEFAULT_NIX_LADYBIRD="/nix/store/z4qxldbnxxhxlvc46j6ghs5b2sj4f577-ladybird-0-unstable-2026-09-18/bin/Ladybird"
LADYBIRD_BIN="${LADYBIRD_BIN:-$(command -v Ladybird 2>/dev/null || command -v ladybird 2>/dev/null || echo "$DEFAULT_NIX_LADYBIRD")}"
WIDTH="${1:-416}"
HEIGHT="${2:-416}"
URL="${3:-https://asteroidos.org}"
OUTPUT="${4:-/tmp/ladybird-watch-${WIDTH}x${HEIGHT}.png}"

if [ ! -x "${LADYBIRD_BIN}" ]; then
  echo "Error: Ladybird binary not found at ${LADYBIRD_BIN}" >&2
  exit 1
fi

echo "=== Ladybird Smartwatch Viewport Test ==="
echo "Target resolution: ${WIDTH}x${HEIGHT} (Smartwatch circular/square viewport)"
echo "Target URL:        ${URL}"
echo "Output screenshot: ${OUTPUT}"

# Run Ladybird in headless screenshot mode with watch dimensions
# We wrap with timeout so it gracefully finishes after rendering
timeout --kill-after=5s 20s "${LADYBIRD_BIN}" \
  --headless=screenshot \
  --screenshot-delay=3 \
  --screenshot-path="${OUTPUT}" \
  --window-width="${WIDTH}" \
  --window-height="${HEIGHT}" \
  "${URL}" || true

if [ -f "${OUTPUT}" ]; then
  echo "Success! Screenshot generated:"
  ls -lh "${OUTPUT}"
  file "${OUTPUT}"
else
  echo "Note: Screenshot was not generated or timed out."
fi
