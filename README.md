# 8 bit art

The 2018 iMessage sticker pack is recovered and back in development. This repository preserves its Git history, Xcode project, original icons and eleven original stickers. The revival now adds 36 editable designs, including **24 cute and meme reactions drawn on a true 16×16 grid**, two animations, an unsigned native build, and a working local Sticker Studio.

![Cute 16×16 pixel art](docs/previews/cute-art-board.png)

![Meme 16×16 pixel art](docs/previews/meme-art-board.png)

## Try the two MVPs

**iMessage pack — proposed version 1.2 (4).** Open `8 bit art.xcodeproj` in Xcode and select the shared **8 bit art** scheme. The native pack contains **47 stickers**, including a pulsing heart and blinking robot. It keeps the original bundle identifiers and icon. It requires iOS/iPadOS 15 or later with the current toolchain.

```sh
./scripts/build-ios.sh simulator
./scripts/build-ios.sh device
```

These verification builds do not use signing credentials. For simulator installation and the distribution path, see [the native guide](docs/native-mvp.md).

**Sticker Studio — local browser prototype.** Browse all stickers, filter themes, search, save favorites, try a local conversation preview, and download original PNG/APNG files. The Pixel Lab supports drawing, erasing, flood fill, undo, remixing a sticker and downloading a transparent 300×300 PNG. Favorites and one draft persist in local browser storage when available. The canvas supports pointer/touch input and keyboard arrows + Space; `P`, `E`, `F` switch tools.

```sh
./scripts/start-preview.sh
```

Open **http://127.0.0.1:8787/prototype/**. Python 3 is the only runtime needed to serve the Studio. No npm install, account, API key or external service is needed. Stop the preview server with Ctrl+C. Bind only to localhost as the script does; it serves the repository to that local browser.

The Studio is a working product experiment. Search, favorites, chat previews and the editor are **not bundled into the native sticker pack**. It does not send messages or install exported art into Messages automatically. Editing animation loads one frame and exports a static PNG.

![Sticker Studio](docs/previews/studio-desktop.png)

## Art you can keep editing

`art/sprites.json`, `art/cute-sprites.json` and `art/meme-sprites.json` contain palette-based pixel commands. The latest two collections use a 16×16 canvas, dark outlines and limited colors with no white rim. `scripts/generate-art.py` generates native catalog additions, browser assets, raw PNGs in `art/pixels/`, animation frames and review boards. The recovered eleven images remain unchanged.

The tiny PNGs are truly 16×16. Native 300×300 sticker exports use integer 18× enlargement with six pixels of transparent padding; no smoothing or added detail is introduced. Open a tiny sticker in Studio to download either size.

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements-art.txt
.venv/bin/python scripts/generate-art.py
python3 scripts/build-preview.py
```

Read [the art guide](art/README.md) for the editable source format and provenance. The new tiny collection includes frog, bunny, cat, puppy, toast, boba, duck, penguin, sleepy bear, dumpling, mushroom and capybara, alongside side-eye, bruh, melting, crying-laughing, sus, heart-eyes and other meme reactions. The previous twelve revival designs remain included. Existing art was recovered as-is; review its provenance before publishing a new release.

## Verification

The native simulator and device Release builds passed under Xcode 27.1. The extension was installed and registered in an iOS 27 simulator. Browser checks cover assets, filters, persistence, chat previews, downloads, editor tools, undo, PNG dimensions/transparency format, remixing and mobile layout. Details and release limitations are in [verification notes](docs/verification.md).

Optional browser checks, with the preview server already running:

```sh
npm ci
npx playwright install chromium
npm run test:preview
```

To use an installed Google Chrome instead, run `PLAYWRIGHT_CHANNEL=chrome npm run test:preview`. Tests save review screenshots to `docs/previews/` and an example export under ignored `build/`.

## Releasing the existing app

The published app is **8 bit art, Apple ID 1366485724**, bundle ID **`eu.armand.--bit-art`**. The similarly named unpublished **8-bit art, ID 1366403490**, is a separate record. Update the published record.

The published release is 1.1. The recovered source was already marked 1.2 (3), so its exact correspondence to the published binary is unverified. The new local version 1.2 (4) remains provisional until the App Store Connect build history is checked.

See [recovery and roadmap](docs/recovery-and-roadmap.md) for the update path, recommended improvements, remaining account/device checks and backup strategy. [App Store draft](docs/app-store-draft.md) includes listing copy, review notes and an unpublished privacy-policy draft. No Apple upload, review submission or release has been performed.

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
