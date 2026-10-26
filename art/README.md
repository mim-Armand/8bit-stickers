# Editable pixel art

The original eleven sticker files were recovered from `mim-Armand/8bit-stickers` at commit `816eba114d65f5a0182c4ed3bf6dd1c1bd4f9256`. Their pixels and original names are preserved in the native asset catalog. Repository recovery establishes where these files came from; it does not establish ownership of every depicted design. Review provenance before publishing the recovered collection.

Thirty-six new designs are recorded as editable drawing commands. The first twelve are in [`sprites.json`](sprites.json); the latest **24 cute and meme designs** are in [`cute-sprites.json`](cute-sprites.json) and [`meme-sprites.json`](meme-sprites.json). These are original pixel compositions using generic subjects. No stock images, fonts, remote services, or image-generation model are involved in the sticker pixels. The preview boards use Pillow's bundled default font.

| Collection | New designs |
| --- | --- |
| Reactions | A little love, Better days ahead, Make a wish |
| Everyday | Warm & awake, Sent with love |
| Cosmic | You are a star, Let us go, Sleep sweet |
| Cozy | Growing on you, Do not disturb |
| Play | One more level, Hello, human |
| Cute — 16×16 | Frog, bunny, cat, puppy, toast, boba, duck, penguin, sleeping bear, dumpling, mushroom, capybara |
| Memes — 16×16 | Side-eye, crying laughter, melting, gasp, bruh, This is fine, sus, heart-eyes, stonks, loading, skull, touch grass |

## Regenerate

Use Python 3.10+ and the Pillow version in `requirements-art.txt` in your preferred virtual environment, then:

```sh
python3 scripts/generate-art.py
python3 scripts/verify-art.py
python3 scripts/build-preview.py
```

This regenerates:

- Thirty-six native `.sticker` directories and appends their references after the eleven originals, without changing the original PNG files.
- Thirty-six matching browser assets in `prototype/assets/new/`.
- Raw logical-resolution PNGs in `art/pixels/`, including 24 genuine 16×16 images.
- `art/manifest.json`, the shared catalog consumed by the browser MVP.
- `docs/previews/new-art-board.png`, `recovered-art-board.png`, `tiny-art-board.png`, `cute-art-board.png` and `meme-art-board.png`.

The three `*-sprites.json` / `sprites.json` files are authoritative. The manifest, asset PNGs, native sticker metadata, and preview boards are generated outputs and are checked into Git so a normal Xcode build does not require Python or Pillow. Use the same Pillow version to reproduce preview-board bytes; typography and compression can change between Pillow releases. Generation uses Pillow 12.3.0. Cross-platform checks compare decoded pixels and animation timing rather than compression bytes.

## Source format

Each collection supplies a `canvas` and `palette`. A sprite can override `canvas` and `rim`. The first twelve revival sprites use a transparent 50×50 canvas enlarged exactly 6×. The latest 24 use a **16×16 canvas**, enlarged exactly **18× to 288×288**, then centered with six transparent pixels on each side inside a native 300×300 PNG. No interpolation or extra detail is introduced. The raw 16×16 PNGs are also downloadable from the Studio.

Commands are painted in order:

```json
["rect", "coral", 10, 10, 20, 20]
["poly", "ink", [[10, 10], [20, 10], [15, 20]]]
["line", "mint", [[10, 10], [20, 20]], 1]
```

Colors reference the collection's hex palette. Coordinates are inclusive integer pixels. A one-pixel warm-white rim is generated for the first twelve revival sprites. The latest cute/meme collections set `rim: false`, use dark one-pixel outlines and three to six colors per design, and retain the simpler look of the original art. There is no antialiasing in the source art.

The `animation` property enables `pulse` for the heart or `blink` for the robot. They export as looping APNG files using `.png` filenames, preserving real alpha transparency. The heart has four frames; the robot has three. Other stickers are static. The first APNG frame is also a usable fallback in viewers without APNG support.

The generator validates size, full alpha range, and Apple's per-file 500KB limit. It does not certify App Review acceptance or replace real-device appearance and animation testing.
