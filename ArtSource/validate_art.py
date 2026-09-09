import bpy,os,json
from mathutils import Vector
root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)));report={}
for name in ['CloudSegment','CloudDragonHead','CreamCat']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.fbx(filepath=os.path.join(root,'UnityProject','Assets','CozyRescue','Art','Models',name+'.fbx'))
 objs=list(bpy.context.selected_objects);points=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box]
 report[name]={'objects':len(objs),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objs),'bounds_imported_blender':[[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)],'object_names':[o.name for o in objs]}
with open(os.path.join(root,'ArtSource','mesh_validation.json'),'w') as f:json.dump(report,f,indent=2)
print(json.dumps(report,indent=2))
