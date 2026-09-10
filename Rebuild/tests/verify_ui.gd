extends SceneTree
const State=preload("res://scripts/state.gd")
var failures: Array[String]=[]
var checks=0
var game: Node
func check(value: bool,description: String) -> void:
	checks+=1
	if not value:failures.append(description);printerr("FAIL ",description)
func _initialize() -> void:run.call_deferred()
func frames() -> void:
	await process_frame
	await process_frame
func press(id: String) -> void:
	var ui=game.get_node("Interface")
	check(ui.buttons.has(id),"Action exists: "+id)
	if ui.buttons.has(id):ui.buttons[id].pressed.emit()
	await frames()
func pointer(point: Vector2,down: bool) -> void:
	var actual=game.get_viewport().get_final_transform()*point
	var motion=InputEventMouseMotion.new();motion.position=actual;motion.global_position=actual;Input.parse_input_event(motion)
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=actual;event.global_position=actual;Input.parse_input_event(event)
func exposed_counts(s: State) -> Dictionary:
	var counts={}
	for i in range(s.units.size()):
		if s.exposed(i):counts[s.units[i].color]=counts.get(s.units[i].color,0)+1
	for id in s.slots:
		if id>=0:counts[s.blocks[id].color]=counts.get(s.blocks[id].color,0)-s.blocks[id].remaining
	return counts
func ancestors(s: State,id: int,seen: Array=[]) -> Array:
	if seen.has(id):return []
	var path=seen.duplicate();path.append(id)
	if s.can_select(id):return [id]
	var result=[]
	for blocker in s.blockers(id):
		for candidate in ancestors(s,blocker,path):
			if not result.has(candidate):result.append(candidate)
	return result
func choose(s: State,style: int=0) -> int:
	var counts=exposed_counts(s);var best=-1;var score=-INF
	for b in s.blocks:
		if not s.can_select(b.id):continue
		var matching=int(counts.get(b.color,0))
		if matching<=0:continue
		var value=float(matching)/b.remaining
		if style==1:value=float(matching)-b.remaining*0.1
		if value>score:score=value;best=b.id
	if best>=0:return best
	# Open a blocked matching color while leaving room for its spool.
	if s.slots.count(-1)<2:return -1
	for b in s.blocks:
		if b.phase!="board" or counts.get(b.color,0)<=0:continue
		var candidates=ancestors(s,b.id)
		if not candidates.is_empty():return candidates[0]
	return -1
func run() -> void:
	game=load("res://scenes/game.tscn").instantiate();root.add_child(game);await frames()
	var s=game.state;var ui=game.get_node("Interface");var board=game.get_node("PuzzleBoard")
	check(game.screen=="home" and not s.active,"Fresh install opens home")
	check(ui.buttons.Level2.disabled,"Next stage locked before clear")
	await press("Start")
	check(s.active and s.hearts==1,"Challenge starts with one heart")
	var frozen_time=s.time;var frozen_units=s.units.size()
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);s.advance(10);await frames()
	check(s.time==frozen_time and s.units.size()==frozen_units and not s.paused,"Focus loss suspends without opening a menu")
	check(not ui.buttons.has("Home"),"Focus suspension does not put Home over the board")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(s.active and not s.paused,"Focus return resumes the same board")
	s.paused=true;game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(s.paused,"Focus return preserves an explicit manual pause");s.paused=false;await frames()
	var id=s.request_hint();var point=board.rect_for(s.blocks[id]).get_center()
	pointer(point,true);await process_frame;pointer(point,false);await frames()
	check(s.blocks[id].phase=="travel","Viewport tap selects and reserves a slot")
	await press("Pause");var time=s.time;s.advance(5)
	check(s.paused and s.time==time,"Pause freezes game time")
	await press("Resume");check(not s.paused,"Resume retains game")
	await press("Pause");await press("Retry")
	check(s.collected==0 and s.slots.count(-1)==4 and s.coins==300,"Retry resets stage without cost")
	point=board.rect_for(s.blocks[s.request_hint()]).get_center()
	pointer(point,true);await process_frame;pointer(point+Vector2(30,0),false);await frames()
	check(s.slots.count(-1)==4,"Drag does not select a block")
	for level in range(10):
		var next=s.time
		while s.time<200 and not s.won and not s.lost:
			if s.time>=next:
				var candidate=choose(s)
				if candidate>=0:s.select(candidate)
				next=s.time+0.8
			s.advance(0.05)
		check(s.won and not s.lost,"Scene completes stage %d"%(level+1))
		check(game.profile.current().completed.has(level),"Victory persists before result animation")
		s.advance(2.1);await frames()
		check(game.screen=="result" and not s.active,"Victory opens result")
		check(ui.pictures.size()==1 and ui.pictures[0].name=="Memory%d"%(level+1),"Victory displays earned scene %d"%(level+1))
		check(ui.pictures[0].size.x<=394 and ui.pictures[0].size.y<=247,"Reward picture stays above its title")
		await press("ResultHome")
		check(game.screen=="home" and game.profile.current().pending.is_empty(),"Result returns home and acknowledges receipt")
		if level==0:
			await press("Collection")
			check(ui.pictures.size()==1 and ui.pictures[0].name=="Memory1","Mixed collection reveals only the earned first scene")
			await press("Home")
		if level<9:await press("Start")
	check(game.profile.current().cards.size()==10 and game.profile.current().coins==800,"Ten unique cards and first rewards")
	await press("Collection");check(game.screen=="collection","Collection reachable")
	check(ui.pictures.size()==10,"Collection displays ten earned scenes")
	var regions=[]
	for picture in ui.pictures:
		check(picture.size.x<=244 and picture.size.y<=147,"Collection picture stays inside its card")
		check(picture.material==null and not picture.use_parent_material,"Scene greens remain opaque")
		check(not regions.has(picture.texture.region),"Every memory has a distinct atlas panel");regions.append(picture.texture.region)
	await press("Home");check(ui.pictures.is_empty(),"Memory controls removed after navigation")
	await press("Growth");check(game.screen=="growth" and game.profile.stats().max_hearts==3,"Growth reachable and earned");await press("Home")
	await press("Free");check(game.profile.current().completed.is_empty(),"Free mode has independent progression")
	await press("Start");await press("Tool0");check(s.slots.size()==5 and s.coins==300,"Free tool has no coin charge")
	await press("Pause");await press("Home");await press("Challenge")
	check(game.profile.current().coins==800 and game.profile.current().cards.size()==10,"Challenge progress preserved across mode switch")
	for player in game.tones:player.stop();player.stream=null
	game.queue_free();await process_frame;await process_frame
	print("UI_VERIFY ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
