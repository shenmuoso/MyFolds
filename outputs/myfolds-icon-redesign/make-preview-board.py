"""Arrange unmodified Icon Composer exports for visual comparison (Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent
previews = root / 'previews'
font_path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf'

def font(size):
    return ImageFont.truetype(font_path, size)

def center_text(draw, text, center_x, y, size, fill):
    face = font(size)
    box = draw.textbbox((0, 0), text, font=face)
    draw.text((center_x - (box[2] - box[0]) / 2, y), text, font=face, fill=fill)

def place(canvas, candidate, rendition, x, y, size, native=False):
    suffix = f'-{size}' if native else ''
    im = Image.open(previews / f'MyFolds-{candidate}-{rendition}{suffix}.png').convert('RGBA')
    if im.size != (size, size):
        im = im.resize((size, size), Image.Resampling.LANCZOS)
    canvas.paste(im, (x, y), im)

board = Image.new('RGB', (1400, 980), '#e9e7e2')
d = ImageDraw.Draw(board)
d.rectangle((0, 630, 1400, 980), fill='#27292e')
d.text((72, 42), 'MyFolds', font=font(45), fill='#25262a')
d.text((74, 109), '原生玻璃图标 · 造型对比', font=font(23), fill='#606168')
d.text((1010, 112), 'Icon Composer · macOS 27', font=font(19), fill='#606168')
for candidate, name, cx in [('Folder', 'A · 折叠文件夹', 350), ('Fold', 'B · 双面折页', 1050)]:
    center_text(d, name, cx, 174, 27, '#292a2e')
    place(board, candidate, 'Default', cx - 188, 230, 376)
    place(board, candidate, 'Dark', cx - 126, 672, 252)
    center_text(d, '深色外观', cx, 940, 18, '#ced0d6')
board.save(previews / 'MyFolds-comparison.png')

sizes = Image.new('RGB', (1024, 496), '#e9e7e2')
d = ImageDraw.Draw(sizes)
d.rectangle((512, 0, 1024, 496), fill='#27292e')
for i, (candidate, rendition) in enumerate([
    ('Folder', 'Default'), ('Fold', 'Default'), ('Folder', 'Dark'), ('Fold', 'Dark')
]):
    cx = i * 256 + 128
    color = '#44464c' if i < 2 else '#d6d8df'
    center_text(d, f'{candidate} / {rendition}', cx, 20, 17, color)
    for size, y in [(128, 64), (64, 248), (32, 384)]:
        place(sizes, candidate, rendition, cx - size // 2, y, size, native=True)
        center_text(d, f'{size} px', cx, y + size + 12, 15, color)
sizes.save(previews / 'MyFolds-native-sizes.png')

for candidate in ['Folder', 'Fold']:
    for rendition in ['Default', 'Dark']:
        for size in [32, 64, 128, 1024]:
            suffix = '' if size == 1024 else f'-{size}'
            path = previews / f'MyFolds-{candidate}-{rendition}{suffix}.png'
            im = Image.open(path)
            assert im.size == (size, size), path
            assert im.convert('RGBA').getbbox(), path
print('Created comparison and native-size review sheets; checked 16 rendered PNGs.')
