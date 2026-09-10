extends SceneTree
const State=preload("res://scripts/state.gd")
const Campaign=preload("res://scripts/campaign.gd")
var checks=0
var failures=[]
var reports=[]
var out="C:/SourceCodes/WoolGame/Evidence/Rebuild/BlockExit/Stages"
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label);printerr("FAIL ",label)
func fresh(level: int) -> State:
	var s=State.new()
	s.reset(0,level,{"max_hearts":3 if level>=6 else 2 if level>=3 else 1,"shield":level>=2,"freeze":level>=7})
	return s
func depth(s: State,id: int,path: Array=[]) -> int:
	if path.has(id):return 1000
	var next=path.duplicate();next.append(id);var deepest=0
	for blocker in s.blockers(id):deepest=maxi(deepest,1+depth(s,blocker,next))
	return deepest
func exposed_counts(s: State) -> Dictionary:
	var counts={}
	for i in range(s.units.size()):
		if s.exposed(i):counts[s.units[i].color]=counts.get(s.units[i].color,0)+1
	for id in s.slots:
		if id>=0:counts[s.blocks[id].color]=counts.get(s.blocks[id].color,0)-s.blocks[id].remaining
	return counts
func ancestors(s: State,id: int,seen: Array=[]) -> Array:
	if seen.has(id):return []
	var path=seen.duplicate();path.append(id)
	if s.can_select(id):return [id]
	var result=[]
	for blocker in s.blockers(id):
		for candidate in ancestors(s,blocker,path):
			if not result.has(candidate):result.append(candidate)
	return result
func choose(s: State,style: int=0) -> int:
	var counts=exposed_counts(s);var best=-1;var score=-INF
	for b in s.blocks:
		if not s.can_select(b.id):continue
		var matching=int(counts.get(b.color,0))
		if matching<=0:continue
		var value=float(matching)/b.remaining
		if style==1:value=float(matching)-b.remaining*0.1
		if value>score:score=value;best=b.id
	if best>=0:return best
	# Open a blocked matching color while leaving room for its spool.
	if s.slots.count(-1)<2:return -1
	for b in s.blocks:
		if b.phase!="board" or counts.get(b.color,0)<=0:continue
		var candidates=ancestors(s,b.id)
		if not candidates.is_empty():return candidates[0]
	return -1
func simulate(level: int,interval: float,initial_delay: float=0.0,blocked_taps: int=0,style: int=0,off_color: bool=false) -> Dictionary:
	var s=fresh(level);var next=initial_delay;var actions=[];var max_slots=0;var mistakes=0
	var minimum_choices=1000;var choices_sum=0;var choices_samples=0;var off_color_id=-1
	var last_collected=0;var last_capture=0.0;var max_capture_gap=0.0
	var all_hidden_time=0.0;var max_all_hidden_time=0.0;var mixed_fog_time=0.0;var peak_fog_hidden=0;var first_hurt=-1.0
	if off_color:
		for b in s.blocks:
			if s.can_select(b.id) and not s.available(b.color):off_color_id=b.id
		if off_color_id>=0:
			check(s.select(off_color_id),"off-color legal choice %d"%level);actions.append({"time":0.0,"block":off_color_id,"off_color":true});next=interval
	while s.time<240.0 and not s.won and not s.lost:
		if s.time>=next:
			var candidates=0
			for b in s.blocks:
				if s.can_select(b.id):candidates+=1
			if candidates>0:minimum_choices=mini(minimum_choices,candidates);choices_sum+=candidates;choices_samples+=1
			if mistakes<blocked_taps:
				for b in s.blocks:
					if b.phase=="board" and not s.blockers(b.id).is_empty():
						check(not s.select(b.id),"blocked tap rejected %d"%level);mistakes+=1;break
			else:
				var id=choose(s,style)
				if id>=0:
					check(s.select(id),"selected legal %d"%level);actions.append({"time":snappedf(s.time,0.01),"block":id})
			next=s.time+interval
		max_slots=maxi(max_slots,4-s.slots.count(-1));s.advance(0.1)
		if first_hurt<0 and s.hearts<s.max_hearts:first_hurt=s.time
		if s.collected>last_collected:max_capture_gap=maxf(max_capture_gap,s.time-last_capture);last_capture=s.time;last_collected=s.collected
		if s.definition.fog and not s.units.is_empty():
			var exposed_now=0;var fog_hidden_now=0
			for i in range(s.units.size()):
				if s.exposed(i):exposed_now+=1
				elif s.unit_distance(i)>=0 and Rect2(0,20,592,397).has_point(s.unit_point(i)) and s.unit_point(i).y<s.fog_edge():fog_hidden_now+=1
			if exposed_now==0:all_hidden_time+=0.1;max_all_hidden_time=maxf(max_all_hidden_time,all_hidden_time)
			else:all_hidden_time=0.0
			if fog_hidden_now>0 and exposed_now>0:mixed_fog_time+=0.1
			peak_fog_hidden=maxi(peak_fog_hidden,fog_hidden_now)
	return {"interval":interval,"initial_delay":initial_delay,"blocked_taps":mistakes,"style":style,"off_color_id":off_color_id,"won":s.won,"lost":s.lost,"reason":s.loss_reason,"time":snappedf(s.time,0.01),"hearts":s.hearts,"coins":s.coins,"max_slots":max_slots,"minimum_legal_choices":minimum_choices,"mean_legal_choices":snappedf(float(choices_sum)/maxi(1,choices_samples),0.01),"actions":actions,"remaining_units":s.units.size(),"last_action_to_clear":snappedf(s.time-float(actions[-1].time),0.01) if not actions.is_empty() else -1,"max_capture_gap":snappedf(max_capture_gap,0.01),"max_all_yarn_hidden":snappedf(max_all_hidden_time,0.01),"mixed_fog_seconds":snappedf(mixed_fog_time,0.01),"peak_fog_hidden_yarn":peak_fog_hidden,"first_hurt":snappedf(first_hurt,0.01),"shield_used":s.shield_used,"freeze_used":s.freeze_used}
