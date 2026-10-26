#!/bin/bash
set -euo pipefail

# Capture the actual Messages sticker UI. This never sends a message.
# Requires a booted iOS 17.5 simulator with Apple's default John Appleseed fixture.
# Usage: PYTHON_BIN=/path/to/python scripts/capture-release-screenshots.sh UUID iphone-6.1
capture_uuid="${1:?Pass a booted simulator UUID}"
capture_family="${2:?Pass iphone-6.1 or ipad-13}"
case "$capture_family" in
  iphone-6.1|ipad-13) ;;
  *) echo 'Expected screenshot family: iphone-6.1 or ipad-13' >&2; exit 2 ;;
esac
capture_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
capture_python="${PYTHON_BIN:-python3}"
capture_work="$capture_root/build/release-capture/$capture_family-$(date +%Y%m%d%H%M%S)"
capture_output="$capture_root/release/screenshots/$capture_family"
mkdir -p "$capture_work/Tests" "$capture_output"
"$capture_python" -c 'from PIL import Image'
xcrun simctl install "$capture_uuid" "$capture_root/build/ios-simulator/Build/Products/Release-iphonesimulator/8 bit art.app"
xcrun simctl status_bar "$capture_uuid" override --time '9:41' --batteryState charged --batteryLevel 100 --wifiMode active --wifiBars 3 --dataNetwork wifi

cat > "$capture_work/project.yml" <<'YAML'
name: ReleaseCapture
settings:
  base:
    IPHONEOS_DEPLOYMENT_TARGET: '17.0'
    SWIFT_VERSION: '5.0'
    GENERATE_INFOPLIST_FILE: YES
targets:
  ReleaseCaptureTests:
    type: bundle.ui-testing
    platform: iOS
    sources: [Tests]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: eu.armand.releasecapture.tests
schemes:
  ReleaseCapture:
    build:
      targets:
        ReleaseCaptureTests: all
    test:
      targets: [ReleaseCaptureTests]
YAML
cat > "$capture_work/Tests/ReleaseCaptureTests.swift" <<'SWIFT'
import XCTest

final class ReleaseCaptureTests: XCTestCase {
    let messages = XCUIApplication(bundleIdentifier: "com.apple.MobileSMS")
    override func setUp() { continueAfterFailure = false }

    func test01Collection() {
        messages.launch()
        XCTAssertTrue(messages.wait(for: .runningForeground, timeout: 15))
        if messages.buttons["OK"].waitForExistence(timeout: 2) { messages.buttons["OK"].tap() }
        if messages.buttons["Continue"].waitForExistence(timeout: 1) { messages.buttons["Continue"].tap() }
        if messages.collectionViews["ConversationList"].exists {
            let fixture = messages.collectionViews["ConversationList"].cells.matching(NSPredicate(format: "label CONTAINS %@", "+1 (888) 555-1212")).firstMatch
            XCTAssertTrue(fixture.exists, "Use Apple's default simulator fixture, never a personal conversation")
            fixture.tap()
        }
        if messages.buttons["Apps"].exists { messages.buttons["Apps"].tap() }
        else if messages.buttons["add"].exists { messages.buttons["add"].tap() }
        if messages.cells["Stickers"].waitForExistence(timeout: 3) { messages.cells["Stickers"].tap() }
        XCTAssertTrue(messages.buttons["8 bit art"].waitForExistence(timeout: 5), "Select the real installed sticker pack")
        messages.buttons["8 bit art"].tap()
        let grabber = messages.buttons["Sheet Grabber"]
        if grabber.exists && grabber.frame.midY > messages.frame.height * 0.3 {
            grabber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1, thenDragTo: point(0.5, 0.15))
        }
    }

    func test02Cute() {
        messages.activate()
        XCTAssertTrue(messages.buttons["8 bit art"].waitForExistence(timeout: 5))
        scrollGallery(times: 2)
        if messages.frame.width < 600 { point(0.5, 0.40).press(forDuration: 0.1, thenDragTo: point(0.5, 0.54)) }
    }

    func test03Memes() {
        messages.activate()
        XCTAssertTrue(messages.buttons["8 bit art"].waitForExistence(timeout: 5))
        scrollGallery(times: 2)
    }

    func point(_ x: Double, _ y: Double) -> XCUICoordinate {
        messages.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }
    func scrollGallery(times: Int) {
        for _ in 0..<times {
            let targetY = messages.frame.width > 600 ? 0.55 : 0.31
            point(0.5, 0.86).press(forDuration: 0.1, thenDragTo: point(0.5, targetY))
        }
    }
}
SWIFT
xcodegen generate --spec "$capture_work/project.yml" --project "$capture_work" > "$capture_work/project-generation.log"
for capture_step in '01:Collection:classics-and-revival' '02:Cute:cute-pixels' '03:Memes:meme-reactions'; do
  IFS=: read -r capture_number capture_method capture_name <<< "$capture_step"
  if ! xcodebuild -quiet test \
    -project "$capture_work/ReleaseCapture.xcodeproj" -scheme ReleaseCapture \
    -destination "id=$capture_uuid" -derivedDataPath "$capture_work/DerivedData" \
    -only-testing:"ReleaseCaptureTests/ReleaseCaptureTests/test${capture_number}${capture_method}" \
    CODE_SIGNING_ALLOWED=NO > "$capture_work/$capture_number.log" 2>&1; then
    tail -60 "$capture_work/$capture_number.log" >&2
    exit 1
  fi
  # simctl preserves native device dimensions; XCTest can round a window by 1px.
  xcrun simctl io "$capture_uuid" screenshot "$capture_work/$capture_number.png"
  "$capture_python" - "$capture_work/$capture_number.png" "$capture_output/$capture_number-$capture_name.png" "$capture_family" <<'PY'
import sys
from PIL import Image
image = Image.open(sys.argv[1]).convert('RGB')
expected = {'iphone-6.1': (1179, 2556), 'ipad-13': (2064, 2752)}[sys.argv[3]]
assert image.size == expected, f'Native capture has unexpected dimensions: {image.size}'
image.save(sys.argv[2], optimize=True)
print(f'Saved {sys.argv[2]}: {image.width}×{image.height}, RGB PNG')
PY
done
echo "Actual native screenshots saved to $capture_output"
