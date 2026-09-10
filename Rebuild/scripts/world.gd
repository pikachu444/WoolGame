extends Node2D
const WoolArt = preload("res://scripts/art.gd")
const WoolState = preload("res://scripts/state.gd")
const HEAD_IMAGE = preload("res://art/reference_details.res")
const Layout = preload("res://scripts/layout.gd")
const MapTheme = preload("res://scripts/map_theme.gd")
const CUFF_SIZE = Vector2(65,80)

var state: WoolState
@onready var route: Curve2D = $DragonRoute.curve
var positions: Dictionary = {}
var flights: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var clock = 0.0
var rescue_time = -1.0
var mist_visibility=1.0
var scenery_positions: Array[Vector2]=[]

func _ready() -> void:
	position=Layout.WORLD_ORIGIN
	material = WoolArt.material()
	for i in range(8):
		var bobbin=Node2D.new();bobbin.set_script(preload("res://scripts/spool.gd"));bobbin.index=i;bobbin.show_behind_parent=true;add_child(bobbin)

func point_at(distance: float) -> Vector2:
	return route.sample_baked(clampf(distance, 0, route.get_baked_length()), true)

func tangent_at(distance: float) -> float:
	return (point_at(distance+4)-point_at(distance-4)).angle()

func slot_center(index: int) -> Vector2:
	return Layout.slot_center(index)-position

func capture(unit: Dictionary, block: Dictionary) -> void:
	var index = 0
	for i in range(state.units.size()):
		if state.units[i].id == unit.id: index=i; break
	var distance = float(positions.get(unit.id,state.unit_distance(index)))
	flights.append({"start":state.time,"distance":distance,"color":block.color,"slot":block.slot,"dragon":unit.dragon,"angle":tangent_for(state.dragons[unit.dragon].curve,distance)-PI/2})
	positions.erase(unit.id)

func reset_visuals() -> void:
	positions.clear(); flights.clear(); sparks.clear(); rescue_time=-1
	mist_visibility=1.0 if state!=null and state.has_lower_yarn() and not state.won and state.time>=state.boost_until else 0.0
	scenery_positions=choose_scenery_positions()

func celebrate() -> void:
	rescue_time=state.time
	for i in range(55):
		sparks.append({"p":state.cat_position,"v":Vector2(sin(i*2.4)*250,-180-absf(cos(i*1.7))*240),"color":i%6,"t":0.0,"r":float(i%5+3)})

func _process(dt: float) -> void:
	if state==null: return
	if state.active and not state.paused:
		clock+=dt
		mist_visibility=move_toward(mist_visibility,1.0 if state.has_lower_yarn() and not state.won and state.time>=state.boost_until else 0.0,dt*3)
		for i in range(state.units.size()):
			var u=state.units[i]
			var target=state.unit_distance(i)
			positions[u.id]=lerpf(float(positions.get(u.id,target)),target,1-exp(-dt*13))
		flights=flights.filter(func(f): return state.time-f.start<0.48)
		for p in sparks:
			p.t+=dt; p.v.y+=360*dt; p.p+=p.v*dt
		sparks=sparks.filter(func(p): return p.t<2.6)
	queue_redraw()

func ellipse(center: Vector2, radii: Vector2, color: Color, segments: int = 48) -> void:
	var points=PackedVector2Array()
	for i in range(segments): points.append(center+Vector2(cos(TAU*i/segments),sin(TAU*i/segments))*radii)
	draw_colored_polygon(points,color)

func spool(index: int) -> void:
	if index>=state.slots.size() or state.slots[index]<0:return
	var b=state.blocks[state.slots[index]]
	if b.phase!="travel":WoolArt.outlined_text(self,str(b.remaining),slot_center(index)+Vector2(0,39),21)

func slot_completion(index: int) -> void:
	if index>=state.slots.size() or state.slots[index]<0:return
	var b=state.blocks[state.slots[index]]
	if b.phase!="clearing":return
	var t=clampf(1-(b.finish-state.time)/0.52,0,1)
	var center=slot_center(index)
	for i in range(9):
		var angle=i*TAU/9+t*0.8
		var p=center+Vector2(cos(angle)*(20+t*21),sin(angle)*(9+t*18))
		for layer in range(4,0,-1):draw_circle(p,(5+layer*1.4)*(1-t*0.35),Color(1,1,0.92,(1-t)*0.13))
	for i in range(5):
		var p=center+Vector2(sin(i*2.4)*45,cos(i*3.1)*22-t*16)
		draw_line(p-Vector2(3,0),p+Vector2(3,0),Color(1,0.96,0.45,(1-t)*0.9),2,true)
		draw_line(p-Vector2(0,3),p+Vector2(0,3),Color(1,0.96,0.45,(1-t)*0.9),2,true)

