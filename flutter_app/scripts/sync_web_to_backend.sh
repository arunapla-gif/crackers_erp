#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/flutter_app"
WEB_BUILD_DIR="$FLUTTER_DIR/build/web"
BACKEND_PUBLIC_DIR="$ROOT_DIR/backend/public"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/arun_ap/development/flutter/bin/flutter}"

if [[ "${1:-}" == "--build" ]]; then
  if ! command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
  fi
  (cd "$FLUTTER_DIR" && "$FLUTTER_BIN" build web)
fi

rm -rf "$BACKEND_PUBLIC_DIR"
mkdir -p "$BACKEND_PUBLIC_DIR"
rsync -a --exclude='.last_build_id' "$WEB_BUILD_DIR/" "$BACKEND_PUBLIC_DIR/"

echo "Synced Flutter Web bundle to $BACKEND_PUBLIC_DIR"

