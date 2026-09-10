extends SceneTree
var game: Node
var folder="C:/SourceCodes/WoolGame/Evidence/Rebuild/FunRevision/Rewards"
func _initialize():run.call_deferred()
func shot(name: String):
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func run():
 game=load("res://scenes/game.tscn").instantiate();root.add_child(game);game.set_process(false);game.muted=true
 for level in range(10):
  game.receipt=game.profile.settle(game.profile.start_run(),level)
  game.navigate("result")
  if level in [0,5,7,9]:await shot("result-%02d"%(level+1))
  game.acknowledge_result()
 game.navigate("collection");await shot("collection-all")
 game.navigate("home");await shot("home-complete")
 game.switch_mode("free");game.navigate("collection");await shot("collection-locked")
 game.queue_free();await process_frame;await process_frame
 print("REWARD_CAPTURE_DONE: visual profile fixture, no play claim");quit()
