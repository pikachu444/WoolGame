import bpy, math, os, json
from mathutils import Vector, Matrix
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=os.path.join(ROOT,'UnityProject','Assets','CozyRescue','Art','Models')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
colors={'Wool':(.82,.19,.015,1),'Cream':(1,.70,.25,1),'Blush':(.97,.31,.25,1),'Cocoa':(.24,.075,.022,1),'Eye':(.055,.027,.014,1),'EyeWhite':(1,.96,.84,1),'Highlight':(1,1,1,1),'Scarf':(.79,.055,.07,1),'Nose':(.55,.15,.11,1)}
mats={}
for n,c in colors.items():
 m=bpy.data.materials.new(n);m.diffuse_color=c;m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=c;p.inputs['Roughness'].default_value=.3 if n in ('Eye','Highlight','EyeWhite') else .72
 if n in ('Wool','Cream'):
  tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(os.path.join(ROOT,'UnityProject','Assets','CozyRescue','Art','Textures','PhysicalKnitNormal.png'),check_existing=True);tex.image.colorspace_settings.name='Non-Color'
  uv=m.node_tree.nodes.new('ShaderNodeTexCoord');mapping=m.node_tree.nodes.new('ShaderNodeVectorMath');mapping.operation='SCALE';mapping.inputs[3].default_value=3
  norm=m.node_tree.nodes.new('ShaderNodeNormalMap');norm.inputs['Strength'].default_value=.35
  m.node_tree.links.new(uv.outputs['UV'],mapping.inputs[0]);m.node_tree.links.new(mapping.outputs[0],tex.inputs[0]);m.node_tree.links.new(tex.outputs[0],norm.inputs['Color']);m.node_tree.links.new(norm.outputs[0],p.inputs['Normal'])
 mats[n]=m
parts=[]
def sphere(n,loc,scale,mat='Wool',seg=24,rings=16):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=loc);o=bpy.context.object;o.name=n;
 for v in o.data.vertices:
  q=v.co.copy();v.co=(q.x,q.z,-q.y)
 o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[mat]);parts.append(o)
 for f in o.data.polygons:f.use_smooth=True
 return o
def line(n,points,r,mat):
 cu=bpy.data.curves.new(n,'CURVE');cu.dimensions='3D';cu.bevel_depth=r;cu.bevel_resolution=2;cu.use_fill_caps=True;sp=cu.splines.new('BEZIER');sp.bezier_points.add(len(points)-1)
 for b,p in zip(sp.bezier_points,points):b.co=p;b.handle_left_type='AUTO';b.handle_right_type='AUTO'
 o=bpy.data.objects.new(n,cu);bpy.context.collection.objects.link(o);o.data.materials.append(mats[mat]);bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH');parts.append(bpy.context.object)
def tapered(n,loc,scale,mat):
 o=sphere(n,loc,scale,mat)
 for v in o.data.vertices:
  t=(v.co.y/scale[1]+1)*.5;v.co.x*=1-.70*t;v.co.z*=1-.4*t
 return o
assets={}
def finish(name):
 global parts
 objs=parts;parts=[];assets[name]=objs
 # Static surfaces combine by material; animation parts retain individual names.
 copies=[];groups={};names={o:o.name for o in objs}
 for o in objs:o.name='SOURCE_'+o.name
 for o in objs:
  q=o.copy();q.data=o.data.copy();bpy.context.collection.objects.link(q);q.name=names[o]
  if q.name.startswith(('EyeL','EyeR','EyeGlint','WavePaw')):copies.append(q)
  else:groups.setdefault(q.data.materials[0].name,[]).append(q)
 for mat,grp in groups.items():
  bpy.ops.object.select_all(action='DESELECT')
  for q in grp:q.select_set(True)
  bpy.context.view_layer.objects.active=grp[0]
  if len(grp)>1:bpy.ops.object.join()
  q=bpy.context.object;q.name=name+'_'+mat;copies.append(q)
 bpy.ops.object.select_all(action='DESELECT')
 for q in copies:q.select_set(True)
 bpy.context.view_layer.objects.active=copies[0]
 bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,name+'.fbx'),use_selection=True,object_types={'MESH'},axis_forward='Z',axis_up='Y',global_scale=1,apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,mesh_smooth_type='FACE')
 for q in copies:bpy.data.objects.remove(q,do_unlink=True)
 for o in objs:o.name=names[o];o.hide_render=True;o.hide_set(True)
# Strong pear-shaped head with short projecting double-lobed muzzle.
sphere('DragonCranium',(0,.20,-.025),(.42,.40,.37))
sphere('DragonMuzzle',(0,.075,.345),(.35,.21,.31),'Cream')
sphere('DragonBridge',(0,.28,.20),(.265,.23,.235))
sphere('DragonJaw',(0,-.06,.30),(.30,.105,.24),'Cream')
for s in (-1,1):
 tapered('IvoryHorn',(s*.25,.58,-.19),(.11,.235,.12),'Cream')
 fin=tapered('SweptFin',(s*.46,.24,-.19),(.20,.15,.095),'Wool');fin.rotation_euler[2]=-s*.60
 sphere('WarmCheek',(s*.30,.09,.30),(.145,.135,.13))
 sphere('PinkCheek',(s*.327,.16,.408),(.06,.043,.022),'Blush',20,12)
 sphere('EyeSocket',(s*.225,.367,.24),(.15,.18,.105))
 sphere('EyeWhite',(s*.222,.372,.313),(.112,.141,.068),'EyeWhite')
 sphere('EyeL' if s<0 else 'EyeR',(s*.205,.365,.370),(.071,.090,.028),'Eye')
 sphere('EyeGlint',(s*.205-.020,.402,.391),(.024,.028,.013),'Highlight',16,10)
 brow=sphere('Brow',(s*.225,.505,.32),(.13,.040,.068));brow.rotation_euler[2]=-s*.17
 sphere('Nostril',(s*.16,.169,.584),(.030,.022,.014),'Cocoa',16,10)
 line('SmileCorner',[(s*.27,.05,.544),(s*.24,.006,.564),(s*.16,-.024,.580)],.012,'Cocoa')
