class_name WoolState
extends RefCounted

signal captured(unit: Dictionary, block: Dictionary)
signal changed
signal rejected(reason: String)
signal rescued
signal hurt
signal selected(id: int)

const Layouts = preload("res://scripts/levels.gd")
const WIDTH = 592
const HEIGHT = 1038
const SLOT_COUNT = 4
const DIRS = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const LEVELS = [0,1,2]
var level_index=0
var blocks: Array[Dictionary] = []
var units: Array[Dictionary] = []
var slots: Array[int] = [-1,-1,-1,-1]
var witness: Array[int] = []
var time = 0.0
var paused = false
var won = false
var lost = false
var won_at = -1.0
var hearts = 3
var total = 0
var collected = 0
var head = 0.0
var route_length = 1450.0
var speed = 4.8
var pitch = 44.0
var route_curve: Curve2D
var initial_collected=0
var boost_until=0.0
var initial_head_ratio=0.69
var visible_start = 120.0
var hint_id = -1
var hint_time = 0.0

func reset(length: float = 2400.0, level: int = 0) -> void:
	blocks.clear(); units.clear(); slots.assign([-1,-1,-1,-1]); witness.clear()
	time=0; paused=false; won=false; lost=false; won_at=-1; hearts=3; collected=0; total=0; hint_id=-1; boost_until=0
	route_length=length; head=route_length*initial_head_ratio
	level_index=clampi(level,0,2)
	speed=[14.0,10.0,12.0][level_index]
	var layout=Layouts.OBSERVED if level_index==0 else Layouts.dense(level_index)
	for f in layout:
		var id=blocks.size()
		blocks.append({"id":id,"cell":Vector2i(f[0],f[1]),"size":Vector2i(f[2],f[3]),"direction":f[4],"color":f[5],"capacity":f[6],"remaining":f[6],"phase":"board","slot":-1,"depart":-1.0,"arrival":-1.0,"next":0.0,"finish":-1.0})
	var removed: Array[int]=[]
	while removed.size()<blocks.size():
		var candidates: Array[int]=[]
		for b in blocks:
			if not removed.has(b.id) and blockers(b.id,removed).is_empty(): candidates.append(b.id)
		if candidates.is_empty(): push_error("Authored board contains an escape cycle"); break
		var id=candidates[0]
		removed.append(id); witness.append(id)
	initial_collected=181 if level_index==0 else 0
	collected=initial_collected; total=initial_collected
	if level_index==0:
		for seed in [[0,1,4,4],[1,4,2,4],[3,3,5,10]]:
			var id=blocks.size(); slots[seed[0]]=id
			blocks.append({"id":id,"cell":Vector2i.ZERO,"size":Vector2i(44,56),"direction":0,"color":seed[1],"capacity":seed[3],"remaining":seed[2],"phase":"working","slot":seed[0],"depart":-1.0,"arrival":-1.0,"next":0.8,"finish":-1.0})
		for group in [[2,4],[1,4],[4,4],[5,10],[3,5],[0,6],[1,6],[4,8],[3,8],[2,2]]:
			for _j in range(group[1]): units.append({"id":total,"color":group[0]}); total+=1
	else:
		for id in witness:
			var b=blocks[id]
			for _j in range(b.capacity): units.append({"id":total,"color":b.color}); total+=1
	changed.emit()

func blockers(id: int, removed: Array[int] = []) -> Array[int]:
	var found: Array[int]=[]
	var b=blocks[id]
	var a=Rect2i(b.cell,b.size-Vector2i(0,12))
	for other in blocks:
		if other.id==id or removed.has(other.id) or other.phase!="board": continue
		var r=Rect2i(other.cell,other.size-Vector2i(0,12))
		var overlap_x=a.position.x<r.end.x-2 and a.end.x>r.position.x+2
		var overlap_y=a.position.y<r.end.y-3 and a.end.y>r.position.y+3
		if (b.direction==0 and overlap_x and r.position.y<a.position.y) or (b.direction==2 and overlap_x and r.end.y>a.end.y) or (b.direction==3 and overlap_y and r.position.x<a.position.x) or (b.direction==1 and overlap_y and r.end.x>a.end.x): found.append(other.id)
	return found

