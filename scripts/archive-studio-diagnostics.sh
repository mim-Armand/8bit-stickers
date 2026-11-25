#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
studio_output="${STUDIO_DIAGNOSTICS_OUTPUT:-$project_root/build/studio-diagnostics/1.4.1-12}"
mkdir -p "$studio_output"
# Signed internal diagnostic beta only. No App Review changes, uploads or fixtures.
xcodebuild clean archive -project NativeStudio/Studio.xcodeproj \
  -scheme 'Studio Diagnostics Internal' -configuration TestFlightDiagnostics \
  -destination 'generic/platform=iOS' -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -derivedDataPath "$studio_output/DerivedData"
xcodebuild -exportArchive -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -exportOptionsPlist Config/ExportStudioTestFlight.plist -exportPath "$studio_output/export"
echo "Internal-only diagnostic archive/export prepared in $studio_output. Nothing uploaded."
