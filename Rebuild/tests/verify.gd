extends SceneTree
const State=preload("res://scripts/state.gd")
var failures: Array[String]=[]
var checks=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures.append(label);printerr("FAIL ",label)
func _initialize() -> void:
	var geometry=load("res://scenes/game.tscn").instantiate()
	var curve=geometry.get_node("World/DragonRoute").curve
	var length=curve.get_baked_length()
	geometry.free()
	var state=State.new()
	state.route_curve=curve
	for level in range(3):
		state.reset(length,level)
		var count=state.blocks.filter(func(b):return b.phase=="board").size()
		check(state.witness.size()==count,"All visible blocks have an escape order")
		var remaining=0
		for b in state.blocks:
			remaining+=b.remaining
			if b.phase!="board":continue
			check(b.cell.x>=0 and b.cell.x+b.size.x<=592 and b.cell.y>=553 and b.cell.y+b.size.y<=1038,"Visible block fits the reference puzzle field")
			for other in state.blocks:
				if other.id<=b.id or other.phase!="board":continue
				check(not Rect2i(b.cell,b.size-Vector2i(0,12)).intersects(Rect2i(other.cell,other.size-Vector2i(0,12))),"Raised tile faces do not overlap")
		check(remaining==state.units.size() and remaining==state.total-state.collected,"All remaining spool capacities equal the remaining yarn")
		var captures={"count":0,"bad":false}
		var validate=func(unit,b):
			captures.count+=1
			var index=-1
			for i in range(state.units.size()):
				if state.units[i].id==unit.id:index=i;break
			if index<0 or unit.color!=b.color or not state.exposed(index):captures.bad=true
			for i in range(index):
				if state.exposed(i) and state.units[i].color==unit.color:captures.bad=true
		state.captured.connect(validate)
		var next=1.0
		for _frame in range(60*240):
			state.advance(1.0/60)
			if state.time>=next:
				var id=state.request_hint()
				if id>=0:state.select(id)
				next=state.time+0.9
			if state.won or state.lost:break
		check(state.won,"Puzzle is completable through normal directional moves")
		check(not captures.bad,"Collection always consumes first exposed matching yarn")
		check(captures.count==remaining and state.collected==state.total,"Every remaining yarn is captured exactly once")
		check(state.units.is_empty() and state.slots.all(func(id):return id==-1),"Win waits for winding and slot release")
		state.captured.disconnect(validate)
		print("LEVEL_RESULT level=",level," elapsed=",state.time," hearts=",state.hearts," captured=",captures.count," total=",state.total)
	state.reset(length,1)
	var blocked=-1
	for b in state.blocks:
		if not state.blockers(b.id).is_empty():blocked=b.id;break
	check(blocked>=0 and not state.select(blocked),"Blocked moves are rejected")
	check(state.slots.count(-1)==4,"Rejected move does not reserve a slot")
	for i in range(4):check(state.select(state.witness[i]),"Departure reserves slot immediately")
	check(state.slots.count(-1)==0 and not state.select(state.witness[4]),"Full workbench cannot be overbooked")
	var time=state.time;var head=state.head
	state.paused=true;state.advance(10)
	check(state.time==time and state.head==head,"Pause freezes the simulation")
	state.paused=false;state.advance(0.61)
	check(state.collected==0,"Travelling blocks cannot collect before arrival")
	state.reset(length,1)
	for _i in range(4):check(state.unlock_slot(),"A locked lower position can be opened")
	check(state.slots.size()==8 and not state.unlock_slot(),"Extra slots are bounded by visible workbench positions")
	var total=state.units.size()
	state.sort_yarn();state.strengthen()
	check(state.units.size()==total and state.boost_until>state.time,"Sort and boost preserve yarn and activate the timed range")
	check(state.free_block(),"Removal tool sends an available block through normal winding")
	state.reset(length);state.hearts=1;state.head=length-85.01;state.advance(0.1)
	check(state.lost and state.hearts==0,"Last hit reaches retry state")
	state.reset(length)
	check(not state.lost and state.collected==181 and state.slots.count(-1)==1,"Reference puzzle restores its observed late-level state")
	state.reset(length)
	state.advance(0.81)
	check(state.blocks[9].remaining==4 and state.blocks[10].remaining==2,"Initial fogged yellow and purple wait while the lower band is active")
	check(state.blocks[11].remaining==4,"Initial blue spool collects the lower visible band first")
	state.units=state.units.filter(func(u):return u.color==2)
	check(not state.has_lower_yarn() and state.available(2),"Upper knit becomes collectible after the lower band is gone")
	print("VERIFY ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
