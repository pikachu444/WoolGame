extends Node2D
const WoolArt=preload("res://scripts/art.gd")
const Layout=preload("res://scripts/layout.gd")
func _ready() -> void:
	var mat=ShaderMaterial.new()
	mat.shader=preload("res://art/textile.gdshader")
	mat.set_shader_parameter("stage_bottom",Layout.STAGE_BOTTOM)
	mat.set_shader_parameter("dock_bottom",Layout.DOCK_BOTTOM)
	material=mat
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,Layout.SIZE),Color("bfdfed"))
	draw_rect(Rect2(0,0,592,420),Color("c3ddf2"))
	draw_rect(Rect2(0,420,592,133),Color("97b7d3"))
	draw_rect(Rect2(0,420,592,3),Color("e8f4fa"))
	for i in range(8):
		var r=Layout.slot_rect(i)
		WoolArt.box(self,r,Color("799cbf"),5)
		draw_line(r.position+Vector2(5,1),r.position+Vector2(r.size.x-5,1),Color("8babca"),2,true)
