"""Bake original three-ply interlocking stocking-stitch geometry; never reads reference pixels.
Run Blender --background --python ArtSource/bake_knit_physical.py.
Outputs versioned maps only. Existing KnitNormal/KnitAO are deliberately untouched.
"""
import bpy,math,os,json
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEX=os.path.join(ROOT,'UnityProject','Assets','CozyRescue','Art','Textures');ART=os.path.join(ROOT,'ArtSource')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
# A stocking stitch: two sloping legs and a rounded upper return. Upper returns lie
# beneath the following row's neck; the exact crossing height is geometrical.
controls=[(-.055,-.08,.19),(-.13,.16,.155),(-.27,.47,.14),(-.29,.72,.105),(-.22,.93,.060),(0,1.02,.055),(.22,.93,.060),(.29,.72,.105),(.27,.47,.14),(.13,.16,.155),(.055,-.08,.19)]
def catmull(p0,p1,p2,p3,t):return .5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)
p=[Vector(q) for q in controls];samples=[]
for k in range(len(p)-1):
 for j in range(9):samples.append(catmull(p[max(0,k-1)],p[k],p[k+1],p[min(len(p)-1,k+2)],j/9))
samples.append(p[-1]);verts=[];faces=[]
# 4x4 tile plus full neighbor rows/columns prevents bake borders from differing.
for row in range(-3,8):
 for col in range(-2,7):
  path=[q+Vector((col*.60+.30,row*.50,0)) for q in samples]
  length=0
  for ply in range(3):
   start=len(verts);prev=None
   for i,q in enumerate(path):
    if prev is not None:length+=(q-prev).length
    prev=q;t=(path[min(i+1,len(path)-1)]-path[max(0,i-1)]).normalized()
    side=t.cross(Vector((0,0,1))).normalized();up=t.cross(side).normalized()
    phase=i*.62+ply*2*math.pi/3
    center=q+.038*(side*math.cos(phase)+up*math.sin(phase))
    for j in range(7):
     a=j/7*2*math.pi;v=center+.047*(side*math.cos(a)+up*math.sin(a));verts.append(tuple(v))
   for i in range(len(path)-1):
    for j in range(7):a=start+i*7+j;b=start+i*7+(j+1)%7;faces.append((a,b,b+7,a+7))
# A soft continuous backing layer closes the knit valleys and gives AO actual depth instead of ray-miss black.
base=len(verts);verts.extend([(-3,-3,-.045),(6,-3,-.045),(6,6,-.045),(-3,6,-.045)]);faces.append((base,base+1,base+2,base+3))
mesh=bpy.data.meshes.new('OriginalThreePlyLoopMesh');mesh.from_pydata(verts,[],faces);mesh.update();high=bpy.data.objects.new('PhysicalStockinetteSource',mesh);scene.collection.objects.link(high)
for f in mesh.polygons:f.use_smooth=True
wool=bpy.data.materials.new('PhysicalYarn');wool.diffuse_color=(.16,.48,.59,1);wool.use_nodes=True;bs=wool.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.16,.48,.59,1);bs.inputs['Roughness'].default_value=.86;high.data.materials.append(wool)
# Plane spans exactly four columns/four rows. Relative tile aspect = 2.4:2.0.
bpy.ops.mesh.primitive_plane_add(size=2,location=(1.2,1.0,-.015));low=bpy.context.object;low.name='BakedTile';low.scale=(1.2,1.0,1);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
mat=bpy.data.materials.new('PhysicalBakedYarn');mat.use_nodes=True;low.data.materials.append(mat);nodes=mat.node_tree.nodes;links=mat.node_tree.links;bs=nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.16,.48,.59,1);bs.inputs['Roughness'].default_value=.86
scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.43;scene.render.bake.max_ray_distance=.7;scene.render.bake.margin=0
images={}
for label,kind in [('PhysicalKnitNormal','NORMAL'),('PhysicalKnitAO','AO')]:
 im=bpy.data.images.new(label,width=1024,height=1024,alpha=False);im.colorspace_settings.name='Non-Color';node=nodes.new('ShaderNodeTexImage');node.image=im;nodes.active=node
 bpy.ops.object.select_all(action='DESELECT');high.select_set(True);low.select_set(True);bpy.context.view_layer.objects.active=low
 bpy.ops.object.bake(type=kind)
 im.filepath_raw=os.path.join(TEX,label+'.png');im.file_format='PNG';im.save();images[label]=im
normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=1;normaltex=nodes.new('ShaderNodeTexImage');normaltex.image=images['PhysicalKnitNormal'];links.new(normaltex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bs.inputs['Normal'])
aotex=nodes.new('ShaderNodeTexImage');aotex.image=images['PhysicalKnitAO'];mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[1].default_value=(.16,.48,.59,1);links.new(aotex.outputs['Color'],mix.inputs[2]);links.new(mix.outputs[0],bs.inputs['Base Color'])
# Preview baked plane under grazing light, independent from high source render.
high.hide_render=True;scene.world.color=(.20,.20,.20)
bpy.ops.object.camera_add(location=(1.2,-1.8,4));cam=bpy.context.object;cam.rotation_euler=(Vector((1.2,1.0,0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.0;scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(-1,-1,3));light=bpy.context.object;light.data.energy=180;light.data.size=3;light.rotation_euler=(Vector((1.2,1.0,0))-light.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=900;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX';scene.render.filepath=os.path.join(ART,'PhysicalKnitBakedPreview.png');bpy.ops.render.render(write_still=True)
# Save standalone editable source, including low plane and generated image nodes.
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART,'PhysicalKnitSource.blend'))
with open(os.path.join(ART,'physical_knit_manifest.json'),'w') as f:json.dump({'original':True,'blender':bpy.app.version_string,'stitches':[4,4],'normal':'OpenGL tangent space','source_triangles':sum(len(q.vertices)-2 for q in high.data.polygons),'samples':24,'source':'three helical plys following raised knit legs and underpassing rounded return','texture_resolution':1024},f,indent=2)
print('PHYSICAL_KNIT_BAKE_COMPLETE')


