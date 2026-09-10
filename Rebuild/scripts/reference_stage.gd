extends RefCounted
# Representative source: HR-0KwTL8dA (N3), Level 2 at 6.80 s, 0%.
# Visual bbox/direction/color/length were manually observed; bbox tolerance is ±2 source pixels.
# Source pixels include depth/shadow. State subtracts its existing 12px visual depth for collision.
const BOARD_SCALE=1.8
const UPPER_SCALE=1.9
const SOURCE_BLOCKS=[
 ["b01","G","U","S",132,293,25,31],
 ["b02","R","U","S",104,318,24,32],
 ["b03","P","U","S",161,318,24,32],
 ["b04","Y","U","M",132,326,25,36],
 ["b05","C","U","S",48,362,24,31],
 ["b06","P","U","L",76,347,24,46],
 ["b07","Y","U","M",104,356,25,37],
 ["b08","G","U","L",133,363,24,46],
 ["b09","B","U","M",161,356,24,37],
 ["b10","P","U","L",190,347,24,46],
 ["b11","Y","U","S",218,362,24,31],
 ["b12","R","L","S",17,394,23,32],
 ["b13","P","L","M",48,395,33,31],
 ["b14","G","L","L",90,395,39,31],
 ["b15","C","R","L",160,395,40,31],
 ["b16","R","R","M",208,395,33,31],
 ["b17","C","R","S",249,395,23,31],
 ["b18","Y","D","S",48,430,24,31],
 ["b19","B","D","L",76,432,24,45],
 ["b20","B","D","M",105,432,24,38],
 ["b21","Y","D","L",133,413,24,44],
 ["b22","M","D","M",162,432,23,38],
 ["b23","O","D","L",190,432,24,45],
 ["b24","O","D","S",218,432,24,29],
 ["b25","O","D","S",105,473,24,30],
 ["b26","C","D","M",133,458,24,38],
 ["b27","P","D","S",162,473,23,30],
 ["b28","Y","D","S",133,498,24,31]
]
const EXPECTED_BLOCKERS=[
 [],
 [],
 [],
 [0],
 [],
 [],
 [1],
 [0,3],
 [2],
 [],
 [],
 [],
 [11],
 [11,12],
 [15,16],
 [16],
 [],
 [],
 [],
 [24],
 [25,27],
 [26],
 [],
 [],
 [],
 [27],
 [],
 []
]
# All28 arrival counters were directly observed: S=4, M=6, L=10.
const CLASS_CAPACITY={"S":4,"M":6,"L":10}
const OBSERVED_CAPACITIES={0:4,1:4,2:4,3:6,4:4,5:10,6:6,7:10,8:6,9:10,10:4,11:4,12:6,13:10,14:10,15:6,16:4,17:4,18:10,19:6,20:10,21:6,22:10,23:4,24:4,25:6,26:4,27:4}
# The first C4/R6/C10 choice chain is source-guided. The unseen remainder is explicit
# provisional authored data, never a runtime escape-witness-generated answer.
const YARN_ORDER=[16,15,14,0,3,7,2,9,10,27,25,4,13,11,12,17,18,19,20,21,22,23,24,26,8,6,5,1]
# Segments reconstruct observed early C9, O11 then O1, delayed C/R/O supply.
# Exact original segment order is not recovered; amounts preserve each color total.
const YARN_SEGMENTS=[{"color":6,"amount":4,"dragon":0},{"color":4,"amount":4,"dragon":0},{"color":5,"amount":4,"dragon":0},{"color":2,"amount":4,"dragon":0},{"color":5,"amount":7,"dragon":0},{"color":3,"amount":10,"dragon":0},{"color":6,"amount":5,"dragon":0},{"color":4,"amount":14,"dragon":0},{"color":1,"amount":4,"dragon":0},{"color":1,"amount":6,"dragon":0},{"color":1,"amount":4,"dragon":0},{"color":5,"amount":1,"dragon":0},{"color":3,"amount":6,"dragon":0},{"color":4,"amount":10,"dragon":0},{"color":2,"amount":10,"dragon":0},{"color":2,"amount":7,"dragon":0},{"color":6,"amount":15,"dragon":0},{"color":2,"amount":3,"dragon":0},{"color":7,"amount":6,"dragon":0},{"color":0,"amount":14,"dragon":0},{"color":3,"amount":5,"dragon":0},{"color":4,"amount":6,"dragon":0},{"color":1,"amount":4,"dragon":0},{"color":1,"amount":5,"dragon":0},{"color":5,"amount":1,"dragon":0},{"color":1,"amount":3,"dragon":0},{"color":5,"amount":1,"dragon":0},{"color":5,"amount":4,"dragon":0},{"color":1,"amount":6,"dragon":0},{"color":3,"amount":1,"dragon":0},{"color":1,"amount":2,"dragon":0}]
static func upper(source: Vector2) -> Vector2:
 return Vector2(296+(source.x-144)*UPPER_SCALE,source.y*UPPER_SCALE)
