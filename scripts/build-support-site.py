#!/usr/bin/env python3
"""Refresh the static support site's selected art from the committed catalog.

The site/ directory is the deployable source. This command does not deploy it,
modify hosting, publish the Studio, or call any external service.
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SELECTED = ['tiny_frog', 'tiny_bunny', 'tiny_cat', 'tiny_sideeye', 'tiny_boba', 'tiny_this_is_fine']


def main():
    manifest = json.loads((ROOT / 'art/manifest.json').read_text())
    stickers = {item['id']: item for item in manifest['stickers']}
    destination = ROOT / 'site/assets'
    destination.mkdir(parents=True, exist_ok=True)
    for identifier in SELECTED:
        source = ROOT / stickers[identifier]['preview']
        if not source.is_file():
            raise FileNotFoundError(f'Missing sticker export: {source.relative_to(ROOT)}')
        target = destination / f'{identifier}.png'
        shutil.copyfile(source, target)
        print(f'{identifier}: {target.stat().st_size} bytes')
    for page in ['index.html', 'support/index.html', 'privacy/index.html']:
        if not (ROOT / 'site' / page).is_file():
            raise FileNotFoundError(page)
    print('Static support site ready in site/. No deployment performed.')


if __name__ == '__main__':
    main()
