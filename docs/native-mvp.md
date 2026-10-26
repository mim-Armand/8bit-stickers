# Native iMessage MVP

The original Xcode sticker-pack project and all 11 catalog stickers were recovered from `mim-Armand/8bit-stickers` at commit `816eba114d65f5a0182c4ed3bf6dd1c1bd4f9256`. This is a working continuation of that project, not a replacement App Store listing. The current release candidate includes 46 stickers: 10 shipped classics plus 36 new designs, including two APNG animations. All 11 original PNGs remain preserved; the wine-glass sticker was moved to `art/recovered/wine_01.sticker/` and omitted from shipping assets at the owner's request. The latest 24 additions use a true 16×16 source grid for chunky cute characters and meme reactions closer to the original art.

## Identity preserved

| Field | Value |
| --- | --- |
| App Store record | `1366485724` |
| Host bundle ID | `eu.armand.--bit-art` |
| Extension bundle ID | `eu.armand.--bit-art.StickerPackExtension` |
| Recorded development team | `7N3Y4QZT3Z` |
| Current release candidate | `1.2` / `5` |
| Supported device families | iPhone and iPad |
| Deployment target | iOS / iPadOS 15.0 |

The existing release supports iOS 10. Current local Xcode 27.1 rejects deployment targets below iOS 15, so the rebuilt update requires iOS 15 or later. Access to the recorded team and App Store provisioning was verified during preparation; the revised build 5 has a clean signed archive and exported IPA. The preceding build 4 passed Apple validation/upload but has been replaced by build 5 because it includes wine artwork.

## What works in this MVP

- Native sticker-pack extension inside Messages, using Apple's generated `StickerBrowserViewController`.
- Original app icon retained. Ten classics ship; all eleven originals remain preserved in source.
- Thirty-six additional transparent pixel-art stickers: twelve revival designs and twenty-four tiny cute/meme designs, with two animated PNG designs in the revival set.
- Both target version/build values come from the same Xcode build settings.
- Shared build/archive scheme, an unsigned verification script, and GitHub Actions builds.
- `NSStickerSharingLevel = OS`, matching the current Xcode sticker-pack template, to opt into system sticker sharing on supported OS versions. Availability and placement must be verified on devices.
- Explicit privacy manifests in both bundles declaring no tracking, no data collection, and no required-reason API use. The project contains no application code or third-party SDKs.

This remains an iMessage-only app: it has no home-screen window. Search, favorites, and a pixel editor are browser prototype features; they are not in this static native pack.

## Build locally

Open `8 bit art.xcodeproj` in Xcode. To build without signing or Apple account access:

```sh
./scripts/build-ios.sh simulator
./scripts/build-ios.sh device
```

The simulator app is written to `build/ios-simulator/Build/Products/Release-iphonesimulator/8 bit art.app`. The unsigned device app is under `build/ios-device/Build/Products/Release-iphoneos/` and is not an installable distribution build.

To install into a booted simulator, use its explicit device UUID:

```sh
xcrun simctl install SIMULATOR_UUID "$PWD/build/ios-simulator/Build/Products/Release-iphonesimulator/8 bit art.app"
xcrun simctl launch SIMULATOR_UUID com.apple.MobileSMS
xcrun simctl spawn SIMULATOR_UUID pluginkit -m -v -i eu.armand.--bit-art.StickerPackExtension
```

In Messages, open a conversation, tap the plus button, and locate the sticker pack in the app/sticker drawer. In Xcode, the auto-generated `8 bit art StickerPackExtension` scheme can also run with Messages as its host. The shared `8 bit art` scheme builds and archives both targets.

`simctl listapps` and `get_app_container` may omit this hidden host app. Verify the extension using `pluginkit`; absence from the home screen is expected for a sticker-only app.

## Signed release preparation

