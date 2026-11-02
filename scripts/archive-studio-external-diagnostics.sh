#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
studio_output="${STUDIO_EXTERNAL_DIAGNOSTICS_OUTPUT:-$project_root/build/studio-external-test/1.4.1-13}"
mkdir -p "$studio_output"
# Export supports the authorized named external beta; no upload or review mutation.
xcodebuild clean archive -project NativeStudio/Studio.xcodeproj \
  -scheme 'Studio External Diagnostics' -configuration TestFlightExternalDiagnostics \
  -destination 'generic/platform=iOS' -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -derivedDataPath "$studio_output/DerivedData"
xcodebuild -exportArchive -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -exportOptionsPlist Config/ExportStudioAppStore.plist -exportPath "$studio_output/export"
echo "External diagnostic beta archive/export prepared in $studio_output. Nothing uploaded."
