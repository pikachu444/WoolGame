"""Original game control artwork; generated from geometric masks, never source pixels."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import math
root=Path(__file__).resolve().parents[1]
out=root/'UnityProject/Assets/CozyRescue/Art/UI';out.mkdir(parents=True,exist_ok=True)
S=384
for name,color in [('pause',(39,151,216)),('replay',(233,107,45)),('speed',(85,171,75))]:
    mask=Image.new('L',(S,S));d=ImageDraw.Draw(mask)
    if name=='pause':
        d.rounded_rectangle((70,50,148,330),radius=22,fill=255);d.rounded_rectangle((235,50,313,330),radius=22,fill=255)
    elif name=='replay':
        d.arc((53,53,331,331),45,335,fill=255,width=73);d.polygon([(320,54),(329,185),(195,163)],fill=255)
    else:
        d.polygon([(48,72),(198,193),(48,314)],fill=255);d.polygon([(191,72),(341,193),(191,314)],fill=255)
    edge=mask.filter(ImageFilter.MaxFilter(17));img=Image.new('RGBA',(S,S));shade=Image.new('RGBA',(S,S),(95,63,25,255));img.paste(shade,(0,0),edge)
    fill=Image.new('RGBA',(S,S));p=fill.load()
    for y in range(S):
        light=1.16-.38*y/S
        for x in range(S):p[x,y]=tuple(min(255,round(c*light)) for c in color)+(255,)
    img.paste(fill,(0,0),mask)
    small=img.resize((128,128),Image.Resampling.LANCZOS);small.save(out/f'control_{name}.png')
