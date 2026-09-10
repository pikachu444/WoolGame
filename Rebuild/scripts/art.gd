class_name WoolArt
extends RefCounted

const ATLAS = preload("res://art/characters.res")
const CUFF_IMAGE=preload("res://art/pointed_cuff.res")
const CUFF_SOURCE=Rect2(219,117,767,1082)
const CAST=preload("res://art/reference_cast.res")
const DETAILS=preload("res://art/reference_details.res")
const FONT = preload("res://art/korean.res")
const KEY = preload("res://art/chroma.gdshader")
const HEAD = Rect2(22, 15, 633, 602)
const CAT = Rect2(715, 53, 445, 565)
const CUFF = Rect2(24, 687, 586, 453)
const BLOCK = Rect2(710, 679, 481, 495)
const COLORS = [Color("f13b30"), Color("ffdd23"), Color("37d629"), Color("3299ff"), Color("a331f6"), Color("ff9823"), Color("21c8b4"), Color("e45ae1")]

static func material() -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = KEY
	return m

static func stamp(n: CanvasItem, region: Rect2, center: Vector2, size: Vector2, color: Color = Color.WHITE, angle: float = 0.0, mirrored: bool = false) -> void:
	n.draw_set_transform(center, angle,Vector2(-1,1) if mirrored else Vector2.ONE)
	n.draw_texture_rect_region(CUFF_IMAGE if region==CUFF else ATLAS, Rect2(-size / 2.0, size), CUFF_SOURCE if region==CUFF else region, color)
	n.draw_set_transform(Vector2.ZERO)

static func patch(n: CanvasItem, destination: Rect2, color: Color) -> void:
	# Nine-slice keeps the knit scale stable on one-, two- and three-cell blocks.
	var edge = minf(13.0, minf(destination.size.x, destination.size.y) * 0.24)
	var cut = 105.0
	var sx = [BLOCK.position.x, BLOCK.position.x + cut, BLOCK.end.x - cut, BLOCK.end.x]
	var sy = [BLOCK.position.y, BLOCK.position.y + cut, BLOCK.end.y - cut, BLOCK.end.y]
	var dx = [destination.position.x, destination.position.x + edge, destination.end.x - edge, destination.end.x]
	var dy = [destination.position.y, destination.position.y + edge, destination.end.y - edge, destination.end.y]
	for j in range(3):
		for i in range(3):
			var dest = Rect2(dx[i], dy[j], dx[i+1]-dx[i], dy[j+1]-dy[j])
			var src = Rect2(sx[i], sy[j], sx[i+1]-sx[i], sy[j+1]-sy[j])
			var nx = maxi(1, int(round(dest.size.x / 38.0))) if i == 1 else 1
			var ny = maxi(1, int(round(dest.size.y / 38.0))) if j == 1 else 1
			for ty in range(ny):
				for tx in range(nx):
					var cell = Rect2(dest.position + dest.size * Vector2(float(tx)/nx, float(ty)/ny), dest.size / Vector2(nx, ny))
					n.draw_texture_rect_region(ATLAS, cell, src, color)

static func box(n: CanvasItem, rect: Rect2, fill: Color, radius: float = 16.0, border: Color = Color.TRANSPARENT, width: float = 0.0) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(int(radius))
	style.border_color = border
	style.set_border_width_all(int(width))
	n.draw_style_box(style, rect)

static func text(n: CanvasItem, value: String, position: Vector2, size: int, color: Color, centered: bool = true) -> void:
	var p = position
	if centered: p.x -= FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	n.draw_string(FONT, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

static func arrow(n: CanvasItem, center: Vector2, direction: Vector2, length: float, color: Color = Color.WHITE) -> void:
	if length<0.8: return
	var unit=minf(length/45.0,1.0)
	var side = direction.orthogonal()
	var tip = center + direction * length * 0.5
	var tail = center - direction * length * 0.5
	var neck = tip - direction * 13.0*unit
	var p = PackedVector2Array([tail-side*4*unit, neck-side*4*unit, neck-side*11*unit, tip, neck+side*11*unit, neck+side*4*unit, tail+side*4*unit])
	var shadow = PackedVector2Array()
	for v in p: shadow.append(v + Vector2(0, 2.5))
	n.draw_colored_polygon(shadow, Color(0.13, 0.23, 0.29, 0.75))
	n.draw_colored_polygon(p, color)
	n.draw_polyline(PackedVector2Array([p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[0]]), Color(0.25,0.28,0.30,0.55),1.0,true)

static func outlined_text(n: CanvasItem,value: String,position: Vector2,size: int,color: Color=Color.WHITE,outline: Color=Color("493d4f")) -> void:
	var p=position-Vector2(FONT.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5,0)
	n.draw_string_outline(FONT,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,3,outline)
	n.draw_string(FONT,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
