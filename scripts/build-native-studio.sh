#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
case "${1:-preview}" in
  preview) studio_scheme='Studio Local'; studio_platform='generic/platform=iOS Simulator';;
  messages) studio_scheme='Studio Messages Local'; studio_platform='generic/platform=iOS Simulator';;
  device) studio_scheme='Studio Messages Local'; studio_platform='generic/platform=iOS';;
  *) printf 'Usage: %s [preview|messages|device]\n' "$0" >&2; exit 2;;
esac
xcodebuild -project NativeStudio/Studio.xcodeproj -scheme "$studio_scheme" \
  -configuration Debug -destination "$studio_platform" \
  -derivedDataPath "$project_root/build/native-studio" \
  CODE_SIGNING_ALLOWED=NO build