func breath_flame() -> void:
	if state.won or flights.is_empty():return
	var heat=clampf(sin(state.time*2.3-0.8)*1.5,0,1)
	if heat<=0:return
	for i in range(12,0,-1):
		var q=i/12.0
		var p=Vector2(-27,24)+Vector2(-1,0.3)*q*47*heat+Vector2(0,sin(clock*19+i)*4*q)
		var radius=(5+8*sin(q*PI))*(1-q*0.35)*heat
		for layer in range(3,0,-1):draw_circle(p,radius+layer*2,Color(1,0.5,0.08,0.10*heat))
		draw_circle(p,radius,Color(1,0.65+0.28*(1-q),0.12,0.70*heat))
		draw_circle(p-Vector2(1,1),radius*0.56,Color(1,0.98,0.49,0.86*heat))

func winding_point(index: int) -> Vector2:
	var b=state.blocks[state.slots[index]]
	var span=65.0 if b.capacity<=4 else 83.0 if b.capacity<=6 else 129.0
	var fill=clampf(1-float(b.remaining)/b.capacity,0,1)
	return slot_center(index)+Vector2(-(span-10)*0.5+14+(span-21)*fill,-13)

func draw_route() -> void:
	var line=route.get_baked_points()
	var palette=MapTheme.for_level(state.level_index)
	draw_polyline(line,Color(palette.rim),54,true)
	draw_polyline(line,Color(palette.road),48,true)
	draw_circle(line[-1],24,Color(palette.road),true,-1,true)
	for distance in range(0,int(route.get_baked_length())-8,16):
		for side in [-1,1]:
			var a=point_at(distance)+Vector2.UP.rotated(tangent_at(distance))*21*side
			var b=point_at(distance+7)+Vector2.UP.rotated(tangent_at(distance+7))*21*side
			draw_line(a,b,Color(palette.seam),1.1,true)

func snow_decor() -> void:
	# Small scenery stays below the moving figures, as in the observed winter stage.
	for center in [Vector2(41,296),Vector2(210,77),Vector2(550,309)]:
		for i in range(6):
			var a=Vector2.RIGHT.rotated(i*TAU/6)
			draw_line(center-a*9,center+a*9,Color("e6f0f5"),2,true)
	draw_texture_rect_region(WoolArt.CAST,Rect2(346,122,41,50),Rect2(739,695,402,486))
	draw_texture_rect_region(WoolArt.DETAILS,Rect2(498,227,51,60),Rect2(74,651,509,571))

func choose_scenery_positions() -> Array[Vector2]:
	var result: Array[Vector2]=[]
	for preferred in [Vector2(105,190),Vector2(460,210),Vector2(285,321)]:
		var best=Vector2.ZERO;var score=-INF
		for y in range(120,353,42):
			for x in range(45,551,55):
				var p=Vector2(x,y);var clearance=INF
				for enemy in state.dragons:
					var curve: Curve2D=enemy.curve
					clearance=minf(clearance,p.distance_to(curve.sample_baked(curve.get_closest_offset(p),true)))
				if clearance<37 or p.distance_to(state.cat_position)<72:continue
				if result.any(func(other):return other.distance_to(p)<85):continue
				var value=minf(clearance,65)*2.0-p.distance_to(preferred)*0.3
				if value>score:score=value;best=p
		if score> -INF:result.append(best)
	return result

func felt_disk(center: Vector2,radius: float,color: Color) -> void:
	draw_circle(center+Vector2(0,2),radius,Color(0.18,0.29,0.22,0.13))
	draw_circle(center,radius,color)
	draw_arc(center,radius-2,0.2,2.8,18,color.lightened(0.18),1.0,true)

func flower(center: Vector2,color: Color) -> void:
	for i in range(5):felt_disk(center+Vector2.UP.rotated(i*TAU/5)*9,8,color)
	felt_disk(center,5,Color("ffdf73"))

func ribbon(center: Vector2,color: Color) -> void:
	for sign in [-1,1]:
		draw_set_transform(center,sign*0.30)
		ellipse(Vector2(sign*10,0),Vector2(13,10),color)
		draw_arc(Vector2(sign*10,0),7,0,TAU,24,color.lightened(0.16),1.0,true)
		draw_colored_polygon(PackedVector2Array([Vector2(sign*4,4),Vector2(sign*17,20),Vector2(sign*9,18),Vector2(sign*6,24)]),color.darkened(0.05))
		draw_set_transform(Vector2.ZERO)
	felt_disk(center,6,color.lightened(0.10))

