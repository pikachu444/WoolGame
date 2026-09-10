extends SceneTree
var game: Node
var out=""
func _initialize():run.call_deferred()
func run():
 var args=OS.get_cmdline_user_args()
 for i in range(args.size()):
  if args[i]=="--out":out=args[i+1]
 game=load("res://scenes/game.tscn").instantiate();root.add_child(game);game.demo=true;game.set_process(false);game.muted=true
 var board=game.get_node("PuzzleBoard")
 for direction in [3,1,2,0]:
  game.start_stage(2,true)
  var s=game.state
  var id=-1
  for b in s.blocks:
   if b.direction==direction and s.can_select(b.id):id=b.id;break
  if id<0:push_error("Missing direction "+str(direction));quit(1);return
  s.select(id)
  var duration=s.blocks[id].arrival-s.blocks[id].depart
  for sample in [0.0,0.2,0.38,0.48,0.65,0.82,0.96,1.0]:
   s.time=duration*sample
   board.queue_redraw()
   await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out.path_join("dir%d-%03d.png"%[direction,int(sample*100)]))
 for p in game.tones:p.stop();p.stream=null
 game.queue_free();await process_frame;await process_frame
 print("EXIT_CAPTURE_DONE ",out);quit()
