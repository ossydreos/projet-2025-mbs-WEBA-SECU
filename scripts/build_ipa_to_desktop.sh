#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESKTOP="$HOME/Desktop"
cd "$PROJECT_DIR"
if ! xcrun xcodebuild -version >/dev/null 2>&1; then
  echo "Xcode not fully installed. Install Xcode, then run:"
  echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
  echo "  sudo xcodebuild -runFirstLaunch"
  exit 1
fi
flutter clean
flutter pub get
pushd ios >/dev/null
pod install --repo-update
popd >/dev/null
flutter build ipa
IPA_PATH=$(find build -type f -name "*.ipa" | head -n 1)
if [[ -z "${IPA_PATH:-}" ]]; then
  echo "No IPA produced. Check build logs." >&2
  exit 1
fi
mkdir -p "$DESKTOP"
cp -f "$IPA_PATH" "$DESKTOP/"
echo "Copied $(basename "$IPA_PATH") to $DESKTOP"
