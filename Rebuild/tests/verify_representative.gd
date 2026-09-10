extends SceneTree
const State=preload("res://scripts/state.gd")
const Reference=preload("res://scripts/reference_stage.gd")
var checks=0
var failures=[]
var output="C:/SourceCodes/WoolGame/BuildWork/Representative/Design"
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures.append(label);printerr("FAIL ",label)
func fresh() -> State:
 var s=State.new();s.reset(0,1,{"max_hearts":1,"coins":300});return s
func credit(s: State) -> Dictionary:
 var counts={}
 for i in range(s.units.size()):
  if s.exposed(i):counts[s.units[i].color]=counts.get(s.units[i].color,0)+1
 for id in s.slots:
  if id>=0:counts[s.blocks[id].color]=counts.get(s.blocks[id].color,0)-s.blocks[id].remaining
 return counts
func entrances(s: State,id: int,seen: Array=[]) -> Array:
 if seen.has(id):return []
 var visited=seen.duplicate();visited.append(id)
 if s.can_select(id):return [id]
 var result=[]
 for parent in s.blockers(id):
  for next in entrances(s,parent,visited):
   if not result.has(next):result.append(next)
 return result
func choose(s: State,style: int) -> int:
 var counts=credit(s);var chosen=-1;var best=-INF
 for b in s.blocks:
  if not s.can_select(b.id):continue
  var count=int(counts.get(b.color,0))
  if count<=0:continue
  if style==2 and s.slots.count(-1)==1 and count<b.remaining:continue
  var value=float(count)/b.remaining if style==0 else float(count)-0.1*b.remaining
  if value>best:best=value;chosen=b.id
 if chosen>=0:return chosen
 if s.slots.count(-1)<2:return -1
 for b in s.blocks:
  if b.phase!="board" or counts.get(b.color,0)<=0:continue
  var candidates=entrances(s,b.id)
  if not candidates.is_empty():return candidates[0]
 return -1
func simulate(interval: float,style: int,observed: bool=false) -> Dictionary:
 var s=fresh();var actions=[];var next=0.0;var cursor=0;var max_slots=0;var last_capture=0.0;var gap=0.0;var collected=0
 var reference_actions: Array=Reference.observed_actions() if observed else []
 var power_events=[]
 var record_power=func(unit,_block):
  if unit.has("power"):power_events.append({"time":snappedf(s.time,0.01),"source_time":snappedf(s.time+16.4,0.01),"unit_id":unit.id,"color":unit.color,"kind":unit.power.kind,"head_before_power":s.head,"head_source_x_before_power":snappedf((s.route_curve.sample_baked(s.head,true).x-296)/Reference.UPPER_SCALE+144,0.1)})
 s.captured.connect(record_power)
 var checkpoints=[];var checkpoint_times=[2.1,7.6,8.0,14.6,28.6,43.6,56.6,73.1,78.6,100.6,124.0];var checkpoint_cursor=0
 while s.time<240 and not s.won and not s.lost:
  if cursor<reference_actions.size():
   var action: Dictionary=reference_actions[cursor]
   if s.time>=action.time:
    check(s.select(action.block),"observed selection legal "+str(cursor));actions.append({"time":snappedf(s.time,0.01),"block":action.block,"source":"observed","slot":s.blocks[action.block].slot+1});cursor+=1;next=s.time+interval
  elif s.time>=next:
   var id=choose(s,style)
   if id>=0:
    check(s.select(id),"visible policy selection legal");actions.append({"time":snappedf(s.time,0.01),"block":id,"source":"visible-policy"})
   next=s.time+interval
  max_slots=maxi(max_slots,4-s.slots.count(-1));s.advance(0.1)
  if observed and checkpoint_cursor<checkpoint_times.size() and s.time>=checkpoint_times[checkpoint_cursor]:
   checkpoints.append({"time":snappedf(s.time,0.01),"source_time":snappedf(s.time+16.4,0.01),"head_distance":s.head,"head_source_x":snappedf((s.route_curve.sample_baked(s.head,true).x-296)/Reference.UPPER_SCALE+144,0.1),"red_remaining":s.blocks[15].remaining,"cyan_remaining":s.blocks[14].remaining,"orange_remaining":s.blocks[22].remaining,"slots":s.slots.duplicate(),"collected":s.collected});checkpoint_cursor+=1
  if s.collected>collected:gap=maxf(gap,s.time-last_capture);last_capture=s.time;collected=s.collected
 s.captured.disconnect(record_power)
 return {"interval":interval,"power_events":power_events,"style":style,"observed_prefix":observed,"observed_actions_replayed":cursor,"checkpoints":checkpoints,"won":s.won,"lost":s.lost,"time":snappedf(s.time,0.01),"collected":s.collected,"total":s.total,"hearts":s.hearts,"coins":s.coins,"reason":s.loss_reason,"max_capture_gap":snappedf(gap,0.01),"max_slots":max_slots,"last_action_to_clear":snappedf(s.time-float(actions[-1].time),0.01) if not actions.is_empty() else -1,"actions":actions}