func unlock_slot() -> bool:
	if slots.size()>=8 or paused or won or lost: return false
	slots.append(-1); changed.emit(); return true

func free_block() -> bool:
	if not slots.has(-1) or paused or won or lost: return false
	for b in blocks:
		if b.phase=="board" and available(b.color): return begin_travel(b.id)
	return false

func sort_yarn() -> void:
	if paused or won or lost: return
	var id=request_hint()
	if id<0: return
	var color=blocks[id].color
	units.sort_custom(func(a,b): return a.color==color and b.color!=color)
	changed.emit()

func strengthen() -> void:
	if not paused and not won and not lost: boost_until=time+12; changed.emit()

func can_select(id: int) -> bool:
	return id>=0 and id<blocks.size() and not paused and not won and not lost and blocks[id].phase=="board" and slots.has(-1) and blockers(id).is_empty()

func select(id: int) -> bool:
	if id<0 or id>=blocks.size() or paused or won or lost: return false
	if blocks[id].phase!="board": return false
	if not blockers(id).is_empty(): rejected.emit("화살표 앞을 먼저 비워 주세요"); return false
	if not slots.has(-1): rejected.emit("감기가 끝나면 자리가 비어요"); return false
	return begin_travel(id)

func begin_travel(id: int) -> bool:
	var b = blocks[id]
	b.slot=slots.find(-1); slots[b.slot]=id; b.phase="travel"; b.depart=time; b.arrival=time+0.62; b.next=b.arrival+0.16
	hint_id=-1
	selected.emit(id)
	changed.emit()
	return true

func unit_distance(index: int) -> float:
	# The first sleeve begins behind the head, where its stitches are actually visible.
	return head-65.0-index*pitch

func has_lower_yarn() -> bool:
	if route_curve==null:return true
	for i in range(units.size()):
		var d=unit_distance(i)
		if d>=0 and d<=route_length and Rect2(0,285,592,132).has_point(route_curve.sample_baked(d,true)):return true
	return false

func exposed(index: int) -> bool:
	var d = unit_distance(index)
	if d<0 or d>route_length-50.0:return false
	if route_curve!=null:
		var p=route_curve.sample_baked(d,true)
		if not Rect2(0,18,592,399).has_point(p):return false
		return p.y>=285 or not has_lower_yarn() or time<boost_until
	return d>=visible_start

func available(color: int) -> bool:
	for i in range(units.size()):
		if exposed(i) and units[i].color==color: return true
	return false

func advance(dt: float) -> void:
	if paused or lost: return
	time += dt
	if won: return
	head += dt*speed
	for b in blocks:
		if b.phase=="travel" and time>=b.arrival: b.phase="working"; changed.emit()
		if b.phase!="working" or time<b.next: continue
		var target=-1
		for i in range(units.size()):
			if units[i].color==b.color and exposed(i): target=i; break
		if target<0: continue
		var unit=units[target]
		captured.emit(unit.duplicate(),b.duplicate())
		units.remove_at(target); b.remaining-=1; collected+=1; b.next=time+0.46; head=maxf(route_length*0.32,head-8.0)
		if b.remaining==0: b.phase="clearing"; b.finish=time+0.52
		changed.emit()
	for b in blocks:
		if b.phase=="clearing" and time>=b.finish:
			b.phase="finished"; slots[b.slot]=-1; changed.emit()
	if units.is_empty() and slots.all(func(id): return id==-1):
		won=true; won_at=time; rescued.emit(); changed.emit()
	elif head>=route_length-85.0:
		hearts-=1
		if hearts<=0: lost=true
		else: head-=190.0
		hurt.emit(); changed.emit()

func request_hint() -> int:
	for id in witness:
		if can_select(id) and available(blocks[id].color):
			hint_id=id; hint_time=time; return id
	for b in blocks:
		if can_select(b.id): hint_id=b.id; hint_time=time; return b.id
	return -1
