#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
studio_output="${STUDIO_TESTFLIGHT_OUTPUT:-$project_root/build/studio-testflight/1.4-8}"
mkdir -p "$studio_output"
# Signed internal beta only. This helper archives/exports locally and never uploads.
xcodebuild clean archive -project NativeStudio/Studio.xcodeproj \
  -scheme 'Studio TestFlight Internal' -configuration TestFlight \
  -destination 'generic/platform=iOS' -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -derivedDataPath "$studio_output/DerivedData"
xcodebuild -exportArchive -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -exportOptionsPlist Config/ExportStudioTestFlight.plist -exportPath "$studio_output/export"
echo "Internal-only TestFlight archive/export prepared in $studio_output. Nothing uploaded."
