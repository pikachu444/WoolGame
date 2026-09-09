import bpy,math,os,json,sys
import numpy as np
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=os.path.join(ROOT,'UnityProject','Assets','CozyRescue','Art');MODEL=os.path.join(OUT,'Models');TEX=os.path.join(OUT,'Textures')
os.makedirs(MODEL,exist_ok=True);os.makedirs(TEX,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
colors={'Wool':(.81,.91,.90,1),'Cream':(.96,.86,.67,1),'Blush':(.94,.43,.44,1),'Cocoa':(.39,.28,.24,1),'Eye':(.045,.032,.04,1),'Highlight':(1,1,.95,1),'Scarf':(.27,.58,.56,1),'Nose':(.52,.26,.25,1)}
mats={}
for name,c in colors.items():
 m=bpy.data.materials.new(name);m.diffuse_color=c;m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=c;p.inputs['Roughness'].default_value=.82;mats[name]=m
parts=[]
def sphere(name,loc,scale,mat='Wool',seg=24,rings=16):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=loc)
 o=bpy.context.object;o.name=name
 for v in o.data.vertices:
  q=v.co.copy();v.co=(q.x,q.z,-q.y)
 for uv in o.data.uv_layers.active.data:uv.uv=(uv.uv.x*2*math.pi*scale[0],uv.uv.y*math.pi*scale[1])
 o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[mat])
 for f in o.data.polygons:f.use_smooth=True
 parts.append(o);return o

