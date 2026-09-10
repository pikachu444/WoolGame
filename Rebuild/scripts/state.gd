class_name WoolState
extends RefCounted

signal captured(unit: Dictionary,block: Dictionary)
signal changed
signal rejected(reason: String)
signal rescued
signal hurt
signal selected(id: int)
signal wallet_changed(coins: int)
signal encounter(kind: String)

const Campaign=preload("res://scripts/campaign.gd")
const WIDTH=592
const HEIGHT=1138
const DIRS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const LEVELS=[0,1,2,3,4,5,6,7,8,9]
const COSTS={"unlock":100,"remove":75,"sort":75,"boost":100,"continue":100}
var level_index=0
var definition: Dictionary={}
var mode="challenge"
var coins=300
var blocks: Array[Dictionary]=[]
var units: Array[Dictionary]=[]
var slots: Array[int]=[-1,-1,-1,-1]
var reserve: Array[int]=[]
var witness: Array[int]=[]
var dragons: Array[Dictionary]=[]
var time=0.0
var paused=false
var won=false
var lost=false
var active=false
var loss_reason=""
var won_at=-1.0
var hearts=1
var max_hearts=1
var shield_enabled=false
var freeze_enabled=false
var shield_used=false
var freeze_used=false
var shield_until=0.0
var invulnerable_until=0.0
var freeze_until=0.0
var collected=0
var initial_collected=0
var total=0
var pitch=44.0
var speed=18.0
var route_curve: Curve2D
var route_length=0.0
var cat_anchor_index=0
var cat_position=Vector2.ZERO
var cat_phase="waiting"
var flee_start=0.0
var flee_from=0.0
var flee_to=0.0
var boost_until=0.0
var visible_start=0.0
var hint_id=-1
var hint_time=0.0
var stalled_since=-1.0
var head: float:
	get:return float(dragons[0].head) if not dragons.is_empty() else 0.0
	set(value):
		if not dragons.is_empty():dragons[0].head=value

func reset(_length: float=0.0,level: int=0,options: Dictionary={}) -> void:
	level_index=clampi(level,0,9);definition=Campaign.definition(level_index)
	mode=options.get("mode","challenge");coins=int(options.get("coins",300))
	max_hearts=int(options.get("max_hearts",1));hearts=max_hearts
	shield_enabled=bool(options.get("shield",false));freeze_enabled=bool(options.get("freeze",false))
	shield_used=false;freeze_used=false;shield_until=0;freeze_until=0;invulnerable_until=0
	blocks.clear();units.clear();slots.assign([-1,-1,-1,-1]);reserve.clear();witness.clear();dragons.clear()
	time=0;won=false;lost=false;paused=false;active=true;won_at=-1;collected=0;initial_collected=0;total=0;boost_until=0;hint_id=-1;loss_reason="";stalled_since=-1
	route_curve=definition.curve;route_length=route_curve.get_baked_length();speed=definition.speed
	cat_anchor_index=0;cat_position=definition.anchors[0];cat_phase="waiting"
	for i in range(definition.dragons):
		var curve=route_curve if i==0 else Campaign.curve_for(level_index,true)
		dragons.append({"id":i,"curve":curve,"head":curve.get_baked_length()*0.34,"phase":"chasing","until":0.0})
	for item in definition.blocks:
		var b=item.duplicate(true)
		b.merge({"id":blocks.size(),"remaining":b.capacity,"phase":"board","slot":-1,"depart":-1.0,"arrival":-1.0,"next":0.0,"finish":-1.0})
		blocks.append(b)
	var removed: Array[int]=[]
	while removed.size()<blocks.size():
		var next=-1
		for b in blocks:
			if not removed.has(b.id) and blockers(b.id,removed).is_empty():next=b.id;break
		if next<0:push_error("Campaign escape cycle");break
		removed.append(next);witness.append(next)
	for order in range(witness.size()):
		var b=blocks[witness[order]]
		for j in range(b.capacity):units.append({"id":total,"color":b.color,"dragon":order%dragons.size()});total+=1
	changed.emit()

func playable() -> bool:return active and not paused and not won and not lost

func blockers(id: int,removed: Array[int]=[]) -> Array[int]:
	var found: Array[int]=[]
	if id<0 or id>=blocks.size():return found
	var b=blocks[id];var a=Rect2i(b.cell,b.size-Vector2i(0,12))
	for other in blocks:
		if other.id==id or removed.has(other.id) or other.phase!="board":continue
		var r=Rect2i(other.cell,other.size-Vector2i(0,12))
		var ox=a.position.x<r.end.x-2 and a.end.x>r.position.x+2
		var oy=a.position.y<r.end.y-3 and a.end.y>r.position.y+3
		if (b.direction==0 and ox and r.position.y<a.position.y) or (b.direction==2 and ox and r.end.y>a.end.y) or (b.direction==3 and oy and r.position.x<a.position.x) or (b.direction==1 and oy and r.end.x>a.end.x):found.append(other.id)
	return found

