#!/usr/bin/env bash
# Forces the generated flutter_bootstrap.js to load CanvasKit from the local
# build/web/canvaskit/ folder instead of gstatic.com. See README.md.
set -euo pipefail

BOOTSTRAP_FILE="${1:?Usage: patch-local-canvaskit.sh <path to flutter_bootstrap.js>}"

sed -i 's/"engineRevision":"\([^"]*\)","builds"/"engineRevision":"\1","useLocalCanvasKit":true,"builds"/' "$BOOTSTRAP_FILE"

grep -q '"useLocalCanvasKit":true' "$BOOTSTRAP_FILE"
echo "Patched $BOOTSTRAP_FILE to use local CanvasKit."
