# Native iMessage MVP

The original Xcode sticker-pack project and all 11 catalog stickers were recovered from `mim-Armand/8bit-stickers` at commit `816eba114d65f5a0182c4ed3bf6dd1c1bd4f9256`. This is a working continuation of that project, not a replacement App Store listing. The revived pack includes those 11 originals plus 12 new designs, including two APNG animations.

## Identity preserved

| Field | Value |
| --- | --- |
| App Store record | `1366485724` |
| Host bundle ID | `eu.armand.--bit-art` |
| Extension bundle ID | `eu.armand.--bit-art.StickerPackExtension` |
| Recorded development team | `7N3Y4QZT3Z` |
| Proposed version/build | `1.2` / `4` |
| Supported device families | iPhone and iPad |
| Deployment target | iOS / iPadOS 15.0 |

The existing release supports iOS 10. Current local Xcode 27.1 rejects deployment targets below iOS 15, so the rebuilt update requires iOS 15 or later. The team ID is recovered project configuration; current account access and provisioning still need verification before distribution.

## What works in this MVP

- Native sticker-pack extension inside Messages, using Apple's generated `StickerBrowserViewController`.
- Original catalog and original app icon retained.
- Twelve additional transparent pixel-art stickers, with two animated PNG designs.
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

## Verification recorded October 26, 2026

- Xcode 27.1 (`27A9275`).
- Unsigned simulator Release build passed, including compilation of all 23 catalog entries.
- Unsigned device Release build passed.
- Installed on an iOS 27.0 iPhone 17 simulator; `pluginkit` reported the extension registered as version 1.2.
- Messages launched successfully.

Unsigned compilation and simulator installation do not verify App Store provisioning, distribution signing, TestFlight, delivery to another person, or App Review acceptance. A real-device pass must still cover tapping a sticker, dragging it onto a message, animation playback, appearance in light/dark mode, and iPad layouts.

## Before shipping

Confirm the original App Store record, both identifiers, and current development-team access in App Store Connect/Xcode. Inspect the existing build history before choosing a final build number; `4` is a proposed local value. Complete privacy and age-rating questionnaires, publish support/privacy pages, create current Messages screenshots, sign/archive, and test through TestFlight. Review the provenance of recovered legacy art before redistribution; the new art has editable source in this repository.

No signing identity was changed, no identifier was registered, and nothing was uploaded or submitted to Apple during this work.

References: [Apple Messages framework](https://developer.apple.com/documentation/messages), [Apple iMessage development](https://developer.apple.com/imessage/), [NSStickerSharingLevel](https://developer.apple.com/documentation/bundleresources/information-property-list/nsstickersharinglevel), [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).
