# Verification — October 26, 2026

## Native pack

Xcode 27.1 (27A9275) built both the simulator and device Release configurations without signing. Both include the catalog's 23 entries, including the two animated PNGs. The parent and extension identifiers match the recovered project. All eleven original sticker PNGs are byte-identical to the recovered commit `816eba1`.

The app installed into an iOS 27.0 iPhone 17 simulator; `pluginkit` confirmed `eu.armand.--bit-art.StickerPackExtension` version 1.2 registered in Messages. Apple supplies the sticker browser runtime for this catalog-only extension.

See [native MVP](native-mvp.md) for build commands and manual checks. A compiled unsigned device bundle is not a signed distribution archive. Current team access, App Store build-number availability, installation over the published app, real-device send/place behavior, animation playback, iPad layouts, TestFlight and App Review are still release checks.

## Artwork

`scripts/generate-art.py` validates all twelve generated images: RGBA with transparent pixels, 300×300 dimensions, and each below 500 KB. The heart contains four APNG frames and the robot three. Generated files are about 1–5 KB each. Regeneration was checked twice byte-for-byte in the local Pillow 12.3.0 environment. Pixel sources and the palette are committed alongside exports.

## Browser Studio

`scripts/verify-preview.cjs` passed against the local server using Playwright and installed Google Chrome. It checks:

- All 23 catalog image paths decode, and no JavaScript errors or failed HTTP responses occur.
- New/original/animated/theme filters, text search and empty-state reset.
- Favorites survive a reload; local conversation preview updates to the chosen sticker.
- The original PNG downloads with its correct filename.
- Pixel drawing, erasing, flood fill, undo, draft persistence and remixing work.
- Pixel export produces a 300×300 RGBA PNG; the export canvas is transparent before drawing.
- Collection and editor fit a 390-pixel viewport without horizontal overflow.

Reviewed screenshots: `studio-desktop.png`, `studio-mobile.png`, `pixel-lab-desktop.png` and `pixel-lab-mobile.png` under `docs/previews/`. These show browser prototypes, not App Store screenshots of shipped iOS functionality.

The Studio is served locally, has no service API calls and uses local browser storage. It has not been deployed as a public website. Browser storage can be cleared or disabled; downloaded artwork and committed source remain separate from drafts.
