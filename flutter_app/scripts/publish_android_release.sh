#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/flutter_app"
BACKEND_DIR="$ROOT_DIR/backend"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/arun_ap/development/flutter/bin/flutter}"
JAVA_HOME_DEFAULT="/Users/arun_ap/development/jdk-17.0.21+9/Contents/Home"
RAILWAY_BIN="${RAILWAY_BIN:-/Users/arun_ap/.local/bin/railway}"
BUCKET_NAME="${BUCKET_NAME:-crackers-erp-apks}"
RAILWAY_ENV="${RAILWAY_ENV:-production}"
RAILWAY_SERVICE="${RAILWAY_SERVICE:-crackers-erp-api}"

if ! command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
fi
if [[ -z "${JAVA_HOME:-}" && -d "$JAVA_HOME_DEFAULT" ]]; then
  export JAVA_HOME="$JAVA_HOME_DEFAULT"
fi
if ! command -v "$RAILWAY_BIN" >/dev/null 2>&1; then
  RAILWAY_BIN="$(command -v railway)"
fi

NOTES="Latest stability & feature improvements."
MANDATORY="false"
TARGET_PLATFORM="${TARGET_PLATFORM:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notes)
      NOTES="${2:-}"
      shift 2
      ;;
    --mandatory)
      MANDATORY="true"
      shift
      ;;
    --arm64)
      TARGET_PLATFORM="android-arm64"
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--notes \"Release notes\"] [--mandatory] [--arm64]" >&2
      exit 1
      ;;
  esac
done

VERSION_LINE="$(grep -E '^version:' "$FLUTTER_DIR/pubspec.yaml" | head -n1 | awk '{print $2}' | tr -d '[:space:]')"
if [[ -z "$VERSION_LINE" || "$VERSION_LINE" != *+* ]]; then
  echo "Invalid version in pubspec.yaml (expected x.y.z+code): '$VERSION_LINE'" >&2
  exit 1
fi

VERSION_NAME="${VERSION_LINE%%+*}"
VERSION_CODE="${VERSION_LINE##*+}"
OBJECT_KEY="releases/crackers-erp-${VERSION_NAME}+${VERSION_CODE}.apk"
APK_PATH="$FLUTTER_DIR/build/app/outputs/flutter-apk/app-release.apk"

echo "Building release APK v${VERSION_NAME} (code ${VERSION_CODE})..."
if [[ -n "$TARGET_PLATFORM" ]]; then
  (cd "$FLUTTER_DIR" && "$FLUTTER_BIN" build apk --release --target-platform "$TARGET_PLATFORM")
else
  (cd "$FLUTTER_DIR" && "$FLUTTER_BIN" build apk --release)
fi

if [[ ! -f "$APK_PATH" ]]; then
  echo "Expected APK not found at $APK_PATH" >&2
  exit 1
fi

echo "Uploading $OBJECT_KEY to Railway Storage Bucket '$BUCKET_NAME'..."
(cd "$ROOT_DIR" && "$RAILWAY_BIN" bucket credentials --bucket "$BUCKET_NAME" --environment "$RAILWAY_ENV" --json | \
  node "$BACKEND_DIR/upload_apk_to_bucket.js" --file "$APK_PATH" --key "$OBJECT_KEY" --credentials-json -)

echo "Publishing version metadata to Railway service '$RAILWAY_SERVICE'..."
(cd "$ROOT_DIR" && "$RAILWAY_BIN" variable set \
  --service "$RAILWAY_SERVICE" \
  --environment "$RAILWAY_ENV" \
  "APP_LATEST_VERSION_CODE=$VERSION_CODE" \
  "APP_LATEST_VERSION_NAME=$VERSION_NAME" \
  "APP_APK_KEY=$OBJECT_KEY" \
  "APP_UPDATE_NOTES=$NOTES" \
  "APP_UPDATE_MANDATORY=$MANDATORY")

echo "Published APK v${VERSION_NAME}+${VERSION_CODE} cleanly."