func gingerbread(center: Vector2) -> void:
	var dough=Color("d7a569");var icing=Color("fff0ce")
	for offset in [Vector2(-9,10),Vector2(9,10),Vector2(-8,26),Vector2(8,26)]:
		draw_line(center+Vector2(0,12),center+offset,dough,11,true)
	WoolArt.box(self,Rect2(center+Vector2(-9,4),Vector2(18,23)),dough,7)
	felt_disk(center-Vector2(0,4),11,dough)
	draw_circle(center+Vector2(-4,-6),1.5,Color("77442c"));draw_circle(center+Vector2(4,-6),1.5,Color("77442c"))
	draw_arc(center+Vector2(0,-4),4,0.15,PI-0.15,12,icing,1.5,true)
	for y in [10,17]:draw_circle(center+Vector2(0,y),2.2,icing)

func stocking(center: Vector2) -> void:
	var sock=Color("c85542")
	WoolArt.box(self,Rect2(center+Vector2(-8,-13),Vector2(19,27)),sock,6)
	WoolArt.box(self,Rect2(center+Vector2(-18,4),Vector2(29,15)),sock,7)
	WoolArt.box(self,Rect2(center+Vector2(-10,-16),Vector2(23,10)),Color("fff4d5"),4)
	draw_line(center+Vector2(6,-3),center+Vector2(6,8),sock.lightened(0.28),1,true)

func santa(center: Vector2) -> void:
	felt_disk(center+Vector2(0,5),16,Color("fff4df"))
	felt_disk(center,11,Color("efc399"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(-14,-7),center+Vector2(8,-28),center+Vector2(14,-7)]),Color("c65441"))
	WoolArt.box(self,Rect2(center+Vector2(-15,-10),Vector2(30,7)),Color("fff4df"),3)
	felt_disk(center+Vector2(9,-26),4,Color("fff4df"))
	draw_circle(center+Vector2(-4,-1),1.4,Color("66513b"));draw_circle(center+Vector2(4,-1),1.4,Color("66513b"))

func draw_scenery() -> void:
	var theme=MapTheme.for_level(state.level_index).id
	if theme=="winter":snow_decor();return
	for i in range(scenery_positions.size()):
		var center=scenery_positions[i]
		if theme=="meadow":
			flower(center,Color("f3b1c4") if i%2==0 else Color("f0cb72"))
			for side in [-1,1]:draw_line(center+Vector2(18*side,15),center+Vector2(22*side,7),Color("8ab777"),2,true)
		elif theme=="festive":
			if i==0:santa(center)
			elif i==1:stocking(center)
			else:gingerbread(center)
		else:
			ribbon(center,Color("ceacdF") if i%2==0 else Color("f1b4c8"))
			felt_disk(center+Vector2(25,18),5,Color("f0c8e2"))

func upper_mist() -> void:
	if mist_visibility<=0:return
	var edge=state.fog_edge()
	for y in range(0,ceili(edge+15),3):
		var alpha=0.94*mist_visibility*(1-smoothstep(edge,edge+15,float(y)))
		draw_rect(Rect2(0,y,592,3),Color(0.87,0.93,0.98,alpha))

func unravel_contact(source: Vector2, angle: float, edge: Vector2, peel: float, t: float, color: Color) -> void:
	# The light belongs to the shrinking knit edge, and fades before the loose tail retracts.
	var strength=smoothstep(0,0.055,t)*(1-smoothstep(0.64,0.84,t))
	if strength<=0.001:return
	var contact=source+edge.rotated(angle)
	for layer in range(5,0,-1):
		draw_circle(contact,5+layer*3.0,Color(1,0.82,0.28,0.045*strength))
	var half_width=CUFF_SIZE.x*0.41*(1-0.65*smoothstep(0.45,0.96,peel))
	var rim=PackedVector2Array()
	for i in range(21):
		var q=i/20.0
		var p=Vector2(lerpf(-half_width,half_width,q),edge.y+sin(q*PI)*6)
		rim.append(source+p.rotated(angle))
	draw_polyline(rim,Color(1,0.59,0.1,0.14*strength),14,true)
	draw_polyline(rim,Color(1,0.86,0.34,0.35*strength),8,true)
	draw_polyline(rim,Color(1,0.98,0.64,0.97*strength),3.5,true)
	for i in range(7):
		var phase=fmod(t*2.4+i*0.143,1.0)
		var direction=Vector2.RIGHT.rotated(angle-PI/2+i*2.399)
		var p=contact+direction*(5+phase*20)+Vector2(0,-phase*8)
		var alpha=strength*(1-phase)*0.85
		draw_line(p-direction*2.5,p+direction*2.5,Color(color.lightened(0.72),alpha),1.8,true)
		draw_circle(p,1.5,Color(1,0.98,0.8,alpha))

