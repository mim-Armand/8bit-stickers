#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
studio_mode="${1:-preview}"
case "$studio_mode" in preview|messages) ;; *) printf 'Usage: %s [preview|messages] [simulator UUID]\n' "$0" >&2; exit 2;; esac
studio_device="${2:-${STUDIO_SIMULATOR_ID:-}}"
if [ -z "$studio_device" ]; then
  studio_device="$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; d=[v for a in json.load(sys.stdin)["devices"].values() for v in a if v["state"]=="Booted"]; print(next((v["udid"] for v in d if "iPhone" in v["name"]),d[0]["udid"] if d else ""))')"
fi
if [ -z "$studio_device" ]; then
  echo 'Open an iPhone or iPad simulator in Xcode, then run this command again.' >&2
  exit 1
fi
./scripts/build-native-studio.sh "$studio_mode" > "build/native-studio-run-$studio_mode.log" 2>&1
if [ "$studio_mode" = preview ]; then
  studio_app='StudioLocal.app'; studio_bundle='eu.armand.pixelstudio.local'
else
  studio_app='8 bit art.app'; studio_bundle='com.apple.MobileSMS'
fi
xcrun simctl install "$studio_device" "$project_root/build/native-studio/Build/Products/Debug-iphonesimulator/$studio_app"
xcrun simctl terminate "$studio_device" "$studio_bundle" > /dev/null 2>&1 || true
studio_simulator_app="$(xcode-select -p)/Applications/Simulator.app"
if [ -d "$studio_simulator_app" ]; then
  open -a "$studio_simulator_app" --args -CurrentDeviceUDID "$studio_device"
else
  echo "Simulator window unavailable. Use scripts/run-native-viewer.sh $studio_device for the browser viewer."
fi
xcrun simctl launch "$studio_device" "$studio_bundle"
echo 'Local test only. No real charges, upload, or App Store submission.'
