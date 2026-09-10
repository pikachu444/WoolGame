extends SceneTree
const State=preload("res://scripts/state.gd")
const Profile=preload("res://scripts/profile.gd")
var failures=[]
var checks=0
var runs=[]
var identities={}
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/OfflineCampaign/Rules"
var workspace="C:/SourceCodes/WoolGame/BuildWork/IndependentRules"
func check(ok: bool,name: String,detail: Variant=null):
 checks+=1
 if not ok and not identities.has(name):
  identities[name]=true; failures.append({"name":name,"detail":detail});print("FAIL ",name," ",JSON.stringify(detail))
func _initialize():call_deferred("run")
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
  if s.definition.fog and p.y<210:continue
  colors[u.color]=int(colors.get(u.color,0))+1
 return colors
func solve(s,limit=420.0,interval=0.85):
 var actions=[];var next_select=0.0;var last_audit=-1.0
 while not s.won and not s.lost and s.time<limit:
  if s.time>=next_select and s.slots.has(-1):
   var visible=visible_colors(s);var selected=-1;var score=-1.0
   for occupied in s.slots:
    if occupied>=0:
     var pending=s.blocks[occupied]
     visible[pending.color]=maxi(0,int(visible.get(pending.color,0))-int(pending.remaining))
   for b in s.blocks:
    if not own_clear(s,b):continue
    var n=visible.get(b.color,0)
    if n>0 and float(n)/maxi(1,b.remaining)>score:score=float(n)/maxi(1,b.remaining);selected=b.id
   if selected<0:
    for target in s.blocks:
     if target.phase!="board" or int(visible.get(target.color,0))<=0:continue
     var exits=unblock_candidates(s,target,[])
     if not exits.is_empty():selected=exits[0];break
   if selected>=0:
    var ok=s.select(selected);check(ok,"solver legal selection",[s.level_index,selected,s.snapshot()])
    actions.append({"time":s.time,"block":selected});next_select=s.time+interval
  s.advance(0.1)
  if s.time-last_audit>=0.8:invariant(s,"level "+str(s.level_index));last_audit=s.time
 return {"level":s.level_index,"mode":s.mode,"won":s.won,"lost":s.lost,"time":s.time,"hearts":s.hearts,"collected":s.collected,"total":s.total,"actions":actions,"snapshot":s.snapshot() if not s.won else {}}
func at_last(s):
 s.cat_anchor_index=s.definition.anchors.size()-1;s.cat_position=s.definition.anchors[-1]
 for d in s.dragons:d.head=d.curve.get_closest_offset(s.cat_position)-90.0;d.phase="chasing";d.until=0
