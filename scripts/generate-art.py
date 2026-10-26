#!/usr/bin/env python3
"""Render editable pixel commands to native stickers, browser assets and review boards.

Requires Pillow >= 10. No network, randomness, fonts or image generation services.
Run from any directory: python3 scripts/generate-art.py
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / '8 bit art StickerPackExtension/Stickers.xcstickers/Sticker Pack.stickerpack'
ART = ROOT / 'art'
PREVIEWS = ROOT / 'docs/previews'
MEME_EXPANSION_FILES = ['meme-reactions-sprites.json', 'meme-animals-sprites.json', 'six-seven-sprites.json']
CLUB_67_FILES = ['club67-animals-sprites.json', 'club67-reactions-sprites.json']
SOURCE_FILES = ['sprites.json', 'cute-sprites.json', 'meme-sprites.json', *MEME_EXPANSION_FILES, *CLUB_67_FILES]


def source_sprites():
    """Keep each collection's logical grid and palette with its editable sprites."""
    for filename in SOURCE_FILES:
        path = ART / filename
        if not path.exists():
            continue
        source = json.loads(path.read_text())
        for sprite in source['sprites']:
            yield ({'canvas': source.get('canvas', [50, 50]),
                    'rim': source.get('rim', True), **sprite}, source['palette'], filename)


