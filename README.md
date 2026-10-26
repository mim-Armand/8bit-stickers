# 8 bit art

The 2018 iMessage sticker pack is recovered and back in development. This repository preserves its Git history, Xcode project, original icons and eleven original stickers. The revival now adds 36 editable designs, including **24 cute and meme reactions drawn on a true 16×16 grid**, two animations, an unsigned native build, and a working local Sticker Studio.

![Cute 16×16 pixel art](docs/previews/cute-art-board.png)

![Meme 16×16 pixel art](docs/previews/meme-art-board.png)

## Try the two MVPs

**iMessage pack — version 1.2 (5), submitted for App Review.** Apple reports **Waiting for Review**, with **automatic release after approval** selected. The clean signed archive and IPA passed Apple validation/upload with no errors. Build 5 processed as `VALID` and remains selected. Six actual native screenshots have twelve `COMPLETE` placements across iPhone/iPad App Store and iMessage wells.

The **Data Not Collected** App Privacy label was published on October 26, 2026. Version 1.2 (5) was submitted at **3:01 PM CDT**; it has not yet been approved or publicly released. Verified IDs and release evidence are recorded in [release status](release/release-status.json).

Open `8 bit art.xcodeproj` in Xcode and select the shared **8 bit art** scheme. The native pack contains **46 stickers**, including a pulsing heart and blinking robot. It keeps the original bundle identifiers and icon and requires iOS/iPadOS 15 or later.

```sh
./scripts/build-ios.sh simulator
./scripts/build-ios.sh device
```

These verification builds do not use signing credentials. For simulator installation and the distribution path, see [the native guide](docs/native-mvp.md).

The signed release can be rebuilt with `./scripts/archive-release.sh` using the installed distribution identity/profiles and public settings in `Config/ExportOptions.plist`. Signing keys and build output remain outside Git.

**Sticker Studio — local browser prototype.** Browse all stickers, filter themes, search, save favorites, try a local conversation preview, and download original PNG/APNG files. The Pixel Lab supports drawing, erasing, flood fill, undo, remixing a sticker and downloading a transparent 300×300 PNG. Favorites and one draft persist in local browser storage when available. The canvas supports pointer/touch input and keyboard arrows + Space; `P`, `E`, `F` switch tools.

```sh
./scripts/start-preview.sh
```

Open **http://127.0.0.1:8787/prototype/**. Python 3 is the only runtime needed to serve the Studio. No npm install, account, API key or external service is needed. Stop the preview server with Ctrl+C. Bind only to localhost as the script does; it serves the repository to that local browser.

The Studio is a working product experiment. Search, favorites, chat previews and the editor are **not bundled into the native sticker pack**. It does not send messages or install exported art into Messages automatically. Editing animation loads one frame and exports a static PNG.

The [public app/support site](https://mim-armand.github.io/8bit-stickers/), [support page](https://mim-armand.github.io/8bit-stickers/support/) and [privacy policy](https://mim-armand.github.io/8bit-stickers/privacy/) are now hosted on **GitHub Pages**. The interactive Studio is **not** published there; it remains localhost only. The [Studio product plan](docs/studio-product-plan.md) recommends adding a native Studio **inside Messages** in a future update to this same listing. Apple's app-type rules require a new app record for a full home-screen Studio app.

![Sticker Studio](docs/previews/studio-desktop.png)

## Art you can keep editing

`art/sprites.json`, `art/cute-sprites.json` and `art/meme-sprites.json` contain palette-based pixel commands. The latest two collections use a 16×16 canvas, dark outlines and limited colors with no white rim. `scripts/generate-art.py` generates native catalog additions, browser assets, raw PNGs in `art/pixels/`, animation frames and review boards. All eleven recovered images remain unchanged as source. Ten classics ship; the wine-glass original is retained under `art/recovered/wine_01.sticker/` and excluded from the app and Studio gallery at the owner's request.

The tiny PNGs are truly 16×16. Native 300×300 sticker exports use integer 18× enlargement with six pixels of transparent padding; no smoothing or added detail is introduced. Open a tiny sticker in Studio to download either size.

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements-art.txt
.venv/bin/python scripts/generate-art.py
python3 scripts/build-preview.py
```

Read [the art guide](art/README.md) for the editable source format and provenance. The new tiny collection includes frog, bunny, cat, puppy, toast, boba, duck, penguin, sleepy bear, dumpling, mushroom and capybara, alongside side-eye, bruh, melting, crying-laughing, sus, heart-eyes and other meme reactions. The previous twelve revival designs remain included. Existing art was recovered as-is; review its provenance before publishing a new release.

## Verification

The initial expanded pack passed simulator/device builds and rendered in the iOS 17.5 Messages picker. The revised 46-sticker candidate passed a clean simulator build and clean signed device archive/export under Xcode 27.1; the final archive/export was checked for the absence of wine assets. Browser checks cover assets, filters, persistence, chat previews, downloads, editor tools, undo, PNG dimensions/transparency format, remixing and mobile layout. Details and release limitations are in [verification notes](docs/verification.md).

Optional browser checks, with the preview server already running:

```sh
npm ci
npx playwright install chromium
npm run test:preview
```

To use an installed Google Chrome instead, run `PLAYWRIGHT_CHANNEL=chrome npm run test:preview`. Tests save review screenshots to `docs/previews/` and an example export under ignored `build/`.

## Releasing the existing app

The published app is **8 bit art, Apple ID 1366485724**, bundle ID **`eu.armand.--bit-art`**. The similarly named unpublished **8-bit art, ID 1366403490**, is a separate record. Update the published record.

The published release is 1.1. The recovered source was already marked 1.2 (3), so its exact correspondence to the published binary is unverified. The submitted update is **1.2 (5)** with 46 stickers and API age rating `FOUR_PLUS`. The wine-glass artwork is omitted from shipping assets. Build 5 replaced the earlier build 4 and is now **Waiting for Review**, with automatic release after approval selected.

See the [release checklist](docs/release-checklist.md) for publication/submission evidence and optional device checks; [recovery and roadmap](docs/recovery-and-roadmap.md) covers the update path and backup strategy. [App Store listing](docs/app-store-draft.md) records the submitted copy and live support/privacy URLs. [Monetization options](docs/monetization-options.md) explains a possible paid pack or future Studio purchase; this submission does not add a purchase or change pricing.

## Repository layout

| Path | Purpose |
| --- | --- |
| `8 bit art.xcodeproj` | Recovered, modernized native project |
| `8 bit art StickerPackExtension/` | Original and new sticker catalogs |
| `art/` | Editable new artwork and manifest |
| `prototype/` | Local Studio, with no production dependencies |
| `scripts/` | Native builds, art generation and browser checks |
| `docs/` | Recovery notes, release draft and visual previews |

Commit source, artwork and generated assets together. Keep credentials and build products out of Git. Tag each submitted build and keep an independent repository/archive backup; instructions are in the roadmap. No general open-source or art license has been added; public repository access does not establish reuse rights.

Support: **seltzer.wisdom7h@icloud.com**.
