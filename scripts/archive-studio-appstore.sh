#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
studio_identity="$(node -p 'const m = require("./Config/StudioAppStoreMetadata.json"); `${m.version}-${m.build}`')"
studio_output="${STUDIO_APPSTORE_OUTPUT:-$project_root/build/studio-release/$studio_identity}"
mkdir -p "$studio_output"
# Signed App Store eligible release candidate. This helper archives/exports locally and never uploads.
xcodebuild clean archive -project NativeStudio/Studio.xcodeproj \
  -scheme 'Studio App Store' -configuration AppStore \
  -destination 'generic/platform=iOS' -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -derivedDataPath "$studio_output/DerivedData"
xcodebuild -exportArchive -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -exportOptionsPlist Config/ExportStudioAppStore.plist -exportPath "$studio_output/export"
echo "App Store eligible archive/export prepared in $studio_output. Nothing uploaded."
