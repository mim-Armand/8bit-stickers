# Native App Store screenshot evidence

Captured October 26, 2026 from the actual **46-sticker app, version 1.2 (5)**, in Apple's Messages system Stickers picker. These are native simulator captures, not Studio screens or interface mockups. The recovered wine artwork is retained in source history but is excluded from this shipped catalog and these captures.

| Set | Device / runtime | Native PNG dimensions | Intended iMessage screenshot well |
| --- | --- | --- | --- |
| `release/screenshots/iphone-6.1/` | iPhone 15 Pro / iOS 17.5 | 1179×2556 portrait | `IMESSAGE_APP_IPHONE_61` |
| `release/screenshots/ipad-13/` | iPad Pro 13-inch (M4) / iPadOS 17.5 | 2064×2752 portrait | `IMESSAGE_APP_IPAD_PRO_3GEN_129` |

Each set contains:

1. `01-classics-and-revival.png` — the original stickers and initial revival collection.
2. `02-cute-pixels.png` — the chunky cute collection in the native browser.
3. `03-meme-reactions.png` — the native meme/reaction collection.

The Messages picker is full-height on iPhone and a floating system panel on iPad. Partial rows at the scroll edges are the actual system browser layout. The displayed conversation addresses are Apple's built-in simulator fixtures. No personal conversation content was used, and no messages were sent while capturing these images.

All six deliverables are lossless **RGB PNGs without alpha**. No cropping, resizing, added artwork, captions or UI replacement was applied. `release/screenshots/manifest.json` records dimensions, byte sizes and SHA-256 checksums. The native device dimensions were preserved with `simctl io screenshot`; XCTest attachment screenshots rounded the iPhone window width by one pixel and were therefore excluded from the deliverables.

Apple's current [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) list these dimensions in the corresponding supported classes. Confirm the actual App Store Connect version's wells and any remaining requirements when uploading; these filenames alone do not establish upload acceptance.

## Repeat the capture

The script creates a temporary UI-test project only under ignored `build/`, installs the existing unsigned simulator app and navigates the genuine Messages interface. It does not modify the app project, sign a distribution build or tap Send.

Prerequisites: Xcode, `xcodegen`, Pillow from `requirements-art.txt`, an existing simulator build from `scripts/build-ios.sh simulator`, and booted matching iOS/iPadOS 17.5 simulators with Apple's default John Appleseed conversation fixture. The script fails instead of choosing an arbitrary personal conversation.

```sh
PYTHON_BIN=.venv/bin/python ./scripts/capture-release-screenshots.sh IPHONE_15_PRO_UUID iphone-6.1
PYTHON_BIN=.venv/bin/python ./scripts/capture-release-screenshots.sh IPAD_PRO_13_M4_UUID ipad-13
```

The script verifies exact dimensions and saves the three RGB files into the corresponding `release/screenshots/` directory. Review every recapture visually before uploading. The manifest describes this recorded capture; regenerate its checksums if the PNGs change.

## What this verifies

- The installed native extension is selectable as **8 bit art** in the system Stickers picker on both tested devices.
- The original, revival, cute and meme assets render; the browser expands and scrolls on iPhone and scrolls within the floating iPad picker.
- The final image files have accepted native pixel dimensions and contain actual app UI.

These captures do not verify installation over the published 1.1 app, sending to another person, peel/place behavior, animation timing or physical-device behavior. The separate release checklist remains applicable.

In the existing iOS 27 simulator fixture, the Messages plus menu omitted the system Stickers entry even though both the system picker and this app were registered and indexed. Testing the same pack on iOS 17.5 reached and rendered it without any project configuration change. Treat the missing menu entry as an unresolved property of that simulator environment; verify the release build on a current physical device/TestFlight before distribution.
