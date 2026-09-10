extends SceneTree

var failures: Array[String]=[]
var checks=0
var game: Node

func check(value: bool,description: String) -> void:
	checks+=1
	if not value: failures.append(description); printerr("FAIL ",description)

func _initialize() -> void:
	run.call_deferred()

func pointer(point: Vector2,down: bool) -> void:
	var actual=game.get_viewport().get_final_transform()*point
	var motion=InputEventMouseMotion.new(); motion.position=actual; motion.global_position=actual
	Input.parse_input_event(motion)
	var event=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; event.position=actual; event.global_position=actual
	Input.parse_input_event(event)

func run() -> void:
	game=load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var state=game.state
	var ui=game.get_node("Interface")
	var board=game.get_node("PuzzleBoard")
	game.demo=false; state.paused=false; state.level_index=0; game.restart()
	ui.hint_button.pressed.emit()
	check(state.hint_id>=0 and state.can_select(state.hint_id),"Hint identifies an actually legal block")
	var id=state.hint_id
	var point=board.rect_for(state.blocks[id]).get_center()
	pointer(point,true)
	await process_frame
	pointer(point,false)
	await process_frame
	check(state.blocks[id].phase=="travel","A real viewport tap selects the intended block")
	game.restart()
	point=board.rect_for(state.blocks[state.witness[0]]).get_center()
	pointer(point,true)
	await process_frame
	pointer(point+Vector2(25,0),false)
	await process_frame
	check(state.slots.count(-1)==1,"A drag does not accidentally select a block")
	pointer(point,true)
	await process_frame
	board.press_time-=1
	pointer(point,false)
	await process_frame
	check(state.slots.count(-1)==1,"Holding a block does not act as a tap")
	ui.menu_button.pressed.emit()
	var time=state.time
	state.advance(5)
	check(state.paused and state.time==time,"Pause button freezes game time")
	await process_frame
	check(ui.modal_primary.visible,"Pause displays the continue action")
	ui.modal_primary.pressed.emit()
	check(not state.paused,"Continue resumes the same game")
	var before=game.muted
	ui.sound_button.pressed.emit()
	check(game.muted!=before and ui.muted==game.muted,"Sound button updates actual audio preference")
	for level in range(3):
		var next=state.time
		for _i in range(60*180):
			state.advance(1.0/60)
			if state.time>=next:
				var candidate=state.request_hint()
				if candidate>=0 and state.available(state.blocks[candidate].color): state.select(candidate)
				next=state.time+0.90
			if state.won or state.lost: break
		check(state.won,"Scene plays through level %d"%(level+1))
		state.advance(3)
		await process_frame
		check(ui.modal_primary.visible,"Success presents the next action")
		ui.modal_primary.pressed.emit()
		check(state.level_index==(level+1)%3 and not state.won and state.hearts==3,"Next action loads a fresh next puzzle")
	state.hearts=1; state.head=state.route_length-85.01; state.advance(0.1)
	await process_frame
	check(state.lost and ui.modal_primary.visible,"Last impact opens the retry flow")
	ui.modal_primary.pressed.emit()
	check(not state.lost and state.hearts==3,"Retry restores the current puzzle")
	game.queue_free()
	await process_frame
	print("UI_VERIFY ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