func can_select(id: int) -> bool:
	if not playable() or id<0 or id>=blocks.size() or not slots.has(-1):return false
	return blocks[id].phase=="reserve" or (blocks[id].phase=="board" and blockers(id).is_empty())

func select(id: int) -> bool:
	if not playable() or id<0 or id>=blocks.size():return false
	if blocks[id].phase not in ["board","reserve"]:return false
	if blocks[id].phase=="board" and not blockers(id).is_empty():rejected.emit("화살표 앞을 먼저 비워 주세요");return false
	if not slots.has(-1):rejected.emit("자리가 가득 찼어요. 감기는 실을 확인해 주세요");return false
	return begin_travel(id)

func begin_travel(id: int) -> bool:
	if not slots.has(-1):return false
	var b=blocks[id];b.slot=slots.find(-1);slots[b.slot]=id
	b.from_reserve=b.phase=="reserve";reserve.erase(id);b.phase="travel";b.depart=time;b.arrival=time+0.62;b.next=b.arrival+0.16
	hint_id=-1;stalled_since=-1;selected.emit(id);changed.emit();return true

func affordable(tool: String) -> bool:return mode=="free" or coins>=int(COSTS[tool])

func pay(tool: String) -> bool:
	if not affordable(tool):rejected.emit("코인이 부족해요. 다시 도전하거나 자유 모드에서 즐겨 보세요");return false
	if mode!="free":coins-=int(COSTS[tool]);wallet_changed.emit(coins)
	return true

func unlock_slot() -> bool:
	if not playable() or slots.size()>=8:return false
	if not pay("unlock"):return false
	slots.append(-1);stalled_since=-1;changed.emit();return true

func free_block() -> bool:
	if not playable():return false
	var candidate=-1
	for b in blocks:
		if b.phase=="board":candidate=b.id;break
	if candidate<0:return false
	if not pay("remove"):return false
	var b=blocks[candidate];b.phase="reserve";b.slot=-1;reserve.append(candidate)
	rejected.emit("블록을 보조 선반으로 옮겼어요");changed.emit();return true

func sort_yarn() -> bool:
	if not playable() or units.is_empty():return false
	if not pay("sort"):return false
	var color=-1
	for id in slots:
		if id>=0 and blocks[id].phase=="working":color=blocks[id].color;break
	if color<0:
		for b in blocks:
			if can_select(b.id):color=b.color;break
	if color<0:color=units[0].color
	var first: Array[Dictionary]=[];var rest: Array[Dictionary]=[]
	for u in units:
		if u.color==color:first.append(u)
		else:rest.append(u)
	units=first+rest;changed.emit();return true

func strengthen() -> bool:
	if not playable() or units.is_empty():return false
	if not pay("boost"):return false
	boost_until=time+12.0;changed.emit();return true

func continue_run() -> bool:
	if not active or not lost:return false
	if not pay("continue"):return false
	for id in slots:
		if id<0:continue
		var b=blocks[id]
		if b.remaining>0:b.phase="reserve";reserve.append(id)
		else:b.phase="finished"
		b.slot=-1
	for i in range(slots.size()):slots[i]=-1
	hearts=max_hearts;lost=false;loss_reason="";invulnerable_until=time+3.0;stalled_since=-1
	for d in dragons:
		d.head=maxf(0.0,float(d.curve.get_closest_offset(cat_position))-maxf(720.0,speed*45.0));d.phase="chasing";d.until=time
	cat_phase="waiting";changed.emit();return true

func unit_distance(index: int) -> float:
	var unit=units[index];var offset=0
	for i in range(index):
		if units[i].dragon==unit.dragon:offset+=1
	return float(dragons[unit.dragon].head)-65.0-offset*pitch

func unit_point(index: int) -> Vector2:
	var u=units[index];var curve: Curve2D=dragons[u.dragon].curve
	return curve.sample_baked(clampf(unit_distance(index),0,curve.get_baked_length()),true)

func exposed(index: int) -> bool:
	if time<boost_until:return true
	var distance=unit_distance(index);var curve: Curve2D=dragons[units[index].dragon].curve
	if distance<0 or distance>curve.get_baked_length():return false
	var p=unit_point(index)
	if not Rect2(0,20,592,397).has_point(p):return false
	return not definition.fog or p.y>=210

func has_lower_yarn() -> bool:return bool(definition.get("fog",false))

func available(color: int) -> bool:
	for i in range(units.size()):
		if units[i].color==color and exposed(i):return true
	return false

func target_unit(color: int) -> int:
	var candidate=-1;var closest=INF
	for i in range(units.size()):
		if units[i].color!=color or not exposed(i):continue
		var d=dragons[units[i].dragon];var gap=d.curve.get_closest_offset(cat_position)-d.head
		if gap<closest:closest=gap;candidate=i
	return candidate

