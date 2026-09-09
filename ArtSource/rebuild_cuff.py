import bpy,math,os
from mathutils import Vector,Matrix
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
# Original, inflated chevron knitted cuff. Crosswise bent cushion, not a straight sleeve.
# Width axis X; vertical Y; direction Z. Rounded lobe ends underlap the next cuff.
verts=[];faces=[];uvs=[];NX=25;NA=18
for j in range(NX):
 t=j/(NX-1)*2-1
 x=.50*t
 cap=math.sqrt(max(.00001,1-abs(t)**5))
 center=.145-.205*(math.sqrt(t*t+.0225)-.15)/.8612
 # A central crest and two distinct rounded backward lobes, visible in plan view.
 for k in range(NA):
  a=k/NA*math.tau
  z=center+.255*cap*math.cos(a)
  y=.025+.205*cap*math.sin(a)
  verts.append((x,y,z))
  u=(t+1)*.5 if math.sin(a)>=0 else 2-(t+1)*.5
  uvs.append((u,(z+.37)/.76))
for j in range(NX-1):
 for k in range(NA):
  a=j*NA+k;b=j*NA+(k+1)%NA;c=(j+1)*NA+(k+1)%NA;d=(j+1)*NA+k
  faces.append((a,b,c,d))
faces.append(tuple(reversed(range(NA))));faces.append(tuple((NX-1)*NA+k for k in range(NA)))
# Padded undersleeve joins the fork to the following segment through bends.
# It lies below the raised chevron and shares its material, UV direction and object.
base=len(verts); NR=8; NC=16
for j in range(NR+1):
 b=j/NR*math.pi; z=-.17+.29*math.cos(b); r=math.sin(b)
 for k in range(NC):
  a=k/NC*math.tau
  verts.append((.29*r*math.cos(a),-.035+.145*r*math.sin(a),z))
  uvs.append((k/NC*2,(z+.46)/.87))
for j in range(NR):
 for k in range(NC):
  a=base+j*NC+k;b=base+j*NC+(k+1)%NC;c=base+(j+1)*NC+(k+1)%NC;d=base+(j+1)*NC+k
  faces.append((a,b,c,d))
mesh=bpy.data.meshes.new('InflatedChevronCuff');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('CloudSegment',mesh);bpy.context.collection.objects.link(o)
# Correct normals independent of profile winding.
bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
uv=mesh.uv_layers.new(name='UVMap')
for f in mesh.polygons:
 f.use_smooth=True
 for li in f.loop_indices:uv.data[li].uv=uvs[mesh.loops[li].vertex_index]
m=bpy.data.materials.new('Wool');m.diffuse_color=(.03,.40,.84,1);m.use_nodes=True;mesh.materials.append(m)
p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(.03,.40,.84,1);p.inputs['Roughness'].default_value=.8
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'ArtSource','CloudSegmentSource.blend'))
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT,'UnityProject','Assets','CozyRescue','Art','Models','CloudSegment.fbx'),use_selection=True,object_types={'MESH'},axis_forward='Z',axis_up='Y',global_scale=1,apply_scale_options='FBX_SCALE_ALL',bake_space_transform=True,add_leaf_bones=False,mesh_smooth_type='FACE')
print('FBX_EXPORT_COMPLETE',flush=True)
# Review both straight overlap and a curved body, with physical knit and game-like camera.
n=m.node_tree.nodes;l=m.node_tree.links;uvnode=n.new('ShaderNodeTexCoord');scale=n.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs[3].default_value=3;l.new(uvnode.outputs['UV'],scale.inputs[0]);im=n.new('ShaderNodeTexImage');im.image=bpy.data.images.load(os.path.join(ROOT,'UnityProject','Assets','CozyRescue','Art','Textures','PhysicalKnitNormal.png'));im.image.colorspace_settings.name='Non-Color';l.new(scale.outputs[0],im.inputs['Vector']);nm=n.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.6;l.new(im.outputs['Color'],nm.inputs['Color']);l.new(nm.outputs['Normal'],p.inputs['Normal'])
for i in range(7):
 q=o if i==0 else o.copy()
 if i:bpy.context.collection.objects.link(q)
 q.location=((i-3)*.32,0,-1);q.rotation_euler[1]=math.pi/2
for i in range(20):
 q=o.copy();bpy.context.collection.objects.link(q);ang=-1.35+i*.14;q.location=(math.sin(ang)*2.35,0,1+math.cos(ang)*2.35);q.rotation_euler[1]=math.pi/2-ang
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,-.2,0),rotation=(math.pi/2,0,0));bpy.context.object.data.materials.append(bpy.data.materials.new('Floor'));bpy.context.object.data.materials[0].diffuse_color=(.64,.77,.82,1)
def aim(obj,at):
 z=(obj.location-Vector(at)).normalized();r=Vector((0,1,0)).cross(z).normalized();u=z.cross(r);obj.rotation_euler=Matrix((r,u,z)).transposed().to_euler()
bpy.ops.object.camera_add(location=(0,10,-2.6));cam=bpy.context.object;aim(cam,(0,0,1));cam.data.type='ORTHO';cam.data.ortho_scale=7;bpy.context.scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(-3,6,-3));lamp=bpy.context.object;lamp.data.energy=700;lamp.data.size=3;aim(lamp,(0,0,1))
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=32;sc.world.color=(.25,.25,.25);sc.render.resolution_x=1100;sc.render.resolution_y=1000;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG';sc.render.filepath=os.path.join(ROOT,'ArtSource','RebuiltCuffReview.png');sc.view_settings.view_transform='AgX';bpy.ops.render.render(write_still=True)
print('CUFF_REBUILD_COMPLETE',len(mesh.vertices),sum(len(p.vertices)-2 for p in mesh.polygons))





