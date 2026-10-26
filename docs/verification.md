# Verification — October 26, 2026

## Development art expansion — 1.3 (6)

The current source contains **60 stickers**, including fourteen new meme-inspired 16×16 designs and four 67 variations. `scripts/verify-art.py` passed for all fifty generated designs: raw/native/browser pixels and animation timing match editable sources, all exports have transparency and remain below 500 KB, and the 38 tiny sprites retain their logical 16×16 grid with at most six opaque colors and no rim. A separate review confirmed that the preceding 36 generated designs retain their pixels/timing and ten classics remain byte-identical.

Clean unsigned **simulator and device Release builds passed** under Xcode 27.1. Both built extension bundles contain exactly sixty sticker PNGs, exclude wine, and agree with the parent app on **version 1.3, build 6**. The new set has not been signed, uploaded, submitted or tested on a physical device. Logs are ignored `build/meme-expansion-simulator.log` and `build/meme-expansion-device.log`.

The full Playwright Studio check passed with installed Google Chrome: sixty images decode, the tiny filter has 38 designs, Cute has twelve, Memes has twenty-six, and `67`, `6 7` and `six seven` each find all four new number-themed stickers. Favorites, downloads, chat preview, editor tools, draft persistence, remixing and desktop/mobile layouts passed without browser or HTTP errors. Updated screenshots are under `docs/previews/`; the fourteen-art contact sheet is `meme-expansion-board.png`.

The submitted **1.2 (5)** remains unchanged at `v1.2-build5-submitted`. Its metadata is copied verbatim to `release/1.2-build5-metadata.json`; `release/release-status.json` and `release/screenshots/manifest.json` remain byte-identical to the submitted record and still describe forty-six stickers. The active `Config/AppStoreMetadata.json` is now a local 1.3 (6) draft. No App Store Connect or public website mutation was performed for this expansion. The sections below preserve the earlier release's evidence.

## Native pack

The initial expanded source passed unsigned simulator/device Release builds under Xcode 27.1 (27A9275), with 47 entries and two APNGs. At the owner's request, the wine-glass sticker was then omitted from shipping assets, producing release candidate **1.2 (5)** with **46 stickers: 10 classics and 36 new designs**. The revised candidate passed a clean simulator build and clean signed device archive/export, with wine absent from those products. The parent and extension identifiers match the recovered project. All eleven original sticker PNGs are preserved byte-identically to recovered commit `816eba1`; ten ship and wine is archived at `art/recovered/wine_01.sticker/`. The initial twelve revival designs are also byte-identical to commit `423256b` in both their native and browser copies.

The initial 47-sticker app installed into an iOS 27.0 iPhone 17 simulator; `pluginkit` confirmed `eu.armand.--bit-art.StickerPackExtension` version 1.2 registered in Messages. Messages launched successfully. Apple supplies the sticker browser runtime for this catalog-only extension.

The pack also rendered in the iOS 17.5 native Messages sticker picker. The current iOS 27 simulator fixture omitted the system Stickers entry itself; comparison against Xcode 27.1's templates found matching product types, principal class and sharing keys. Registration alone was not treated as proof of rendering.

See [native MVP](native-mvp.md) for build commands. Installation over the published app, real-device send/place behavior, animation playback, iPad layouts, TestFlight use and App Review remain separate checks.

## Signed build and App Store staging

The owning team and distribution signing path were verified. The revised **1.2 (5)** candidate has a clean signed archive and exported IPA under ignored `build/release/1.2-5/`. Apple validation/upload succeeded without errors and with two expected hidden-app Mac/visionOS compatibility warnings. Delivery UUID: `ecc379bc-4471-489b-887b-826ec30d9c6b`; ignored evidence is `build/release/apple-validation-build5.json` and `apple-upload-build5.json`. Build 5 processed as `VALID` and is selected in the 1.2 draft. It reports `usesNonExemptEncryption: false`, `READY_FOR_BETA_TESTING` internally and `READY_FOR_BETA_SUBMISSION` externally. No completed TestFlight device pass is claimed. A stale wine file was caught in an incremental build product, so release preparation now uses a clean archive and explicitly verifies wine is absent from the simulator bundle, archive and IPA.

The preceding **1.2 (4)** passed Apple's validation/upload with zero errors, then processed as `VALID`. Its two expected compatibility warnings concerned the hidden sticker-only app being unlaunchable as a normal Mac or visionOS app. Build 4 is not the intended release because it contains wine. Build 5 replaced it as the selected build in version `7c6caa34-4ee8-4423-87d9-e4acc09b1b40`, which now reports **Waiting for Review** with release type **`AFTER_APPROVAL`**.