`./scripts/archive-release.sh` creates the archive and exports an App Store Connect IPA using `Config/ExportOptions.plist`. It reads version/build from `Config/AppStoreMetadata.json` and runs `clean archive`; the current default output is `build/release/1.2-5/`, including `8 bit art.xcarchive` and `export/8 bit art.ipa`. A clean archive prevents removed sticker files from lingering in incremental build products. The two installed App Store profile names and team/bundle identifiers are public configuration; private keys, profile files and archives are not committed.

Version **1.2 (5)** has a clean signed archive and exported IPA. The simulator app, archive and export were checked for the absence of wine assets. Apple validation/upload succeeded with no errors and two expected hidden-app Mac/visionOS compatibility warnings. Build `ecc379bc-4471-489b-887b-826ec30d9c6b` processed as `VALID`, reports `usesNonExemptEncryption: false`, and is selected in the 1.2 draft. It is `READY_FOR_BETA_TESTING` internally and `READY_FOR_BETA_SUBMISSION` externally; no completed TestFlight device pass is claimed.

The preceding **1.2 (4)** passed Apple validation/upload with no errors and two expected compatibility warnings: this iMessage-only hidden app cannot launch as a normal app on Apple silicon Macs or Apple Vision Pro. Its processed build is valid, but it is not the intended release because it contains wine artwork.

Draft version `7c6caa34-4ee8-4423-87d9-e4acc09b1b40` remains **Prepare for Submission** with **manual release**. The no-collected-data App Privacy answer is saved as a draft; Publish has not been pressed. Six actual native iPhone/iPad screenshots were captured for build 5's 46-sticker set and staged as twelve placements across four App Store/iMessage sets. Every placement processed as `COMPLETE`, with no upload errors; legacy 2018 images were removed only from the editable 1.2 draft, leaving published 1.1 assets untouched. No App Review submission or public app release has occurred.

## Verification recorded October 26, 2026

- Xcode 27.1 (`27A9275`).
- The initial 47-sticker source passed unsigned simulator/device builds and rendered in the iOS 17.5 Messages picker.
- The revised 46-sticker candidate passed a clean simulator build and clean signed device archive/export, with wine absent from the shipping products.
- The initial expanded pack installed on an iOS 27.0 iPhone 17 simulator; `pluginkit` reported the extension registered as version 1.2.
- Messages launched successfully.
- Six RGB screenshots of the actual 46-sticker native picker were captured on iOS/iPadOS 17.5: three iPhone 1179×2556 images and three iPad 2064×2752 images. All twelve App Store/iMessage placements are `COMPLETE`.
- Build 5 passed Apple validation/upload, processed as `VALID` and replaced build 4 as the selected release candidate. Wine is excluded from its simulator/archive/export products.

Unsigned compilation, simulator rendering and processed-build acceptance do not establish real-device/TestFlight behavior or App Review acceptance. An optional real-device/TestFlight pass can still cover tapping a sticker, dragging it onto a message, animation playback, appearance in light/dark mode, and iPad layouts. No completed physical-device pass is claimed.

## Before shipping

The existing record, identifiers, team, version/build and signing path are verified. App Store copy, support/privacy URLs, review notes and age-rating answers were staged and read back. Removing wine from the shipping set and declaring alcohol references `NONE` produces API age rating `FOUR_PLUS`, with no override. Public [support](https://mim-armand.github.io/8bit-stickers/support/) and [privacy](https://mim-armand.github.io/8bit-stickers/privacy/) pages are live on GitHub Pages; the interactive Studio remains localhost only.

The release candidate, metadata and screenshots are staged and verified. Publishing the saved App Privacy draft and submitting 1.2 for App Review await final approval. Optional physical-device/TestFlight checks can still exercise sending, placement, animations and upgrade behavior; they are not represented as already completed. See [release-checklist.md](release-checklist.md). Review the provenance of recovered legacy art before redistribution; the new art has editable source. The app has been uploaded, but not submitted for App Review or publicly released.

References: [Apple Messages framework](https://developer.apple.com/documentation/messages), [Apple iMessage development](https://developer.apple.com/imessage/), [NSStickerSharingLevel](https://developer.apple.com/documentation/bundleresources/information-property-list/nsstickersharinglevel), [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).
