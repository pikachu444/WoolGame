extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var game=load("res://scenes/game.tscn").instantiate();root.add_child(game);game.demo=true;game.set_process(false)
	game.start_stage(0,true);var s=game.state
	s.encounter.connect(func(kind):print("ENCOUNTER ",s.time," ",kind," hearts=",s.hearts))
	s.hurt.connect(func():print("DAMAGE ",s.time," hearts=",s.hearts))
	# Boundary fixture: approach naturally from 130px away, then show actual timed transitions.
	s.head=s.route_curve.get_closest_offset(s.cat_position)-130
	for i in range(120):s.advance(1.0/30);await process_frame
	game.start_stage(0,true);s.cat_anchor_index=2;s.cat_position=s.definition.anchors[2];s.max_hearts=3;s.hearts=3
	s.head=s.route_curve.get_closest_offset(s.cat_position)-130
	for i in range(210):s.advance(1.0/30);await process_frame
	for connection in s.encounter.get_connections():s.encounter.disconnect(connection.callable)
	for connection in s.hurt.get_connections():s.hurt.disconnect(connection.callable)
	game.queue_free();await process_frame
	quit()
