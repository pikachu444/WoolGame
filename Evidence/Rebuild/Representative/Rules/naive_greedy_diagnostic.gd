extends SceneTree
const State=preload("res://scripts/state.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Baseline=preload("C:/SourceCodes/WoolGame/BuildWork/Representative/Rules/baseline_campaign.gd")
var source=JSON.parse_string(FileAccess.get_file_as_string("C:/SourceCodes/WoolGame/Evidence/Rebuild/Representative/Reference/level2_replay_observed.json"))
var checks=0
var failures=[]
var identities={}
var runs=[]
func check(ok: bool,name: String,detail: Variant=null):
 checks+=1
 if not ok and not identities.has(name):
  identities[name]=true; failures.append({"name":name,"detail":detail});print("FAIL ",name," ",JSON.stringify(detail))

func counts(items,field):
 var d={}
 for item in items:d[item.color]=int(d.get(item.color,0))+int(item.get(field,1))
 return d

func invariant(s,label):
 var remaining=counts(s.blocks,"remaining");var yarn=counts(s.units,"quantity")
 for color in remaining:check(remaining[color]==yarn.get(color,0),label+" conservation color"+str(color),[remaining,yarn])
 check(s.collected+s.units.size()==s.total,label+" total",s.snapshot())
 var occupied=[]
 for i in range(s.slots.size()):
  var id=s.slots[i]
  if id<0:continue
  check(not occupied.has(id),label+" duplicate slot",s.slots);occupied.append(id)
  check(s.blocks[id].slot==i,label+" slot ownership",[i,id,s.blocks[id]])
  check(s.blocks[id].phase in ["travel","working","clearing"],label+" slot phase",s.blocks[id])
 for b in s.blocks:
  check(b.remaining>=0 and b.remaining<=b.capacity,label+" bounded remaining",b)
  check((b.phase=="reserve")==s.reserve.has(b.id),label+" reserve ownership",b)

func own_clear(s,b):
 if b.phase=="reserve":return true
 if b.phase!="board":return false
 var left=b.cell.x;var right=left+b.size.x;var top=b.cell.y;var bottom=top+b.size.y-12
 for other in s.blocks:
  if other.id==b.id or other.phase!="board":continue
  var ol=other.cell.x;var oright=ol+other.size.x;var ot=other.cell.y;var ob=ot+other.size.y-12
  var overlaps_x=min(right,oright)>max(left,ol)
  var overlaps_y=min(bottom,ob)>max(top,ot)
  if (b.direction==0 and overlaps_x and ot<top) or (b.direction==2 and overlaps_x and ob>bottom) or (b.direction==3 and overlaps_y and ol<left) or (b.direction==1 and overlaps_y and oright>right):return false
 return true

func unblock_candidates(s,b,seen):
 var found=[]
 if seen.has(b.id):return found
 seen=seen.duplicate();seen.append(b.id)
 if own_clear(s,b):return [b.id]
 var a=Rect2i(b.cell,b.size-Vector2i(0,12))
 for other in s.blocks:
  if other.id==b.id or other.phase!="board":continue
  var r=Rect2i(other.cell,other.size-Vector2i(0,12));var x=min(a.end.x,r.end.x)>max(a.position.x,r.position.x);var y=min(a.end.y,r.end.y)>max(a.position.y,r.position.y)
  if (b.direction==0 and x and r.position.y<a.position.y) or (b.direction==2 and x and r.end.y>a.end.y) or (b.direction==3 and y and r.position.x<a.position.x) or (b.direction==1 and y and r.end.x>a.end.x):
   for id in unblock_candidates(s,other,seen):
    if not found.has(id):found.append(id)
 return found

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

func visible_count(s):
 var result={};var ordinal={}
 for unit in s.units:
  var order=int(ordinal.get(unit.dragon,0));ordinal[unit.dragon]=order+1
  var d=s.dragons[unit.dragon];var distance=d.head-65.0-order*s.pitch
  if distance<0 or distance>d.curve.get_baked_length():continue
  var p=d.curve.sample_baked(distance,true)
  if p.x<0 or p.x>=592 or p.y<20 or p.y>=417:continue
  if s.definition.fog and p.y<float(s.definition.get("fog_ceiling",210)):continue
  result[unit.color]=int(result.get(unit.color,0))+1
 return result
func pick(s,policy,guard):
 var visible=visible_count(s)
 # Diagnostic policy deliberately ignores already reserved color demand.
 var last=s.slots.count(-1)==1;var ranked=[]
 for b in s.blocks:
  if not own_clear(s,b):continue
  var count=int(visible.get(b.color,0))
  if count<=0 or (guard and last and count<b.remaining):continue
  var score=float(count)/maxi(1,b.remaining) if policy==0 else float(mini(count,b.remaining))
  ranked.append({"id":b.id,"score":score})
 if not ranked.is_empty():
  ranked.sort_custom(func(a,b):return a.score>b.score if a.score!=b.score else a.id<b.id if policy==0 else a.id>b.id)
  return ranked[0].id
 var openings=[]
 for b in s.blocks:
  if b.phase!="board" or int(visible.get(b.color,0))<=0:continue
  for id in unblock_candidates(s,b,[]):
   var option=s.blocks[id]
   if guard and last and int(visible.get(option.color,0))<option.remaining:continue
   if not openings.has(id):openings.append(id)
 openings.sort()
 return -1 if openings.is_empty() else openings[0] if policy==0 else openings[-1]
func simulate(observed,interval=1.2,policy=0,guard=true):
 var s=State.new();s.reset(0,1,{"max_hearts":1,"shield":false,"freeze":false,"coins":300})
 var actions=[];var arrivals=[];var captures=[];var checkpoints=[];var pending_arrivals={};var last_capture=[0.0];var longest_gap=[0.0];var yellow=[0];var powers=[];var ordinary_min=[INF];var bad_forward=[0]
 var capture_cb=func(u,b):
  var d=s.dragons[u.dragon]
  if u.color==1:yellow[0]+=1
  var event={"time":s.time,"source_time":s.time+source.active_start_source_seconds,"unit_id":u.id,"block":b.id,"reference_id":b.reference_id,"color":u.color,"spool_ordinal":b.capacity-b.remaining+1,"yellow_ordinal":yellow[0] if u.color==1 else 0,"head_before":d.head,"phase_before":d.phase}
  if u.has("power"):event.power=u.power.kind;powers.append(event.duplicate(true))
  captures.append(event);longest_gap[0]=maxf(longest_gap[0],s.time-last_capture[0]);last_capture[0]=s.time
 var change_cb=func():
  if captures.is_empty() or captures[-1].has("head_after"):return
  var event=captures[-1];event.head_after=s.dragons[0].head
  if event.head_after>event.head_before+0.001:bad_forward[0]+=1
  if event.phase_before not in ["repelled","recovering"] and not event.has("power"):
   ordinary_min[0]=minf(ordinary_min[0],event.head_after)
 s.captured.connect(capture_cb);s.changed.connect(change_cb)
 var next_index=0;var next_decision=interval;var last_audit=-1.0;var observed_times=[45.0,60.0,110.967];var checkpoint_index=0
 while not s.won and not s.lost and s.time<240:
  if observed and next_index<source.events.size() and s.time+0.00001>=float(source.events[next_index].relative_active_seconds):
   var ref=source.events[next_index];var id=int(String(ref.id).substr(1))-1;var ok=s.select(id)
   actions.append({"order":next_index+1,"reference_id":ref.id,"time":s.time,"ok":ok,"slot":s.blocks[id].slot+1,"expected_slot":ref.get("shelf_slot_1based",-1),"capacity":s.blocks[id].capacity})
   check(ok,"source input accepted "+str(next_index+1),actions[-1]);check(s.blocks[id].capacity==int(ref.capacity.value),"source observed capacity "+ref.id)
   if next_index<10:check(s.blocks[id].slot+1==int(ref.shelf_slot_1based),"first ten shelf slots "+ref.id,actions[-1])
   pending_arrivals[id]=true;next_index+=1
  elif not observed and s.time+0.00001>=next_decision:
   next_decision+=interval
   if s.slots.has(-1):
    var id=pick(s,policy,guard)
    if id>=0:
     var ok=s.select(id);check(ok,"visible policy legal selection")
     actions.append({"reference_id":s.blocks[id].reference_id,"time":s.time,"id":id,"ok":ok});pending_arrivals[id]=true
  for id in pending_arrivals.keys():
   if s.blocks[id].phase!="travel":arrivals.append({"id":id,"time":s.time,"reference_id":s.blocks[id].reference_id});pending_arrivals.erase(id)
  if observed and checkpoint_index<observed_times.size() and s.time+source.active_start_source_seconds+0.00001>=observed_times[checkpoint_index]:
   var frame={"source_time":observed_times[checkpoint_index],"time":s.time,"remaining_R6":s.blocks[15].remaining,"remaining_C10":s.blocks[14].remaining,"remaining_O10":s.blocks[22].remaining,"collected":s.collected,"head":canonical(s.route_curve.sample_baked(s.head,true)),"cat":canonical(s.cat_position),"phase":s.dragons[0].phase,"hearts":s.hearts}
   checkpoints.append(frame)
   if checkpoint_index<2:check(frame.remaining_R6==6 and frame.remaining_C10==5 and frame.remaining_O10==2,"source shelf R6 C5 O2 "+str(frame.source_time),frame)
   checkpoint_index+=1
  if s.time-last_audit>=1:invariant(s,"representative replay");last_audit=s.time
  var dt=0.02
  if observed and next_index<source.events.size():dt=minf(dt,maxf(0.00001,float(source.events[next_index].relative_active_seconds)-s.time))
  if observed and checkpoint_index<observed_times.size():dt=minf(dt,maxf(0.00001,float(observed_times[checkpoint_index])-source.active_start_source_seconds-s.time))
  if not observed:dt=minf(dt,maxf(0.00001,next_decision-s.time))
  s.advance(dt)
 s.captured.disconnect(capture_cb);s.changed.disconnect(change_cb)
 var last_action=actions[-1].time if not actions.is_empty() else 0.0
 var summary={"observed":observed,"interval":interval,"policy":policy,"last_slot_guard":guard,"won":s.won,"lost":s.lost,"loss_reason":s.loss_reason,"time":s.time,"source_end_time":s.time+source.active_start_source_seconds,"hearts":s.hearts,"collected":s.collected,"total":s.total,"actions":actions,"arrivals":arrivals,"captures":captures,"powers":powers,"checkpoints":checkpoints,"max_between_captures":longest_gap[0],"automatic_wait_after_last_choice":s.time-last_action,"after_last_capture":s.time-last_capture[0],"ordinary_min_head":ordinary_min[0],"ordinary_floor":s.route_length*float(s.definition.recoil_floor_fraction),"capture_forward_count":bad_forward[0],"end":{} if s.won else s.snapshot()}
 check(bad_forward[0]==0,"capture never jumps head forwards",summary.capture_forward_count)
 if observed:
  check(next_index==28 and s.won,"source28 completes",{"selected":next_index,"won":s.won,"reason":s.loss_reason})
  check(powers.size()==2,"source two marked powers",powers)
  if powers.size()==2:
   check(powers[0].reference_id=="b11" and powers[0].spool_ordinal==3 and powers[0].yellow_ordinal==3 and powers[0].power=="repel","source punch acquisition ordinal",powers[0])
   check(powers[1].reference_id=="b18" and powers[1].spool_ordinal==4 and powers[1].yellow_ordinal==18 and powers[1].power=="slow","source slow acquisition ordinal",powers[1])
  check(summary.automatic_wait_after_last_choice<6,"source final automatic wait below6",summary.automatic_wait_after_last_choice)
 elif guard:
  check(s.won,"visible policy completion "+str(interval)+":"+str(policy),{"time":s.time,"collected":s.collected,"reason":s.loss_reason})
  check(summary.max_between_captures<8,"visible policy capture gap below8 "+str(interval)+":"+str(policy),summary.max_between_captures)
  check(summary.automatic_wait_after_last_choice<6,"visible policy final wait below6 "+str(interval)+":"+str(policy),summary.automatic_wait_after_last_choice)
 print("REP_RUN observed=",observed," interval=",interval," policy=",policy," guard=",guard," won=",s.won," t=",s.time," gap=",summary.max_between_captures," endwait=",summary.automatic_wait_after_last_choice)
 return summary
func old_distance(s,index):
 var offset=0;var dragon=s.units[index].dragon
 for i in range(index):
  if s.units[i].dragon==dragon:offset+=1
 return s.dragons[dragon].head-65.0-offset*s.pitch
func old_target(s,color):
 var candidate=-1;var closest=INF
 for i in range(s.units.size()):
  if s.units[i].color!=color:continue
  var distance=old_distance(s,i);var d=s.dragons[s.units[i].dragon]
  var exposed=s.time<s.boost_until
  if not exposed and distance>=0 and distance<=d.curve.get_baked_length():
   var p=d.curve.sample_baked(distance,true);exposed=p.x>=0 and p.x<592 and p.y>=20 and p.y<417 and (not s.definition.fog or p.y>=s.fog_edge())
  if not exposed:continue
  var gap=d.curve.get_closest_offset(s.cat_position)-d.head
  if gap<closest:closest=gap;candidate=i
 return candidate
func test_optimization_and_preservation():
 for level in range(10):
  var s=State.new();s.reset(0,level)
  if level!=1:
   check(canonical(s.definition)==canonical(Baseline.definition(level)),"other nine definition "+str(level+1))
   check(s.pitch==44 and is_equal_approx(s.head_recoil,4) and is_equal_approx(s.winding_interval,0.46) and is_equal_approx(s.clear_duration,0.52),"other nine defaults "+str(level+1))
  for variant in range(3):
   for i in range(s.units.size()):check(is_equal_approx(s.unit_distance(i),old_distance(s,i)),"distance optimization equivalent")
   for color in range(8):check(s.target_unit(color)==old_target(s,color),"target optimization preserves returned order",[level,variant,color,s.target_unit(color),old_target(s,color)])
   if variant==0:
    for i in range(3):s.units.remove_at(0)
   else:s.boost_until=10
func test_reading_and_approach():
 var s=State.new();s.reset(0,1);var head=s.head;s.advance(9.9);check(s.head==head and not s.first_departure,"reading grace holds before10s");check(not s.select(7) and not s.first_departure,"blocked input does not end grace");s.advance(0.2);check(s.head>head,"grace expires after10s")
 s=State.new();s.reset(0,1);head=s.head;check(s.select(16) and s.first_departure,"first valid selection ends grace");s.advance(0.1);check(s.head>head,"first departure enables immediate chase")
 s=State.new();s.reset(0,1);s.first_departure=true;s.cat_anchor_index=s.definition.anchors.size()-1;s.cat_position=s.definition.anchors[-1];var target=s.route_curve.get_closest_offset(s.cat_position)
 s.head=target-400;head=s.head;s.advance(0.1);check(absf(s.head-head-5.4)<0.01,"distant movement54px per second")
 s.head=target-250;head=s.head;s.advance(0.1);check(absf(s.head-head-2.7)<0.01,"final approach27px per second")
func _initialize():
 var trial=simulate(false,0.8,1,false)
 var file=FileAccess.open("C:/SourceCodes/WoolGame/Evidence/Rebuild/Representative/Rules/naive-greedy-diagnostic.json",FileAccess.WRITE);file.store_string(JSON.stringify({"diagnostic_only":true,"policy":"current visible match count; no pending-demand subtraction or last-slot completion guard","run":trial,"rule_failures":failures,"state_sha256":FileAccess.get_sha256("res://scripts/state.gd"),"reference_sha256":FileAccess.get_sha256("res://scripts/reference_stage.gd")},"  "));file.close();quit()