The revised description, keywords, promotional text, support/privacy URLs and review notes were saved and read back through the API. Evidence is ignored `build/release/draft-metadata-readback.json`. Existing App Review contact details remain private. Removing wine and declaring alcohol references `NONE` produces API age rating `FOUR_PLUS` without an override.

Six actual native screenshots were captured for build 5's 46-sticker pack: three iPhone RGB images at 1179×2556 and three iPad RGB images at 2064×2752. The source manifest is `release/screenshots/manifest.json`, with `nativePackBuild: 5`, `stickerCount: 46` and `wineExcluded: true`. The same six images form twelve placements across `APP_IPHONE_61`, `IMESSAGE_APP_IPHONE_61`, `APP_IPAD_PRO_3GEN_129` and `IMESSAGE_APP_IPAD_PRO_3GEN_129`; all processed as `COMPLETE`, with no errors. Ignored readback evidence is `build/release/screenshot-upload-readback.json`. Legacy 2018 placements were removed only from draft 1.2; published 1.1 sets/assets were protected.

The **Data Not Collected** App Privacy label was published through the App Store Connect UI, which showed “Published a few seconds ago by mim Armand”; evidence is ignored `build/submission/privacy-published.jpg`. Review submission `d6780537-3c51-43b3-97d9-67f900dfc768` was submitted at `2026-10-26T20:01:02.003Z` / October 26, 2026, **3:01 PM CDT**. API readback verified both the submission and version as `WAITING_FOR_REVIEW`, release type `AFTER_APPROVAL` and selected build 5 unchanged. Evidence is ignored `build/submission/review-submitted.json` and `final-readback.json`; public fields are recorded in [`release/release-status.json`](../release/release-status.json). The update has not yet been approved or publicly released. A physical-device/TestFlight pass remains optional; simulator capture and processed-build acceptance do not establish that testing.

## Public support website

The app page, support instructions and privacy policy are live at `https://mim-armand.github.io/8bit-stickers/`, `/support/` and `/privacy/`. All three returned HTTP 200, the GitHub Pages build completed, and HTTPS enforcement is enabled. The published `gh-pages` source is commit `30355ecd03d7b135b002f614803367d73eb3c805`. The public homepage now describes 46 stickers, and all three pages were rechecked with HTTP 200 responses after that update.

This deployment contains only the app/support/privacy site. It does not publish the interactive Sticker Studio or its pixel editor.

## Artwork

`scripts/generate-art.py` validates generated images as RGBA with transparent pixels, 300×300 dimensions, and each below 500 KB. The expanded collection contains 36 generated designs: 12 revival designs and 24 cute/meme designs on a true 16×16 source grid. The expanded set passes source-pixel and animation-timing checks for both native and browser exports. The heart contains four APNG frames and the robot three. Native generated files are 895–4,419 bytes each. Regeneration was checked twice byte-for-byte in the local Pillow 12.3.0 environment. Pixel sources and palettes are committed alongside exports. The latest twenty-four PNGs retain a 16×16 logical grid, enlarged 18× to 288×288 and centered in a transparent 300×300 native canvas; no smoothing or white rim is added.

`scripts/verify-art.py` compares every decoded native/browser frame and animation duration directly to the editable source. This is the cross-platform integrity check: PNG compression bytes differ between the local macOS encoder and GitHub's Linux encoder even when decoded pixels are identical.

## Browser Studio

The initial expanded 47-sticker source passed `scripts/verify-preview.cjs` against the local server using Playwright and installed Google Chrome. The revised gallery contains 46 stickers because wine is omitted. The prior Studio checks covered:

- All original expanded catalog image paths decode, and no JavaScript errors or failed HTTP responses occur.
- New/original/animated/theme filters, the 24-sticker tiny collection, 12 Cute and 12 Memes filters, text search and empty-state reset.
- Favorites survive a reload; local conversation preview updates to the chosen sticker.
- The original PNG downloads with its correct filename; a tiny source PNG downloads at its actual 16×16 resolution.
- Pixel drawing, erasing, flood fill, undo, draft persistence and remixing work.
- Pixel export produces a 300×300 RGBA PNG; the export canvas is transparent before drawing.
- Collection and editor fit a 390-pixel viewport without horizontal overflow.

Reviewed screenshots: `studio-desktop.png`, `studio-mobile.png`, `pixel-lab-desktop.png` and `pixel-lab-mobile.png` under `docs/previews/`. These show browser prototypes, not App Store screenshots of shipped iOS functionality.

The Studio is served locally, has no service API calls and uses local browser storage. It has not been deployed as a public website. Browser storage can be cleared or disabled; downloaded artwork and committed source remain separate from drafts.