func original_run():
 for mode in ["challenge","free"]:
  for level in range(10):
   var s=fresh(level,{"mode":mode,"max_hearts":3 if level>=6 else 2 if level>=3 else 1,"shield":level>=2,"freeze":level>=7})
   var result=solve(s);runs.append(result);check(s.won,"tool-free completion "+mode+" "+str(level),result);check(s.coins==300,"tool-free wallet",result)
   print("RUN ",mode," ",level," won=",s.won," t=",s.time," hp=",s.hearts)
 test_encounter();test_tools();test_profile();test_boundaries();test_real_failure()
 var resource_hashes={}
 for path in ["res://scripts/state.gd","res://scripts/profile.gd","res://scripts/campaign.gd","res://scripts/game.gd"]:resource_hashes[path]=FileAccess.get_sha256(path)
 var report={"checks":checks,"failures":failures,"runs":runs,"resource_hashes":resource_hashes}
 var file=FileAccess.open(out+"/source-rules.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("INDEPENDENT_RULES checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
func test_encounter():
 var s=fresh();var h=s.hearts;var initial=s.cat_position;s.dragons[0].head=s.route_curve.get_closest_offset(initial)-34.0
 s.advance(0.05);check(s.cat_phase=="fleeing" and s.hearts==h,"flee begins without damage",s.snapshot())
 s.advance(0.34);check(s.cat_position.distance_to(initial)>1 and s.hearts==h,"flee moves",s.snapshot())
 s.advance(0.39);check(s.cat_anchor_index==1 and s.cat_phase=="waiting" and s.hearts==h,"flee reaches next anchor",s.snapshot())
 s=fresh(0,{"max_hearts":3});at_last(s);var before=s.head;s.advance(0.1);check(s.dragons[0].phase=="windup" and s.hearts==3,"attack warning",s.snapshot())
 s.advance(0.35);check(s.hearts==3,"warning precedes damage",s.snapshot());s.advance(0.15);check(s.hearts==2,"fire deals one damage",s.snapshot());check(s.head>=before-1,"ordinary hit no repel",s.snapshot())
 var protected=s.hearts;s.attack();s.attack();check(s.hearts==protected,"same instant duplicate damage blocked",s.snapshot())
 s=fresh(8,{"max_hearts":3});at_last(s);s.advance(0.65);check(s.hearts==2,"two dragons one protected damage",s.snapshot())
 s=fresh(0,{"shield":true});at_last(s);s.advance(0.65);check(s.shield_used and s.hearts==1,"shield absorbs first attack",s.snapshot());var sh=s.head;s.advance(4.8);check(s.hearts==1 and s.shield_until>0,"shield lasts five seconds",s.snapshot());s.advance(0.25);check(s.shield_until==0 and s.head<sh-70,"shield expiry distinct two pitch repel",s.snapshot());check(s.hearts==1,"repel expiry no immediate damage",s.snapshot())
 s=fresh(0,{"freeze":true});s.head=s.route_curve.get_closest_offset(s.cat_position)-34.0;s.advance(0.05);var fh=s.head;check(s.freeze_used,"freeze triggers",s.snapshot());s.advance(2.8);check(abs(s.head-fh)<0.1,"freeze stops motion three seconds",s.snapshot());s.advance(0.4);check(s.head>fh,"freeze resumes",s.snapshot())
 s=fresh();at_last(s);s.advance(0.7);check(s.lost and s.hearts==0,"last heart loss",s.snapshot());var losttime=s.time;s.advance(10);check(s.time==losttime and s.hearts==0,"lost stops simulation",s.snapshot());check(not s.select(0),"lost blocks select")
 s=fresh();var snap=s.snapshot();s.paused=true;s.advance(10);check(s.time==0 and s.head==snap.dragons[0].head,"paused stops simulation")
func test_tools():
 var s=fresh(0,{"coins":99});check(not s.unlock_slot() and s.coins==99 and s.slots.size()==4,"insufficient unlock unchanged")
 s=fresh(0,{"coins":500});check(s.unlock_slot() and s.coins==400 and s.slots.size()==5,"unlock cost")
 while s.slots.size()<8:s.unlock_slot()
 var coins=s.coins;check(not s.unlock_slot() and s.coins==coins,"max slots no cost")
 s=fresh(0,{"coins":300});var units=JSON.stringify(s.units);check(s.free_block() and s.coins==225 and s.reserve.size()==1,"remove moves reserve cost");check(JSON.stringify(s.units)==units,"remove retains yarn");invariant(s,"remove")
 var id=s.reserve[0];check(s.select(id),"reserve selectable");check(not s.select(id),"duplicate selection rejected");invariant(s,"travel")
 s=fresh(5,{"mode":"free","coins":0});var outside=-1
 for i in range(s.units.size()):
  if s.unit_distance(i)<0:outside=i;break
 check(outside>=0 and not s.exposed(outside),"offscreen hidden before boost");check(s.strengthen() and s.coins==0,"free boost no cost");check(s.exposed(outside),"boost exposes offscreen")
 s.time=s.boost_until;check(not s.exposed(outside),"boost expiry hides offscreen")
 s=fresh(3,{"mode":"free","coins":0});var original=counts(s.units,"quantity");check(s.sort_yarn() and s.coins==0,"free sort no cost");check(counts(s.units,"quantity")==original,"sort color conservation")
 s=fresh(0,{"coins":300,"max_hearts":2})
 for b in s.blocks:
  if own_clear(s,b) and s.slots.has(-1):s.select(b.id)
 s.advance(1.0);s.lost=true;var progress=s.collected;var remaining_units=JSON.stringify(s.units);var working=[]
 for occupied in s.slots:
  if occupied>=0 and s.blocks[occupied].remaining>0:working.append(occupied)
 check(s.continue_run() and s.coins==200,"continue cost accepted");check(s.collected==progress and JSON.stringify(s.units)==remaining_units,"continue retains exact progress and yarn");check(s.hearts==2 and s.slots.all(func(n):return n==-1),"continue restores life frees slots")
 for occupied in working:check(s.reserve.has(occupied),"continue restores remaining spool "+str(occupied))
 invariant(s,"continued");var result=solve(s);check(s.won,"continued board tool-free solution",result)
 s=fresh(0,{"mode":"free","coins":0})
 for i in range(4):s.lost=true;check(s.continue_run() and s.coins==0,"free continue unlimited "+str(i))
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

func test_boundaries():
 var s=fresh(8,{"max_hearts":3,"shield":true,"freeze":true});at_last(s);s.advance(0.1);check(s.freeze_used and not s.shield_used,"freeze delays shield attack",s.snapshot());s.advance(2.8);check(s.hearts==3 and not s.shield_used,"freeze prevents fire resolution",s.snapshot());s.advance(0.7);check(s.shield_used and s.hearts==3,"shield follows frozen windup",s.snapshot())
 var a=fresh(8,{"max_hearts":3,"shield":true,"freeze":true});var b=fresh(8,{"max_hearts":3,"shield":true,"freeze":true});at_last(a);at_last(b)
 for _i in range(900):a.advance(1.0/60.0)
 for _i in range(150):b.advance(0.1)
 check(a.hearts==b.hearts and a.lost==b.lost and a.cat_phase==b.cat_phase,"delta time consistent encounter",[a.snapshot(),b.snapshot()])
 s=fresh(0,{"coins":300});var selected=[]
 for block in s.blocks:
  if own_clear(s,block) and s.slots.has(-1):
   check(s.select(block.id),"rapid valid select");selected.append(block.id)
 check(selected.size()==4 and not s.slots.has(-1),"four rapid selections reserve slots",s.snapshot())
 var other=-1
 for block in s.blocks:
  if own_clear(s,block):other=block.id;break
 check(other>=0 and not s.select(other),"fifth selection rejected while travelling",s.snapshot());invariant(s,"rapid selection")
 s.paused=true;var wallet=s.coins;var spoolcount=s.slots.size();check(not s.unlock_slot() and not s.free_block() and not s.sort_yarn() and not s.strengthen(),"paused tools reject");check(s.coins==wallet and s.slots.size()==spoolcount,"paused tools no cost")
 s=fresh(0,{"coins":74});check(not s.free_block() and not s.sort_yarn() and s.coins==74,"insufficient seventy five tools unchanged");check(not s.strengthen() and s.coins==74,"insufficient boost unchanged")
 s=fresh(0,{"coins":300});check(s.sort_yarn() and s.coins==225,"sort exact cost");check(s.strengthen() and s.coins==125,"boost exact cost");check(not s.continue_run() and s.coins==125,"continue inactive rejection no charge")
 s.lost=true;s.coins=99;check(not s.continue_run() and s.lost and s.coins==99,"unaffordable continue retains failure")
 for mode in ["challenge","free"]:
  for level in range(10):
   s=fresh(level,{"mode":mode,"coins":300,"max_hearts":3 if level>=6 else 2 if level>=3 else 1,"shield":level>=2,"freeze":level>=7})
   for block in s.blocks:
    if own_clear(s,block) and s.slots.has(-1):s.select(block.id)
   s.advance(1.5);s.lost=true;check(s.continue_run(),"all levels continue accepted "+mode+str(level));var result=solve(s);check(s.won,"all levels continued solution "+mode+str(level),result)
 s=fresh();var result=solve(s);var progress=s.collected;var money=s.coins
 check(s.won,"terminal win fixture");check(not s.select(0) and not s.unlock_slot() and not s.free_block() and not s.sort_yarn() and not s.strengthen() and not s.continue_run(),"terminal win disallows mutations");s.advance(5);check(s.won and not s.lost and s.collected==progress and s.coins==money,"terminal win stops gameplay")
 var path=workspace+"/profile/growth-"+str(Time.get_ticks_usec())+".json";var p=Profile.new();p.open(path)
 for level in range(7):p.settle(p.start_run(),level)
 var q=Profile.new();q.open(path);check(q.stats()=={"max_hearts":3,"shield":true,"freeze":true},"growth survives reload",q.stats())
 var nofolder=Profile.new();var invalid=workspace+"/missing-parent/invalid.json";check(not nofolder.open(invalid),"save failure surfaced")

func test_real_failure():
 for level in range(10):
  var s=fresh(level,{"max_hearts":3 if level>=6 else 2 if level>=3 else 1,"shield":level>=2,"freeze":level>=7})
  var events={"flee":0,"shield":0,"freeze":0,"repel":0,"warning":0}
  s.encounter.connect(func(kind):events[kind]=int(events.get(kind,0))+1)
  s.advance(300.0)
  check(s.lost and s.hearts==0,"no input eventual fire loss "+str(level),s.snapshot())
  check(events.flee==2,"each anchor traversed once "+str(level),events)
  check(events.shield==(1 if level>=2 else 0) and events.repel==events.shield,"one shield and distinct repel per run "+str(level),events)
  check(events.freeze==(1 if level>=7 else 0),"one freeze per run "+str(level),events)
  var damage_time=s.time;check(s.continue_run(),"natural fire loss accepts continue "+str(level));var result=solve(s,damage_time+420.0);check(s.won,"natural failure recovery tool free "+str(level),result)

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

func run():
 var variants=[]
 for interval in [0.1,0.25,0.4,0.6,0.85,1.35]:
  var s=fresh(9,{"max_hearts":3,"shield":true,"freeze":true});s.advance(300);s.continue_run();var start=s.time;var result=solve(s,start+420,interval);result.interval=interval;result.resume_duration=s.time-start;variants.append(result);print("VARIANT interval=",interval," won=",s.won," after=",s.time-start," pct=",s.collected*100.0/s.total)
 var file=FileAccess.open(out+"/continue-level10-variants.json",FileAccess.WRITE);file.store_string(JSON.stringify(variants,"  "));file.close();quit()
