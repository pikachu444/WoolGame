extends RefCounted

# Observed visual/mechanical vocabulary; authored personal campaign, not original level IDs.
const TITLES=["첫 번째 실","옆으로 한 걸음","네 방향 출구","갈림길의 순서","긴 실과 짧은 실","선반 한 칸","안개 속 출구","눈 속의 여섯 색","두 갈래 추격","함께 집으로"]
const CARDS=["첫 만남","들꽃 산책","작은 용기","따뜻한 목도리","무지개 실","숲속의 약속","안개 속 불빛","얼음꽃","두 친구","우리의 집"]
const COUNTS=[12,16,18,20,22,24,24,26,26,28]
const LESSONS=["위쪽부터 차례로 꺼내요","가로 화살표는 옆 출구로 나가요","아래쪽 출구도 함께 살펴봐요","막힌 색의 앞을 먼저 열어요","숫자는 실의 양 · 감는 동안 다음 색을 골라요","다섯 색을 네 칸 선반에 나눠 담아요","안개 밖에서 보이는 색을 먼저 골라요","짧은 실로 자리를 만들고 긴 실을 준비해요","두 용의 색을 번갈아 살펴봐요","출구와 선반, 두 용을 함께 살펴봐요"]
const SPEEDS=[13.0,14.0,14.0,14.5,15.0,15.0,17.0,15.0,14.5,15.0]
# Authored cells: color (R/Y/G/B/P/O), direction (U/R/D/L), yarn capacity.
# Each row is eight fixed columns. Dots are intentional open corridors.
# Paths and card IDs stay stable; these are personal designs, not claimed original levels.
const BOARDS=[
 [". . . . . . . .", ". . RU3 YU3 BU3 RU3 . .", ". . BU3 RU3 YU3 BU3 . .", ". . YU3 BU3 RU3 YU3 . ."],
 [". . . RU3 YU3 . . .", ". . RU3 BU3 YU3 RU3 . .", ". YL3 BL3 RU3 BU3 YR3 . .", ". BL3 YL3 BL3 RU3 BR3 . ."],
 [". . RU3 YU3 GU3 BU3 . .", ". RL3 YL3 GU3 BU3 RR3 BR3 .", ". GL3 BU3 YU3 RU3 . . .", ". . YD3 GD3 BD3 RD3 . ."],
 [". . RU3 YU3 GU3 BU3 . .", ". RL3 YL3 GU3 BU3 GR3 BR3 .", ". GL3 BL3 RU3 YU3 RR3 YR3 .", ". . GU3 BU3 RU3 YU3 . ."],
 [". . RU2 YU4 GU2 BU4 . .", ". RL2 YL6 GU2 BU4 RR2 BR6 .", ". GU4 BL2 RU6 YU2 GR4 YR2 .", ". GL6 YL2 BU4 RU2 YR4 BR6 ."],
 [". RU2 YU4 GU4 BU2 PU4 RU4 .", ". YU4 RL4 BL2 GR4 PR4 RU2 .", ". BU2 YL4 GL4 PR2 RR4 GU4 .", ". PD4 BD2 YD4 GD4 RD2 PD4 ."],
 [". . RU2 YU2 GU2 BU2 . .", ". PL2 RL2 YU2 GU2 BR2 PR2 .", ". . BU2 PU2 RU2 YU2 . .", ". GL2 YL2 BU2 PU2 RR2 GR2 .", ". . RD2 BD2 GD2 PD2 . ."],
 [". . RU2 YU2 GU4 BU2 . .", ". PL2 RL4 YU2 GU4 BR2 OR4 .", ". GU4 BL2 PU4 OU2 YR4 RR2 .", ". YL2 PL4 RU4 BU2 OR4 GR2 .", ". . BD4 OD4 PD2 YD4 . ."],
 [". . . RU2 BU2 . . .", ". . YU4 GU2 PU4 OU2 . .", ". RL2 YL4 GU4 BU2 PR4 OR4 .", ". BL4 PL2 RU4 YU4 GR2 OR4 .", ". GL4 YL4 BU2 OU4 PR4 RR2 .", ". . . PD6 OD6 . . ."],
 [". . RU2 YU4 GU2 BU4 . .", ". . PU4 OU2 RU4 YU2 . .", ". GL2 BL6 PU4 OU2 YR4 RR6 .", ". YL4 PL2 RU6 BU4 OR2 GR4 .", ". . OU6 GU2 PU4 YU6 . .", ". . RD4 BD6 OD2 PD4 . ."]
]