func opening_winding() -> Dictionary:
 var s=fresh();s.select(16);var initial_head=s.head;var records=[];var last=0
 while s.time<4.0:
  s.advance(0.05)
  if s.collected!=last:
   records.append({"time":snappedf(s.time,0.01),"collected":s.collected,"remaining":s.blocks[16].remaining,"head_distance":snappedf(s.head,0.01),"head_net_movement":snappedf(s.head-initial_head,0.01)})
   last=s.collected
 return {"scope":"One original first block with no subsequent input; mapped timing candidate, not source constants","arrival":s.blocks[16].arrival,"flight_duration":s.blocks[16].flight.duration,"records":records}
func run() -> void:
 var s=fresh();var definition=Reference.definition();var colors={};var lengths={};var graph=[];var color_units={}
 check(s.definition.get("reference_stage",false),"campaign level 2 routes to representative definition")
 check(s.blocks.size()==28,"observed 28 starting blocks")
 for b in s.blocks:
  colors[b.color]=true;lengths[b.reference_length]=true;color_units[b.color]=color_units.get(b.color,0)+b.capacity
  check(b.color>=0 and b.color<8 and b.capacity>0,"valid color and capacity "+str(b.id))
  check(Rect2i(0,590,592,438).encloses(Rect2i(b.cell,b.size)),"inside existing board "+str(b.id))
  var expected: Array=Reference.EXPECTED_BLOCKERS[b.id]
  check(s.blockers(b.id)==expected,"source exit relation "+str(b.id))
  graph.append({"id":b.id,"reference_id":b.reference_id,"blockers":s.blockers(b.id)})
 check(colors.size()==8,"observed 8 colors including cyan and pink")
 check(lengths.size()==3,"observed three visible length classes")
 check(s.witness.size()==28,"escape feasibility only, never used as play solution")
 var removed: Array[int]=[]
 for action in Reference.observed_actions():
  check(s.blockers(action.block,removed).is_empty(),"all28 original departures preserve exit order "+str(action.block));removed.append(action.block)
 var order: Array=definition.yarn_order;var sorted=order.duplicate();sorted.sort()
 check(sorted==range(28),"authored yarn order is complete block permutation")
 check(s.total==color_units.values().reduce(func(a,b):return a+b,0),"yarn total equals spool capacity")
 var generated_colors={}
 for unit in s.units:generated_colors[unit.color]=generated_colors.get(unit.color,0)+1
 check(generated_colors==color_units,"segmented yarn preserves every color capacity")
 var runs=[]
 for interval in [0.8,1.2,2.4,3.2]:
  var result=simulate(interval,2);runs.append(result)
  check(result.won and result.coins==300,"visible planned tool-free completion "+str(interval))
 for interval in [0.8,1.2]:
  var diagnostic=simulate(interval,0);diagnostic.policy_scope="greedy diagnostic, not required to win";runs.append(diagnostic)
 var alternate=simulate(2.4,1);runs.append(alternate);check(alternate.won,"alternate visible choice completion")
 var replay=simulate(2.4,0,true);runs.append(replay);check(replay.won,"all28 source departure replay completion")
 var observed_slots=[1,1,2,3,3,4,4,4,4,4]
 check(replay.actions.size()>=10,"all ten observed opening inputs completed")
 for i in range(mini(10,replay.actions.size())):check(replay.actions[i].slot==observed_slots[i],"original opening slot "+str(i))
 for point in replay.checkpoints:
  if absf(point.source_time-45.0)<0.15 or absf(point.source_time-60.0)<0.15:check(point.red_remaining==6 and point.cyan_remaining==5 and point.orange_remaining==2,"original long-held R6 C5 O2 at "+str(point.source_time))
 check(replay.power_events.size()==2,"both observed yarn powers actually captured")
 if replay.power_events.size()==2:
  check(replay.power_events[0].color==1 and replay.power_events[0].unit_id==Reference.unit_of_color(1,3),"repel on third yellow unit")
  check(replay.power_events[1].color==1 and replay.power_events[1].unit_id==Reference.unit_of_color(1,18),"slow on eighteenth yellow unit")
 check(replay.last_action_to_clear<=6.0,"original full replay has bounded final winding")
 var data={"scope":"Developer checks; source geometry observed, inferred parameters explicitly labelled in reference_stage.gd. Not independent or native play.","checks":checks,"failures":failures,"source_sha256":FileAccess.get_sha256("res://scripts/reference_stage.gd"),"state_sha256":FileAccess.get_sha256("res://scripts/state.gd"),"geometry":graph,"color_units":color_units,"opening_winding":opening_winding(),"runs":runs}
 var file=FileAccess.open(output+"/development-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(data,"  "));file.close()
 print("REPRESENTATIVE ",checks-failures.size(),"/",checks);quit(0 if failures.is_empty() else 1)
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 for i in range(args.size()-1):
  if args[i]=="--out":output=args[i+1]
 DirAccess.make_dir_recursive_absolute(output);call_deferred("run")
