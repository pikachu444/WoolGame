extends SceneTree
const State=preload("res://scripts/state.gd")
const Profile=preload("res://scripts/profile.gd")
var passed=0
var failed=0
func check(value: bool,label: String) -> void:
	if value:passed+=1
	else:failed+=1;printerr("FAIL ",label)
func _initialize() -> void:
	var completed=[]
	for level in range(10):
		var s=State.new()
		s.reset(0,level,{"max_hearts":3 if level>=6 else 2 if level>=3 else 1,"shield":level>=2,"freeze":level>=7})
		check(s.blocks.size()>=12,"board size %d"%level)
		var next=0.2
		while s.time<200 and not s.won and not s.lost:
			if s.time>=next:
				# Test the authored escape sequence via normal validation, never delete units.
				for id in s.witness:
					if s.can_select(id) and s.available(s.blocks[id].color):s.select(id);break
				next=s.time+0.8
			s.advance(1.0/20.0)
		check(s.won and not s.lost,"tool-free completion %d (%s)"%[level,s.loss_reason])
		check(s.total==s.collected+s.units.size(),"conservation %d"%level)
		print("CAMPAIGN_LEVEL ",JSON.stringify({"level":level,"time":s.time,"won":s.won,"lost":s.lost,"reason":s.loss_reason,"hearts":s.hearts,"collected":s.collected,"total":s.total}))
	var s=State.new();s.reset()
	var before=s.hearts
	s.head=s.route_curve.get_closest_offset(s.cat_position)-50
	s.advance(0.1)
	check(s.cat_phase=="fleeing" and s.hearts==before,"flee does not damage")
	s.advance(0.8)
	check(s.cat_anchor_index==1 and s.cat_phase=="waiting","flee arrives")
	s.cat_anchor_index=2;s.cat_position=s.definition.anchors[2];s.head=s.route_curve.get_closest_offset(s.cat_position)-40
	s.advance(0.6)
	check(s.lost and s.hearts==0,"last anchor fire failure")
	var count=s.units.size();var progress=s.collected
	check(s.continue_run(),"continue accepted")
	check(s.units.size()==count and s.collected==progress and s.hearts==s.max_hearts,"continue conservation")
	var p=Profile.new();var path="user://campaign_test_%d.json"%Time.get_ticks_usec();p.open(path)
	var run=p.start_run();var result=p.settle(run,0)
	p.settle(run,0)
	check(p.current().coins==350 and p.current().cards.size()==1,"reward idempotent")
	p.set_mode("free");check(p.current().coins==300 and p.current().completed.is_empty(),"mode isolation")
	var loaded=Profile.new();loaded.open(path);check(loaded.current("challenge").coins==350,"reload reward")
	loaded.set_mode("challenge");loaded.settle(loaded.start_run(),0)
	check(loaded.current().coins==370 and loaded.current().cards.size()==1,"repeat reward remains twenty after JSON reload")
	loaded.settle(loaded.start_run(),2);var again=Profile.new();again.open(path)
	check(again.stats().max_hearts==2,"growth remains earned after JSON reload")
	for suffix in ["",".tmp",".bak"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("CAMPAIGN_VERIFY ",passed,"/",passed+failed)
	quit(0 if failed==0 else 1)
