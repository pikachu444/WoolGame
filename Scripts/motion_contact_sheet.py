"""Unaltered runtime samples, with their recorded wall time, for motion review."""
import csv
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

folder = Path(sys.argv[1])
rows = list(csv.DictReader((folder/'frame_times.csv').open()))
times = [2.0, 2.13, 2.26, 2.4, 3.1, 3.23, 3.36, 3.5, 7.5, 7.8, 8.1, 8.4]
board = Image.new('RGB', (1080, 1830), '#edf2f5')
draw = ImageDraw.Draw(board)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 18)
for i, wanted in enumerate(times):
    row = min(rows, key=lambda r: abs(float(r['wall_seconds'])-wanted))
    im = Image.open(folder/row['file']).convert('RGB').resize((270,585))
    x,y = i%4*270, i//4*610
    board.paste(im,(x,y+25))
    draw.text((x+5,y+3), f"{float(row['wall_seconds']):.3f}s / {row['consumed']} units", font=font, fill='#24344b')
board.save(folder/'motion_contact_sheet.jpg', quality=95)