line('Smile',[(-.16,-.024,.58),(0,-.043,.589),(.16,-.024,.58)],.012,'Cocoa')
finish('CloudDragonHead')
# A seated kitten: compact torso, oversized head, real triangular ears and paired whiskers.
sphere('KittenBody',(0,.28,-.015),(.235,.29,.19),'Cream')
sphere('KittenHead',(0,.73,.03),(.35,.285,.255),'Cream')
for s in (-1,1):
 # Rounded triangular prism with bevels: unmistakable feline silhouette.
 verts=[(s*.12,.87,-.09),(s*.33,.87,-.09),(s*.29,1.16,-.04),(s*.12,.87,.09),(s*.33,.87,.09),(s*.29,1.16,.035)]
 me=bpy.data.meshes.new('PointedEar');me.from_pydata(verts,[],[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)]);me.update();o=bpy.data.objects.new('PointedEar',me);bpy.context.collection.objects.link(o);o.data.materials.append(mats['Cream']);parts.append(o);be=o.modifiers.new('Soft seam','BEVEL');be.width=.025;be.segments=3;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=be.name)
 for f in o.data.polygons:f.use_smooth=True
 inner=tapered('EarPink',(s*.253,.973,.082),(.059,.122,.019),'Blush');inner.rotation_euler[2]=-s*.15
 sphere('Foot',(s*.125,.035,.13),(.107,.077,.15),'EyeWhite')
 sphere('WavePawL' if s<0 else 'WavePawR',(s*.23,.27,.11),(.074,.15,.084),'Cream')
 sphere('EyeWhite',(s*.145,.777,.249),(.103,.116,.037),'EyeWhite')
 sphere('EyeL' if s<0 else 'EyeR',(s*.139,.778,.278),(.074,.088,.025),'Eye')
 sphere('EyeGlint',(s*.139-.024,.810,.298),(.026,.028,.011),'Highlight',16,10)
 sphere('MuzzleLobe',(s*.068,.636,.270),(.088,.065,.056),'EyeWhite')
 for k in range(2):
  y=.649-k*.049
  line('Whisker',[(s*.20,y,.242),(s*.31,y+.006,.267),(s*.41,y+.035,.268)],.005,'Cocoa')
 line('CatMouth',[(0,.631,.323),(s*.052,.611,.322),(s*.084,.636,.309)],.007,'Cocoa')
sphere('Nose',(0,.668,.324),(.035,.025,.019),'Nose',16,10)
sphere('ScarfCollar',(0,.466,.006),(.246,.051,.194),'Scarf')
sphere('ScarfKnot',(-.11,.439,.19),(.062,.065,.055),'Scarf')
sc=sphere('ScarfEnd',(-.15,.335,.17),(.045,.12,.035),'Scarf');sc.rotation_euler[2]=-.2
line('CurledTail',[(.17,.10,-.12),(.31,.12,-.15),(.36,.23,-.13),(.29,.30,-.11)],.06,'Cream')
finish('CreamCat')
manifest={}
for name,objs in assets.items():
 points=[o.matrix_world@Vector(v) for o in objs for v in o.bound_box];bounds=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)];tri=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objs);manifest[name]={'bounds_Yup':bounds,'triangles':tri,'source_objects':len(objs)}
# Reference-angle review renders. Source coordinates remain Y-up, +Z face.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=900;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world.color=(.25,.25,.25);scene.view_settings.view_transform='AgX'
def orient(o,target):
 f=(Vector(target)-o.location).normalized();r=f.cross(Vector((0,1,0))).normalized();u=r.cross(f);o.rotation_euler=Matrix((r,u,-f)).transposed().to_euler()
bpy.ops.object.camera_add(location=(1.65,2.5,5));cam=bpy.context.object;orient(cam,(0,.35,.1));cam.data.type='ORTHO';cam.data.ortho_scale=1.8;scene.camera=cam
for loc,energy,size in [((-3,5,4),650,4),((3,2,1),180,3),((0,3,-3),250,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);light=bpy.context.object;light.data.energy=energy;light.data.shape='DISK';light.data.size=size;orient(light,(0,.3,0))
scene.render.film_transparent=True
for name,objs in assets.items():
 for o in objs:o.hide_render=False
 cam.data.ortho_scale=1.65 if name=='CloudDragonHead' else 1.5
 orient(cam,(0,.25 if name=='CloudDragonHead' else .53,.12))
 scene.render.filepath=os.path.join(ROOT,'ArtSource',name+'_rebuild_preview.png');bpy.ops.render.render(write_still=True)
 for o in objs:o.hide_render=True
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'ArtSource','CharacterRebuild.blend'))
with open(os.path.join(ROOT,'ArtSource','character_rebuild_manifest.json'),'w') as f:json.dump({'original':True,'axes':'Y up, +Z front','assets':manifest,'materials':colors},f,indent=2)
print(json.dumps(manifest))


