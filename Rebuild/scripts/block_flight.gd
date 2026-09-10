extends RefCounted
const Layout=preload("res://scripts/layout.gd")
const DIRS=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
const EDGE=8.0
const LANE=28.0
const CARRY_SCALE=0.86
const TURN_TIME=0.12

# Reference: the arrow turns with the block, then follows the perimeter to the dock.
# Keeping the contact and carried block visible is an intentional readability adjustment.
static func step(p: Dictionary,to: Vector2,duration: float,angle: float,scale: float,kind: String="line",control: Vector2=Vector2.ZERO) -> void:
 p.segments.append({"a":p.position,"b":to,"start":p.duration,"duration":duration,"angle_a":p.angle,"angle_b":angle,"scale_a":p.scale,"scale_b":scale,"kind":kind,"control":control})
 p.position=to;p.angle=angle;p.scale=scale;p.duration+=duration

static func contact(p: Dictionary,point: Vector2,normal: Vector2) -> void:
 p.impacts.append({"time":p.duration,"point":point,"normal":normal})

static func angle_for(p: Dictionary,direction: Vector2) -> float:
 return direction.angle()-float(p.base_angle)

static func turn(p: Dictionary,direction: Vector2) -> void:
 step(p,p.position,TURN_TIME,angle_for(p,direction),CARRY_SCALE,"turn")

static func build(b: Dictionary,slot: int) -> Dictionary:
 var size=Vector2(b.size);var a=Vector2(b.cell)+size/2.0
 var v: Vector2=DIRS[b.direction];var target=Layout.slot_center(slot)
 var p={"segments":[],"impacts":[],"duration":0.0,"position":a,"angle":0.0,"scale":1.0,"base_angle":v.angle(),"size":size}
 if b.get("from_reserve",false):
  p.position=Vector2(296,574);p.scale=CARRY_SCALE
  step(p,target,0.42,0.0,CARRY_SCALE,"curve",Vector2(target.x,574))
  return p
 var top=Layout.DOCK_BOTTOM+EDGE+size.y/2.0
 if b.direction==0:
  var edge=Vector2(a.x,top)
  step(p,edge,clampf(a.distance_to(edge)/1700.0,0.13,0.30),0.0,1.0)
  contact(p,Vector2(a.x,Layout.DOCK_BOTTOM+EDGE),Vector2.UP)
 else:
  # Both left and right bottom exits are observed; nearest side is the personal tie rule.
  var left=b.direction==3 or (b.direction==2 and a.x<Layout.SIZE.x/2.0)
  var side=Vector2.LEFT if left else Vector2.RIGHT
  var side_x=LANE if left else Layout.SIZE.x-LANE
  if b.direction==2:
   var edge=Vector2(a.x,Layout.BOARD_BOTTOM-EDGE-size.y/2.0)
   step(p,edge,clampf(a.distance_to(edge)/1700.0,0.13,0.32),0.0,1.0)
   contact(p,Vector2(a.x,Layout.BOARD_BOTTOM-EDGE),Vector2.DOWN)
   turn(p,side)
   var wall=Vector2(EDGE+size.y*CARRY_SCALE/2.0 if left else Layout.SIZE.x-EDGE-size.y*CARRY_SCALE/2.0,edge.y)
   step(p,wall,maxf(0.10,p.position.distance_to(wall)/1800.0),p.angle,CARRY_SCALE)
   contact(p,Vector2(EDGE if left else Layout.SIZE.x-EDGE,wall.y),side)
  else:
   var wall=Vector2(EDGE+size.x/2.0 if left else Layout.SIZE.x-EDGE-size.x/2.0,a.y)
   step(p,wall,clampf(a.distance_to(wall)/1700.0,0.13,0.30),0.0,1.0)
   contact(p,Vector2(EDGE if left else Layout.SIZE.x-EDGE,a.y),side)
  turn(p,Vector2.UP)
  var upper=Vector2(side_x,top)
  step(p,upper,maxf(0.15,p.position.distance_to(upper)/1900.0),p.angle,CARRY_SCALE)
 # Original motion crosses below the dock, turns up at the slot x, then enters it.
 if absf(target.x-p.position.x)>8.0:
  turn(p,Vector2.RIGHT if target.x>p.position.x else Vector2.LEFT)
  var entrance=Vector2(target.x,p.position.y)
  step(p,entrance,maxf(0.10,p.position.distance_to(entrance)/1800.0),p.angle,CARRY_SCALE)
  turn(p,Vector2.UP)
 step(p,target,maxf(0.10,p.position.distance_to(target)/1600.0),angle_for(p,Vector2.UP),CARRY_SCALE)
 return p

static func sample(p: Dictionary,elapsed: float) -> Dictionary:
 if p.is_empty():return {"position":Vector2.ZERO,"angle":0.0,"scale":Vector2.ONE}
 var part: Dictionary=p.segments.back()
 for segment in p.segments:
  if elapsed<=segment.start+segment.duration:part=segment;break
 var t=clampf((elapsed-part.start)/part.duration,0.0,1.0)
 var eased=smoothstep(0.0,1.0,t) if part.kind=="turn" else t
 var pos: Vector2=part.a.lerp(part.b,eased)
 var angle=lerp_angle(part.angle_a,part.angle_b,eased)
 if part.kind=="curve":
  pos=part.a.lerp(part.control,t).lerp(part.control.lerp(part.b,t),t)
  var tangent=2.0*((1.0-t)*(part.control-part.a)+t*(part.b-part.control))
  if tangent.length_squared()>0.01:angle=tangent.angle()-float(p.base_angle)
 var scale=lerpf(part.scale_a,part.scale_b,eased)
 var shape=Vector2(scale,scale)
 for hit in p.impacts:
  var age=elapsed-hit.time
  if age>=0.0 and age<TURN_TIME:
   var pulse=sin(PI*age/TURN_TIME)
   var local_normal=Vector2(hit.normal).rotated(-angle).abs()
   shape*=Vector2.ONE-0.10*pulse*local_normal+0.045*pulse*Vector2(local_normal.y,local_normal.x)
 # During a turn the diagonal footprint grows; retain a visible rim and shadow.
 var extent=Vector2(absf(cos(angle))*p.size.x*shape.x+absf(sin(angle))*p.size.y*shape.y,absf(sin(angle))*p.size.x*shape.x+absf(cos(angle))*p.size.y*shape.y)/2.0
 pos.x=clampf(pos.x,extent.x+3.0,Layout.SIZE.x-extent.x-3.0)
 pos.y=minf(pos.y,Layout.BOARD_BOTTOM-extent.y-3.0)
 return {"position":pos,"angle":angle,"scale":shape}
