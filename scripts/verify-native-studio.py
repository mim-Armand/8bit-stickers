#!/usr/bin/env python3
"""Check the committed native Studio resources against the authoritative art."""
import importlib.util
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('catalog_source', ROOT / 'scripts/catalog-source.py')
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)
originals = source.load_catalog()
items = json.loads((ROOT / 'NativeStudio/Resources/NativeCatalog.json').read_text())
assert [i['id'] for i in items] == [i['id'] for i in originals]
assert len(items) == json.loads((ROOT / 'Config/AppStoreMetadata.json').read_text())['stickerCount']
assert not any('wine' in item['id'] for item in items)
for item, original in zip(items, originals):
    for field in ['title', 'category', 'tags', 'animated']:
        assert item[field] == original[field], (item['id'], field)
    native = ROOT / 'NativeStudio/Resources' / item['filename']
    assert native.read_bytes() == (ROOT / original['filename']).read_bytes(), item['id']
    if 'template' in item:
        assert original['logicalSize'] == [16, 16]
        palette = [tuple(c[k] for k in ['r','g','b','a']) for c in item['template']['palette']]
        cells = item['template']['pixels']
        assert len(cells) == 256 and palette[0] == (0,0,0,0)
        actual = [palette[index] for index in cells]
        with Image.open(ROOT / original['pixelSource']) as raw:
            expected = [(0,0,0,0) if p[3] == 0 else tuple(p) for p in raw.convert('RGBA').get_flattened_data()]
        assert actual == expected, item['id']
    else:
        assert original.get('logicalSize') != [16,16], item['id']
print(f'PASS: {len(items)} native stickers copied byte-identically, {sum("template" in i for i in items)} lossless16px templates, wine excluded')
