#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
studio_identity="$(node -p 'const m = require("./Config/StudioAppStoreMetadata.json"); `${m.version}-${m.build}`')"
export_options=Config/ExportStudioAppStore.plist
output_parent=studio-release
archive_settings=(-scheme 'Studio App Store' -configuration AppStore)
if (( $# )); then
  if [[ $# != 3 || $1 != --internal-testflight || ! $2 =~ ^[0-9]+(\.[0-9]+){1,2}$ || ! $3 =~ ^[1-9][0-9]*$ ]]; then
    echo "Usage: $0 [--internal-testflight VERSION BUILD]" >&2
    exit 2
  fi
  studio_identity="$2-$3"
  output_parent=studio-testflight
  export_options=Config/ExportStudioTestFlight.plist
  archive_settings+=("MARKETING_VERSION=$2" "CURRENT_PROJECT_VERSION=$3")
fi
studio_output="${STUDIO_APPSTORE_OUTPUT:-$project_root/build/$output_parent/$studio_identity}"
mkdir -p "$studio_output"
# Use the shipping StoreKit configuration for both release and internal TestFlight.
xcodebuild clean archive -project NativeStudio/Studio.xcodeproj \
  "${archive_settings[@]}" \
  -destination 'generic/platform=iOS' -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -derivedDataPath "$studio_output/DerivedData"
xcodebuild -exportArchive -archivePath "$studio_output/8 bit art Studio.xcarchive" \
  -exportOptionsPlist "$export_options" -exportPath "$studio_output/export"
echo "Archive/export prepared in $studio_output using $export_options."
