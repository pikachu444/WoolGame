extends SceneTree
const State=preload("res://scripts/state.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Flight=preload("res://scripts/block_flight.gd")
const Layout=preload("res://scripts/layout.gd")
const Art=preload("res://scripts/art.gd")
const Baseline=preload("C:/SourceCodes/WoolGame/BuildWork/Representative/Rules/baseline_campaign.gd")
var checks=0
var failures=[]
var unique={}
var details=[]
var trajectories=0
var samples=0
var source=JSON.parse_string(FileAccess.get_file_as_string("C:/SourceCodes/WoolGame/Evidence/Rebuild/Representative/Reference/level2_start_blocks.json"))
func check(ok: bool,label: String,detail: Variant=null):
 checks+=1
 if not ok and not unique.has(label):unique[label]=true;failures.append({"label":label,"detail":detail});print("FAIL ",label," ",JSON.stringify(detail))
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
 for n in range(61):
  var time=plan.duration*n/60.0;var pose=Flight.sample(plan,time);samples+=1
  check(is_finite(pose.position.x) and is_finite(pose.position.y) and is_finite(pose.angle),"finite pose",[label,time,pose])
  for p in corners(b,pose):
   check(p.x>=-0.01 and p.x<=592.01 and p.y>=-0.01 and p.y<1041.0,"body and shadow visible before footer dir"+str(b.direction),[label,slot,time,p,pose,b])
  if n>0:
   check(pose.position.distance_to(previous.position)<105.0,"no position leap dir"+str(b.direction),[label,time,previous,pose])
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

func own_blockers(rows,id,depth=0.0):
 var result=[];var a=rows[id];var ar=a.bbox;var d=a.direction
 for j in range(rows.size()):
  if j==id:continue
  var br=rows[j].bbox;var x=minf(ar[0]+ar[2],br[0]+br[2])>maxf(ar[0],br[0]);var y=minf(ar[1]+ar[3]-depth,br[1]+br[3]-depth)>maxf(ar[1],br[1])
  if (d=="U" and x and br[1]<ar[1]) or (d=="D" and x and br[1]+br[3]>ar[1]+ar[3]) or (d=="L" and y and br[0]<ar[0]) or (d=="R" and y and br[0]+br[2]>ar[0]+ar[2]):result.append(j)
 return result
func _initialize():
 var s=State.new();s.reset(0,1);var comparisons=[];var initial_clear=[];var palette={};var max_error=0.0
 check(s.blocks.size()==28 and source.block_count==28,"observed 28 blocks")
 check(Art.COLORS.size()==8,"eight render colors")
 for i in range(s.blocks.size()):
  var b=s.blocks[i];var observed=source.blocks[i];var r=observed.bbox;palette[b.color]=true
  check(b.reference_id==observed.id and b.color==observed.color_index and "URDL"[b.direction]==observed.direction,"reference identity color direction "+str(i))
  var expected=[296+(r[0]-144.5)*1.8,599+(r[1]-293)*1.8,r[2]*1.8,r[3]*1.8];var actual=[b.cell.x,b.cell.y,b.size.x,b.size.y]
  for k in range(4):max_error=maxf(max_error,absf(actual[k]-expected[k]));check(absf(actual[k]-expected[k])<=0.5001,"uniform source bbox transform "+str(i)+":"+str(k))
  var raw_blockers=own_blockers(source.blocks,i);var face_blockers=own_blockers(source.blocks,i,12.0/1.8);var current=s.blockers(i)
  check(raw_blockers==current,"source visual blocker topology "+str(i),[raw_blockers,current])
  check(face_blockers==current,"depth corrected blocker topology "+str(i),[face_blockers,current])
  if current.is_empty():initial_clear.append(observed.id)
  comparisons.append({"id":observed.id,"source_bbox":r,"target_bbox":actual,"blockers":current,"reference_visual_blockers":raw_blockers})
  for slot in range(8):geometry(b,slot,observed.id+"-slot"+str(slot))
 check(palette.size()==8,"all eight source colors represented")
 var preserved=[]
 for level in range(10):
  if level==1:continue
  var d=Campaign.definition(level);var old=Baseline.definition(level)
  check(canonical(d)==canonical(old),"unchanged other stage "+str(level+1));var ordinary=State.new();ordinary.reset(0,level)
  var defaults={"pitch":ordinary.pitch,"winding_interval":ordinary.winding_interval,"unwind_duration":ordinary.unwind_duration,"clear_duration":ordinary.clear_duration,"head_recoil":ordinary.head_recoil,"initial_head_fraction":ordinary.dragons[0].head/ordinary.dragons[0].curve.get_baked_length()}
  check(is_equal_approx(ordinary.pitch,44) and is_equal_approx(ordinary.winding_interval,0.46) and is_equal_approx(ordinary.unwind_duration,0.46) and is_equal_approx(ordinary.clear_duration,0.52) and is_equal_approx(ordinary.head_recoil,4) and is_equal_approx(defaults.initial_head_fraction,0.34),"ordinary stage defaults "+str(level+1),defaults)
  preserved.append({"level":level+1,"defaults":defaults})
 var hashes={}
 for path in ["scripts/reference_stage.gd","scripts/campaign.gd","scripts/state.gd","scripts/art.gd","scripts/block_flight.gd"]:hashes[path]=FileAccess.get_sha256("res://"+path)
 var f=FileAccess.open("C:/SourceCodes/WoolGame/Evidence/Rebuild/Representative/Rules/geometry-preliminary.json",FileAccess.WRITE);f.store_string(JSON.stringify({"phase":"preliminary geometry only","checks":checks,"failures":failures,"comparisons":comparisons,"max_transform_rounding_error":max_error,"initial_clear":initial_clear,"palette":palette.keys(),"trajectories":trajectories,"samples":samples,"flight_details":details,"preserved_stages":preserved,"resource_hashes":hashes},"  "));f.close();print("INDEPENDENT_REFERENCE_GEOMETRY failures=",failures.size()," paths=",trajectories," initial_clear=",initial_clear," max_rounding_error=",max_error);quit(0 if failures.is_empty() else 1)