def textures():
 n=1024;y,x=np.mgrid[0:n,0:n]/n*4;u=x%1;v=y%1;h=np.zeros((n,n),np.float32)
 for oy in (-1,0,1):
  vv=v+oy
  for sign in (-1,1):
   for t in np.linspace(0,1,70):
    cx=.5+sign*(.055+.29*t+.035*math.sin(t*math.pi));cy=.1+.83*t;dx=np.minimum(np.abs(u-cx),1-np.abs(u-cx));dy=vv-cy;dist=np.sqrt(dx*dx+dy*dy)
    h=np.maximum(h,np.sqrt(np.maximum(0,1-(dist/.105)**2))*.85)
 h+=.018*np.sin((x*39+y*13)*2*math.pi)*h
 gy=(np.roll(h,-1,axis=0)-np.roll(h,1,axis=0))*7;gx=(np.roll(h,-1,axis=1)-np.roll(h,1,axis=1))*7
 normal=np.stack((-gx,-gy,np.ones_like(h)),axis=-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
 def save(name,arr):
  if arr.ndim==2:arr=np.repeat(arr[:,:,None],3,axis=2)
  rgba=np.concatenate((arr,np.ones((n,n,1))),axis=2).astype(np.float32);im=bpy.data.images.new(name,width=n,height=n,alpha=True);im.pixels.foreach_set(rgba.reshape(-1));im.filepath_raw=os.path.join(TEX,name+'.png');im.file_format='PNG';im.save();bpy.data.images.remove(im)
 save('KnitBase',.84+.16*h);save('KnitNormal',normal*.5+.5);save('KnitAO',.76+.24*np.minimum(1,h*1.8))

def export(name,objs):
 coll=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(coll)
 for o in objs:
  for c in list(o.users_collection):c.objects.unlink(o)
  coll.objects.link(o)
 # Export-only copies preserve editable source objects and all UV/triangle geometry.
 originals={o:o.name for o in objs}
 for o in objs:o.name='SOURCE_'+o.name
 copies=[];groups={}
 for o in objs:
  q=o.copy();q.data=o.data.copy();bpy.context.scene.collection.objects.link(q);q.name=originals[o];q.hide_set(False)
  if name=='CloudSegment' or q.name.startswith(('WavePaw','EyeL','EyeR','EyeGlint')):copies.append(q)
  else:groups.setdefault(q.data.materials[0].name,[]).append(q)
 for material,group in groups.items():
  bpy.ops.object.select_all(action='DESELECT')
  for q in group:q.select_set(True)
  bpy.context.view_layer.objects.active=group[0]
  if len(group)>1:bpy.ops.object.join()
  q=bpy.context.view_layer.objects.active;q.name=name+'_'+material;copies.append(q)
 bpy.ops.object.select_all(action='DESELECT')
 for q in copies:q.select_set(True)
 bpy.context.view_layer.objects.active=copies[0]
 bpy.ops.export_scene.fbx(filepath=os.path.join(MODEL,name+'.fbx'),use_selection=True,object_types={'MESH'},axis_forward='Z',axis_up='Y',global_scale=1,apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,mesh_smooth_type='FACE')
 for q in copies:bpy.data.objects.remove(q,do_unlink=True)
 for o,original in originals.items():o.name=original;o.hide_set(True)
if '--geometry-only' not in sys.argv:textures()
# Sealed puffy sleeve. Its transverse rim visibly rises above the narrower trailing lip.
# 24 angular samples, 15 interior rings and two poles = 720 triangles.
profile=[(-.35,0),(-.34,.37),(-.31,.64),(-.265,.76),(-.21,.80),(-.14,.82),(-.07,.84),(0,.85),(.07,.91),(.13,.985),(.19,1),(.24,.96),(.28,.86),(.31,.71),(.333,.49),(.345,.24),(.35,0)]
verts=[];faces=[];uvs=[];N=24
for j,(z,r) in enumerate(profile):
 for k in range(N):
  a=k/N*2*math.pi;c=math.cos(a);v=math.sin(a)
  # Softly squared cross-section prevents leaf tips while retaining an upholstered arch.
  x=.5*r*math.copysign(abs(c)**.86,c)
  ridge=math.exp(-((z-.17)/.075)**2)
  # Strong padded opening lip, a low trailing sleeve, and a swept chevron crest.
  y=(.12*r*abs(v)**.85+.18*ridge*max(0,v)**.45) if v>=0 else -.12*r*abs(v)**.85
  shaped_z=z-.125*abs(c)**1.4*math.sin(math.pi*(z+.35)/.70)
  verts.append((x,y,shaped_z));uvs.append((k/N*2.0,(z+.35)/.70))
for j in range(len(profile)-1):
 for k in range(N):
  a=j*N+k;b=j*N+(k+1)%N;c=(j+1)*N+(k+1)%N;d=(j+1)*N+k
  if j==0:faces.append((a,c,d))
  elif j==len(profile)-2:faces.append((a,b,c))
  else:faces.append((a,b,c,d))
mesh=bpy.data.meshes.new('PuffySleeveMesh');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('CloudSegment',mesh);bpy.context.scene.collection.objects.link(o);mesh.materials.append(mats['Wool']);uv=mesh.uv_layers.new(name='UVMap')
for f in mesh.polygons:
 f.use_smooth=True
 for li in f.loop_indices:
  vi=mesh.loops[li].vertex_index;uv.data[li].uv=uvs[vi]
  if vi%N==0 and any(mesh.loops[t].vertex_index%N==N-1 for t in f.loop_indices):uv.data[li].uv.x=2.0
parts=[o];export('CloudSegment',parts);parts=[]
if '--segment-only' in sys.argv:
 o.hide_set(False);bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'ArtSource','CloudSegmentSource.blend'));print('SEGMENT_ONLY_COMPLETE');sys.exit(0)
# Original gentle cloud dragon: cream blunt horns, swept side fins, projecting short snout.
sphere('Head',(0,.14,0),(.445,.325,.40))
for side in (-1,1):
 horn=sphere('CloudHornL' if side<0 else 'CloudHornR',(side*.235,.435,-.17),(.105,.13,.14),'Cream',20,14)
 for v in horn.data.vertices:
  t=max(0,v.co.y/.13);v.co.x*=1-.30*t;v.co.z-=.13*t*t
 horn.rotation_euler[2]=-side*.22
 fin=sphere('ClothEarL' if side<0 else 'ClothEarR',(side*.46,.20,-.21),(.19,.09,.245),'Wool',20,14);fin.rotation_euler[2]=-side*.32;fin.rotation_euler[1]=side*.25
 sphere('FinFold',(side*.49,.25,-.15),(.14,.038,.16),'Wool',20,12)
 sphere('Cheek',(side*.29,.095,.285),(.19,.18,.18))
 sphere('CheekBlush',(side*.315,.145,.443),(.075,.043,.019),'Blush',16,10)
 sphere('EyeL' if side<0 else 'EyeR',(side*.218,.296,.362),(.083,.101,.047),'Eye')
 sphere('EyeGlint',(side*.218-.020,.332,.400),(.026,.029,.014),'Highlight',16,10)
 sphere('Brow',(side*.218,.429,.32),(.09,.022,.026),'Wool',20,10)
