extends Node2D
const WoolArt=preload("res://scripts/art.gd")
const Layout=preload("res://scripts/layout.gd")
const MapTheme=preload("res://scripts/map_theme.gd")
var level_index=0
func _ready() -> void:
 var mat=ShaderMaterial.new()
 mat.shader=preload("res://art/textile.gdshader")
 mat.set_shader_parameter("stage_bottom",Layout.STAGE_BOTTOM)
 mat.set_shader_parameter("dock_bottom",Layout.DOCK_BOTTOM)
 material=mat
func apply_theme(level: int) -> void:
 level_index=level;queue_redraw()
func _draw() -> void:
 var palette=MapTheme.for_level(level_index)
 draw_rect(Rect2(Vector2.ZERO,Layout.SIZE),Color(palette.board))
 draw_rect(Rect2(0,0,592,420),Color(palette.stage))
 draw_rect(Rect2(0,420,592,133),Color(palette.dock))
 draw_rect(Rect2(0,420,592,3),Color(palette.stage).lightened(0.30))
 for i in range(8):
  var r=Layout.slot_rect(i)
  WoolArt.box(self,r,Color(palette.well),5)
  draw_line(r.position+Vector2(5,1),r.position+Vector2(r.size.x-5,1),Color(palette.well).lightened(0.18),2,true)