def export_frame(frame):
    """Use integer enlargement, then transparent padding to meet native 300px size."""
    scale = 300 // max(frame.size)
    assert scale >= 1, 'Logical sticker canvas must fit 300px'
    resized = frame.resize((frame.width * scale, frame.height * scale), Image.Resampling.NEAREST)
    if resized.size == (300, 300):
        return resized
    output = Image.new('RGBA', (300, 300))
    output.alpha_composite(resized, ((300 - resized.width) // 2, (300 - resized.height) // 2))
    return output


def render_sprite(sprite, palette):
    image = Image.new('RGBA', tuple(sprite.get('canvas', [50, 50])))
    draw = ImageDraw.Draw(image)
    for command in sprite['commands']:
        kind, color, *args = command
        color = palette.get(color, color)
        if kind == 'rect':
            draw.rectangle(tuple(args), fill=color)
        elif kind == 'poly':
            draw.polygon([tuple(p) for p in args[0]], fill=color)
        elif kind == 'line':
            draw.line([tuple(p) for p in args[0]], fill=color, width=args[1] if len(args) > 1 else 1)
        else:
            raise ValueError(f'Unknown pixel command: {kind}')
    if not sprite.get('rim', True):
        return image
    # The first revival collection has a rim; tiny originals-style sprites do not.
    rim = Image.new('RGBA', image.size, palette['paper'])
    rim.putalpha(image.getchannel('A').filter(ImageFilter.MaxFilter(3)))
    rim.alpha_composite(image)
    return rim


def frames_for(sprite, image):
    if sprite.get('animation') == 'pulse':
        frames = []
        for width in [46, 48, 50, 48]:
            frame = Image.new('RGBA', image.size)
            scaled = image.resize((width, width), Image.Resampling.NEAREST)
            frame.alpha_composite(scaled, ((50-width)//2, (50-width)//2))
            frames.append(frame)
        return frames, [200, 150, 300, 150]
    if sprite.get('animation') == 'blink':
        blink = image.copy()
        draw = ImageDraw.Draw(blink)
        # Robot face is cyan; closed eyes replace its two dark eye columns.
        draw.rectangle((18, 20, 20, 24), fill='#77E4DB')
        draw.rectangle((29, 20, 31, 24), fill='#77E4DB')
        draw.rectangle((18, 23, 20, 23), fill='#2F243A')
        draw.rectangle((29, 23, 31, 23), fill='#2F243A')
        return [image, blink, image], [2000, 140, 700]
    return [image], [1000]


def text_font(size):
    # Pillow's bundled font makes the preview reproducible across computers.
    return ImageFont.load_default(size=size)


def review_board(items, title, subtitle, destination):
    width, columns, card_w, card_h = 1440, 4, 310, 342
    rows = (len(items) + columns-1)//columns
    board = Image.new('RGB', (width, 222 + rows*370 + 65), '#F5F1E9')
    draw = ImageDraw.Draw(board)
    draw.text((64, 46), '8 BIT ART / THE NEXT CHAPTER', font=text_font(18), fill='#7E6B8F')
    draw.text((60, 88), title, font=text_font(46), fill='#2F243A')
    draw.text((64, 157), subtitle, font=text_font(19), fill='#756C79')
    for index, item in enumerate(items):
        x, y = 64+(index%columns)*334, 222+(index//columns)*370
        draw.rounded_rectangle((x,y,x+card_w,y+card_h), radius=20, fill='#FFFFFF')
        draw.rounded_rectangle((x+14,y+14,x+card_w-14,y+268), radius=14, fill='#EEEAF4')
        sticker = Image.open(item['path']).convert('RGBA')
        if max(sticker.size) < 244:
            scale = 244 // max(sticker.size)
            sticker = sticker.resize((sticker.width*scale, sticker.height*scale), Image.Resampling.NEAREST)
        else:
            sticker.thumbnail((244,244), Image.Resampling.NEAREST)
        board.paste(sticker, (x+(card_w-sticker.width)//2, y+20+(244-sticker.height)//2), sticker)
        draw.text((x+22,y+286), item['title'], font=text_font(21), fill='#2F243A')
        draw.text((x+22,y+316), item['caption'], font=text_font(14), fill='#7E6B8F')
    draw.text((64,board.height-42), 'Original pixel sources + transparent PNG/APNG / local, reproducible, versioned', font=text_font(15), fill='#756C79')
    board.save(destination, optimize=True)


def main():
    source = json.loads((ART/'sprites.json').read_text())
    sprites = list(source_sprites())
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    (ART/'pixels').mkdir(parents=True, exist_ok=True)
    (ROOT/'prototype/assets/new').mkdir(parents=True, exist_ok=True)
    manifest = {'schemaVersion': 1, 'palette': source['palette'], 'stickers': []}
    board_items = []
    tiny_items = []
    expansion_items = []
    club_items = []
    for sprite, palette, source_file in sprites:
        identifier = sprite['id']
        directory = PACK / f'new_{identifier}.sticker'
        directory.mkdir(parents=True, exist_ok=True)
        filename = f'new_{identifier}.png'
        raw = render_sprite(sprite, palette)
        pixel_source = ART/'pixels'/f'{identifier}.png'
        raw.save(pixel_source, optimize=True)
        frames, durations = frames_for(sprite, raw)
        frames = [export_frame(frame) for frame in frames]
        kwargs = {'save_all': True, 'append_images': frames[1:], 'duration': durations,
                  'loop': 0, 'disposal': 0, 'blend': 0} if len(frames)>1 else {}
        frames[0].save(directory/filename, optimize=True, **kwargs)
        preview = ROOT/f'prototype/assets/new/{identifier}.png'
        preview.write_bytes((directory/filename).read_bytes())
        (directory/'Contents.json').write_text(json.dumps({'info': {'version':1,'author':'xcode'}, 'properties': {'filename':filename}},indent=2)+'\n')
        manifest['stickers'].append({
            'id':identifier, 'title':sprite['title'], 'category':sprite['category'],
            'tags':sprite['tags'], 'filename':str((directory/filename).relative_to(ROOT)),
            'preview':str(preview.relative_to(ROOT)), 'animated':len(frames)>1,
            'source':f'art/{source_file}', 'logicalSize':list(raw.size),
            'pixelSource':str(pixel_source.relative_to(ROOT)),
            'collection':sprite.get('collection', 'revival')})
        item = {'path':pixel_source if sprite.get('collection') == 'tiny-pixels' else preview,'title':sprite['title'],
                'caption':sprite['category'] + (' / ANIMATED' if len(frames)>1 else f' / {raw.width} x {raw.height} pixels')}
        (tiny_items if sprite.get('collection') == 'tiny-pixels' else board_items).append(item)
        if source_file in MEME_EXPANSION_FILES:
            expansion_items.append(item)
        if source_file in CLUB_67_FILES:
            club_items.append(item)
    (ART/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    catalog = json.loads((PACK/'Contents.json').read_text())
    original = [item for item in catalog['stickers'] if not item['filename'].startswith('new_')]
    catalog['stickers'] = original + [{'filename':f"new_{sprite['id']}.sticker"} for sprite, _, _ in sprites]
    (PACK/'Contents.json').write_text(json.dumps(catalog,indent=2)+'\n')
    review_board(board_items, 'Small pixels. Big feelings.', 'Twelve new sticker concepts / one playful, coordinated palette', PREVIEWS/'new-art-board.png')
    if tiny_items:
        review_board(tiny_items, 'Fewer pixels. More personality.',
                     f'{len(tiny_items)} cute + meme reactions / true 16 x 16 sprites / crisp integer scaling',
                     PREVIEWS/'tiny-art-board.png')
        for category, filename in [('Cute', 'cute-art-board.png'), ('Memes', 'meme-art-board.png')]:
            category_items = [item for item in tiny_items if item['caption'].startswith(category + ' /')]
            review_board(category_items, 'Tiny ' + category.lower() + '. Big feelings.',
                         'Original-style chunky pixels / 16 x 16 editable art / no smoothing', PREVIEWS/filename)
        sample = [item for item in tiny_items if item['caption'].startswith('Cute /')][:4]
        sample += [item for item in tiny_items if item['caption'].startswith('Memes /')][:4]
        review_board(sample, 'Tiny cute. Big moods.',
                     f'A peek at {len(tiny_items)} tiny reactions / true 16 x 16 pixels / original-style outlines',
                     PREVIEWS/'tiny-sample.png')
    if expansion_items:
        review_board(expansion_items, 'More memes. Still tiny.',
                     f'{len(expansion_items)} new reactions, including four 67 designs / true 16 x 16 pixels',
                     PREVIEWS/'meme-expansion-board.png')
    if club_items:
        review_board(club_items, 'Welcome to the 67 club.',
                     f'{len(club_items)} more cute memes / true 16 x 16 pixels / 67 stickers total, wine excluded',
                     PREVIEWS/'club67-board.png')
    names = {'exclamation_point_01':'Exclamation block', 'hear_01':'Heart', 'dealwithit_01':'Deal with it',
             'smiley_01':'Smile', 'smiley_02':'Big smile'}
    recovered = []
    for item in original:
        folder = PACK/item['filename']
        asset = json.loads((folder/'Contents.json').read_text())['properties']['filename']
        recovered.append({'path':folder/asset, 'title':names.get(folder.stem,folder.stem.replace('_01','').title()), 'caption':'RECOVERED / original repository'})
    excluded_wine = ART/'recovered/wine_01.sticker/wine_01.png'
    if excluded_wine.exists():
        recovered.append({'path':excluded_wine, 'title':'Wine glass', 'caption':'PRESERVED SOURCE / not shipped'})
    review_board(recovered, 'The originals survived.', 'Eleven recovered stickers / preserved without changing their pixels', PREVIEWS/'recovered-art-board.png')
    for entry in manifest['stickers']:
        file = ROOT/entry['filename']
        with Image.open(file) as image:
            assert image.size == (300,300), file
            assert image.mode == 'RGBA', file
            assert image.getchannel('A').getextrema() == (0,255), file
            assert file.stat().st_size < 500_000, file
            print(f"{entry['id']}: {file.stat().st_size:,} bytes, {getattr(image,'n_frames',1)} frames")
    print(f"Generated {len(sprites)} stickers; preserved {len(original)} originals.")


if __name__ == '__main__':
    main()
