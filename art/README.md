# Editable pixel art

The original eleven sticker files were recovered from `mim-Armand/8bit-stickers` at commit `816eba114d65f5a0182c4ed3bf6dd1c1bd4f9256`. Ten remain in the native catalog. The original wine-glass file is preserved unchanged in [`recovered/wine_01.sticker`](recovered/wine_01.sticker), outside the shipped catalog, following the owner's decision to omit it and aim for a 4+ age rating. Repository recovery establishes where these files came from; it does not establish ownership of every depicted design. Review provenance before publishing the recovered collection.

The development collection for **1.3 (6)** contains **60 stickers: 10 classics plus 50 new designs**. The first twelve new designs are in [`sprites.json`](sprites.json); the initial 24 tiny cute/meme designs are in [`cute-sprites.json`](cute-sprites.json) and [`meme-sprites.json`](meme-sprites.json). Fourteen forthcoming meme designs are in [`meme-reactions-sprites.json`](meme-reactions-sprites.json), [`meme-animals-sprites.json`](meme-animals-sprites.json) and [`six-seven-sprites.json`](six-seven-sprites.json). There are **38 true 16×16 designs: 12 cute and 26 meme stickers**. These are original pixel compositions using generic subjects. No stock images, fonts, remote services, or image-generation model are involved in the sticker pixels. The preview boards use Pillow's bundled default font.

The submitted **1.2 (5)** remains a frozen **46-sticker** release at Git tag `v1.2-build5-submitted`. Adding these sources does not alter its uploaded binary or App Review submission. The new fourteen are prepared for a later update; native Studio and in-app purchase functionality are not implemented by this art expansion.

| Collection | New designs |
| --- | --- |
| Reactions | A little love, Better days ahead, Make a wish |
| Everyday | Warm & awake, Sent with love |
| Cosmic | You are a star, Let us go, Sleep sweet |
| Cozy | Growing on you, Do not disturb |
| Play | One more level, Hello, human |
| Cute — 16×16 | Frog, bunny, cat, puppy, toast, boba, duck, penguin, sleeping bear, dumpling, mushroom, capybara |
| Memes — initial 16×16 | Side-eye, crying laughter, melting, gasp, bruh, This is fine, sus, heart-eyes, stonks, loading, skull, touch grass |
| Memes — forthcoming reactions | Absolute cinema, Let me cook, Popcorn mode, Locked in, Tiny violin |
| Memes — forthcoming characters | No thoughts, Aura +1, Keyboard cat, Dramatic cat, NPC mode |
| Memes — forthcoming 67 set | Six seven!, Six-seven hands, Number 67, Certified 67 cat |

## Regenerate

Use Python 3.10+ and the Pillow version in `requirements-art.txt` in your preferred virtual environment, then:

```sh
python3 scripts/generate-art.py
python3 scripts/verify-art.py
python3 scripts/build-preview.py
```

This regenerates:

- Fifty native `.sticker` directories, with catalog references appended after the ten shipped classics, without changing any original PNG files. The archived wine sticker stays excluded.
- Fifty matching browser assets in `prototype/assets/new/`.
- Raw logical-resolution PNGs in `art/pixels/`, including 38 genuine 16×16 images.
- `art/manifest.json`, the shared catalog consumed by the browser MVP.
- `docs/previews/new-art-board.png`, `recovered-art-board.png`, `tiny-art-board.png`, `cute-art-board.png`, `meme-art-board.png` and the fourteen-design `meme-expansion-board.png`.

The six editable sprite JSON files listed above are authoritative. The manifest, asset PNGs, native sticker metadata, and preview boards are generated outputs and are checked into Git so a normal Xcode build does not require Python or Pillow. Use the same Pillow version to reproduce preview-board bytes; typography and compression can change between Pillow releases. Generation uses Pillow 12.3.0. Cross-platform checks compare decoded pixels and animation timing rather than compression bytes.

## Source format

Each collection supplies a `canvas` and `palette`. A sprite can override `canvas` and `rim`. The first twelve revival sprites use a transparent 50×50 canvas enlarged exactly 6×. The 38 tiny cute/meme designs use a **16×16 canvas**, enlarged exactly **18× to 288×288**, then centered with six transparent pixels on each side inside a native 300×300 PNG. No interpolation or extra detail is introduced. The raw 16×16 PNGs are also downloadable from the Studio.

Commands are painted in order:

```json
["rect", "coral", 10, 10, 20, 20]
["poly", "ink", [[10, 10], [20, 10], [15, 20]]]
["line", "mint", [[10, 10], [20, 20]], 1]
```

Colors reference the collection's hex palette. Coordinates are inclusive integer pixels. A one-pixel warm-white rim is generated for the first twelve revival sprites. The latest cute/meme collections set `rim: false`, use dark one-pixel outlines and at most six opaque colors per design, and retain the simpler look of the original art. There is no antialiasing in the source art.

The `animation` property enables `pulse` for the heart or `blink` for the robot. They export as looping APNG files using `.png` filenames, preserving real alpha transparency. The heart has four frames; the robot has three. Other stickers are static. The first APNG frame is also a usable fallback in viewers without APNG support.

The generator validates size, full alpha range, and Apple's per-file 500KB limit. It does not certify App Review acceptance or replace real-device appearance and animation testing.
