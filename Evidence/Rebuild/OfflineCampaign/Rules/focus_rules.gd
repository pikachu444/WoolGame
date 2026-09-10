extends SceneTree
var failures=[]
var checks=0
var scene: Node
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/OfflineCampaign/Rules"
func check(ok: bool,label: String,detail: Variant=null):
 checks+=1
 if not ok:failures.append({"label":label,"detail":detail});print("FAIL ",label," ",JSON.stringify(detail))
func _initialize():call_deferred("run")
func core():return JSON.stringify(scene.state.snapshot())
func focus_out():scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
func focus_in():scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
func frames():
 await process_frame
 await process_frame
func run():
 scene=load("res://scenes/game.tscn").instantiate();root.add_child(scene);await frames()
 scene.muted=true;scene.start_stage(0);await frames()
 check(scene.state.select(0),"partial winding fixture selects normal block")
 scene.state.advance(1.25);check(scene.state.collected>0,"fixture contains collected yarn")
 var id=scene.run_id;var screen=scene.screen;var ui=scene.get_node("Interface");var board=scene.get_node("PuzzleBoard")
 board.press_id=1;board.cancelled=false
 focus_out();var suspended=core();var coins=scene.profile.current().coins
 check(not scene.state.active and not scene.state.paused,"focus out suspends progress without manual pause")
 check(scene.focus_suspended,"focus suspend remembered")
 check(board.press_id==-1 and board.cancelled,"interrupted pointer press cleared")
 for i in range(30):scene._process(0.1)
 await frames()
 check(core()==suspended and scene.profile.current().coins==coins,"background preserves time yarn dragons slots wallet")
 check(scene.screen==screen and scene.run_id==id,"background retains same stage and run")
 check(not ui.buttons.has("Resume") and not ui.buttons.has("Home"),"background does not replace board with pause menu",ui.buttons.keys())
 var before_again=core();focus_out();check(core()==before_again,"duplicate focus out idempotent")
 focus_in();check(scene.state.active and not scene.state.paused and not scene.focus_suspended,"focus in restores active board")
 check(core()==suspended and scene.run_id==id,"focus in has no catch up or reset")
 focus_in();check(core()==suspended,"duplicate focus in idempotent")
 scene._process(0.1);check(scene.state.time>JSON.parse_string(suspended).time,"foreground simulation resumes")
 await frames();check(not ui.buttons.has("Resume") and not ui.buttons.has("Home"),"foreground has no accidental Home target",ui.buttons.keys())
 scene.back();await frames();check(scene.state.paused and ui.buttons.has("Resume") and ui.buttons.has("Home"),"manual pause opens menu intentionally")
 focus_out();var manual=core()
 for i in range(10):scene._process(0.1)
 focus_in();check(scene.state.paused and core()==manual,"focus round trip preserves manual pause")
 scene._process(1.0);check(core()==manual,"manual pause stays frozen after focus in")
 scene.back();check(not scene.state.paused and scene.state.active,"manual resume restores same game")
 focus_out();scene.navigate("home");focus_in();check(scene.screen=="home" and not scene.state.active and not scene.focus_suspended,"focus in cannot revive game after home navigation")
 focus_out();focus_in();check(scene.screen=="home" and not scene.state.active,"home focus events leave gameplay inactive")
 scene.start_stage(0);focus_out();scene.start_stage(0);check(not scene.focus_suspended and scene.state.active,"new run clears stale suspension")
 scene.state.won=true;scene.state.won_at=scene.state.time;focus_out();check(not scene.focus_suspended,"completed game is not suspended")
 scene._process(0.1);check(scene.state.time>scene.state.won_at,"success delay can progress after focus event")
 scene.state.won=false;scene.state.lost=true;focus_out();check(not scene.focus_suspended,"lost game is not newly suspended")
 var resources={}
 for path in ["res://scripts/game.gd","res://scripts/state.gd"]:resources[path]=FileAccess.get_sha256(path)
 var result={"checks":checks,"failures":failures,"resource_hashes":resources,"scope":"headless notification/state and generated controls; not native focus delivery"}
 var file=FileAccess.open(out+"/focus-rules.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
 for player in scene.tones:player.stop();player.stream=null
 await create_timer(0.2).timeout
 scene.queue_free();await process_frame
 print("INDEPENDENT_FOCUS checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
