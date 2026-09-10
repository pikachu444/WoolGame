extends SceneTree
var game: Node
var problems=[]
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/Play"
func _initialize():run.call_deferred()
func shot(label):
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(label+".png"))
func replay(label,actions_path,times):
 game.start_stage(6,true)
 var s=game.state;var raw=JSON.parse_string(FileAccess.get_file_as_string(out+"/"+actions_path));var actions=[];var n=0;var captures=[]
 for entry in raw:
  if entry is Array and entry.size()==2:actions.append({"time":float(entry[0]),"block":int(entry[1])})
  elif entry is Dictionary and entry.has("time") and entry.has("block"):actions.append(entry)
  else:problems.append(label+" invalid action format");return {"error":"invalid action format"}
 while not times.is_empty() and s.time<90 and not s.lost:
  if n<actions.size() and s.time+0.001>=actions[n].time:
   if not s.select(int(actions[n].block)):problems.append(label+" rejected action "+str(actions[n])+" at "+str(s.time))
   n+=1
  if s.time+0.001>=times[0]:
   var t=times.pop_front();var name="pacing-"+label+"-%03d"%int(round(t*10));await shot(name)
   var exposed=0
   for i in range(s.units.size()):
    if s.exposed(i):exposed+=1
   captures.append({"file":name+".png","time":s.time,"collected":s.collected,"slots":s.slots.duplicate(),"exposed":exposed,"units":s.units.size(),"hearts":s.hearts,"won":s.won})
  if times.is_empty():break
  s.advance(0.1);game.get_node("World")._process(0.1);game.get_node("PuzzleBoard")._process(0.1)
 if not times.is_empty():problems.append(label+" ended before all captures")
 return {"case":label,"actions":actions_path,"captures":captures,"lost":s.lost,"time":s.time}
func run():
 game=load("res://scenes/game.tscn").instantiate();root.add_child(game);game.demo=true;game.set_process(false);game.muted=true
 var fresh=await replay("final","pacing-actions.json",[45.5,46.5,48.2,53.5,56.0,58.8])
 var old=await replay("old-input","pacing-old-actions.json",[53.5,56.0,59.4])
 var hashes={}
 for f in ["state","campaign","world","hud","map_theme","background","layout","board","block_flight"]:hashes[f+".gd"]=FileAccess.get_sha256("res://scripts/"+f+".gd")
 var file=FileAccess.open(out+"/pacing-render.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"scope":"Normal scene, QA stage7 start with separate fresh profile; replay final development 2.4s actions and old fixed actions through select/advance; no time/position/collection injection; not native input or independent solving","problems":problems,"cases":[fresh,old],"source_sha256":hashes,"harness_sha256":FileAccess.get_sha256(out+"/capture_pacing.gd")},"  "));file.close()
 for p in game.tones:p.stop();p.stream=null
 game.queue_free();await process_frame;await process_frame
 if problems.is_empty():print("PACING_RENDER_DONE")
 else:printerr("PACING_RENDER_FAILED ",problems)
 quit(0 if problems.is_empty() else 1)
