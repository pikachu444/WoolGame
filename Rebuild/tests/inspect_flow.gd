extends SceneTree
func _initialize():
	var g=load("res://scenes/game.tscn").instantiate();var s=load("res://scripts/state.gd").new();s.route_curve=g.get_node("World/DragonRoute").curve;s.reset(s.route_curve.get_baked_length());g.free()
	var next=2.2;var snap=0.0
	for i in range(60*100):
		s.advance(1.0/60)
		if s.time>=next:
			var id=s.request_hint()
			if id>=0:s.select(id)
			next=s.time+1.35
		if s.time>=snap:
			var available=[]
			for c in range(6):if s.available(c):available.append(c)
			print(s.time," ",s.collected," ",s.has_lower_yarn()," colors ",available," slots ",s.slots)
			snap+=3
		if s.won or s.lost:break
	quit()
