import bpy,os,math
from mathutils import Vector,Matrix
root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.open_mainfile(filepath=os.path.join(root,'ArtSource','CloudSegmentSource.blend'))
base=bpy.data.objects['CloudSegment'];base.hide_set(False)
for i in range(5):
 o=base if i==0 else base.copy()
 if i: o.data=base.data;bpy.context.scene.collection.objects.link(o)
 o.location=( (i-2)*.45,0,0);o.rotation_euler[1]=math.pi/2
m=base.data.materials[0];m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF');p.inputs['Base Color'].default_value=(.66,.17,.09,1);p.inputs['Roughness'].default_value=.85
tex=os.path.join(root,'UnityProject','Assets','CozyRescue','Art','Textures');uv=n.new('ShaderNodeTexCoord');scale=n.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs[3].default_value=3;l.new(uv.outputs['UV'],scale.inputs[0]);im=n.new('ShaderNodeTexImage');im.image=bpy.data.images.load(os.path.join(tex,'PhysicalKnitNormal.png'));im.image.colorspace_settings.name='Non-Color';l.new(scale.outputs[0],im.inputs['Vector']);normal=n.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.55;l.new(im.outputs['Color'],normal.inputs['Color']);l.new(normal.outputs['Normal'],p.inputs['Normal'])
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,-.135,0),rotation=(math.pi/2,0,0));floor=bpy.context.object;mat=bpy.data.materials.new('Background');mat.diffuse_color=(.7,.75,.74,1);floor.data.materials.append(mat)
def aim(o,target):
 z=(o.location-Vector(target)).normalized();r=Vector((0,1,0)).cross(z).normalized();u=z.cross(r);o.rotation_euler=Matrix((r,u,z)).transposed().to_euler()
bpy.ops.object.camera_add(location=(0,6,-2.184));cam=bpy.context.object;aim(cam,(0,0,0));cam.data.type='ORTHO';cam.data.ortho_scale=3.3;bpy.context.scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(-3,5,-3));light=bpy.context.object;light.data.energy=450;light.data.size=3;aim(light,(0,0,0))
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=32;sc.world.color=(.3,.3,.3);sc.render.resolution_x=1100;sc.render.resolution_y=650;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG';sc.render.filepath=os.path.join(root,'ArtSource','CloudSegmentOverlapPreview.png');sc.view_settings.view_transform='AgX';bpy.ops.render.render(write_still=True)
