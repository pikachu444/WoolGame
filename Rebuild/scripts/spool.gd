extends Node2D
const Art=preload("res://scripts/art.gd")
const Layout=preload("res://scripts/layout.gd")
var index=0
func _ready() -> void:
	var mat=ShaderMaterial.new();mat.shader=preload("res://art/spool.gdshader");material=mat
func _process(_dt: float) -> void:
	var state=get_parent().state
	visible=state!=null and index<state.slots.size() and state.slots[index]>=0
	if not visible:return
	var b=state.blocks[state.slots[index]]
	visible=b.phase!="travel"
	material.set_shader_parameter("opacity",clampf((b.finish-state.time)/state.clear_duration,0,1) if b.phase=="clearing" else 1.0)
	position=Layout.slot_center(index)
	var span=65.0 if b.capacity<=4 else 83.0 if b.capacity<=6 else 129.0
	material.set_shader_parameter("span",span)
	material.set_shader_parameter("fill",clampf(1-float(b.remaining)/b.capacity,0,1))
	material.set_shader_parameter("yarn_color",Art.COLORS[b.color])
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-70,-25,140,52),Color.WHITE)
