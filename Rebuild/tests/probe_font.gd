extends SceneTree
func _initialize() -> void:
	var font=load("res://art/korean.res")
	print("AXES ",font.get_supported_variation_list())
	for value in ["0","1","2","3","4","5","6","7","8","9","소리 켬","화살표 앞을 먼저 비워 주세요","↻"]:
		print("MEASURE ",value)
		print(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,23))
	quit()
