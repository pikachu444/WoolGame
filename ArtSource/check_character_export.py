import bpy,json,os
from mathutils import Vector
root=r'C:\SourceCodes\WoolGame'
f=os.path.join(root,'ArtSource','character_rebuild_manifest.json')
with open(f) as h:data=json.load(h)
for name in data['assets']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.fbx(filepath=os.path.join(root,'UnityProject','Assets','CozyRescue','Art','Models',name+'.fbx'))
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[o.matrix_world@Vector(v) for o in obs for v in o.bound_box]
 data['assets'][name]['fbx_roundtrip_blender_world_bounds']=[max(p[i] for p in pts)-min(p[i] for p in pts) for i in range(3)]
 data['assets'][name]['fbx_mesh_objects']=len(obs)
 data['assets'][name]['animated_names']=[o.name for o in obs if o.name.startswith(('EyeL','EyeR','WavePaw'))]
with open(f,'w') as h:json.dump(data,h,indent=2)
print(json.dumps(data['assets']))
