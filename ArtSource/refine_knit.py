"""Original periodic stockinette relief; numpy/Pillow, no external image input.

Writes versioned candidates only to ArtSource/RefinedKnit. One map contains 4x4
stitches, matching the existing physical texture contract. Continuous closed
loops eliminate visible cut ends; overlapping rows bury the rounded returns.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent / 'RefinedKnit'
OUT.mkdir(exist_ok=True)
N=256
px=.6/N
py=.4/N
y,x=np.mgrid[0:N,0:N].astype(float)
x=(x+.5)*px; y=.4-(y+.5)*py
height=np.full((N,N),-.045)
# Closed narrow teardrop loop, widened rounded yarn, rounded tip and shoulder.
controls=np.array([(0,-.08),(-.12,.06),(-.205,.27),(-.218,.49),
                   (-.15,.66),(0,.70),(.15,.66),(.218,.49),
                   (.205,.27),(.12,.06)])
samples=[]
for k in range(len(controls)):
 p0,p1,p2,p3=[controls[i%len(controls)] for i in (k-1,k,k+1,k+2)]
 for t in np.linspace(0,1,12,endpoint=False):
  samples.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
samples=np.array(samples)
segment_lengths=np.linalg.norm(np.roll(samples,-1,axis=0)-samples,axis=1)
arc=np.r_[0,np.cumsum(segment_lengths)]
for row in range(-2,3):
 for col in range(-1,2):
  best=np.full_like(x,99); along=np.zeros_like(x); near_y=np.zeros_like(x); side=np.zeros_like(x)
  for i,a in enumerate(samples):
   b=samples[(i+1)%len(samples)]; v=b-a
   ax=a[0]+.3+col*.6; ay=a[1]+row*.4
   t=np.clip(((x-ax)*v[0]+(y-ay)*v[1])/np.dot(v,v),0,1)
   dist=(x-ax-t*v[0])**2+(y-ay-t*v[1])**2
   better=dist<best; best=np.minimum(best,dist)
   along=np.where(better,(arc[i]+t*segment_lengths[i])/arc[-1],along)
   near_y=np.where(better,a[1]+t*v[1],near_y)
   side=np.where(better,((x-ax)*v[1]-(y-ay)*v[0])/np.linalg.norm(v),side)
  d=np.sqrt(best); radius=.117
  core=np.sqrt(np.maximum(0,1-(d/radius)**2))
  # Tip in front, shoulder behind. Fine spiral relief is shallow, never faceted.
  z=.015+.065*np.clip((.65-near_y)/.7,0,1)
  # Three helical plys around the circular yarn, sampled by true arc length.
  # Higher-frequency aligned fibres sit on those plys without changing the
  # broad round silhouette; integer turns preserve the closed-loop join.
  angle=np.arctan2(side,radius*core+1e-6)
  phase=3*(angle-along*2*np.pi*10)
  twist=.0065*np.cos(phase)*core
  fibre=(.0009*np.cos(phase*3+along*2*np.pi*2)
         +.0004*np.sin(phase*5-along*2*np.pi*3))*core
  strand=np.where(d<radius,z+radius*core+twist+fibre,-.045)
  height=np.maximum(height,strand)
# Slight smoothing makes finite-resolution fibres soft and avoids ridge aliasing.
for _ in range(2):
 height=(height*4+np.roll(height,1,0)+np.roll(height,-1,0)+np.roll(height,1,1)+np.roll(height,-1,1))/8
dx=(np.roll(height,-1,1)-np.roll(height,1,1))/(2*px)
dy=(np.roll(height,-1,0)-np.roll(height,1,0))/(2*py)
normal=np.stack((-dx,dy,np.ones_like(dx)),axis=-1)
normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
# Cavity visibility follows the round yarn flank, not absolute surface height.
# Absolute height alone saturated the whole strand white in the actual game.
# Smooth a separate relief for the broad flank term, keeping the normal intact.
macro=height.copy()
for _ in range(5):
 macro=(macro*4+np.roll(macro,1,0)+np.roll(macro,-1,0)+np.roll(macro,1,1)+np.roll(macro,-1,1))/8
mx=(np.roll(macro,-1,1)-np.roll(macro,1,1))/(2*px)
my=(np.roll(macro,-1,0)-np.roll(macro,1,0))/(2*py)
flank=1/np.sqrt(1+mx*mx+my*my)
depth=np.clip((height+.045)/.25,0,1)
ao=.20+.65*flank**1.6+.07*normal[:,:,2]**1.4+.08*depth
ao=np.where(height<-.02,.32,ao)
def save_tile(a,name):
 a=np.uint8(np.clip(a,0,1)*255+.5)
 rep=(4,4,1) if a.ndim==3 else (4,4)
 Image.fromarray(np.tile(a,rep)).save(OUT/name)
save_tile(normal*.5+.5,'RefinedKnitNormal.png')
save_tile(ao,'RefinedKnitAO.png')
# Standalone mathematical material preview, not a Unity execution capture.
light=np.array([-.40,-.35,.85]);light/=np.linalg.norm(light)
shade=(.60+.40*np.maximum(0,np.sum(normal*light,axis=-1)))*(.55+.45*ao)
rgb=np.array([.19,.61,.89])[None,None,:]*shade[:,:,None]
save_tile(rgb,'RefinedKnitPreview.png')
Image.open(OUT/'RefinedKnitPreview.png').resize((256,256),Image.Resampling.LANCZOS).save(OUT/'RefinedKnitPreview_small.png')
Image.fromarray(np.uint8(np.tile(np.clip((height+.045)/.25,0,1),(4,4))*255)).save(OUT/'RefinedKnitHeight.png')
(OUT/'manifest.json').write_text(json.dumps({'original':True,'source':'periodic closed Catmull-Rom yarn loops with rounded circular relief','stitches':[4,4],'size':[1024,1024],'normal':'OpenGL tangent space','preview':'mathematical Lambert preview, not game capture','periodic_height_seam_max':float(max(np.abs(height[0]-height[-1]).max(),np.abs(height[:,0]-height[:,-1]).max()))},indent=2))
print(OUT)


