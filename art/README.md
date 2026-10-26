# Editable pixel art

The original eleven sticker files were recovered from `mim-Armand/8bit-stickers` at commit `816eba114d65f5a0182c4ed3bf6dd1c1bd4f9256`. Their pixels and original names are preserved in the native asset catalog. Repository recovery establishes where these files came from; it does not establish ownership of every depicted design. Review provenance before publishing the recovered collection.

Twelve new designs are recorded as editable drawing commands in [`sprites.json`](sprites.json). These are new pixel compositions created for this revival, using generic subjects rather than third-party game characters or logos. No stock images, fonts, remote services, or image-generation model are involved in the sticker pixels. The preview boards use Pillow's bundled default font.

| Collection | New designs |
| --- | --- |
| Reactions | A little love, Better days ahead, Make a wish |
| Everyday | Warm & awake, Sent with love |
| Cosmic | You are a star, Let us go, Sleep sweet |
| Cozy | Growing on you, Do not disturb |
| Play | One more level, Hello, human |

## Regenerate

Use Python 3.10+ and Pillow 10+ (`python3 -m pip install 'Pillow>=10'` in your preferred virtual environment), then:

```sh
python3 scripts/generate-art.py
```

This regenerates:

- Twelve native `.sticker` directories and appends their references after the eleven originals, without changing the original PNG files.
- Twelve matching browser assets in `prototype/assets/new/`.
- `art/manifest.json`, the shared catalog consumed by the browser MVP.
- `docs/previews/new-art-board.png` and `recovered-art-board.png`.

`sprites.json` is authoritative. The manifest, asset PNGs, native sticker metadata, and preview boards are generated outputs and are checked into Git so a normal Xcode build does not require Python or Pillow. Use the same Pillow version to reproduce preview-board bytes; typography and compression can change between Pillow releases. Initial generation used Pillow 12.3.0.

## Source format

Each sprite uses a transparent 50×50 canvas, enlarged exactly 6× with nearest-neighbor sampling to a 300×300 PNG. Commands are painted in order:

```json
["rect", "coral", 10, 10, 20, 20]
["poly", "ink", [[10, 10], [20, 10], [15, 20]]]
["line", "mint", [[10, 10], [20, 20]], 1]
```

Colors reference the shared hex palette. Coordinates are inclusive integer pixels. A one-pixel warm-white rim is generated from the silhouette, keeping the image legible against both light and dark message bubbles. There is no antialiasing in the source art.

The `animation` property enables `pulse` for the heart or `blink` for the robot. They export as looping APNG files using `.png` filenames, preserving real alpha transparency. The heart has four frames; the robot has three. Other stickers are static. The first APNG frame is also a usable fallback in viewers without APNG support.

The generator validates size, full alpha range, and Apple's per-file 500KB limit. It does not certify App Review acceptance or replace real-device appearance and animation testing.
