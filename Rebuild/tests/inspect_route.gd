extends SceneTree
func _initialize():
	var s=load("res://scenes/game.tscn").instantiate()
	var c=s.get_node("World/DragonRoute").curve
	for r in [0.65,0.67,0.69,0.71,0.73]:print(r," ",c.sample_baked(c.get_baked_length()*r,true))
	s.free();quit()