static func curve_for(level: int,secondary: bool=false) -> Curve2D:
	var shapes=[
  [Vector2(-180,355),Vector2(105,355),Vector2(430,350),Vector2(534,290),Vector2(520,198),Vector2(393,130),Vector2(230,120),Vector2(95,170),Vector2(92,260),Vector2(220,290),Vector2(390,285)],
  [Vector2(-180,335),Vector2(120,360),Vector2(448,355),Vector2(535,265),Vector2(480,155),Vector2(360,115),Vector2(230,165),Vector2(110,178),Vector2(70,228),Vector2(210,285),Vector2(389,285)],
  # S-shaped flower path, guided by the observed original level 3.
  [Vector2(-160,15),Vector2(80,70),Vector2(330,90),Vector2(500,105),Vector2(525,200),Vector2(435,265),Vector2(265,245),Vector2(105,211),Vector2(63,300),Vector2(210,358),Vector2(525,358)],
  [Vector2(760,350),Vector2(490,350),Vector2(420,275),Vector2(474,170),Vector2(424,93),Vector2(295,100),Vector2(245,180),Vector2(145,205),Vector2(89,274),Vector2(218,332),Vector2(367,328)],
  # Hook-shaped red path, guided by the observed original level 5.
  [Vector2(770,350),Vector2(523,350),Vector2(420,313),Vector2(386,229),Vector2(365,126),Vector2(253,81),Vector2(143,107),Vector2(198,211),Vector2(192,277),Vector2(143,328),Vector2(94,367)],
  [Vector2(-180,353),Vector2(100,353),Vector2(508,346),Vector2(525,227),Vector2(480,99),Vector2(340,104),Vector2(316,188),Vector2(193,191),Vector2(104,246),Vector2(190,296),Vector2(355,295)],
  # White ribbon path, guided by the observed original level 7.
  [Vector2(-180,350),Vector2(83,350),Vector2(500,350),Vector2(534,278),Vector2(527,92),Vector2(417,73),Vector2(297,79),Vector2(296,187),Vector2(143,197),Vector2(153,285),Vector2(348,285)],
  [Vector2(-180,360),Vector2(110,360),Vector2(424,359),Vector2(533,293),Vector2(498,181),Vector2(370,109),Vector2(254,171),Vector2(130,130),Vector2(73,221),Vector2(207,274),Vector2(355,270)],
  [Vector2(-180,355),Vector2(145,355),Vector2(455,350),Vector2(529,271),Vector2(499,142),Vector2(355,105),Vector2(235,160),Vector2(111,153),Vector2(72,240),Vector2(224,287),Vector2(390,284)],
  [Vector2(-180,353),Vector2(130,353),Vector2(466,351),Vector2(536,267),Vector2(515,117),Vector2(378,92),Vector2(190,104),Vector2(103,197),Vector2(133,275),Vector2(273,286),Vector2(402,250)]
	]
	var points: Array=shapes[clampi(level,0,9)].duplicate()
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
	for row in range(BOARDS[level].size()):
		var tokens: PackedStringArray=BOARDS[level][row].split(" ",false)
		for col in range(tokens.size()):
			var token: String=tokens[col]
			if token==".":continue
			var color="RYGBPO".find(token[0]);var direction="URDL".find(token[1]);var capacity=int(token.substr(2))
			var width=48 if direction%2==0 else 56
			var height=68 if direction%2==0 and capacity>=5 else 59
			blocks.append({"cell":Vector2i(39+col*64,599+row*70),"size":Vector2i(width,height),"direction":direction,"color":color,"capacity":capacity})
	return {"id":level,"title":TITLES[level],"card":CARDS[level],"lesson":LESSONS[level],"blocks":blocks,"curve":curve,"anchors":anchors,"dragons":2 if level>=8 else 1,"speed":SPEEDS[level],"fog":level in [6,7],"fog_ceiling":110.0 if level==6 else 155.0 if level==7 else 210.0}
