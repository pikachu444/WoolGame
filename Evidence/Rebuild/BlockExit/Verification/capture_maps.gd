extends SceneTree
var game: Node
var folder="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/Maps"
func _initialize():run.call_deferred()
func shot(name: String):
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func run():
 game=load("res://scenes/game.tscn").instantiate();root.add_child(game);game.demo=true;game.set_process(false);game.muted=true
 for level in range(10):
  game.start_stage(level,true);await shot("stage-%02d-start"%(level+1))
 game.start_stage(2,true)
 var s=game.state
 s.head=s.route_curve.get_closest_offset(s.cat_position)-90;s.advance(0.05);await shot("stage-03-cat-flee-start")
 s.advance(0.75);await shot("stage-03-cat-after-flee")
 game.start_stage(2,true)
 var selected=-1
 for b in game.state.blocks:
  if game.state.can_select(b.id):selected=b.id;break
 if selected>=0:game.state.select(selected);game.state.advance(0.15)
 game.state.paused=true;await shot("pause-with-travel")
 game.state.paused=false;game.state.lost=true;await shot("loss-with-travel")
 for p in game.tones:p.stop();p.stream=null
 game.queue_free();await process_frame;await process_frame
 print("MAP_CAPTURE_DONE");quit()
