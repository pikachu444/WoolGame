import bpy,os,math,json
from mathutils import Vector, Matrix
root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.open_mainfile(filepath=os.path.join(root,'ArtSource','WoolLabOriginals.blend'))
for coll in bpy.data.collections:
 shift={'CloudSegment':(-1.7,.3,0),'CloudDragonHead':(0,.35,0),'CreamCat':(1.7,0,0)}.get(coll.name)
 if shift:
  for o in coll.objects:o.hide_set(False);o.location+=Vector(shift)
# Preview materials use our maps; spherical UVs preview fixed-density tiling.
tex=os.path.join(root,'UnityProject','Assets','CozyRescue','Art','Textures')
for m in bpy.data.materials:
 if m.name not in ['Wool','Cream','Scarf']:continue
 n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF')
 uv=n.new('ShaderNodeTexCoord');scale=n.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs[3].default_value=4;l.new(uv.outputs['UV'],scale.inputs[0])
 im=n.new('ShaderNodeTexImage');im.image=bpy.data.images.load(os.path.join(tex,'KnitNormal.png'),check_existing=True);im.image.colorspace_settings.name='Non-Color';l.new(scale.outputs[0],im.inputs['Vector'])
 norm=n.new('ShaderNodeNormalMap');norm.inputs['Strength'].default_value=.8;l.new(im.outputs['Color'],norm.inputs['Color']);l.new(norm.outputs['Normal'],p.inputs['Normal'])
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,-.045,0),rotation=(math.pi/2,0,0))
f=bpy.context.object;f.name='PreviewBackdrop';m=bpy.data.materials.new('Backdrop');m.diffuse_color=(.76,.84,.85,1);f.data.materials.append(m)
def aim(o,target):
 z=(o.location-Vector(target)).normalized();r=Vector((0,1,0)).cross(z).normalized();u=z.cross(r);o.rotation_euler=Matrix((r,u,z)).transposed().to_euler()
bpy.ops.object.camera_add(location=(0,3.8,7));cam=bpy.context.object;cam.name='ArtPreviewCamera';aim(cam,(0,.65,0));cam.data.type='ORTHO';cam.data.ortho_scale=5.5;bpy.context.scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(-3,5,4));light=bpy.context.object;light.data.energy=450;light.data.shape='DISK';light.data.size=5;aim(light,(0,.4,0))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.world.color=(.45,.45,.45);scene.render.resolution_x=1400;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.filepath=os.path.join(root,'ArtSource','ArtPreview.png');scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(root,'ArtSource','ArtPreview.blend'));bpy.ops.render.render(write_still=True)


