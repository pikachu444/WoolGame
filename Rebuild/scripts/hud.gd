extends Control
const WoolArt=preload("res://scripts/art.gd")
const WoolState=preload("res://scripts/state.gd")
const Layout=preload("res://scripts/layout.gd")
signal restart_requested
signal pause_requested
signal hint_requested
signal sound_requested
signal next_requested
signal speed_requested
var state: WoolState
var muted=false
var fast=false
var toast=""
var toast_until=0.0
var clock=0.0
var menu_button: Button
var restart_button: Button
var hint_button: Button
var sound_button: Button
var speed_button: Button
var modal_primary: Button
var modal_restart: Button
var tool_buttons: Array[Button]=[]
var unlock_buttons: Array[Button]=[]

func make_button(label: String,rect: Rect2,callback: Callable,font_size: int=22) -> Button:
	var b=Button.new()
	b.text=label; b.position=rect.position; b.size=rect.size
	b.add_theme_font_override("font",WoolArt.FONT)
	b.add_theme_font_size_override("font_size",font_size)
	b.add_theme_color_override("font_color",Color("795326"))
	b.add_theme_color_override("font_hover_color",Color("795326"))
	b.add_theme_color_override("font_pressed_color",Color("795326"))
	for key in ["normal","hover","pressed","focus","disabled"]:
		var box=StyleBoxFlat.new()
		box.bg_color=Color("fff2b4") if key!="pressed" else Color("efcc74")
		box.border_color=Color("ecc167"); box.set_border_width_all(3); box.set_corner_radius_all(18)
		box.shadow_color=Color(0.29,0.38,0.40,0.18); box.shadow_size=2; box.shadow_offset=Vector2(0,3)
		b.add_theme_stylebox_override(key,box)
	b.focus_mode=Control.FOCUS_NONE; b.pressed.connect(callback); add_child(b)
	return b

func icon_rect(parent: Node,texture: Texture2D,region: Rect2,position: Vector2,size: Vector2) -> void:
	var atlas=AtlasTexture.new(); atlas.atlas=texture; atlas.region=region
	var image=TextureRect.new(); image.texture=atlas; image.position=position; image.size=size
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_SCALE;image.size=size
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var mat=ShaderMaterial.new();mat.shader=preload("res://art/icon_chroma.gdshader");image.material=mat
	parent.add_child(image)
	image.set_deferred("size",size)

func _ready() -> void:
	material=WoolArt.material()
	menu_button=make_button("",Rect2(22,74,65,58),func():pause_requested.emit())
	for key in ["normal","hover","pressed","focus"]:menu_button.add_theme_stylebox_override(key,StyleBoxEmpty.new())
	icon_rect(menu_button,WoolArt.DETAILS,Rect2(702,671,474,471),Vector2.ZERO,Vector2(65,58))
	speed_button=make_button("» ×1",Rect2(501,78,70,43),func():speed_requested.emit(),19)
	for i in range(4):
		var slot=i
		var unlock=make_button("VIP" if i==0 else "해제",Layout.slot_rect(i+4),func():
			if state.unlock_slot(): notify("실패 자리를 열었어요"),21)
		unlock_buttons.append(unlock)
		if i>0:
			for key in ["normal","hover","pressed","focus","disabled"]:
				var style=StyleBoxFlat.new(); style.bg_color=Color("81a4c2"); style.border_color=Color("adcce1"); style.set_border_width_all(2);style.set_corner_radius_all(7)
				style.content_margin_left=4;style.content_margin_right=43
				unlock.add_theme_stylebox_override(key,style)
			for key in ["font_color","font_hover_color","font_pressed_color","font_disabled_color"]:unlock.add_theme_color_override(key,Color.WHITE)
			unlock.alignment=HORIZONTAL_ALIGNMENT_CENTER
			var plus_art=Image.new()
			plus_art.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40"><rect x="1" y="1" width="38" height="38" rx="9" fill="#55c333" stroke="#a5e67a" stroke-width="2"/><path d="M20 9v22M9 20h22" stroke="white" stroke-width="6" stroke-linecap="round"/></svg>')
			var plus=TextureRect.new();plus.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;plus.texture=ImageTexture.create_from_image(plus_art);plus.position=Vector2(94,0);plus.mouse_filter=Control.MOUSE_FILTER_IGNORE;unlock.add_child(plus);plus.set_deferred("size",Vector2(39,40))
	var callbacks=[func():state.unlock_slot(),func():
		if not state.free_block():notify("감기가 끝나면 다시 눌러 주세요"),func():state.sort_yarn();hint_requested.emit(),func():state.strengthen()]
	var names=["잠금해제","제거","정렬","강화"]
	var icons=load("res://art/booster_icons.res") if FileAccess.file_exists("res://art/booster_icons.res") else null
	for i in range(4):
		var b=make_button("",Rect2(34+i*138,1042,113,84),callbacks[i],16)
		tool_buttons.append(b)
		if icons!=null:
			var quadrant=icons.get_size()/2
			icon_rect(b,icons,Rect2(Vector2(i%2,i/2)*quadrant,quadrant),Vector2(6,-11),Vector2(101,95))
		var label=Label.new();label.text=names[i];label.position=Vector2(0,62);label.size=Vector2(113,19);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font",WoolArt.FONT);label.add_theme_font_size_override("font_size",16)
		label.add_theme_color_override("font_color",Color("6c5136"));label.add_theme_color_override("font_outline_color",Color("fff7d4"));label.add_theme_constant_override("outline_size",2)
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(label)
		var plus_image=Image.new()
		plus_image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28"><circle cx="14" cy="14" r="12" fill="#42c950" stroke="#b9eea3" stroke-width="2"/><path d="M14 8v12m-6-6h12" stroke="white" stroke-width="3" stroke-linecap="round"/></svg>')
		var plus=TextureRect.new();plus.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;plus.texture=ImageTexture.create_from_image(plus_image);plus.position=Vector2(95,-6);plus.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(plus);plus.set_deferred("size",Vector2(25,25))

	hint_button=tool_buttons[2]
	modal_primary=make_button("계속하기",Rect2(176,546,240,56),func():
		if state.won:next_requested.emit()
		elif state.lost:restart_requested.emit()
		else:pause_requested.emit(),22)
	modal_restart=make_button("다시 시작",Rect2(176,611,240,49),func():restart_requested.emit(),20)
	restart_button=modal_restart
	sound_button=make_button("소리 켬",Rect2(176,672,240,45),func():sound_requested.emit(),18)
	modal_primary.visible=false; modal_restart.visible=false; sound_button.visible=false