func yarn_flight(f: Dictionary) -> void:
	var t=clampf((state.time-f.start)/0.46,0,1)
	var flight_curve: Curve2D=state.dragons[f.dragon].curve
	var source=flight_curve.sample_baked(clampf(f.distance,0,flight_curve.get_baked_length()),true)
	source=Vector2(clampf(source.x,8,584),clampf(source.y,24,410))
	var end=winding_point(f.slot) if f.slot<state.slots.size() and state.slots[f.slot]>=0 else slot_center(f.slot)
	var color: Color=WoolArt.COLORS[f.color]
	# Consume rows at their original stitch scale. The strand follows that same moving edge.
	var peel=smoothstep(0,0.86,t)
	var size=CUFF_SIZE
	if peel<0.995:
		var region=Rect2(WoolArt.CUFF_SOURCE.position+Vector2(0,WoolArt.CUFF_SOURCE.size.y*peel),Vector2(WoolArt.CUFF_SOURCE.size.x,WoolArt.CUFF_SOURCE.size.y*(1-peel)))
		var destination=Rect2(Vector2(-size.x/2,-size.y/2+size.y*peel),Vector2(size.x,size.y*(1-peel)))
		draw_set_transform(source,f.angle)
		draw_texture_rect_region(WoolArt.CUFF_IMAGE,destination,region,color)
		draw_set_transform(Vector2.ZERO)
	var edge=Vector2(sin(peel*TAU*4)*size.x*0.18*minf(1,peel*4),size.y*(peel-0.5))
	var thread_source=source+edge.rotated(f.angle)
	var strand=PackedVector2Array()
	var unwind=thread_source.lerp(end,smoothstep(0.75,1.0,t))
	var control1=unwind+Vector2(0,60)
	var control2=end+Vector2(sin(t*PI)*25,-80)
	for j in range(42):
		var q=j/41.0
		strand.append(pow(1-q,3)*unwind+3*pow(1-q,2)*q*control1+3*(1-q)*q*q*control2+q*q*q*end)
	var shadow=PackedVector2Array()
	for p in strand: shadow.append(p+Vector2(2,4))
	draw_polyline(shadow,Color(0.22,0.36,0.4,0.15),5,true)
	draw_polyline(strand,color.darkened(0.22),4.6,true)
	draw_polyline(strand,color.lightened(0.22),2.4,true)
	for j in range(0,40,3):
		var p=strand[j]
		draw_line(p+Vector2(-1,1),p+Vector2(2,-2),Color(color.lightened(0.45),0.65),0.7,true)
	var pulse=int(clampf(t*1.28,0,1)*38)
	var pulse_alpha=sin(t*PI)*0.8
	draw_polyline(PackedVector2Array([strand[pulse],strand[pulse+1],strand[pulse+2]]),Color(1,0.97,0.72,pulse_alpha),3.0,true)
	unravel_contact(source,f.angle,edge,peel,t,color)

func tangent_for(curve: Curve2D,distance: float) -> float:
	var length=curve.get_baked_length()
	return (curve.sample_baked(clampf(distance+4,0,length),true)-curve.sample_baked(clampf(distance-4,0,length),true)).angle()

func draw_flame(start: Vector2,end: Vector2,amount: float) -> void:
	var vector=end-start
	for i in range(16,0,-1):
		var q=i/16.0
		var p=start+vector*q+vector.orthogonal().normalized()*sin(clock*27+i)*5*q
		var radius=(7+10*sin(q*PI))*(1-q*0.65)*amount
		draw_circle(p,radius+6,Color(1,0.42,0.06,0.18))
		draw_circle(p,radius,Color(1,0.56+q*0.3,0.07,0.9))
		draw_circle(p,radius*0.5,Color(1,0.98,0.62,0.95))

