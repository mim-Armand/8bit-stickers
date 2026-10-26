#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
studio_device="${1:?Pass an available simulator UUID from xcrun simctl list devices}"
studio_result="build/native-studio-test-$(date +%Y%m%d%H%M%S).xcresult"
xcodebuild test -project NativeStudio/Studio.xcodeproj -scheme 'Studio Local' \
  -configuration Debug -destination "platform=iOS Simulator,id=$studio_device" \
  -derivedDataPath build/native-studio -resultBundlePath "$studio_result" \
  CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO
