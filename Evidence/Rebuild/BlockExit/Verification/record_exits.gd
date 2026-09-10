extends SceneTree
var game: Node
var frame_number=0
var folder="C:/SourceCodes/WoolGame/BuildWork/BlockExit/frames"
var evidence="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/after-final"
var runs=[]
func _initialize():run.call_deferred()
func frame():
 game.get_node("World")._process(1.0/30.0);game.get_node("PuzzleBoard")._process(1.0/30.0)
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join("frame_%05d.png"%frame_number));frame_number+=1
func run():
 game=load("res://scenes/game.tscn").instantiate();root.add_child(game);game.demo=true;game.set_process(false);game.muted=true
 game.get_node("World").set_process(false);game.get_node("PuzzleBoard").set_process(false)
 for spec in [{"name":"left","level":2,"dir":3},{"name":"right","level":2,"dir":1},{"name":"down-left","level":3,"dir":2,"side":0},{"name":"down-right","level":3,"dir":2,"side":1},{"name":"up","level":2,"dir":0}]:
  game.start_stage(spec.level,true)
  var s=game.state;var id=-1
  for b in s.blocks:
   if b.direction!=spec.dir or not s.can_select(b.id):continue
   if spec.has("side") and ((b.cell.x<296)!=(spec.side==0)):continue
   id=b.id;break
  if id<0:push_error("Missing exit "+spec.name);quit(1);return
  var record={"case":spec.name,"level":spec.level+1,"block":id,"start_frame":frame_number}
  for i in range(9):await frame()
  s.select(id)
  var block=s.blocks[id];record.duration=block.flight.duration;record.impacts=block.flight.impacts.duplicate(true)
  var snapped={}
  while s.time<block.arrival+0.4:
   s.advance(1.0/30.0);await frame()
   for i in range(block.flight.impacts.size()):
    if s.time-block.depart>=block.flight.impacts[i].time+0.055 and not snapped.has(i):
     snapped[i]=true;root.get_texture().get_image().save_png(evidence.path_join(spec.name+"-contact-"+str(i)+".png"))
  root.get_texture().get_image().save_png(evidence.path_join(spec.name+"-arrived.png"))
  record.end_frame=frame_number;runs.append(record)
 var manifest=FileAccess.open(evidence.path_join("recording.json"),FileAccess.WRITE)
 manifest.store_string(JSON.stringify({"fps":30,"method":"staged initial board, normal select and advance at 30fps; not native mouse input","runs":runs},"  "));manifest.close()
 for p in game.tones:p.stop();p.stream=null
 game.queue_free();await process_frame;await process_frame
 print("RECORDED ",frame_number);quit()
