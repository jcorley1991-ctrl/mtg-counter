#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is required. Install the stable Flutter SDK first." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

flutter create \
  --platforms=android,ios \
  --project-name mtg_counter_app \
  --org dev.local.mtgcounter \
  "$TMP_DIR/mtg_counter_app"

rm -rf android ios
cp -R "$TMP_DIR/mtg_counter_app/android" ./android
cp -R "$TMP_DIR/mtg_counter_app/ios" ./ios

echo "Android and iOS platform shells generated with temporary development identifiers."
