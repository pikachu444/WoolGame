extends SceneTree

func add_directory(packer: PCKPacker,path: String) -> void:
	var folder=DirAccess.open(path)
	for name in folder.get_files():
		if name.get_extension() not in ["res","gd","gdshader","tscn","txt"]: continue
		var file=path.path_join(name)
		var error=packer.add_file(file,file)
		if error!=OK: push_error("Packing failed: "+file); quit(1); return
	for name in folder.get_directories(): add_directory(packer,path.path_join(name))

func _initialize() -> void:
	var args=OS.get_cmdline_user_args()
	if args.is_empty(): printerr("Output .pck path is required"); quit(1); return
	var packer=PCKPacker.new()
	if packer.pck_start(args[0])!=OK: printerr("Cannot create output pack"); quit(1); return
	packer.add_file("res://project.godot","res://project.godot")
	packer.add_file("res://.godot/global_script_class_cache.cfg","res://tests/export_class_cache.cfg")
	for folder in ["art","scenes","scripts"]: add_directory(packer,"res://"+folder)
	var result=packer.flush()
	print("PACK_RESULT ",result)
	quit(0 if result==OK else 1)
