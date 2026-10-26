#!/usr/bin/env python3
"""Compare decoded PNG/APNG pixels to editable sources across OS encoders."""
import importlib.util
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('art_generator', ROOT / 'scripts/generate-art.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
manifest = json.loads((ROOT / 'art/manifest.json').read_text())
by_id = {entry['id']: entry for entry in manifest['stickers']}
sprites = list(generator.source_sprites())
assert len(by_id) == len(sprites), 'Source/manifest count differs'
for sprite, palette, source_file in sprites:
    entry = by_id[sprite['id']]
    raw = generator.render_sprite(sprite, palette)
    if sprite.get('collection') == 'tiny-pixels':
        assert raw.size == (16, 16), f"{entry['id']}: keep the logical canvas at 16x16"
        assert sprite.get('rim') is False, f"{entry['id']}: no outer white rim"
        opaque_colors = [color for _, color in raw.getcolors(256) if color[3] > 0]
        assert len(opaque_colors) <= 6, f"{entry['id']}: keep the limited-color style"
    assert entry['logicalSize'] == list(raw.size), entry['id']
    with Image.open(ROOT / entry['pixelSource']) as pixel_source:
        assert pixel_source.size == raw.size, entry['id']
        assert pixel_source.convert('RGBA').tobytes() == raw.tobytes(), entry['id']
    frames, durations = generator.frames_for(sprite, raw)
    expected = [generator.export_frame(frame) for frame in frames]
    assert entry['animated'] == (len(expected) > 1), entry['id']
    for key in ['filename', 'preview']:
        path = ROOT / entry[key]
        assert path.stat().st_size < 500_000, path
        with Image.open(path) as actual:
            assert actual.size == (300, 300), path
            assert getattr(actual, 'n_frames', 1) == len(expected), path
            if len(expected) > 1:
                assert actual.info.get('loop') == 0, path
            for index, frame in enumerate(expected):
                actual.seek(index)
                assert actual.convert('RGBA').tobytes() == frame.tobytes(), f'{path}: stale pixels in frame {index}'
                assert actual.convert('RGBA').getchannel('A').getextrema() == (0, 255), path
                if len(expected) > 1:
                    assert abs(actual.info['duration'] - durations[index]) < 1, path
    print(f"Verified {entry['id']}: {len(expected)} frame(s), pixels + timing match source")
print('PASS: native and browser art match editable sources. PNG compression bytes may differ across platforms.')
