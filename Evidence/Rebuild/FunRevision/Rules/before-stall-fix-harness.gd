extends SceneTree
const State=preload("res://scripts/state.gd")
const Profile=preload("res://scripts/profile.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Baseline=preload("C:/SourceCodes/WoolGame/BuildWork/FunAudit/IndependentRules/baseline_campaign.gd")
var failures=[]
var checks=0
var identities={}
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/FunRevision/Rules"
var workspace="C:/SourceCodes/WoolGame/BuildWork/FunAudit/IndependentRules"
var trials=[]
var definition_results=[]
func _initialize():call_deferred("run")
func check(ok: bool,name: String,detail: Variant=null):
 checks+=1
 if not ok and not identities.has(name):
  identities[name]=true; failures.append({"name":name,"detail":detail});print("FAIL ",name," ",JSON.stringify(detail))

func fresh(level=0,opts={}):
 var s=State.new();s.reset(0,level,opts);return s

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

func visible_colors(s):
 var colors={};var ordinal={}
 for u in s.units:
  var n=ordinal.get(u.dragon,0);ordinal[u.dragon]=n+1
  var curve=s.dragons[u.dragon].curve;var distance=s.dragons[u.dragon].head-65.0-n*44.0
  if distance<0 or distance>curve.get_baked_length():continue
  var p=curve.sample_baked(distance,true)
  if p.x<0 or p.x>=592 or p.y<20 or p.y>=417:continue
  var edge=110.0 if s.level_index==6 else 155.0 if s.level_index==7 else 0.0
  if edge>0.0 and p.y<edge:continue
  colors[u.color]=int(colors.get(u.color,0))+1
 return colors

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


func test_profile():
 var path=workspace+"/profile/test-"+str(Time.get_ticks_usec())+".json";var p=Profile.new();check(p.open(path),"new profile save");check(p.current().coins==300,"fresh wallet")
 var id=p.start_run();var receipt=p.settle(id,0);check(receipt.first and receipt.coins==50 and p.current().coins==350,"first reward")
 p.settle(id,0);check(p.current().coins==350 and p.current().cards.size()==1,"duplicate settle idempotent")
 var q=Profile.new();check(q.open(path),"reload settled");check(q.current().coins==350 and q.current().pending.run_id==id,"pending result survives reload")
 q.settle(id,0);check(q.current().coins==350,"reload settle idempotent");q.acknowledge();q.settle(q.start_run(),0);check(q.current().coins==370 and q.current().cards.size()==1,"replay twenty no card duplicate")
 q.set_mode("free");check(q.current().coins==300 and q.current().completed.is_empty(),"mode separation initial");q.settle(q.start_run(),1);check(q.stats().shield and q.current().coins==350,"free growth separate");q.set_mode("challenge");check(not q.stats().shield and q.current().coins==370,"challenge unaffected by free")
 for level in range(1,10):q.settle(q.start_run(),level)
 check(q.stats()=={"max_hearts":3,"shield":true,"freeze":true},"growth milestones");check(q.current().cards.size()==10 and q.current().unlocked==9,"ten card frontier")
 var recover_data=q.data.duplicate(true);recover_data.revision+=1;recover_data.profiles.challenge.coins+=50
 var temp=FileAccess.open(path+".tmp",FileAccess.WRITE);temp.store_string(JSON.stringify(recover_data));temp.close()
 var recovered=Profile.new();recovered.open(path);check(recovered.current().coins==q.current().coins+50,"flushed newer temp recovered")
 temp=FileAccess.open(path+".tmp",FileAccess.WRITE);temp.store_string("{truncated");temp.close();recovered=Profile.new();recovered.open(path);check(recovered.current().coins==q.current().coins,"truncated temp falls back")

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

func natural(level):
 return fresh(level,{"mode":"challenge","coins":300,"max_hearts":3 if level>=6 else 2 if level>=3 else 1,"shield":level>=2,"freeze":level>=7})
func legal_choices(s):
 var legal=[]
 for b in s.blocks:
  if own_clear(s,b):legal.append(b.id)
 return legal
func independent_order(blocks):
 var removed=[]
 while removed.size()<blocks.size():
  var picked=-1
  for i in range(blocks.size()):
   if removed.has(i):continue
   var a=blocks[i];var has_blocker=false
   for j in range(blocks.size()):
    if j==i or removed.has(j):continue
    var b=blocks[j];var ox=mini(a.cell.x+a.size.x,b.cell.x+b.size.x)>maxi(a.cell.x,b.cell.x);var oy=mini(a.cell.y+a.size.y-12,b.cell.y+b.size.y-12)>maxi(a.cell.y,b.cell.y)
    if (a.direction==0 and ox and b.cell.y<a.cell.y) or (a.direction==1 and oy and b.cell.x>a.cell.x) or (a.direction==2 and ox and b.cell.y>a.cell.y) or (a.direction==3 and oy and b.cell.x<a.cell.x):has_blocker=true;break
   if not has_blocker:picked=i;break
  if picked<0:return []
  removed.append(picked)
 return removed
func audit_definitions():
 for level in range(10):
  var s=natural(level);var definition=s.definition;var base=Baseline.definition(level)
  var changed=level in [5,7,9]
  if not changed:check(canonical(definition)==canonical(base),"unchanged definition "+str(level+1))
  var order=definition.get("yarn_order",independent_order(definition.blocks))
  var seen={}
  for id in order:
   check(typeof(id)==TYPE_INT and id>=0 and id<s.blocks.size(),"order valid ID "+str(level+1),id)
   check(not seen.has(id),"order duplicate ID "+str(level+1),id);seen[id]=true
  check(order.size()==s.blocks.size() and seen.size()==s.blocks.size(),"order complete permutation "+str(level+1))
  var expected={};var sequence=[];var expected_total=0
  for position in range(order.size()):
   var block=s.blocks[order[position]];var dragon=position%s.dragons.size();var key=str(dragon)+":"+str(block.color)
   expected[key]=int(expected.get(key,0))+block.capacity
   for _j in range(block.capacity):sequence.append({"id":expected_total,"color":block.color,"dragon":dragon});expected_total+=1
  var actual={}
  for unit in s.units:
   var key=str(unit.dragon)+":"+str(unit.color);actual[key]=int(actual.get(key,0))+1
  var baseline_dragon_colors={};var baseline_order=independent_order(base.blocks)
  for position in range(baseline_order.size()):
   var block=base.blocks[baseline_order[position]];var key=str(position%base.dragons)+":"+str(block.color);baseline_dragon_colors[key]=int(baseline_dragon_colors.get(key,0))+block.capacity
  check(counts(definition.blocks,"capacity")==counts(base.blocks,"capacity"),"baseline total color quantities "+str(level+1))
  check(actual==baseline_dragon_colors,"baseline per dragon color quantities "+str(level+1),[actual,baseline_dragon_colors])
  check(expected==actual,"dragon color quantities "+str(level+1),[expected,actual])
  check(sequence==s.units,"exact declared yarn sequence "+str(level+1))
  check(expected_total==s.total,"initial total "+str(level+1));invariant(s,"initial "+str(level+1))
  definition_results.append({"level":level+1,"changed":changed,"order":order,"blocks":s.blocks.size(),"total":s.total,"dragon_colors":actual,"definition":canonical(definition)})
func choose_visible(s,policy):
 var visible=visible_colors(s)
 for id in s.slots:
  if id>=0:visible[s.blocks[id].color]=maxi(0,int(visible.get(s.blocks[id].color,0))-s.blocks[id].remaining)
 var candidates=[]
 for b in s.blocks:
  if not own_clear(s,b):continue
  var n=int(visible.get(b.color,0))
  if n<=0:continue
  var score=float(n)/maxi(1,b.remaining) if policy==0 else float(mini(n,b.remaining))
  candidates.append({"id":b.id,"score":score})
 if not candidates.is_empty():
  candidates.sort_custom(func(a,b):return a.score>b.score if a.score!=b.score else a.id<b.id if policy==0 else a.id>b.id)
  return candidates[0].id
 var opening=[]
 for b in s.blocks:
  if b.phase!="board" or int(visible.get(b.color,0))<=0:continue
  for id in unblock_candidates(s,b,[]):
   if not opening.has(id):opening.append(id)
 opening.sort()
 return (-1 if opening.is_empty() else opening[0] if policy==0 else opening[-1])
func play(level,interval,first_id,policy):
 var s=natural(level);var actions=[];var captured_by_dragon={};var initial_by_dragon={};var next_decision=interval;var last_audit=-1.0;var longest_idle=0.0;var idle_from=0.0;var prior_collected=0
 for u in s.units:initial_by_dragon[u.dragon]=int(initial_by_dragon.get(u.dragon,0))+1
 s.captured.connect(func(u,_b):captured_by_dragon[u.dragon]=int(captured_by_dragon.get(u.dragon,0))+1)
 while not s.won and not s.lost and s.time<240:
  if s.time+0.001>=next_decision:
   next_decision+=interval
   if s.slots.has(-1):
    var chosen=first_id if actions.is_empty() and first_id>=0 else choose_visible(s,policy)
    if chosen>=0:
     var visible=visible_colors(s);var block=s.blocks[chosen]
     check(own_clear(s,block),"independent chosen clear",[level,chosen])
     var ok=s.select(chosen);check(ok,"normal selection accepted",[level,chosen,s.snapshot()])
     actions.append({"t":s.time,"id":chosen,"color":block.color,"capacity":block.capacity,"visible_same_color":int(visible.get(block.color,0))})
  s.advance(0.1)
  if s.collected!=prior_collected:longest_idle=maxf(longest_idle,s.time-idle_from);idle_from=s.time;prior_collected=s.collected
  if s.time-last_audit>=1.0:
   invariant(s,"play "+str(level+1));last_audit=s.time
   var left={}
   for u in s.units:left[u.dragon]=int(left.get(u.dragon,0))+1
   for d in initial_by_dragon:check(int(left.get(d,0))+int(captured_by_dragon.get(d,0))==initial_by_dragon[d],"per dragon runtime conservation "+str(level+1))
 longest_idle=maxf(longest_idle,s.time-idle_from)
 check(s.coins==300,"tool free wallet unchanged")
 return {"level":level+1,"interval":interval,"first":first_id,"policy":policy,"won":s.won,"lost":s.lost,"time":s.time,"hearts":s.hearts,"collected":s.collected,"total":s.total,"longest_no_capture":longest_idle,"actions":actions,"end":{} if s.won else s.snapshot()}
func test_continue_preservation():
 for level in [5,7,9]:
  var s=natural(level)
  for id in legal_choices(s):
   if s.slots.has(-1):s.select(id)
  s.advance(2.0);s.lost=true
  var before_units=s.units.duplicate(true);var before_remaining=[];var progress=s.collected
  for b in s.blocks:before_remaining.append(b.remaining)
  check(s.continue_run(),"continue accepted "+str(level+1))
  check(s.units==before_units and s.collected==progress,"continue exact yarn progress preserved "+str(level+1))
  for i in range(s.blocks.size()):check(s.blocks[i].remaining==before_remaining[i],"continue block remaining "+str(level+1))
  check(s.coins==200 and s.slots.all(func(id):return id==-1),"continue cost and slots "+str(level+1));invariant(s,"continue "+str(level+1))
func run():
 audit_definitions();test_profile();test_continue_preservation()
 for level in [5,7,9]:
  var initial=natural(level);var alternatives=legal_choices(initial)
  alternatives.push_front(-1)
  for interval in [2.4,3.2]:
   for first in alternatives:
    for policy in [0,1]:
     var result=play(level,interval,first,policy);trials.append(result)
     print("FUN_TRIAL level=",level+1," interval=",interval," first=",first," policy=",policy," won=",result.won," t=",result.time," progress=",result.collected,"/",result.total)
 var hashes={}
 for file in DirAccess.get_files_at("res://scripts"):
  if file.ends_with(".gd"):hashes[file]=FileAccess.get_sha256("res://scripts/"+file)
 var file=FileAccess.open(out+"/independent-fun-rules.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"definitions":definition_results,"trials":trials,"resource_hashes":hashes},"  "));file.close();print("INDEPENDENT_FUN checks=",checks," failures=",failures.size()," trials=",trials.size());quit(0 if failures.is_empty() else 1)