static func curve() -> Curve2D:
 var path=Curve2D.new();path.bake_interval=1.0
 # Three stacked horizontal S passes traced from the reference image; outside spawn
 # and final resting point are authored continuations, not extracted source coordinates.
 var points=[Vector2(410,2),Vector2(54,2),Vector2(30,26),Vector2(54,50),Vector2(246,50),Vector2(270,73),Vector2(246,96),Vector2(42,96),Vector2(18,119),Vector2(42,142),Vector2(246,142),Vector2(270,165),Vector2(246,188),Vector2(150,188)]
 for i in range(points.size()):
  var tangent=Vector2.ZERO
  if i in [2,5,8,11]:tangent=Vector2.DOWN*15.0
  elif i in [1,6,7,12]:tangent=Vector2.LEFT*15.0
  elif i in [3,4,9,10]:tangent=Vector2.RIGHT*15.0
  path.add_point(upper(points[i]),-tangent*UPPER_SCALE,tangent*UPPER_SCALE)
 return path
static func observed_actions() -> Array:
 # Active replay starts at the source's first actual selection (~16.4s), skipping
 # its roughly ten-second entrance/watch period. Only confirmed actions are listed.
 return [{"time":0.23,"block":16},{"time":2.83,"block":15},{"time":5.53,"block":14},{"time":9.07,"block":23},{"time":11.73,"block":22},{"time":16.13,"block":9},{"time":23,"block":26},{"time":26,"block":2},{"time":29.37,"block":10},{"time":34.8,"block":0},{"time":38.633,"block":8},{"time":42,"block":3},{"time":46.567,"block":27},{"time":49.867,"block":18},{"time":56.833,"block":5},{"time":64.367,"block":7},{"time":72.5,"block":21},{"time":78.867,"block":24},{"time":80.767,"block":19},{"time":84.4,"block":11},{"time":95,"block":12},{"time":98.767,"block":17},{"time":106.267,"block":25},{"time":110.633,"block":20},{"time":114.167,"block":13},{"time":119.733,"block":1},{"time":121.467,"block":4},{"time":122.867,"block":6}]
static func unit_of_color(color: int,ordinal: int) -> int:
 var id=0;var count=0
 for segment in YARN_SEGMENTS:
  for i in range(segment.amount):
   if segment.color==color:
    count+=1
    if count==ordinal:return id
   id+=1
 return -1
static func powers(path: Curve2D) -> Array:
 # Original b11's third yellow winds into a punch; b18's fourth into slow.
 # Distances/factor are mapped estimates. Recovery endpoint comes from source51s.
 var target=path.get_closest_offset(upper(Vector2(24,142)))/path.get_baked_length()
 return [{"unit_id":unit_of_color(1,3),"kind":"repel","distance":1000.0,"duration":1.7,"return_speed":335.0,"return_to_fraction":target},{"unit_id":unit_of_color(1,18),"kind":"slow","duration":6.0,"factor":0.25}]
static func definition() -> Dictionary:
 var blocks: Array[Dictionary]=[]
 for row in SOURCE_BLOCKS:
  var id=blocks.size();var original=Rect2i(row[4],row[5],row[6],row[7])
  var cell=Vector2i(roundi(296+(original.position.x-144.5)*BOARD_SCALE),roundi(599+(original.position.y-293)*BOARD_SCALE))
  var size=Vector2i(roundi(original.size.x*BOARD_SCALE),roundi(original.size.y*BOARD_SCALE))
  blocks.append({"cell":cell,"size":size,"color":"RYGBPOCM".find(row[1]),"direction":"URDL".find(row[2]),"capacity":CLASS_CAPACITY[row[3]],"reference_id":row[0],"reference_length":row[3],"capacity_observed":OBSERVED_CAPACITIES.has(id)})
 var path=curve()
 var first_cat=path.sample_baked(path.get_closest_offset(upper(Vector2(229,142))),true)
 var anchors=[first_cat,path.get_point_position(path.point_count-1)]
 # Source 14.5–16.5s free movement is 26–27 source px/s;54 game px/s is a mapped
 # candidate. Recoil40 is a mapped candidate; the source60 outlier includes a separate punch; initial head centre and recoil are estimates, not original constants.
 var start=path.get_closest_offset(upper(Vector2(128,142)))
 return {"id":1,"title":"다이아몬드 출구","card":"들꽃 산책","lesson":"화살표 앞을 열고 같은 색 실을 감아요","reference_stage":true,"blocks":blocks,"curve":path,"anchors":anchors,"dragons":1,"speed":54.0,"final_approach_speed":27.0,"final_approach_distance":320.0,"fog":false,"pitch":44.0,"reading_grace":10.0,"flight_time_scale":0.4,"initial_head_fraction":start/path.get_baked_length(),"winding_interval":0.40,"unwind_duration":0.46,"clear_duration":0.10,"head_recoil":40.0,"recoil_floor_fraction":path.get_closest_offset(upper(Vector2(24,142)))/path.get_baked_length(),"yarn_order":YARN_ORDER,"yarn_segments":YARN_SEGMENTS,"yarn_powers":powers(path),"cat_visual_offset":Vector2(0,-18),"reference_evidence":{"board":"observed N3 6.80s, 28 blocks/8 colors","capacity":"all28 shelf counters directly observed, 4/6/10","yarn_order":"segmented reconstruction hypothesis from observed C/R/O slot occupancy, exact source order unknown","active_start":"source16.4s chosen; optional first-input reading grace10s is a UX adaptation","timing":"mapped movement observation; recoil/pitch provisional"}}
