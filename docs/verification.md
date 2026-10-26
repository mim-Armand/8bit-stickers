# Verification — October 26, 2026

## Native pack

Xcode 27.1 (27A9275) built both the simulator and device Release configurations without signing. The final builds include all 47 entries and two animated PNGs, with no warnings or errors in either build. The parent and extension identifiers match the recovered project. All eleven original sticker PNGs are byte-identical to the recovered commit `816eba1`. The initial twelve revival designs are also byte-identical to commit `423256b` in both their native and browser copies.

The final 47-sticker app installed into an iOS 27.0 iPhone 17 simulator; `pluginkit` confirmed `eu.armand.--bit-art.StickerPackExtension` version 1.2 registered in Messages. Messages launched successfully. Apple supplies the sticker browser runtime for this catalog-only extension.

See [native MVP](native-mvp.md) for build commands and manual checks. A compiled unsigned device bundle is not a signed distribution archive. Current team access, App Store build-number availability, installation over the published app, real-device send/place behavior, animation playback, iPad layouts, TestFlight and App Review are still release checks.

## Artwork

`scripts/generate-art.py` validates generated images as RGBA with transparent pixels, 300×300 dimensions, and each below 500 KB. The expanded collection contains 36 generated designs: 12 revival designs and 24 cute/meme designs on a true 16×16 source grid. The expanded set passes source-pixel and animation-timing checks for both native and browser exports. The heart contains four APNG frames and the robot three. Native generated files are 895–4,419 bytes each. Regeneration was checked twice byte-for-byte in the local Pillow 12.3.0 environment. Pixel sources and palettes are committed alongside exports. The latest twenty-four PNGs retain a 16×16 logical grid, enlarged 18× to 288×288 and centered in a transparent 300×300 native canvas; no smoothing or white rim is added.

`scripts/verify-art.py` compares every decoded native/browser frame and animation duration directly to the editable source. This is the cross-platform integrity check: PNG compression bytes differ between the local macOS encoder and GitHub's Linux encoder even when decoded pixels are identical.

## Browser Studio

`scripts/verify-preview.cjs` passed for the expanded 47-sticker source against the local server using Playwright and installed Google Chrome. The checks cover:

- All 47 catalog image paths decode, and no JavaScript errors or failed HTTP responses occur.
- New/original/animated/theme filters, the 24-sticker tiny collection, 12 Cute and 12 Memes filters, text search and empty-state reset.
- Favorites survive a reload; local conversation preview updates to the chosen sticker.
- The original PNG downloads with its correct filename; a tiny source PNG downloads at its actual 16×16 resolution.
- Pixel drawing, erasing, flood fill, undo, draft persistence and remixing work.
- Pixel export produces a 300×300 RGBA PNG; the export canvas is transparent before drawing.
- Collection and editor fit a 390-pixel viewport without horizontal overflow.

Reviewed screenshots: `studio-desktop.png`, `studio-mobile.png`, `pixel-lab-desktop.png` and `pixel-lab-mobile.png` under `docs/previews/`. These show browser prototypes, not App Store screenshots of shipped iOS functionality.

The Studio is served locally, has no service API calls and uses local browser storage. It has not been deployed as a public website. Browser storage can be cleared or disabled; downloaded artwork and committed source remain separate from drafts.
