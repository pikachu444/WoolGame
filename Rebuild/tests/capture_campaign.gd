extends SceneTree
var game: Node
var folder=""
func _initialize() -> void:run.call_deferred()
func shot(name: String) -> void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func run() -> void:
	for i in range(OS.get_cmdline_user_args().size()):
		if OS.get_cmdline_user_args()[i]=="--evidence":folder=OS.get_cmdline_user_args()[i+1]
	if folder.is_empty():quit(1);return
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://scenes/game.tscn").instantiate();root.add_child(game);game.set_process(false);game.demo=true
	await shot("01-home")
	game.navigate("growth");await shot("02-growth")
	game.navigate("collection");await shot("03-collection-locked")
	for level in [0,4,8]:
		game.start_stage(level,true);await shot("stage-%02d-start"%(level+1))
	game.start_stage(0,true)
	var s=game.state
	s.select(s.request_hint());s.advance(0.8);await shot("04-winding")
	s.head=s.route_curve.get_closest_offset(s.cat_position)-50;s.advance(0.3);await shot("05-flee-staged")
	s.advance(0.6);s.cat_anchor_index=2;s.cat_position=s.definition.anchors[2];s.head=s.route_curve.get_closest_offset(s.cat_position)-45;s.advance(0.1);await shot("06-windup-staged")
	s.max_hearts=3;s.hearts=3;s.advance(0.5);await shot("07-fire-staged")
	game.start_stage(2,true);s.shield_enabled=true;s.cat_anchor_index=2;s.cat_position=s.definition.anchors[2];s.head=s.route_curve.get_closest_offset(s.cat_position)-40;s.advance(0.6);await shot("08-shield-staged")
	game.start_stage(7,true);s.freeze_enabled=true;s.head=s.route_curve.get_closest_offset(s.cat_position)-40;s.advance(0.1);await shot("09-freeze-staged")
	game.start_stage(0,true);s.cat_anchor_index=2;s.cat_position=s.definition.anchors[2];s.head=s.route_curve.get_closest_offset(s.cat_position)-40;s.advance(0.6);await shot("10-failure-staged")
	game.continue_stage();await shot("11-continue-staged")
	game.start_stage(0,true)
	var next=0.0
	while s.time<200 and not s.won and not s.lost:
		if s.time>=next:
			var id=s.request_hint()
			if id>=0 and s.available(s.blocks[id].color):s.select(id)
			next=s.time+0.8
		s.advance(0.05)
	s.advance(2.1);game._process(0);await shot("12-result-normal-moves")
	game.acknowledge_result();await shot("13-home-after-clear")
	game.navigate("collection");await shot("14-collection-earned")
	print("CAPTURE_DONE ",folder);quit()
