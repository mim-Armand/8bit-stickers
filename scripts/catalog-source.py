"""Shared, native-order catalogue from tracked classic metadata and generated art."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / '8 bit art StickerPackExtension/Stickers.xcstickers/Sticker Pack.stickerpack'
TITLES = {
    'exclamation_point_01': ('Surprise block', ['surprise', 'retro']),
    'banana_01': ('Banana', ['fruit', 'snack']),
    'hear_01': ('Original heart', ['love', 'heart']),
    'pumpkin_01': ('Pumpkin', ['halloween', 'autumn']),
    'skull_01': ('Skull', ['spooky', 'halloween']),
    'ghost_01': ('Little ghost', ['spooky', 'boo']),
    'flower_01': ('Flower', ['nature', 'bloom']),
    'smiley_01': ('Happy face', ['happy', 'smile']),
    'smiley_02': ('Big grin', ['happy', 'smile']),
    'dealwithit_01': ('Pixel shades', ['cool', 'sunglasses']),
}


def load_catalog():
    items = []
    for entry in json.loads((PACK / 'Contents.json').read_text())['stickers']:
        folder = PACK / entry['filename']
        stem = folder.stem
        if stem not in TITLES:
            continue
        filename = json.loads((folder / 'Contents.json').read_text())['properties']['filename']
        title, tags = TITLES[stem]
        path = str((folder / filename).relative_to(ROOT))
        items.append(dict(id=stem, title=title, category='Originals', tags=tags,
                          preview=path, filename=path, animated=False, original=True))
    manifest = json.loads((ROOT / 'art/manifest.json').read_text())
    items += [{**item, 'original': False} for item in manifest['stickers']]
    assert len(items) == len({item['id'] for item in items})
    assert not any(item['id'] == 'wine_01' for item in items)
    return items
