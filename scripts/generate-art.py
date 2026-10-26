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


def render_sprite(sprite, palette):
    image = Image.new('RGBA', (50, 50))
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
    # A one-grid-pixel paper edge separates every sticker from light/dark bubbles.
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
        sticker.thumbnail((244,244), Image.Resampling.NEAREST)
        board.paste(sticker, (x+(card_w-sticker.width)//2, y+20+(244-sticker.height)//2), sticker)
        draw.text((x+22,y+286), item['title'], font=text_font(21), fill='#2F243A')
        draw.text((x+22,y+316), item['caption'], font=text_font(14), fill='#7E6B8F')
    draw.text((64,board.height-42), 'Original pixel sources + transparent PNG/APNG / local, reproducible, versioned', font=text_font(15), fill='#756C79')
    board.save(destination, optimize=True)


def main():
    source = json.loads((ART/'sprites.json').read_text())
    palette, sprites = source['palette'], source['sprites']
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    (ROOT/'prototype/assets/new').mkdir(parents=True, exist_ok=True)
    manifest = {'schemaVersion': 1, 'palette': palette, 'stickers': []}
    board_items = []
    for sprite in sprites:
        identifier = sprite['id']
        directory = PACK / f'new_{identifier}.sticker'
        directory.mkdir(parents=True, exist_ok=True)
        filename = f'new_{identifier}.png'
        frames, durations = frames_for(sprite, render_sprite(sprite, palette))
        frames = [frame.resize((300,300), Image.Resampling.NEAREST) for frame in frames]
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
            'source':'art/sprites.json'})
        board_items.append({'path':preview,'title':sprite['title'],'caption':sprite['category'] + (' / ANIMATED' if len(frames)>1 else ' / 300 x 300')})
    (ART/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    catalog = json.loads((PACK/'Contents.json').read_text())
    original = [item for item in catalog['stickers'] if not item['filename'].startswith('new_')]
    catalog['stickers'] = original + [{'filename':f"new_{item['id']}.sticker"} for item in sprites]
    (PACK/'Contents.json').write_text(json.dumps(catalog,indent=2)+'\n')
    review_board(board_items, 'Small pixels. Big feelings.', 'Twelve new sticker concepts / one playful, coordinated palette', PREVIEWS/'new-art-board.png')
    names = {'exclamation_point_01':'Exclamation block', 'hear_01':'Heart', 'dealwithit_01':'Deal with it',
             'smiley_01':'Smile', 'smiley_02':'Big smile'}
    recovered = []
    for item in original:
        folder = PACK/item['filename']
        asset = json.loads((folder/'Contents.json').read_text())['properties']['filename']
        recovered.append({'path':folder/asset, 'title':names.get(folder.stem,folder.stem.replace('_01','').title()), 'caption':'RECOVERED / original repository'})
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
