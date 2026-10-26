#!/usr/bin/env python3
"""Package every included sticker and exact16px templates for the local native Studio."""
import importlib.util
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('catalog_source', ROOT / 'scripts/catalog-source.py')
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)
items = source.load_catalog()
out = ROOT / 'NativeStudio/Resources'
images = out / 'Stickers'
images.mkdir(parents=True, exist_ok=True)
entries = []
for item in items:
    filename = f"{item['id']}.png"
    (images / filename).write_bytes((ROOT / item['filename']).read_bytes())
    entry = {k: item[k] for k in ['id', 'title', 'category', 'tags', 'animated']}
    entry['filename'] = 'Stickers/' + filename
    entry['logicalSize'] = item.get('logicalSize', [])
    if item.get('logicalSize') == [16, 16]:
        raw = Image.open(ROOT / item['pixelSource']).convert('RGBA')
        palette = [(0, 0, 0, 0)]
        cells = []
        for rgba in raw.get_flattened_data():
            rgba = (0, 0, 0, 0) if rgba[3] == 0 else tuple(rgba)
            if rgba not in palette:
                palette.append(rgba)
            cells.append(palette.index(rgba))
        entry['template'] = {'palette': [dict(zip(['r','g','b','a'], c)) for c in palette], 'pixels': cells}
    entries.append(entry)
expected = json.loads((ROOT / 'Config/AppStoreMetadata.json').read_text())['stickerCount']
assert len(entries) == expected
allowed = {f"{entry['id']}.png" for entry in entries}
for path in images.glob('*.png'):
    if path.name not in allowed:
        path.unlink()
(out / 'NativeCatalog.json').write_text(json.dumps(entries, indent=2, ensure_ascii=False) + '\n')
print(f'Native catalogue: {len(entries)} stickers, {sum("template" in x for x in entries)} exact-grid templates; wine excluded')
