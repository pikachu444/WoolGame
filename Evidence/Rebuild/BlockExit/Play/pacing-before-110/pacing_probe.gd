extends SceneTree
const State=preload("res://scripts/state.gd")
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/Play"
func _initialize():run.call_deferred()
func row(s):
 var units=[]
 for i in range(s.units.size()):
  var u=s.units[i];var p=s.unit_point(i);units.append({"color":u.color,"exposed":s.exposed(i),"distance":s.unit_distance(i),"x":p.x,"y":p.y})
 var slots=[]
 for id in s.slots:
  if id>=0:slots.append({"id":id,"color":s.blocks[id].color,"phase":s.blocks[id].phase,"remaining":s.blocks[id].remaining})
 var legal=[]
 for b in s.blocks:
  if s.can_select(b.id):legal.append({"id":b.id,"color":b.color,"available":s.available(b.color)})
 return {"time":s.time,"collected":s.collected,"head":s.head,"cat_phase":s.cat_phase,"units":units,"slots":slots,"legal":legal}
func run():
 var s=State.new();s.reset(0,6,{"max_hearts":3,"shield":true})
 var actions=JSON.parse_string(FileAccess.get_file_as_string(out+"/pacing-actions.json"));var n=0;var samples=[];var gaps=[];var last_time=0.0;var last_count=0;var action_results=[]
 while s.time<240 and not s.won and not s.lost:
  if n<actions.size() and s.time+0.001>=actions[n].time:
   action_results.append({"time":s.time,"id":actions[n].block,"accepted":s.select(int(actions[n].block))});n+=1
  if int(round(s.time*10))%5==0:samples.append(row(s))
  s.advance(0.1)
  if s.collected>last_count:
   gaps.append({"start":last_time,"end":s.time,"duration":s.time-last_time});last_time=s.time;last_count=s.collected
 gaps.sort_custom(func(a,b):return a.duration>b.duration)
 var file=FileAccess.open(out+"/pacing-probe.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"scope":"Replay development 2.4s action timestamps using normal select and advance, not independent solution or native input","won":s.won,"lost":s.lost,"time":s.time,"actions":action_results,"longest_gaps":gaps.slice(0,5),"samples":samples,"state_sha256":FileAccess.get_sha256("res://scripts/state.gd"),"campaign_sha256":FileAccess.get_sha256("res://scripts/campaign.gd")},"  "));file.close()
 print("PACING_REPLAY ",s.won," time ",s.time," maxgap ",gaps[0]);quit()