func _draw() -> void:
	if state==null or state.dragons.is_empty():return
	for enemy in state.dragons:
		route=enemy.curve
		draw_route()
	route=state.route_curve
	draw_scenery()
	if not state.won:
		for i in range(state.units.size()):
			var unit=state.units[i]
			var curve: Curve2D=state.dragons[unit.dragon].curve
			var d=float(positions.get(unit.id,state.unit_distance(i)))
			if d<0 or d>curve.get_baked_length():continue
			var point=curve.sample_baked(d,true)
			if point.x< -60 or point.x>652:continue
			var angle=tangent_for(curve,d)-PI/2
			var color: Color=WoolArt.COLORS[unit.color]
			if state.has_lower_yarn() and state.time>=state.boost_until and not state.exposed(i):color=Color("d6e0e8")
			WoolArt.stamp(self,WoolArt.CUFF,point+Vector2(0,3),CUFF_SIZE+Vector2(2,2),Color(0.2,0.33,0.39,0.12),angle)
			WoolArt.stamp(self,WoolArt.CUFF,point,CUFF_SIZE,color,angle)
	for enemy in state.dragons:
		if enemy.phase=="cleared" and not state.won:continue
		var curve: Curve2D=enemy.curve
		var hp=curve.sample_baked(clampf(enemy.head,0,curve.get_baked_length()),true)
		var heading=tangent_for(curve,enemy.head)
		var mirrored=cos(heading)>0
		var rotation=clampf(heading-(PI if not mirrored and heading>0 else -PI if not mirrored else 0),-0.7,0.7)
		if enemy.phase=="windup":
			WoolArt.box(self,Rect2(hp+Vector2(-22,-80),Vector2(44,31)),Color("ffe7ae"),12)
			WoolArt.text(self,"!",hp+Vector2(0,-55),26,Color("c63d20"))
		if enemy.phase=="fire" and not state.won:draw_flame(hp+(state.cat_position-hp).normalized()*37+Vector2(0,10),state.cat_position+Vector2(0,6),1.0)
		draw_set_transform(hp,rotation,Vector2(-1,1) if mirrored else Vector2.ONE)
		draw_texture_rect_region(HEAD_IMAGE,Rect2(-52,-47,104,94),Rect2(76,13,511,622))
		draw_set_transform(Vector2.ZERO)
		if state.time<state.freeze_until:
			for i in range(8):
				var p=hp+Vector2.RIGHT.rotated(i*TAU/8)*48
				draw_colored_polygon(PackedVector2Array([p+Vector2(-9,0),p+Vector2(0,-23),p+Vector2(10,0),p+Vector2(0,19)]),Color(0.4,0.87,1,0.66))
	upper_mist()
	var cat=state.cat_position
	var running=state.cat_phase=="fleeing"
	var hop=-absf(sin(clock*26))*6 if running else -absf(sin((state.time-rescue_time)*5))*13 if state.won else 0.0
	if running:
		for i in range(4):ellipse(cat+Vector2(-20-i*12,30),Vector2(6+i*2,3+i),Color(1,1,1,0.35-i*0.06))
	ellipse(cat+Vector2(0,33),Vector2(25,5),Color(0.26,0.42,0.48,0.18))
	var tint=Color(1,0.65,0.6) if state.cat_phase=="hurt" and sin(clock*25)>0 else Color.WHITE
	draw_set_transform(cat+Vector2(0,hop),sin(clock*(20 if running else 1.5))*(0.07 if running else 0.018))
	draw_texture_rect_region(WoolArt.CAST,Rect2(-27,-34,54,69),Rect2(712 if state.won else 91,77,452,526),tint)
	draw_set_transform(Vector2.ZERO)
	if state.time<state.shield_until or state.time<state.invulnerable_until:
		var color=Color(0.35,0.85,1,0.85) if state.time<state.shield_until else Color(1,0.86,0.32,0.7)
		draw_circle(cat,45,Color(color,0.14));draw_arc(cat,44,0,TAU,64,color,3.0,true)
	if not state.won:
		for i in range(state.max_hearts):
			var center=cat+Vector2((i-(state.max_hearts-1)*0.5)*25,-52)
			draw_texture_rect_region(WoolArt.DETAILS,Rect2(center-Vector2(12,12),Vector2(24,24)),Rect2(701,166,472,365),Color.WHITE if i<state.hearts else Color("728ea0"))
	ellipse(Vector2(35,373),Vector2(36,30),Color(1,0.85,0.1,0.13))
	draw_texture_rect_region(WoolArt.CAST,Rect2(0,344,69,62),Rect2(78,717,490,444))
	for i in range(state.slots.size()):spool(i);slot_completion(i)
	for f in flights:yarn_flight(f)
	for p in sparks:
		draw_set_transform(p.p,p.t*4+p.r)
		draw_rect(Rect2(-p.r,-p.r*0.45,p.r*2,p.r*0.9),Color(WoolArt.COLORS[p.color],clampf(2.6-p.t,0,1)))
		draw_set_transform(Vector2.ZERO)