func flee() -> void:
	flee_start=time;flee_from=route_curve.get_closest_offset(cat_position)
	cat_anchor_index+=1;flee_to=route_curve.get_closest_offset(definition.anchors[cat_anchor_index]);cat_phase="fleeing"
	encounter.emit("flee");changed.emit()

func attack() -> void:
	if time<invulnerable_until or time<shield_until:return
	if shield_enabled and not shield_used:
		shield_used=true;shield_until=time+5.0;cat_phase="shield";encounter.emit("shield");return
	hearts=maxi(0,hearts-1);invulnerable_until=time+1.0;cat_phase="hurt";hurt.emit();changed.emit()
	if hearts==0:lost=true;loss_reason="용의 불꽃이 고양이에게 닿았어요"

func advance(dt: float) -> void:
	if not active or paused or lost:return
	var remaining=maxf(0,dt)
	while remaining>0.000001:
		var step=minf(remaining,1.0/30.0);remaining-=step;tick(step)
		if lost:break

func tick(dt: float) -> void:
	time+=dt
	if won:return
	if cat_phase=="fleeing":
		var t=clampf((time-flee_start)/0.7,0,1)
		cat_position=route_curve.sample_baked(lerpf(flee_from,flee_to,smoothstep(0,1,t)),true)
		if t>=1:cat_phase="waiting"
	if shield_until>0 and time>=shield_until:
		shield_until=0;cat_phase="waiting"
		for d in dragons:d.head=maxf(0,float(d.head)-pitch*2.0);d.phase="chasing";d.until=time+0.6
		encounter.emit("repel")
	if cat_phase=="hurt" and time>=invulnerable_until:cat_phase="waiting"
	for d in dragons:
		if not units.any(func(u):return u.dragon==d.id):d.phase="cleared";continue
		if time<freeze_until:continue
		var target=float(d.curve.get_closest_offset(cat_position))
		if d.phase=="windup":
			if time>=d.until:d.phase="fire";d.until=time+0.5;attack()
		elif d.phase=="fire":
			if time>=d.until:d.phase="chasing";d.until=time+0.8
		else:
			d.head=minf(float(d.head)+speed*dt,target-90.0)
			if target-d.head<=100.0 and cat_phase!="fleeing" and time>=d.until:
				if freeze_enabled and not freeze_used:freeze_used=true;freeze_until=time+3.0;encounter.emit("freeze")
				if cat_anchor_index<definition.anchors.size()-1:flee()
				else:d.phase="windup";d.until=time+0.5;encounter.emit("warning")
	if lost:return
	for b in blocks:
		if b.phase=="travel" and time>=b.arrival:b.phase="working";changed.emit()
		if b.phase!="working" or time<b.next:continue
		var index=target_unit(b.color)
		if index<0:continue
		var unit=units[index]
		captured.emit(unit.duplicate(),b.duplicate());units.remove_at(index)
		b.remaining-=1;collected+=1;b.next=time+0.46
		var dragon=dragons[unit.dragon];dragon.head=maxf(route_length*0.25,float(dragon.head)-4.0)
		if b.remaining==0:b.phase="clearing";b.finish=time+0.52
		changed.emit()
	for b in blocks:
		if b.phase=="clearing" and time>=b.finish:b.phase="finished";slots[b.slot]=-1;b.slot=-1;changed.emit()
	if units.is_empty() and slots.all(func(id):return id==-1):
		won=true;won_at=time;cat_phase="rescued";rescued.emit();changed.emit();return
	var waiting=not slots.has(-1) and slots.all(func(id):return blocks[id].phase=="working" and not available(blocks[id].color))
	if waiting:
		if stalled_since<0:stalled_since=time
		if time-stalled_since>8.0:lost=true;loss_reason="선반이 가득 차서 실을 더 감을 수 없어요";changed.emit()
	else:stalled_since=-1

func request_hint() -> int:
	for b in blocks:
		if can_select(b.id) and available(b.color):hint_id=b.id;hint_time=time;return b.id
	for b in blocks:
		if can_select(b.id):hint_id=b.id;hint_time=time;return b.id
	return -1

func snapshot() -> Dictionary:
	var enemies=[]
	for d in dragons:enemies.append({"id":d.id,"head":d.head,"phase":d.phase,"until":d.until})
	return {"level":level_index,"mode":mode,"coins":coins,"time":time,"hearts":hearts,"max_hearts":max_hearts,"cat_phase":cat_phase,"cat_anchor":cat_anchor_index,"cat_position":[cat_position.x,cat_position.y],"shield_until":shield_until,"freeze_until":freeze_until,"invulnerable_until":invulnerable_until,"dragons":enemies,"slots":slots.duplicate(),"reserve":reserve.duplicate(),"blocks":blocks.duplicate(true),"units":units.duplicate(true),"won":won,"lost":lost,"collected":collected,"total":total}
