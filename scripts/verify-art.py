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
source = json.loads((ROOT / 'art/sprites.json').read_text())
manifest = json.loads((ROOT / 'art/manifest.json').read_text())
by_id = {entry['id']: entry for entry in manifest['stickers']}
assert len(by_id) == len(source['sprites']), 'Source/manifest count differs'
for sprite in source['sprites']:
    entry = by_id[sprite['id']]
    frames, durations = generator.frames_for(sprite, generator.render_sprite(sprite, source['palette']))
    expected = [frame.resize((300, 300), Image.Resampling.NEAREST) for frame in frames]
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
