extends SceneTree
var game: Node
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/Play"
func _initialize():run.call_deferred()
func shot(label):
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(label+".png"))
func run():
 game=load("res://scenes/game.tscn").instantiate();root.add_child(game);game.demo=true;game.set_process(false);game.muted=true
 game.start_stage(6,true)
 var s=game.state;var actions=JSON.parse_string(FileAccess.get_file_as_string(out+"/pacing-actions.json"));var n=0
 var times=[53.5,56.0,59.4,60.0];var captures=[]
 while s.time<60.1 and not s.lost:
  if n<actions.size() and s.time+0.001>=actions[n].time:s.select(int(actions[n].block));n+=1
  if not times.is_empty() and s.time+0.001>=times[0]:
   var t=times.pop_front();var name="pacing-%03d"%int(round(t*10));await shot(name);captures.append({"file":name+".png","time":s.time,"collected":s.collected,"slots":s.slots.duplicate()})
  if times.is_empty():break
  s.advance(0.1);game.get_node("World")._process(0.1);game.get_node("PuzzleBoard")._process(0.1)
 var file=FileAccess.open(out+"/pacing-render.json",FileAccess.WRITE);file.store_string(JSON.stringify({"scope":"Replay development 2.4s action timestamps in normal scene using select/advance; QA stage7 start; not native input or independent solving","captures":captures,"state_sha256":FileAccess.get_sha256("res://scripts/state.gd"),"campaign_sha256":FileAccess.get_sha256("res://scripts/campaign.gd"),"world_sha256":FileAccess.get_sha256("res://scripts/world.gd"),"hud_sha256":FileAccess.get_sha256("res://scripts/hud.gd")},"  "));file.close()
 for p in game.tones:p.stop();p.stream=null
 game.queue_free();await process_frame;await process_frame
 print("PACING_RENDER_DONE");quit()
