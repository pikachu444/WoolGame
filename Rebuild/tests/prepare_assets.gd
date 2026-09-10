extends SceneTree

func _initialize() -> void:
	var source=Image.load_from_file("res://art/characters_keyed.png")
	var atlas=ImageTexture.create_from_image(source)
	var font=FontFile.new()
	font.data=FileAccess.get_file_as_bytes("res://art/NotoSansKR-Medium.ttf" if FileAccess.file_exists("res://art/NotoSansKR-Medium.ttf") else "res://art/NotoSansKR.ttf")
	font.allow_system_fallback=false
	var face=FontVariation.new()
	face.base_font=font
	face.variation_opentype={"wght":500.0}
	var first=ResourceSaver.save(atlas,"res://art/characters.res",ResourceSaver.FLAG_COMPRESS)
	var second=ResourceSaver.save(face,"res://art/korean.res",ResourceSaver.FLAG_COMPRESS)
	if FileAccess.file_exists("res://art/spool_keyed.png"):
		var spool=ImageTexture.create_from_image(Image.load_from_file("res://art/spool_keyed.png"))
		ResourceSaver.save(spool,"res://art/spool.res",ResourceSaver.FLAG_COMPRESS)
	for name in ["dragon_profile","booster_icons","rounded_cuff","reference_cast","pointed_cuff","reference_details","memory_cards_v1"]:
		if FileAccess.file_exists("res://art/"+name+".png"):
			ResourceSaver.save(ImageTexture.create_from_image(Image.load_from_file("res://art/"+name+".png")),"res://art/"+name+".res",ResourceSaver.FLAG_COMPRESS)
	print("ASSETS_READY ",first," ",second)
	quit(0 if first==OK and second==OK else 1)
