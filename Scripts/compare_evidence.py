"""Place original reference pixels beside actual player captures, without enhancement."""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw, ImageFont

p = argparse.ArgumentParser()
p.add_argument('evidence', type=Path)
a = p.parse_args()
root = Path(__file__).resolve().parents[1]
source = root / 'Wool_Crush_Design/crush_references'
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 22)
for ours, reference, name in [
    ('01_full.png', 'V04_clear_002.0s.png', 'comparison_full.png'),
    ('03_unravel.png', 'V04_clear_006.0s.png', 'comparison_unravel.png'),
    ('04_rescue.png', 'V04_clear_018.7s.png', 'comparison_rescue.png')]:
    board = Image.new('RGB', (1204, 1336), '#f3eee7')
    d = ImageDraw.Draw(board)
    d.text((12, 15), 'SOURCE / Wool Crush', font=font, fill='#514c67')
    d.text((612, 15), 'OUR PROTOTYPE / actual runtime', font=font, fill='#514c67')
    for x, path in [(0, source/reference), (612, a.evidence/ours)]:
        im = Image.open(path).convert('RGB')
        scale = min(592/im.width, 1280/im.height)
        im = im.resize((round(im.width*scale), round(im.height*scale)), Image.Resampling.LANCZOS)
        board.paste(im, (x+(592-im.width)//2, 56+(1280-im.height)//2))
    board.save(a.evidence/name)
