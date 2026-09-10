extends SceneTree
const Flight=preload("res://scripts/block_flight.gd")
const State=preload("res://scripts/state.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Board=preload("res://scripts/board.gd")
const Layout=preload("res://scripts/layout.gd")
var failures=[]
var unique={}
var checks=0
var trajectories=0
var samples=0
var details=[]
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/Rules"
func check(ok: bool,label: String,detail: Variant=null):
 checks+=1
 if not ok and not unique.has(label):unique[label]=true;failures.append({"label":label,"detail":detail});print("FAIL ",label," ",JSON.stringify(detail))
func _initialize():call_deferred("run")
func corners(b,pose):
 var result=[]
 for shadow in [Vector2.ZERO,Vector2(1,2)]:
  for x in [-0.5,0.5]:
   for y in [-0.5,0.5]:result.append(pose.position+((Vector2(b.size)*Vector2(x,y)+shadow)*pose.scale).rotated(pose.angle))
 return result
func geometry(b,slot,label):
 var plan=Flight.build(b,slot);trajectories+=1
 check(plan.duration>0.0 and is_finite(plan.duration),"finite positive duration",label)
 var start=Flight.sample(plan,0.0);var end=Flight.sample(plan,plan.duration)
 var expected=Vector2(296,574) if b.get("from_reserve",false) else Vector2(b.cell)+Vector2(b.size)/2
 check(start.position.distance_to(expected)<0.01,"exact departure position",[label,start,expected])
 check(end.position.distance_to(Layout.slot_center(slot))<0.01,"exact slot destination",[label,slot,end])
 var last=Flight.sample(plan,plan.duration+1.0)
 check(last.position.distance_to(end.position)<0.01,"endpoint clamps",[label,last,end])
 var previous=start
 for n in range(241):
  var time=plan.duration*n/240.0;var pose=Flight.sample(plan,time);samples+=1
  check(is_finite(pose.position.x) and is_finite(pose.position.y) and is_finite(pose.angle),"finite pose",[label,time,pose])
  for p in corners(b,pose):
   check(p.x>=-0.01 and p.x<=592.01 and p.y>=-0.01 and p.y<1041.0,"body and shadow visible before footer dir"+str(b.direction),[label,slot,time,p,pose,b])
  if n>0:
   check(pose.position.distance_to(previous.position)<32.0,"no position leap dir"+str(b.direction),[label,time,previous,pose])
  previous=pose
 for segment in plan.segments:
  var t=float(segment.start)
  if t>0.0:
   var before=Flight.sample(plan,t-0.00001);var after=Flight.sample(plan,t+0.00001)
   check(before.position.distance_to(after.position)<0.1,"continuous junction position",[label,t,before,after])
   check(absf(wrapf(after.angle-before.angle,-PI,PI))<0.025,"continuous junction rotation dir"+str(b.direction),[label,slot,t,before,after])
   check(before.scale.distance_to(after.scale)<0.01,"continuous junction scale",[label,t,before,after])
  if segment.kind=="turn":
   check(absf(absf(wrapf(segment.angle_b-segment.angle_a,-PI,PI))-PI/2)<0.001,"turn is ninety degrees",[label,segment])
   check(segment.a.distance_to(segment.b)<0.01,"turn remains at visible contact",[label,segment])
 for impact in plan.impacts:
  check(impact.time>=0 and impact.time<plan.duration,"impact within flight",[label,impact])
  check(impact.point.x>=3.5 and impact.point.x<=588.5 and impact.point.y>=3.5 and impact.point.y<=1024.5,"contact mark visible",[label,impact])
  var pose=Flight.sample(plan,impact.time)
  var forward=Flight.DIRS[b.direction].rotated(pose.angle)
  check(forward.dot(impact.normal)>0.99,"arrow faces contact normal",[label,impact,pose])
 details.append({"case":label,"direction":b.direction,"slot":slot,"duration":plan.duration,"impacts":plan.impacts.size()})
func geometry_run():
 for level in range(10):
  var data=Campaign.definition(level)
  for index in range(data.blocks.size()):
   var b=data.blocks[index].duplicate(true)
   for slot in range(8):geometry(b,slot,"L%d-B%d"%[level+1,index])
 for direction in range(4):
  var b={"cell":Vector2i(231,949),"size":Vector2i(48,68) if direction%2==0 else Vector2i(56,59),"direction":direction,"from_reserve":true}
  for slot in range(8):geometry(b,slot,"reserve-dir"+str(direction))
 test_state()
 var resources={}
 for path in ["res://scripts/block_flight.gd","res://scripts/state.gd","res://scripts/board.gd"]:resources[path]=FileAccess.get_sha256(path)
 var file=FileAccess.open(out+"/geometry-state.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"trajectories":trajectories,"samples":samples,"details":details,"resource_hashes":resources},"  "));file.close()
 print("INDEPENDENT_EXIT trajectories=",trajectories," samples=",samples," checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
func test_state():
 for level in range(10):
  for slot in range(8):
   var s=State.new();s.reset(0,level,{"mode":"free"});var board=Board.new();board.state=s
   for i in range(4):s.unlock_slot()
   var target=-1
   for b in s.blocks:
    if s.can_select(b.id):target=b.id;break
   # Slot choice fixture: occupy other slots with non-selected sentinels; no advance while occupied.
   var b=s.blocks[target]
   for i in range(slot):s.slots[i]=s.blocks.size()+i
   check(s.select(target),"normal selection starts flight",[level,slot])
   check(s.slots[slot]==target and b.slot==slot,"slot reserved immediately",[level,slot])
   check(not s.select(target),"duplicate travel selection rejected",[level,slot])
   for i in range(slot):s.slots[i]=-1
   var duration=b.arrival-b.depart
   check(abs(duration-b.flight.duration)<0.00001,"state duration matches rendered flight",[level,slot,duration,b.flight.duration])
   var units=s.units.size();var remain=b.remaining;var before=s.collected
   s.advance(maxf(0,duration-0.001))
   check(b.phase=="travel" and s.units.size()==units and b.remaining==remain and s.collected==before,"no collection before arrival",[level,slot,s.time,duration])
   var pose=board.travel_pose(b);s.paused=true;s.advance(0.5);board._process(0.5)
   check(board.travel_pose(b)==pose,"pause freezes pose and rotation",[level,slot])
   s.paused=false;s.advance(0.002)
   check(b.phase=="working" and s.collected==before,"arrival handoff before winding",[level,slot,b])
   var end=board.travel_pose(b);check(end.position.distance_to(Layout.slot_center(slot))<0.01,"working begins at actual slot",[level,slot,end])
   s.advance(0.3)
   check(s.collected+s.units.size()==s.total,"collection conserves total",[level,slot])
   board.free()

func run():
 var captures=0
 for level in range(10):
  var s=State.new();s.reset(0,level,{"mode":"free"})
  for i in range(4):s.unlock_slot()
  var ids=[];var latest_arrival=0.0;var captured_ids={}
  var listener=func(unit,b):
   check(s.time>=s.blocks[b.id].arrival,"all eight collection starts after individual arrival",[level,b.id,s.time,s.blocks[b.id].arrival])
   check(not captured_ids.has(unit.id),"simultaneous spools never collect one unit twice",[level,unit.id]);captured_ids[unit.id]=true
  s.captured.connect(listener)
  for slot in range(8):
   var id=-1
   for b in s.blocks:
    if s.can_select(b.id):id=b.id;break
   check(id>=0 and s.select(id),"eight real blocks fill distinct reserved slots",[level,slot])
   ids.append(id);var b=s.blocks[id]
   check(b.slot==slot and s.slots[slot]==id,"eight slot binding stable",[level,slot,id])
   check(Flight.sample(b.flight,b.flight.duration).position.distance_to(Layout.slot_center(slot))<0.01,"each concurrent flight reaches its own slot",[level,slot])
   latest_arrival=maxf(latest_arrival,b.arrival)
  while s.time<latest_arrival+0.2:
   s.advance(0.01)
   var remaining=0
   for b in s.blocks:remaining+=b.remaining
   check(remaining==s.units.size() and s.collected+s.units.size()==s.total,"eight concurrent flights conserve all yarn",[level,s.time])
  for id in ids:check(s.blocks[id].phase!="travel","all eight arrive by their own deadline",[level,id])
  captures+=captured_ids.size();s.captured.disconnect(listener)
  s=State.new();s.reset(0,level,{"mode":"free"})
  for i in range(4):s.unlock_slot()
  ids=[]
  for slot in range(8):
   for b in s.blocks:
    if s.can_select(b.id):s.select(b.id);ids.append(b.id);break
  s.advance(0.05);var units=JSON.stringify(s.units);s.lost=true
  check(s.continue_run() and JSON.stringify(s.units)==units,"continue interrupts all eight without lost yarn",level)
  for id in ids:
   check(s.blocks[id].phase=="reserve" and s.reserve.has(id),"interrupted block retained on reserve",[level,id])
   check(s.select(id),"restored reserve selection accepted",[level,id])
   var b=s.blocks[id]
   check(b.from_reserve and Flight.sample(b.flight,0).position.distance_to(Vector2(296,574))<0.01,"reserve rebuilds flight from shelf",[level,id])
 var resources={}
 for path in ["res://scripts/block_flight.gd","res://scripts/state.gd"]:resources[path]=FileAccess.get_sha256(path)
 var file=FileAccess.open(out+"/eight-slots.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"resource_hashes":resources},"  "));file.close();print("INDEPENDENT_EIGHT checks=",checks," captures=",captures," failures=",failures.size());quit(0 if failures.is_empty() else 1)
