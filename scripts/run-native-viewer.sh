#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
studio_device="${1:?Pass a booted iPhone simulator UUID}"
if curl --fail --silent --max-time 2 http://127.0.0.1:8792/ > /dev/null; then
  echo 'Native viewer is already running: http://127.0.0.1:8792/'
  exit 0
fi
./scripts/build-native-studio.sh preview > build/native-viewer-build.log 2>&1
xcrun simctl install "$studio_device" "$project_root/build/native-studio/Build/Products/Debug-iphonesimulator/StudioLocal.app"
echo 'Starting the local native viewer at http://127.0.0.1:8792/ — allow a moment for XCTest to start.'
echo 'Keep this command running. Ctrl+C stops it; the viewer also expires after one hour.'
xcodebuild test -project NativeStudio/Studio.xcodeproj -scheme 'Studio Browser Preview' \
  -destination "platform=iOS Simulator,id=$studio_device" -derivedDataPath build/native-studio-preview-bridge \
  CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO \
  > build/native-viewer-server.log 2>&1
