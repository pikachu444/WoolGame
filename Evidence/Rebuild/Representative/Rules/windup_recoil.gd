extends SceneTree
const State=preload("res://scripts/state.gd")
func scenario(select_block):
 var s=State.new();s.reset(0,1,{"max_hearts":1,"shield":false,"freeze":false})
 s.cat_anchor_index=s.definition.anchors.size()-1;s.cat_position=s.definition.anchors[-1]
 var d=s.dragons[0];var target=d.curve.get_closest_offset(s.cat_position);d.head=target-90;d.phase="chasing";d.until=0
 var events=[];var captures=[]
 var cb=func(u,b):captures.append({"time":s.time,"block":b.id,"head_before":d.head,"gap_before":target-d.head,"phase":d.phase})
 s.captured.connect(cb);s.advance(0.01)
 events.append({"time":s.time,"event":"warning","phase":d.phase,"gap":target-d.head,"deadline":d.until,"hearts":s.hearts})
 var selected=-1
 if select_block:
  for b in s.blocks:
   if s.can_select(b.id) and s.available(b.color):selected=b.id;break
  if selected>=0:s.select(selected)
 var last_count=0
 while not s.lost and s.time<0.72:
  s.advance(0.01)
  if s.collected!=last_count:
   events.append({"time":s.time,"event":"collected","phase":d.phase,"gap":target-d.head,"head":d.head,"hearts":s.hearts,"collected":s.collected});last_count=s.collected
 s.captured.disconnect(cb)
 return {"selected":selected,"events":events,"captures":captures,"end":{"time":s.time,"phase":d.phase,"gap":target-d.head,"hearts":s.hearts,"lost":s.lost,"collected":s.collected},"fixture":"Placed normal state at final cat anchor and initial90px approach; all selection/winding afterwards through normal API"}
func _initialize():
 var report={"capture_during_windup":scenario(true),"no_capture_control":scenario(false),"state_sha256":FileAccess.get_sha256("res://scripts/state.gd"),"reference_sha256":FileAccess.get_sha256("res://scripts/reference_stage.gd")}
 var f=FileAccess.open("C:/SourceCodes/WoolGame/Evidence/Rebuild/Representative/Rules/windup_recoil_before.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print(JSON.stringify(report));quit()
