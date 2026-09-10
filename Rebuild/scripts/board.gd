extends Node2D
const WoolArt = preload("res://scripts/art.gd")
const WoolState = preload("res://scripts/state.gd")
const Layout = preload("res://scripts/layout.gd")

const ORIGIN = Layout.BOARD_ORIGIN
var state: WoolState
var press_id=-1
var press_pos=Vector2.ZERO
var press_time=0.0
var cancelled=false
var bounce={}
var clock=0.0
var ripples: Array[Dictionary]=[]

func on_selected(id: int) -> void:
	ripples.append({"p":Vector2(296,574) if state.blocks[id].get("from_reserve",false) else rect_for(state.blocks[id]).get_center(),"time":clock})

func _ready() -> void:
	material=WoolArt.material()
	set_process_input(true)

func rect_for(b: Dictionary) -> Rect2:
	return Rect2(Vector2(b.cell),Vector2(b.size))

func _input(event: InputEvent) -> void:
	if state==null or not state.active or state.paused or state.won or state.lost: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		var p=get_global_mouse_position()
		if event.pressed:
			press_id=-1; press_pos=p; press_time=Time.get_ticks_msec()*0.001; cancelled=false
			for b in state.blocks:
				if b.phase=="board" and rect_for(b).has_point(p): press_id=b.id; bounce[b.id]=clock; break
		elif press_id>=0:
			var id=press_id; press_id=-1
			if not cancelled and p.distance_to(press_pos)<=12 and Time.get_ticks_msec()*0.001-press_time<0.4: state.select(id)
	elif event is InputEventMouseMotion and press_id>=0:
		if get_global_mouse_position().distance_to(press_pos)>12: cancelled=true

func _process(dt: float) -> void:
	clock+=dt
	ripples= ripples.filter(func(r): return clock-r.time<0.28)
	queue_redraw()

func travel_position(b: Dictionary) -> Vector2:
	var r=rect_for(b)
	var a=r.get_center()
	var v=Vector2(WoolState.DIRS[b.direction])
	var t=clampf((state.time-b.depart)/0.62,0,1)
	if b.get("from_reserve",false):return Vector2(296,574).lerp(Layout.slot_center(b.slot),smoothstep(0,1,t))
	var exit=a
	if v.x<0: exit.x=2-r.size.x/2
	elif v.x>0: exit.x=590+r.size.x/2
	elif v.y<0: exit.y=Layout.DOCK_BOTTOM+35-r.size.y/2
	else: exit.y=Layout.BOARD_BOTTOM+30+r.size.y/2
	if t<0.38: return a.lerp(exit,t/0.38)
	var p=(t-0.38)/0.62
	var side=6.0 if b.direction==3 else 586.0
	var corner=Vector2(side,exit.y)
	var upper=Vector2(side,Layout.DOCK_BOTTOM-20)
	var target=Layout.slot_center(b.slot)
	var points=[exit,corner,upper,target]
	var lengths=[exit.distance_to(corner),corner.distance_to(upper),upper.distance_to(target)]
	var d=p*float(lengths[0]+lengths[1]+lengths[2])
	for i in range(3):
		if d<=lengths[i]: return points[i].lerp(points[i+1],d/maxf(0.01,lengths[i]))
		d-=lengths[i]
	return target

func _draw() -> void:
	if state==null: return
	for b in state.blocks:
		if b.phase!="board" and b.phase!="travel": continue
		var r=rect_for(b)
		var center=r.get_center()
		var scale=1.0
		if b.phase=="travel":
			center=travel_position(b)
			scale=lerpf(1,0.27,smoothstep(0.18,0.68,(state.time-b.depart)/0.62))
		elif press_id==b.id: scale=0.96
		elif bounce.has(b.id): scale=1.0+0.045*sin(clampf((clock-bounce[b.id])/0.18,0,1)*PI)
		r=Rect2(center-r.size*scale/2,r.size*scale)
		WoolArt.patch(self,Rect2(r.position+Vector2(1,2),r.size),Color(0.16,0.30,0.39,0.28))
		WoolArt.patch(self,r,WoolArt.COLORS[b.color].darkened(0.27))
		var face=Rect2(r.position,r.size-Vector2(0,12*scale))
		WoolArt.patch(self,face,WoolArt.COLORS[b.color])
		WoolArt.arrow(self,face.get_center(),Vector2(WoolState.DIRS[b.direction]),minf(58,face.size[0 if b.direction%2==1 else 1]*0.67)*scale)
		if b.phase=="board" and state.hint_id==b.id and state.time-state.hint_time<5:
			WoolArt.box(self,r.grow(3),Color.TRANSPARENT,12,Color(1,1,1,0.65+0.3*sin(clock*5)),3)
	for ripple in ripples:
		var t=(clock-ripple.time)/0.28
		draw_arc(ripple.p,12+20*t,0,TAU,32,Color(1,1,1,(1-t)*0.8),2.0,true)
