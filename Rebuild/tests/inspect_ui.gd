extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var game=load("res://scenes/game.tscn").instantiate();root.add_child(game)
	await process_frame
	await process_frame
	for b in game.get_node("Interface").tool_buttons:
		print("BUTTON ",b.position," ",b.size)
		for c in b.get_children():print(c.get_class()," position=",c.position," size=",c.size," min=",c.get_combined_minimum_size())
	quit()