func notify(message: String) -> void:
	toast=message;toast_until=clock+2.5

func _process(dt: float) -> void:
	clock+=dt
	if state==null:return
	var modal=state.paused or state.lost
	var success_next=state.won and state.time-state.won_at>2.5
	modal_primary.visible=modal or success_next;modal_primary.position=Vector2(176,757 if state.won else 546);modal_restart.visible=state.paused;sound_button.visible=state.paused
	menu_button.visible=not modal;speed_button.visible=not modal
	for b in tool_buttons:b.visible=not modal;b.disabled=state.won
	for i in range(4):unlock_buttons[i].visible=not modal and state.slots.size()<=i+4
	modal_primary.text=("다음 퍼즐" if state.level_index<2 else "다시 놀기") if state.won else "다시 도전" if state.lost else "계속하기"
	sound_button.text="소리 끔" if muted else "소리 켬"
	speed_button.text="» ×2" if fast else "» ×1"
	queue_redraw()

func heart(center: Vector2,active: bool) -> void:
	var texture=WoolArt.DETAILS
	var tint=Color.WHITE if active else Color("7d91a4")
	draw_texture_rect_region(texture,Rect2(center-Vector2(13,13),Vector2(26,26)),Rect2(701,166,472,365),tint)

func _draw() -> void:
	if state==null:return
	WoolArt.outlined_text(self,"레벨 %d"%(41+state.level_index),Vector2(56,159),17,Color("fff5e6"),Color("925f64"))
	for i in range(3):heart(Vector2(349+i*28,217),i<state.hearts)
	WoolArt.outlined_text(self,"%d%%"%roundi(100.0*state.collected/maxi(1,state.total)),Vector2(39,411),17)
	if clock<toast_until:
		var width=WoolArt.FONT.get_string_size(toast,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x+30
		WoolArt.box(self,Rect2(296-width/2,564,width,40),Color(0.20,0.30,0.40,0.92),14)
		WoolArt.text(self,toast,Vector2(296,591),19,Color.WHITE)
	if state.won and state.time-state.won_at>0.35:
		draw_success_banner()
	if state.paused or state.lost:
		draw_rect(Rect2(Vector2.ZERO,Layout.SIZE),Color(0.14,0.24,0.36,0.30))
		WoolArt.box(self,Rect2(115,393,362,344 if state.paused else 237),Color("fff3d2"),25,Color("edc77e"),3)
		var title="잠깐 쉬어 갈까요" if state.paused else "고양이를 구했어요!" if state.won else "한 번 더 해볼까요?"
		WoolArt.text(self,title,Vector2(296,459),27,Color("806044"))
		WoolArt.text(self,"준비되면 이어서 놀아요" if state.paused else "모든 실을 차곡차곡 감았어요" if state.won else "빈 실패와 같은 색을 확인해 보세요",Vector2(296,504),18,Color("968471"))

func draw_success_banner() -> void:
	draw_rect(Rect2(0,577,592,131),Color(0.22,0.48,0.23,0.20))
	draw_rect(Rect2(0,571,592,133),Color("9dde7e"))
	draw_rect(Rect2(0,571,592,7),Color("3f922a"))
	draw_rect(Rect2(0,698,592,7),Color("3f922a"))
	draw_rect(Rect2(0,579,592,3),Color("cbf2a9"))
	draw_rect(Rect2(0,692,592,3),Color("cbf2a9"))
	for x in range(0,592,11):
		draw_line(Vector2(x,587),Vector2(x+6,587),Color("85c86a"),1,true)
		draw_line(Vector2(x,687),Vector2(x+6,687),Color("85c86a"),1,true)
		for y in range(596,683,9):
			draw_polyline(PackedVector2Array([Vector2(x,y),Vector2(x+3,y+3),Vector2(x+6,y)]),Color(1,1,1,0.055),1,true)
	for p in [Vector2(35,668),Vector2(536,667)]:
		draw_circle(p,11,Color("86cc6e"))
		for i in range(4):draw_circle(p+Vector2(-14+i*9,-14-5*sin(i*PI/3)),4,Color("86cc6e"))
	WoolArt.outlined_text(self,"고양이를 구했어요",Vector2(296,656),36,Color.WHITE,Color("59853a"))
