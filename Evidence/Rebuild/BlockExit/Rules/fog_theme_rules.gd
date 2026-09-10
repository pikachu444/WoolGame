extends SceneTree
const State=preload("res://scripts/state.gd")
const MapTheme=preload("res://scripts/map_theme.gd")
var checks=0
var failures=[]
var observations=[]
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/Rules"
func check(ok: bool,label: String,detail: Variant=null):
 checks+=1
 if not ok:failures.append({"label":label,"detail":detail});print("FAIL ",label," ",JSON.stringify(detail))
func _initialize():call_deferred("run")
func run():
 var scene=load("res://scenes/game.tscn").instantiate();root.add_child(scene);await process_frame;scene.muted=true
 var world=scene.get_node("World");var backdrop=scene.get_node("TextileBackdrop");var routes={};var palettes={}
 for level in range(10):
  scene.start_stage(level,true);var s=scene.state;var fog=level in [6,7];var edge=110.0 if level==6 else 155.0 if level==7 else 0.0
  check(s.definition.fog==fog,"authored fog stages "+str(level+1))
  if fog:check(abs(s.fog_edge()-edge)<0.00001,"authored fog edge "+str(level+1),s.fog_edge())
  check(backdrop.level_index==level,"backdrop theme uses active stage "+str(level+1))
  check(world.route==s.route_curve,"display path is gameplay path "+str(level+1))
  var points=[]
  for i in range(s.route_curve.get_point_count()):points.append(s.route_curve.get_point_position(i))
  var signature=JSON.stringify(points);check(not routes.has(signature),"ten authored routes are distinct "+str(level+1));routes[signature]=true
  palettes[MapTheme.for_level(level).id]=true
  check(world.mist_visibility==(1.0 if fog else 0.0),"initial fog rendering matches stage rule "+str(level+1),world.mist_visibility)
  for dragon in s.dragons:
   var curve=dragon.curve;var first=-1
   for index in range(s.units.size()):
    if s.units[index].dragon==dragon.id:first=index;break
   for step in range(241):
    var distance=curve.get_baked_length()*step/240.0;dragon.head=distance+65.0
    var p=curve.sample_baked(distance,true)
    var expected=p.x>=0 and p.x<592 and p.y>=20 and p.y<417 and (not fog or p.y>=edge)
    check(s.exposed(first)==expected,"real route visibility boundary L%d D%d sample%d"%[level+1,dragon.id,step],[p,expected,s.exposed(first)])
  if fog:
   var curve=Curve2D.new();curve.add_point(Vector2(200,edge-2));curve.add_point(Vector2(200,edge+2));s.dragons[0].curve=curve
   for distance in [0.0,1.5,2.0,2.5,4.0]:
    s.dragons[0].head=65.0+distance
    check(s.exposed(0)==(distance>=2.0),"exact fog crossing L%d d%.1f"%[level+1,distance],s.unit_point(0))
  world._process(1.0)
  check(world.mist_visibility==(1.0 if fog else 0.0),"steady fog render activation matches rule "+str(level+1),world.mist_visibility)
  s.mode="free";s.dragons[0].head=64.0;check(not s.exposed(0),"offscreen concealed normally "+str(level+1))
  check(s.strengthen(),"boost accepted "+str(level+1));world.reset_visuals()
  check(world.mist_visibility==0.0,"reset during boost keeps mist absent "+str(level+1))
  world._process(0.4)
  check(s.exposed(0) and world.mist_visibility==0.0,"boost removes logical and rendered fog "+str(level+1),world.mist_visibility)
  s.time=s.boost_until+0.001;world._process(0.4)
  check(not s.exposed(0) and world.mist_visibility==(1.0 if fog else 0.0),"boost expiry restores both restrictions "+str(level+1))
  var visibility=world.mist_visibility;s.paused=true;world._process(0.5);check(world.mist_visibility==visibility,"paused fog transition freezes "+str(level+1));s.paused=false
 check(routes.size()==10 and palettes.size()==4,"ten routes and four theme families")
 var source=FileAccess.get_file_as_string("res://scripts/world.gd");var start=source.find("func upper_mist()");var end=source.find("
func ",start+1);var renderer=source.substr(start,end-start)
 var inspection={"uses_state_fog_edge":renderer.contains("var edge=state.fog_edge()"),"opaque_above_edge_then_fifteen_pixel_fade":renderer.contains("range(0,ceili(edge+15),3)") and renderer.contains("0.94*mist_visibility*(1-smoothstep(edge,edge+15,float(y)))"),"hidden_units_neutralized":source.contains("if state.has_lower_yarn() and state.time>=state.boost_until and not state.exposed(i):color=Color(\"d6e0e8\")"),"method":renderer,"note":"Source inspection of actual drawing method; no rendered pixel assertion in headless."}
 var resources={}
 for path in ["res://scripts/campaign.gd","res://scripts/state.gd","res://scripts/world.gd","res://scripts/map_theme.gd","res://scripts/background.gd"]:resources[path]=FileAccess.get_sha256(path)
 var file=FileAccess.open(out+"/fog-theme-rules.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"render_source_inspection":inspection,"resource_hashes":resources},"  "));file.close()
 for player in scene.tones:player.stop();player.stream=null
 await create_timer(0.2).timeout
 scene.queue_free();await process_frame;print("INDEPENDENT_FOG_THEME checks=",checks," failures=",failures.size()," observations=",observations.size());quit(0 if failures.is_empty() else 1)
