extends Node2D
const WoolArt = preload("res://scripts/art.gd")
const WoolState = preload("res://scripts/state.gd")
const Layout = preload("res://scripts/layout.gd")
const BlockFlight = preload("res://scripts/block_flight.gd")
signal edge_tapped
const ORIGIN = Layout.BOARD_ORIGIN
var state: WoolState
var press_id=-1
var press_pos=Vector2.ZERO
var press_time=0.0
var cancelled=false
var bounce={}
var clock=0.0
var ripples: Array[Dictionary]=[]
var hit_marks={}

func reset_visuals() -> void:
 press_id=-1;cancelled=false;bounce.clear();ripples.clear();hit_marks.clear()

func on_selected(id: int) -> void:
 ripples.append({"p":Vector2(296,574) if state.blocks[id].get("from_reserve",false) else rect_for(state.blocks[id]).get_center(),"time":clock})

func _ready() -> void:
 material=WoolArt.material()
 # A moving block must stay visible while it crosses the dock controls into its slot.
 z_index=0
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
 z_index=5 if state!=null and not state.paused and not state.lost else 0
 ripples=ripples.filter(func(r): return clock-r.time<0.28)
 if state!=null and state.playable() and visible:
  for b in state.blocks:
   if b.phase!="travel" or not b.has("flight"):continue
   for i in range(b.flight.impacts.size()):
    var age: float=state.time-b.depart-b.flight.impacts[i].time
    var key="%d:%.5f:%d"%[b.id,b.depart,i]
    if age>=0.0 and age<0.24 and not hit_marks.has(key):hit_marks[key]=true;edge_tapped.emit()
 queue_redraw()

func travel_pose(b: Dictionary) -> Dictionary:
 return BlockFlight.sample(b.flight,state.time-b.depart)

func travel_position(b: Dictionary) -> Vector2:
 return travel_pose(b).position

func draw_contacts() -> void:
 for b in state.blocks:
  if b.phase not in ["travel","working"] or not b.has("flight"):continue
  for hit in b.flight.impacts:
   var age: float=state.time-b.depart-hit.time
   if age<0.0 or age>=0.24:continue
   var fade=1.0-age/0.24
   var point: Vector2=hit.point;var normal: Vector2=hit.normal
   var side=normal.orthogonal()
   draw_line(point-side*22,point+side*22,Color(0.24,0.45,0.58,fade*0.75),7.0,true)
   draw_line(point-side*18,point+side*18,Color(1.0,0.97,0.73,fade),3.0,true)
   for ray in [-0.65,0.0,0.65]:
    var direction=(-normal).rotated(ray)
    var start=point+direction*(6.0+age*25.0)
    var end=start+direction*(9.0+age*20.0)
    draw_line(start,end,Color(0.30,0.52,0.62,fade*0.65),4.0,true)
    draw_line(start,end,Color(1,1,0.94,fade),2.0,true)

func _draw() -> void:
 if state==null: return
 draw_contacts()
 for b in state.blocks:
  if b.phase!="board" and b.phase!="travel": continue
  var size=Vector2(b.size)
  var center=rect_for(b).get_center()
  var scale=Vector2.ONE
  var angle=0.0
  if b.phase=="travel":
   var pose=travel_pose(b);center=pose.position;scale=pose.scale;angle=pose.angle
  elif press_id==b.id:scale=Vector2.ONE*0.96
  elif bounce.has(b.id):scale=Vector2.ONE*(1.0+0.045*sin(clampf((clock-bounce[b.id])/0.18,0,1)*PI))
  draw_set_transform(center,angle,scale)
  var r=Rect2(-size/2.0,size)
  WoolArt.patch(self,Rect2(r.position+Vector2(1,2),r.size),Color(0.16,0.30,0.39,0.28))
  WoolArt.patch(self,r,WoolArt.COLORS[b.color].darkened(0.27))
  var face=Rect2(r.position,r.size-Vector2(0,12))
  WoolArt.patch(self,face,WoolArt.COLORS[b.color])
  WoolArt.arrow(self,face.get_center(),Vector2(WoolState.DIRS[b.direction]),minf(58,face.size[0 if b.direction%2==1 else 1]*0.67))
  if b.phase=="board" and state.hint_id==b.id and state.time-state.hint_time<5:
   WoolArt.box(self,r.grow(3),Color.TRANSPARENT,12,Color(1,1,1,0.65+0.3*sin(clock*5)),3)
  draw_set_transform(Vector2.ZERO)
 for ripple in ripples:
  var t=(clock-ripple.time)/0.28
  draw_arc(ripple.p,12+20*t,0,TAU,32,Color(1,1,1,(1-t)*0.8),2.0,true)
