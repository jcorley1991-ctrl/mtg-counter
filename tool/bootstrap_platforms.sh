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

python3 - <<'PY'
from pathlib import Path
import hashlib

root = Path('assets/branding')

def decode_hex_chunks(pattern, output, expected_sha256):
    parts = sorted(root.glob(pattern))
    if not parts:
        raise RuntimeError(f'No branding chunks matched {pattern}')
    data = ''.join(part.read_text().strip() for part in parts)
    raw = bytes.fromhex(data)
    digest = hashlib.sha256(raw).hexdigest()
    if digest != expected_sha256:
        raise RuntimeError(f'{output} checksum mismatch: {digest}')
    (root / output).write_bytes(raw)

decode_hex_chunks(
    'app_icon.hex.*',
    'app_icon.jpg',
    '260cd0a3831d022fa541c585a3e4b8602752ea0c3f4450cd5409ce3ada24b674',
)
decode_hex_chunks(
    'startup.hex.*',
    'startup.jpg',
    '68944e8c4f51435950fd79f2044bab628b3ee0eb5582098d80cb414783ed63cc',
)

pubspec = Path('pubspec.yaml')
text = pubspec.read_text()
text = text.replace('description: Approved MTG tabletop life and counter app.', 'description: 13 Spells fantasy tabletop life and counter app.')
text = text.replace('version: 0.2.0+2', 'version: 0.3.0+3')
text = text.replace('flutter:\n  uses-material-design: true\n', 'flutter:\n  uses-material-design: true\n  assets:\n    - assets/branding/startup.jpg\n')
pubspec.write_text(text)

manifest = Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text()
text = text.replace('android:label="mtg_counter_app"', 'android:label="13 Spells Life Counter"')
manifest.write_text(text)

plist = Path('ios/Runner/Info.plist')
text = plist.read_text()
text = text.replace('<string>mtg_counter_app</string>', '<string>13 Spells Life Counter</string>')
plist.write_text(text)
PY

ICON="assets/branding/app_icon.jpg"
for dir in android/app/src/main/res/mipmap-*; do
  rm -f "$dir/ic_launcher.png" "$dir/ic_launcher.webp" "$dir/ic_launcher.jpg"
  cp "$ICON" "$dir/ic_launcher.jpg"
done

if command -v sips >/dev/null 2>&1; then
  APPICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"
  for file in "$APPICON_DIR"/*.png; do
    width="$(sips -g pixelWidth "$file" | awk '/pixelWidth/ {print $2}')"
    height="$(sips -g pixelHeight "$file" | awk '/pixelHeight/ {print $2}')"
    sips -s format png -z "$height" "$width" "$ICON" --out "$file" >/dev/null
  done
fi

echo "Android and iOS platform shells generated with 13 Spells branding."
