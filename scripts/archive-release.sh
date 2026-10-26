#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
release_version="$(node -p "require('./Config/AppStoreMetadata.json').version")"
release_build="$(node -p "require('./Config/AppStoreMetadata.json').build")"
release_dir="${RELEASE_OUTPUT_DIR:-$PWD/build/release/$release_version-$release_build}"
mkdir -p "$release_dir"
# Requires the existing team's distribution key and the two installed profiles.
# Signing identifiers and profile names are public configuration, not secrets.
xcodebuild clean archive \
  -project '8 bit art.xcodeproj' -scheme '8 bit art' \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$release_dir/8 bit art.xcarchive" \
  -derivedDataPath "$release_dir/DerivedData" \
  CODE_SIGN_IDENTITY="${APPLE_DISTRIBUTION_IDENTITY:-Apple Distribution}" \
  MARKETING_VERSION="$release_version" CURRENT_PROJECT_VERSION="$release_build"
xcodebuild -exportArchive \
  -archivePath "$release_dir/8 bit art.xcarchive" \
  -exportOptionsPlist Config/ExportOptions.plist \
  -exportPath "$release_dir/export"
echo "Signed archive and IPA prepared in $release_dir"
