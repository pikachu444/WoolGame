extends SceneTree
const State=preload("res://scripts/state.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Reference=preload("res://scripts/reference_stage.gd")
const Baseline=preload("C:/SourceCodes/WoolGame/BuildWork/Representative/Rules/baseline_campaign.gd")
var checks=0
var failures=[]
var identities={}
var records=[]
func check(ok: bool,name: String,detail: Variant=null):
 checks+=1
 if not ok and not identities.has(name):
  identities[name]=true; failures.append({"name":name,"detail":detail});print("FAIL ",name," ",JSON.stringify(detail))
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

func fresh_fixture(kind="repel",start_time=0.0):
 var s=State.new();s.reset(0,1,{"coins":300,"max_hearts":3,"shield":false,"freeze":false});s.time=start_time
 # Controlled marker on an existing exposed cyan unit; no quantities/order changed.
 for u in s.units:u.erase("power")
 var marked=-1
 for i in range(s.units.size()):
  if s.units[i].color==6 and s.exposed(i):marked=i;break
 check(marked>=0,"fixture has exposed cyan")
 if marked>=0:s.units[marked].power={"kind":kind,"duration":1.7 if kind=="repel" else 6.0,"distance":1000.0,"factor":0.25}
 return {"state":s,"unit_id":s.units[marked].id if marked>=0 else -1}
func acquire(fixture):
 var s=fixture.state;check(s.select(16),"real cyan selection accepted")
 var start=s.time
 while s.power_events.is_empty() and not s.lost and s.time-start<3:s.advance(0.01)
 check(s.power_events.size()==1,"capture activates exactly once",s.power_events)
 check(s.power_events[0].unit_id==fixture.unit_id if not s.power_events.is_empty() else false,"event uses captured marker identity")
 check(not s.units.any(func(u):return u.id==fixture.unit_id),"marked unit removed")
 return s
func test_trigger():
 var f=fresh_fixture();var s=f.state;s.advance(80);check(s.power_events.is_empty(),"time alone does not activate")
 f=fresh_fixture();s=f.state;check(s.select(0),"other color selected");s.advance(1.0);check(s.power_events.is_empty() and s.units.any(func(u):return u.id==f.unit_id),"other color cannot collect marker")
 var relative=[]
 for start_time in [0.0,200.0]:
  f=fresh_fixture("repel",start_time);s=acquire(f);relative.append(s.power_events[0].time-start_time)
  var count=s.power_events.size();s.advance(3.0);check(s.power_events.size()==count,"subsequent winding does not repeat marker")
 check(absf(relative[0]-relative[1])<0.011,"activation depends on capture not absolute clock",relative)
 records.append({"case":"capture trigger","relative_times":relative})
func test_repel():
 var f=fresh_fixture();var s=acquire(f);var d=s.dragons[0];var event=s.power_events[0].duplicate(true);s.blocks[16].next=s.time+100
 var from=float(d.repel_from);var to=float(d.repel_to);var start=float(d.repel_start);var until=float(d.until)
 check(d.phase=="repelled" and is_equal_approx(until-start,1.7),"repel duration1.7")
 check(is_equal_approx(from-to,minf(1000,from)),"repel distance1000 limited by path start",[from,to])
 s.advance(0.85);var midpoint=d.head;check(absf(midpoint-(from+to)/2)<1.0,"repel halfway is backwards halfway",[midpoint,from,to])
 var held=s.time;var held_head=d.head;s.paused=true;s.advance(2);check(s.time==held and d.head==held_head,"pause freezes repel");s.paused=false
 s.advance(maxf(0,until-s.time)+0.01);check(d.phase=="chasing" and absf(d.head-to)<1.0,"repel ends on path target",[d.head,to,d.phase])
 var before=d.head;s.advance(0.1);check(d.head>before,"chase resumes after repel")
 records.append({"case":"repel","event":event,"from":from,"to":to,"midpoint":midpoint,"duration":until-start})
func test_slow():
 var f=fresh_fixture("slow");var s=acquire(f);var d=s.dragons[0];s.blocks[16].next=s.time+100
 var start=s.time;var before=d.head;var until=float(d.slow_until)
 check(is_equal_approx(until-start,6) and is_equal_approx(d.slow_factor,0.25),"slow parameters6s quarter speed")
 s.advance(1);var slow_delta=d.head-before;check(absf(slow_delta-s.speed*0.25)<0.1,"slow actual movement quarter speed",slow_delta)
 s.advance(maxf(0,until-s.time)+0.02);before=d.head;s.advance(0.1);var normal_delta=d.head-before
 check(absf(normal_delta-s.speed*0.1)<0.1,"slow expires to normal movement",normal_delta)
 check(s.power_events.size()==1,"slow does not reactivate at expiry")
 records.append({"case":"slow","slow_delta_1s":slow_delta,"normal_delta_0_1s":normal_delta,"until":until,"start":start})
func test_continue_and_serialization():
 for kind in ["repel","slow"]:
  var f=fresh_fixture(kind);var s=acquire(f);s.lost=true;var prior=s.units.duplicate(true);var count=s.power_events.size()
  check(s.continue_run(),"continue accepts "+kind)
  check(s.units==prior and not s.units.any(func(u):return u.id==f.unit_id),"continue preserves consumed marker "+kind)
  s.advance(0.5);check(s.power_events.size()==count,"continue does not reactivate "+kind)
  var snap=s.snapshot();var encoded=JSON.stringify(snap);var decoded=JSON.parse_string(encoded)
  check(not decoded.units.any(func(u):return int(u.id)==f.unit_id),"serialized snapshot retains consumed absence "+kind)
  records.append({"case":"continue "+kind,"events":s.power_events,"snapshot_has_slow_timer":decoded.dragons[0].has("slow_until"),"note":"No product state restore API exists; snapshot encoding is not a save/resume validation"})
func test_windup():
 var s=State.new();s.reset(0,1,{"max_hearts":1,"shield":false,"freeze":false})
 for u in s.units:u.erase("power")
 s.first_departure=true;s.cat_anchor_index=s.definition.anchors.size()-1;s.cat_position=s.definition.anchors[-1];var d=s.dragons[0];var target=d.curve.get_closest_offset(s.cat_position);d.head=target-90;d.phase="chasing";d.until=0
 s.advance(0.01);var old_deadline=d.until;check(d.phase=="windup","windup control begins");check(s.select(0),"windup defence actual selection")
 while s.collected==0 and not s.lost and s.time<old_deadline:s.advance(0.01)
 s.blocks[0].next=s.time+100;s.advance(0.01)
 check(d.phase=="chasing" and target-d.head>100,"recoil cancels windup out of range")
 s.advance(maxf(0,old_deadline-s.time)+0.01);check(not s.lost and s.hearts==1,"old attack deadline no longer damages")
 while d.phase!="windup" and not s.lost and s.time<4:s.advance(0.01)
 var new_warning=s.time;check(d.phase=="windup" and d.until>old_deadline and absf(d.until-s.time-0.5)<0.011,"reapproach gets fresh half-second warning",[s.time,d.until,old_deadline])
 s.advance(0.35);check(s.hearts==1,"new warning is not immediate damage");s.advance(0.2);check(s.lost,"new warning expires into real nearby attack")
 records.append({"case":"attack cancellation","old_deadline":old_deadline,"new_warning":new_warning})
func test_other_stages():
 for level in range(10):
  if level==1:continue
  check(canonical(Campaign.definition(level))==canonical(Baseline.definition(level)),"other stage definition "+str(level+1))
  var s=State.new();s.reset(0,level);check(s.power_events.is_empty() and not s.units.any(func(u):return u.has("power")),"no added markers in other stage "+str(level+1))
func test_recovery():
 var f=fresh_fixture();var seed=f.state
 for u in seed.units:
  if u.id==f.unit_id:u.power.return_speed=335.0;u.power.return_to_fraction=2.0
 var s=acquire(f);var d=s.dragons[0];s.blocks[16].next=s.time+100
 var initial=float(d.repel_from);check(d.recover_to<=initial,"return target cannot exceed activation head",[d.recover_to,initial])
 while d.phase=="repelled" and s.time<5:s.advance(0.01)
 check(d.phase=="recovering","return phase begins after repel")
 var before=d.head;s.advance(0.2);var delta=d.head-before;check(absf(delta-335*0.2)<0.1,"return actual speed335",delta)
 var old_target=float(d.recover_to);var old_collected=s.collected;s.boost_until=s.time+2;s.blocks[16].next=s.time;s.advance(0.01)
 check(s.collected==old_collected+1,"additional actual winding during return")
 check(absf(d.recover_to-(old_target-s.head_recoil))<0.1,"return target shifts back with winding",[old_target,d.recover_to])
 check(s.power_events.size()==1,"return winding does not repeat ability")
 s.blocks[16].next=s.time+100;s.boost_until=0
 while d.phase=="recovering" and s.time<10:
  s.advance(0.01);check(d.head<=d.recover_to+0.01,"return does not overshoot target")
 check(d.phase=="chasing" and absf(d.head-d.recover_to)<0.01,"return ends precisely at target",[d.head,d.recover_to])
 before=d.head;s.advance(0.1);check(absf(d.head-before-s.speed*0.1)<0.1,"ordinary speed resumes after return")
 records.append({"case":"return phase","activation_head":initial,"target_before_extra_winding":old_target,"target_after":d.recover_to,"speed_measurement_0_2s":delta})
 for phase in ["windup","fire"]:
  f=fresh_fixture();s=f.state;check(s.select(16),"power attack fixture select")
  s.advance(0.3);d=s.dragons[0];s.cat_anchor_index=s.definition.anchors.size()-1;s.cat_position=s.definition.anchors[-1];d.head=d.curve.get_closest_offset(s.cat_position)-90;d.phase=phase;d.until=s.time+0.5
  while s.power_events.is_empty() and s.time<1:s.advance(0.01)
  check(s.power_events.size()==1 and d.phase=="repelled","power replaces active "+phase,{"phase":d.phase,"powers":s.power_events})
func test_stage_markers():
 var s=State.new();s.reset(0,1);var declared=s.definition.get("yarn_powers",[])
 check(declared.size()==2,"representative declares two powers")
 var seen={}
 for power in declared:
  var id=int(power.unit_id);check(id>=0 and id<s.units.size() and not seen.has(id),"declared power IDs valid unique",power);seen[id]=true
  if id>=0 and id<s.units.size():check(s.units[id].color==1 and s.units[id].power==power,"actual yellow unit receives declared power",s.units[id])
 records.append({"case":"actual stage marker wiring","markers":declared,"note":"Full observed ordinal verification is in final-replay.json"})
func test_floor_boundaries():
 var boundaries=[]
 for relative in [10.0,-80.0]:
  var s=State.new();s.reset(0,1)
  for u in s.units:u.erase("power")
  var floor=s.route_length*float(s.definition.recoil_floor_fraction);s.head=floor+relative;s.freeze_until=100
  var before=s.head;check(s.select(16),"floor fixture normal selection")
  while s.collected==0 and s.time<2:s.advance(0.01)
  check(s.collected==1,"floor fixture real capture")
  var expected=floor if relative>0 else before
  check(absf(s.head-expected)<0.001,"normal recoil clamp preserves below-floor head",[before,s.head,expected])
  boundaries.append({"relative_to_floor":relative,"before":before,"after":s.head,"floor":floor})
 records.append({"case":"ordinary recoil floor boundaries","measurements":boundaries})
func _initialize():
 var hashes_start={}
 for path in ["state","campaign","reference_stage"]:hashes_start[path]=FileAccess.get_sha256("res://scripts/"+path+".gd")
 test_trigger();test_repel();test_slow();test_continue_and_serialization();test_windup();test_other_stages();test_recovery();test_stage_markers();test_floor_boundaries()
 var loaded={"state":FileAccess.get_sha256("res://scripts/state.gd"),"campaign":FileAccess.get_sha256("res://scripts/campaign.gd"),"reference_stage":FileAccess.get_sha256("res://scripts/reference_stage.gd")}
 check(hashes_start==loaded,"source stable during unit execution",[hashes_start,loaded])
 var report={"source_sha256_at_start":hashes_start,"source_sha256_at_end":loaded,"scope":"frozen candidate07 effect unit regression; full stage replay in final-replay.json","checks":checks,"failures":failures,"records":records,"stage_has_yarn_powers":Campaign.definition(1).has("yarn_powers"),"stage_powers":Campaign.definition(1).get("yarn_powers",[]),"save_limit":"Game has no mid-run State restore API; continue and snapshot serialization only were tested."}
 var f=FileAccess.open("C:/SourceCodes/WoolGame/Evidence/Rebuild/Representative/Rules/final-power-units.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
