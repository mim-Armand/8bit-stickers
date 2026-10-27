#!/usr/bin/env bash
set -euo pipefail
# Actual Messages UI, public Studio copy, verified local Xcode StoreKit purchase.
# The Screenshots configuration is excluded from App Store distribution.
# Use a fresh dedicated simulator; this harness never deletes existing drawings.
capture_uuid="${1:?Pass a booted iOS simulator UUID}"
capture_family="${2:?Pass iphone-6.1 or ipad-13}"
case "$capture_family" in
  iphone-6.1|ipad-13) ;;
  *) echo 'Expected iphone-6.1 or ipad-13' >&2; exit 2 ;;
esac
capture_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$capture_root"
capture_python="${PYTHON_BIN:-python3}"
capture_derived="${STUDIO_CAPTURE_DERIVED:-$capture_root/build/studio-release/CaptureDerived}"
capture_work="$capture_root/build/studio-release/capture-$capture_family-$(date +%Y%m%d%H%M%S)"
mkdir -p "$capture_work"
"$capture_python" -c 'from PIL import Image'
"$capture_python" -u - "$capture_uuid" "$capture_work/native" <<'PYBRIDGE' > "$capture_work/bridge.log" 2>&1 &
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import json, subprocess, sys
uuid, destination = sys.argv[1], Path(sys.argv[2])
destination.mkdir(parents=True, exist_ok=True)
names = {'01-free-stickers', '02-six-seven-reactions', '03-pixel-studio', '04-saved-drafts', 'review-studio-unlock'}
class Capture(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != '/capture' or self.headers.get('Origin') or self.headers.get('X-Studio-Capture') != 'native-simctl':
            self.send_error(403); return
        length = int(self.headers.get('Content-Length', '0'))
        if not 0 < length < 256:
            self.send_error(400); return
        try:
            name = json.loads(self.rfile.read(length))['name']
            if name not in names: raise ValueError('Unknown capture')
            subprocess.run(['/usr/bin/xcrun','simctl','io',uuid,'screenshot',str(destination/(name+'.png'))],check=True,capture_output=True,timeout=20)
        except Exception:
            self.send_error(500); return
        self.send_response(200); self.end_headers(); self.wfile.write(b'OK')
HTTPServer(('127.0.0.1',8793),Capture).serve_forever()
PYBRIDGE
capture_server_pid=$!
trap 'kill "$capture_server_pid" 2>/dev/null || true' EXIT
"$capture_python" - <<'PYREADY'
import socket,time
for _ in range(50):
    try:
        with socket.create_connection(('127.0.0.1',8793),timeout=1): break
    except OSError: time.sleep(.1)
else: raise SystemExit('Native capture bridge did not start')
PYREADY
xcodebuild build -project NativeStudio/Studio.xcodeproj -scheme 'Studio Messages Local' \
  -configuration Screenshots -destination "platform=iOS Simulator,id=$capture_uuid" \
  -derivedDataPath "$capture_derived" CODE_SIGNING_ALLOWED=NO > "$capture_work/build.log" 2>&1
xcrun simctl install "$capture_uuid" "$capture_derived/Build/Products/Screenshots-iphonesimulator/8 bit art.app"
xcrun simctl status_bar "$capture_uuid" override --time '9:41' --batteryState charged --batteryLevel 100 --wifiMode active --wifiBars 3 --dataNetwork wifi
if ! xcodebuild test -project NativeStudio/Studio.xcodeproj -scheme 'Studio Release Capture' \
  -configuration Screenshots -destination "platform=iOS Simulator,id=$capture_uuid" \
  -derivedDataPath "$capture_derived" -resultBundlePath "$capture_work/capture.xcresult" \
  CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO > "$capture_work/test.log" 2>&1; then
  tail -60 "$capture_work/test.log" >&2
  exit 1
fi
xcrun xcresulttool export attachments --path "$capture_work/capture.xcresult" --output-path "$capture_work/attachments"
"$capture_python" - "$capture_work/native" "$capture_family" "$capture_uuid" "$capture_work/capture.xcresult" <<'PY'
from pathlib import Path
from PIL import Image
import datetime, hashlib, json, sys
source, family, uuid, result = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
output = Path('release/studio-1.4/screenshots')
expected = {'iphone-6.1': (1179, 2556), 'ipad-13': (2064, 2752)}[family]
names = ['01-free-stickers', '02-six-seven-reactions', '03-pixel-studio', '04-saved-drafts', 'review-studio-unlock']
assets = []
for name in names:
    raw = source / (name+'.png')
    assert raw.exists(), name
    image = Image.open(raw).convert('RGB')
    assert image.size == expected, (name, image.size, expected)
    target = output / (f'iap-review-{family}.png' if name.startswith('review-') else f'{family}/{name}.png')
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, optimize=True)
    assets.append({'name': name, 'path': str(target), 'size': list(image.size), 'mode': 'RGB', 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(), 'purpose': 'iap-review' if name.startswith('review-') else 'app-store'})
log = (Path(result).parent/'test.log').read_text()
assert 'CAPTURE_CHECKOUT_UI_COMPLETED' in log
checkout = 'UI-initiated verified Xcode transaction completed'
manifest = {'checkoutEvidence': checkout, 'capturedAtUTC': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'appID': '1366485724', 'hostBundleID': 'eu.armand.--bit-art', 'extensionBundleID': 'eu.armand.--bit-art.StickerPackExtension', 'version': '1.4', 'build': '10', 'deviceFamily': family, 'simulatorUUID': uuid, 'configuration': 'Screenshots', 'captureSource': 'simctl native physical screen requested by capture-only local test bridge; no padding/resizing', 'context': 'Actual custom extension inside Messages, Apple simulator fictional conversation fixture', 'purchaseFixture': 'Verified Xcode StoreKit transaction for eu.armand.bitart.studio.unlock; no entitlement bypass', 'publicUICopy': True, 'stickerCount': 67, 'templates': 45, 'wineExcluded': True, 'messageSent': False, 'resultBundle': str(Path(result).relative_to(Path.cwd())), 'assets': assets}
(output / family / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
all_families = [json.loads(p.read_text()) for p in sorted(output.glob('*/manifest.json'))]
(output/'manifest.json').write_text(json.dumps({'appID':'1366485724','version':'1.4','build':'10','families':all_families},indent=2)+'\n')
print(f'Saved {len(assets)} native RGB captures for {family}.')
PY
