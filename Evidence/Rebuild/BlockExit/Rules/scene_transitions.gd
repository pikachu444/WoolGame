extends SceneTree
var failures=[]
var unique={}
var checks=0
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/Rules"
func check(ok: bool,label: String,detail: Variant=null):
 checks+=1
 if not ok and not unique.has(label):unique[label]=true;failures.append({"label":label,"detail":detail});print("FAIL ",label," ",JSON.stringify(detail))
func _initialize():call_deferred("run")
func frames():
 await process_frame
 await process_frame
func run():
 var scene=load("res://scenes/game.tscn").instantiate();root.add_child(scene);await frames();scene.muted=true
 var s=scene.state;var board=scene.get_node("PuzzleBoard");var ui=scene.get_node("Interface")
 for direction in range(4):
  scene.start_stage(9,true);var id=-1
  # Choose a real directional block; remove only its blocking neighbours for transition fixtures.
  for b in s.blocks:
   if b.direction==direction:id=b.id;break
  check(id>=0,"authored direction fixture",direction)
  var block=s.blocks[id]
  for other in s.blocks:
   if other.id!=id:other.phase="finished"
  check(s.select(id),"direction selects through public input",direction)
  var plan=block.flight
  for segment in plan.segments:
   s.time=block.depart+segment.start+segment.duration*0.5
   var pose=board.travel_pose(block);var core=JSON.stringify(s.snapshot());board._process(0)
   var playing_z=board.z_index
   check(playing_z>ui.z_index,"travel rendered above dock controls",[direction,playing_z,ui.z_index])
   scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);board._process(0.3);scene._process(0.3)
   check(board.travel_pose(block)==pose and JSON.stringify(s.snapshot())==core,"focus freezes complete travel pose and progress",[direction,segment.kind])
   check(board.z_index==playing_z,"focus retains visible travel layer",[direction,segment.kind,playing_z,board.z_index])
   scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
   check(board.travel_pose(block)==pose,"focus resumes without pose jump",[direction,segment.kind])
   s.paused=true;board._process(0.3);ui._process(0)
   check(board.z_index<=ui.z_index,"pause panel above all board blocks",[direction,board.z_index,ui.z_index])
   s.advance(0.5);check(board.travel_pose(block)==pose,"pause freezes transfer/turn pose",[direction,segment.kind])
   s.paused=false
  s.lost=true;board._process(0);ui._process(0);check(board.z_index<=ui.z_index,"failure panel above all board blocks",direction);s.lost=false
  var hits={"count":0};var listener=func():hits.count+=1
  board.edge_tapped.connect(listener);board.hit_marks.clear()
  for hit in plan.impacts:
   s.time=block.depart+hit.time+0.03
   var count=hits.count;board._process(0);board._process(0)
   check(hits.count==count+1,"impact sound once per contact",[direction,hit,hits.count,count])
  board.edge_tapped.disconnect(listener)
 var file=FileAccess.open(out+"/scene-transitions.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"game_sha256":FileAccess.get_sha256("res://scripts/game.gd"),"board_sha256":FileAccess.get_sha256("res://scripts/board.gd")},"  "));file.close()
 for player in scene.tones:player.stop();player.stream=null
 await create_timer(0.2).timeout
 scene.queue_free();await process_frame
 print("INDEPENDENT_EXIT_SCENE checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