func run() -> void:
	for level in range(10):
		var s=fresh(level);var colors={};var capacities={};var directions={};var open=0;var productive=0;var maximum_depth=0;var dependency_edges=0
		for b in s.blocks:
			colors[b.color]=true;capacities[b.capacity]=true;directions[b.direction]=true
			check(b.color>=0 and b.color<6 and b.direction>=0 and b.direction<4,"valid token %d"%level)
			check(Rect2i(0,590,592,436).encloses(Rect2i(b.cell,b.size)),"inside board %d"%level)
			var dependencies=s.blockers(b.id);dependency_edges+=dependencies.size();maximum_depth=maxi(maximum_depth,depth(s,b.id))
			if dependencies.is_empty():
				open+=1
				if s.available(b.color):productive+=1
		check(s.blocks.size()==Campaign.COUNTS[level],"authored block count %d"%level)
		check(maximum_depth<1000 and s.witness.size()==s.blocks.size(),"acyclic exit graph %d"%level)
		var idle=fresh(level);var events={"first_flee":-1.0,"first_hurt":-1.0}
		idle.encounter.connect(func(kind):
			if kind=="flee" and events.first_flee<0:events.first_flee=snappedf(idle.time,0.01))
		idle.hurt.connect(func():
			if events.first_hurt<0:events.first_hurt=snappedf(idle.time,0.01))
		idle.advance(240)
		for c in idle.encounter.get_connections():idle.encounter.disconnect(c.callable)
		for c in idle.hurt.get_connections():idle.hurt.disconnect(c.callable)
		check(idle.lost,"idle eventually loses %d"%level)
		var runs=[]
		for interval in [1.2,2.4,3.2]:
			var result=simulate(level,interval);runs.append(result)
			check(result.won and result.coins==300,"tool free completion %.1fs level%d"%[interval,level+1])
			check(result.max_capture_gap<=8.0,"no long winding gap %.1fs level%d"%[interval,level+1])
		var distracted=simulate(level,2.4,8.0,3);runs.append(distracted)
		if level<4:check(distracted.won,"early distracted completion level%d"%[level+1])
		var mistaken=simulate(level,2.4,0,0,0,true);runs.append(mistaken)
		if level<4:check(mistaken.won,"early off-color completion level%d"%[level+1])
		var alternate=simulate(level,1.2,0,0,1);runs.append(alternate)
		check(alternate.won,"alternate order completion level%d"%[level+1])
		for result in runs:
			if result.won:check(result.last_action_to_clear<=6.0,"no excessive final automatic wait level%d"%[level+1])
			if level==6:
				check(result.max_all_yarn_hidden<=0.5,"first fog retains a visible choice")
				check(result.won and result.hearts==3,"first fog slow and mistaken play preserves hearts")
		if level==6:
			check(runs[1].max_capture_gap<=3.0,"reviewed first fog winding gap resolved")
			check(runs[1].mixed_fog_seconds>=5.0,"first fog still creates visible and concealed yarn choices")
		var report={"stage":level+1,"title":Campaign.TITLES[level],"lesson":Campaign.LESSONS[level],"blocks":s.blocks.size(),"colors":colors.size(),"capacities":capacities.keys(),"directions":directions.size(),"total_yarn":s.total,"initial_legal":open,"initial_productive":productive,"dependency_edges":dependency_edges,"dependency_depth":maximum_depth,"speed":s.speed,"fog":s.definition.fog,"fog_ceiling":s.fog_edge(),"dragons":s.dragons.size(),"route_length":snappedf(s.route_length,0.1),"no_input_first_flee":events.first_flee,"no_input_first_hurt":events.first_hurt,"no_input_loss":snappedf(idle.time,0.01),"runs":runs}
		reports.append(report);print("STAGE_MEASURE ",JSON.stringify(report))
	var original_seven=replay_original_seven()
	var file=FileAccess.open(out+"/development-measurements.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"godot_version":Engine.get_version_info().string,"verified_utc":Time.get_datetime_string_from_system(true),"harness_sha256":FileAccess.get_sha256("res://tests/verify_stage_progression.gd"),"campaign_sha256":FileAccess.get_sha256("res://scripts/campaign.gd"),"state_sha256":FileAccess.get_sha256("res://scripts/state.gd"),"scope":"Development simulation, not independent review or native play","original_seven_order_replay":original_seven,"stages":reports},"  "));file.close()
	print("STAGE_PROGRESSION ",checks-failures.size(),"/",checks)
	quit(0 if failures.is_empty() else 1)
func _initialize() -> void:call_deferred("run")

# Fixed pre-review fog110 / speed14.5 sequence; this replay never re-scores choices.
func replay_original_seven() -> Dictionary:
	var actions=[[0,0],[2.4,1],[4.9,2],[7.4,3],[9.9,4],[12.4,21],[14.9,9],[17.3,5],[19.7,6],[22.1,7],[24.5,8],[26.9,11],[29.3,12],[31.7,13],[34.2,14],[36.7,10],[39.2,17],[41.7,20],[44.2,19],[46.7,16],[49.2,23],[51.7,22],[61.7,15],[64.2,18]]
	var s=fresh(6);var cursor=0;var all_hidden=0.0;var max_hidden=0.0;var first_hurt=-1.0;var snapshots=[]
	while s.time<240 and not s.won and not s.lost:
		if cursor<actions.size() and s.time>=actions[cursor][0]:
			check(s.select(actions[cursor][1]),"original seven replay legal action "+str(cursor));cursor+=1
		s.advance(0.1)
		if first_hurt<0 and s.hearts<s.max_hearts:first_hurt=s.time
		var exposed=0
		for i in range(s.units.size()):
			if s.exposed(i):exposed+=1
		if not s.units.is_empty() and exposed==0:all_hidden+=0.1;max_hidden=maxf(max_hidden,all_hidden)
		else:all_hidden=0.0
		if s.time>=52 and s.time<=61 and int(round(s.time*10))%5==0:snapshots.append({"time":snappedf(s.time,0.01),"remaining_yarn":s.units.size(),"exposed_yarn":exposed,"hearts":s.hearts})
	check(s.won,"original seven selection order completes")
	check(max_hidden<=0.5,"original seven sequence never leaves all yarn hidden")
	return {"won":s.won,"lost":s.lost,"time":snappedf(s.time,0.01),"hearts":s.hearts,"first_hurt":snappedf(first_hurt,0.01),"shield_used":s.shield_used,"max_all_yarn_hidden":snappedf(max_hidden,0.01),"fixed_actions":actions,"former_problem_window":snapshots}
