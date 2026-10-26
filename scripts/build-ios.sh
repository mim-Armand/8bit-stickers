#!/usr/bin/env bash
set -euo pipefail

# Unsigned verification only. No signing, account registration, upload, or release.
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
platform="${1:-simulator}"
case "$platform" in
  simulator) destination='generic/platform=iOS Simulator' ;;
  device) destination='generic/platform=iOS' ;;
  *) printf 'Usage: %s [simulator|device]\n' "$0" >&2; exit 2 ;;
esac

xcodebuild \
  -project '8 bit art.xcodeproj' \
  -scheme '8 bit art' \
  -configuration Release \
  -destination "$destination" \
  -derivedDataPath "$project_root/build/ios-$platform" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO \
  clean build
