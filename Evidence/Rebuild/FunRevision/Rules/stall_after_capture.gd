extends SceneTree
const State=preload("res://scripts/state.gd")
func _initialize():
 var actions=JSON.parse_string(FileAccess.get_file_as_string("C:/SourceCodes/WoolGame/BuildWork/FunAudit/IndependentRules/stall-trace-input.json"))
 var s=State.new();s.reset(0,9,{"max_hearts":3,"shield":true,"freeze":true});var index=0;var captures=[]
 var capture_event=func(u,b):captures.append({"time":s.time,"stalled_since_before_capture":s.stalled_since,"block":b.id,"color":u.color,"collected_before":s.collected})
 s.captured.connect(capture_event)
 while not s.lost and s.time<40:
  if index<actions.size() and s.time+0.001>=actions[index].t:s.select(int(actions[index].id));index+=1
  s.advance(0.1)
 s.captured.disconnect(capture_event)
 var result={"time":s.time,"lost":s.lost,"loss_reason":s.loss_reason,"stalled_since":s.stalled_since,"hearts":s.hearts,"collected":s.collected,"last_capture":captures[-1],"elapsed_since_capture":s.time-captures[-1].time,"captures":captures,"state_sha256":FileAccess.get_sha256("res://scripts/state.gd"),"campaign_sha256":FileAccess.get_sha256("res://scripts/campaign.gd")}
 var f=FileAccess.open("C:/SourceCodes/WoolGame/Evidence/Rebuild/FunRevision/Rules/stall-after-capture.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();print(JSON.stringify(result));quit()
