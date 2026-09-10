extends SceneTree
const Reference=preload("res://scripts/reference_stage.gd")
var game: Node
var frame_dir="C:/SourceCodes/WoolGame/BuildWork/Representative/FinalReplayFrames"
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/Representative/Visual"
func _initialize():run.call_deferred()
func run():
 DirAccess.make_dir_recursive_absolute(frame_dir);DirAccess.make_dir_recursive_absolute(out)
 game=load("res://scenes/game.tscn").instantiate();root.add_child(game)
 game.set_process(false);game.demo=true;game.muted=true;game.start_stage(1,true)
 game.get_node("World").set_process(false);game.get_node("PuzzleBoard").set_process(false);game.get_node("Interface").set_process(false)
 var actions=Reference.observed_actions();var cursor=0;var records=[];var shots={0:"start",32:"opening-cyan",114:"held-slots",219:"orange-held",465:"power-approach",480:"knockback",495:"knockback-route",654:"three-held-colors",1179:"late-game",1550:"slow",1860:"source-clear-time"}
 var failed=false
 for frame in range(1951):
  var target=frame/15.0
  while cursor<actions.size() and actions[cursor].time<=target:
   game.state.advance(maxf(0,float(actions[cursor].time)-game.state.time))
   var accepted=game.state.select(actions[cursor].block)
   records.append({"source_time":actions[cursor].time+16.4,"game_time":game.state.time,"block":actions[cursor].block,"accepted":accepted})
   if not accepted:failed=true
   cursor+=1
  game.state.advance(maxf(0,target-game.state.time));game.get_node("World")._process(1.0/15.0);game.get_node("PuzzleBoard")._process(1.0/15.0);game.get_node("Interface")._process(1.0/15.0)
  if frame>525 and not shots.has(frame) and not game.state.won and not game.state.lost:continue
  await process_frame;await RenderingServer.frame_post_draw
  if frame<=525:root.get_texture().get_image().save_png(frame_dir.path_join("frame_%05d.png"%frame))
  if shots.has(frame):root.get_texture().get_image().save_png(out.path_join("stage2-"+shots[frame]+".png"))
  if game.state.won or game.state.lost:
   root.get_texture().get_image().save_png(out.path_join("stage2-final.png"));break
 var report={"scope":"Normal game rendering with deterministic source departure replay; not native manual input.","failed_selection":failed,"actions":records,"state":game.state.snapshot(),"state_sha256":FileAccess.get_sha256("res://scripts/state.gd"),"reference_sha256":FileAccess.get_sha256("res://scripts/reference_stage.gd"),"world_sha256":FileAccess.get_sha256("res://scripts/world.gd")}
 var f=FileAccess.open(out.path_join("render-replay.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("REP_RENDER ",JSON.stringify({"won":game.state.won,"lost":game.state.lost,"time":game.state.time,"actions":cursor,"failed":failed,"effects":game.state.power_events}))
 var success=game.state.won and not failed
 game.queue_free();await process_frame;await process_frame;quit(0 if success else 1)
