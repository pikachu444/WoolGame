extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
const State=preload("res://scripts/state.gd")
const Board=preload("res://scripts/board.gd")
func canonical(value):
 if value is Curve2D:
  var points=[]
  for i in range(value.point_count):points.append([canonical(value.get_point_position(i)),canonical(value.get_point_in(i)),canonical(value.get_point_out(i))])
  return {"kind":"Curve2D","bake_interval":value.bake_interval,"points":points}
 if typeof(value)==TYPE_VECTOR2 or typeof(value)==TYPE_VECTOR2I:return [value.x,value.y]
 if typeof(value)==TYPE_ARRAY:
  var list=[]
  for item in value:list.append(canonical(item))
  return list
 if typeof(value)==TYPE_DICTIONARY:
  var result={};var keys=value.keys();keys.sort()
  for key in keys:result[key]=canonical(value[key])
  return result
 return value
func _initialize():
 var destination=OS.get_cmdline_user_args()[0]
 var hashes={}
 for file in DirAccess.get_files_at("res://scripts"):
  if file.ends_with(".gd"):hashes[file]=FileAccess.get_sha256("res://scripts/"+file)
 var definitions=[];var initial_states=[];var lessons=[]
 for level in range(10):
  var definition=Campaign.definition(level);lessons.append(definition.lesson);definition.erase("lesson");definitions.append(canonical(definition))
  var s=State.new();s.reset(0,level,{"mode":"challenge","coins":300,"max_hearts":1,"shield":false,"freeze":false})
  initial_states.append(canonical({"blocks":s.blocks,"units":s.units,"slots":s.slots,"dragons":s.dragons,"cat_position":s.cat_position,"total":s.total,"speed":s.speed}))
 var added='  if state.level_index>=4:
   WoolArt.box(self,Rect2(Vector2(-11,size.y/2-12),Vector2(22,12)),Color("253d3c"),4)
   WoolArt.text(self,str(b.capacity),Vector2(0,size.y/2-2),12,Color("fff9e8"))
'
 var board_source=FileAccess.get_file_as_string("res://scripts/board.gd")
 var campaign_source=FileAccess.get_file_as_string("res://scripts/campaign.gd")
 var report={"definitions_without_lessons":definitions,"initial_states":initial_states,"lessons":lessons,"resource_hashes":hashes,"board_expected_addition_count":board_source.count(added),"board_without_expected_addition_sha256":board_source.replace(added,"").sha256_text(),"campaign_without_expected_lesson_change_sha256":campaign_source.replace("숫자는 실의 양 · 감는 동안 다음 색을 골라요","긴 실을 감는 동안 다음 색을 골라요").sha256_text()}
 var file=FileAccess.open(destination,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close();print("INDEPENDENT_CAPACITY_EQUIVALENCE definitions=",definitions.size()," states=",initial_states.size()," resources=",hashes.size());quit()