sphere('Muzzle',(0,.070,.443),(.29,.145,.265),'Wool')
sphere('LowerJaw',(0,-.022,.43),(.265,.075,.222),'Cream')
for side in (-1,1):sphere('TinyTooth',(side*.16,-.004,.653),(.026,.038,.021),'Cream',16,10)
for side in (-1,1):sphere('Nostril',(side*.125,.128,.657),(.018,.013,.012),'Cocoa',16,10)
# Curved smiling seam as real tube geometry; it remains part of the static Cocoa export.
curve=bpy.data.curves.new('SmileStitch','CURVE');curve.dimensions='3D';curve.resolution_u=2;curve.bevel_depth=.008;curve.bevel_resolution=2
spl=curve.splines.new('POLY');spl.points.add(12)
for i,p in enumerate(spl.points):
 x=(i/12-.5)*.23;p.co=(x,-.013+.034*(abs(x)/.115)**2,.673-.015*(abs(x)/.115)**2,1)
sm=bpy.data.objects.new('Smile',curve);bpy.context.scene.collection.objects.link(sm);sm.data.materials.append(mats['Cocoa']);bpy.ops.object.select_all(action='DESELECT');sm.select_set(True);bpy.context.view_layer.objects.active=sm;bpy.ops.object.convert(target='MESH');parts.append(bpy.context.object)
for x,y,z,size in [(0,.43,-.31,.075),(0,.37,-.40,.065)]:sphere('CloudTuft',(x,y,z),(size,size*.85,size),'Cream',20,12)
export('CloudDragonHead',parts);parts=[]
sphere('Body',(0,.37,0),(.3,.36,.235),'Cream')
sphere('CatHead',(0,.87,.04),(.39,.34,.29),'Cream')
for s in (-1,1):
 ear=sphere('EarL' if s<0 else 'EarR',(s*.255,1.12,.018),(.135,.2,.13),'Cream');ear.rotation_euler[2]=-s*.3
 for v in ear.data.vertices:v.co.x*=1-.65*max(0,v.co.y/.2)
 sphere('PinkEar',(s*.255,1.15,.116),(.071,.118,.032),'Blush')
 sphere('Foot',(s*.17,.085,.09),(.14,.105,.19),'Cream')
 sphere('WavePawL' if s<0 else 'WavePawR',(s*.285,.4,.16),(.105,.18,.12),'Cream')
 sphere('EyeL' if s<0 else 'EyeR',(s*.171,.925,.295),(.067,.085,.028),'Eye')
 sphere('EyeGlint',(s*.171-.018,.956,.321),(.023,.023,.011),'Highlight',16,10)
sphere('CheekPatch',(.26,.79,.25),(.125,.095,.055),'Cocoa')
sphere('Muzzle',(0,.79,.309),(.15,.087,.046),'Cream')
sphere('Nose',(0,.825,.354),(.043,.03,.02),'Nose',16,10)
sphere('Smile',(0,.756,.350),(.047,.012,.009),'Cocoa',16,10)
sphere('ScarfCollar',(0,.594,.007),(.315,.081,.255),'Scarf')
sc=sphere('ScarfEnd',(.13,.425,.237),(.072,.18,.048),'Scarf');sc.rotation_euler[2]=-.22
sphere('Tail',(.32,.25,-.13),(.14,.24,.105),'Cream')
export('CreamCat',parts)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'ArtSource','WoolLabOriginals.blend'))
with open(os.path.join(ROOT,'ArtSource','asset_manifest.json'),'w') as f:json.dump({'generator':'generate_art.py','blender':bpy.app.version_string,'original':True,'source_axes':'Y up / Z front','stitches_per_tile':4,'segment_bounds':[1,.407645,.70],'materials':colors},f,indent=2)
print('WOOLLAB_ART_COMPLETE')



