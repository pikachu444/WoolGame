extends RefCounted

# Observed visual/mechanical vocabulary; authored personal campaign, not original level IDs.
const TITLES=["첫 번째 실","구불구불 산책","갈림길","차곡차곡","긴 실과 짧은 실","안개 너머","마지막 한 칸","얼음의 도움","두 갈래 추격","함께 집으로"]
const CARDS=["첫 만남","눈꽃 산책","작은 용기","따뜻한 목도리","무지개 실","안개 속 불빛","포근한 쉼터","얼음꽃","두 친구","우리의 집"]
const COUNTS=[12,16,18,20,22,24,24,26,26,28]

static func curve_for(level: int,secondary: bool=false) -> Curve2D:
	var shapes=[
		[Vector2(-180,355),Vector2(105,355),Vector2(430,350),Vector2(534,290),Vector2(520,198),Vector2(393,130),Vector2(230,120),Vector2(95,170),Vector2(92,260),Vector2(220,290),Vector2(390,285)],
		[Vector2(-180,335),Vector2(120,360),Vector2(448,355),Vector2(535,265),Vector2(480,155),Vector2(360,115),Vector2(230,165),Vector2(110,178),Vector2(70,228),Vector2(210,285),Vector2(389,285)],
		[Vector2(-180,355),Vector2(150,355),Vector2(450,352),Vector2(534,277),Vector2(502,148),Vector2(367,108),Vector2(231,126),Vector2(113,178),Vector2(79,260),Vector2(229,285),Vector2(390,285)]]
	var points: Array=shapes[level%3].duplicate()
	if secondary:
		for i in range(6):points[i]=Vector2(592-points[i].x,points[i].y)
	var curve=Curve2D.new();curve.bake_interval=2.0
	for i in range(points.size()):
		var tangent=Vector2.ZERO
		if i>0 and i<points.size()-1:tangent=(points[i+1]-points[i-1]).normalized()*minf(55.0,points[i].distance_to(points[i+1])*0.25)
		curve.add_point(points[i],-tangent,tangent)
	return curve

static func definition(level: int) -> Dictionary:
	level=clampi(level,0,9)
	var curve=curve_for(level)
	var anchors=[curve.get_point_position(7),curve.get_point_position(9),curve.get_point_position(10)]
	var blocks: Array[Dictionary]=[]
	var rows=[[3,4],[2,3,4,5],[1,2,3,4,5,6],[0,1,2,3,4,5,6,7],[1,2,3,4,5,6],[2,3,4,5]]
	var cells: Array[Vector2i]=[]
	for row in range(rows.size()):
		for col in rows[row]:cells.append(Vector2i(col,row))
	if level==0:
		cells=[]
		for row in range(3):
			for col in range(2,6):cells.append(Vector2i(col,row+1))
	elif level in [2,5,8]:
		cells=[]
		for row in range(6):
			for col in range(1,7):
				if not (row in [0,5] and col in [1,6]):cells.append(Vector2i(col,row))
	for i in range(mini(COUNTS[level],cells.size())):
		var c=cells[i];var direction=0
		if level>0:
			if c.y>=3:direction=2
			if level>=2 and c.x<=1:direction=3
			if level>=2 and c.x>=6:direction=1
		var capacity=2+((i+level)%3)*2 if level>=4 else 3+(i%2)
		var width=48 if direction%2==0 else 56
		var height=68 if direction%2==0 and capacity>=5 else 59
		blocks.append({"cell":Vector2i(39+c.x*64,599+c.y*70),"size":Vector2i(width,height),"direction":direction,"color":(i*5+level*2)%(3 if level==0 else 4 if level<3 else 6),"capacity":capacity})
	return {"id":level,"title":TITLES[level],"card":CARDS[level],"blocks":blocks,"curve":curve,"anchors":anchors,"dragons":2 if level>=8 else 1,"speed":[16.0,18.0,17.0,18.0,18.0,17.0,19.0,18.0,17.0,19.0][level],"fog":level in [5,7,9]}
