extends Control
const Art=preload("res://scripts/art.gd")
const State=preload("res://scripts/state.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Layout=preload("res://scripts/layout.gd")
const MapTheme=preload("res://scripts/map_theme.gd")
var state: State
var app: Node
var clock=0.0
var toast=""
var toast_until=0.0
var key=""
var buttons: Dictionary={}
var reserve_page=0
var muted=false
var fast=false

func make_button(id: String,label: String,rect: Rect2,callback: Callable,size: int=22,primary: bool=false) -> Button:
	var b=Button.new();b.name=id;b.text=label;b.position=rect.position;b.size=rect.size
	b.add_theme_font_override("font",Art.FONT);b.add_theme_font_size_override("font_size",size)
	for name in ["font_color","font_hover_color","font_pressed_color"]:b.add_theme_color_override(name,Color("fffbed") if primary else Color("694b34"))
	b.add_theme_color_override("font_disabled_color",Color("aaa79c"))
	for name in ["normal","hover","pressed","focus","disabled"]:
		var box=StyleBoxFlat.new();box.bg_color=Color("82bd54") if primary else Color("fff0bf")
		if name=="pressed":box.bg_color=box.bg_color.darkened(0.12)
		if name=="hover":box.bg_color=box.bg_color.lightened(0.06)
		if name=="disabled":box.bg_color=Color("e0e2da")
		box.border_color=Color("aee081") if primary else Color("e6be73");box.set_border_width_all(2);box.set_corner_radius_all(15)
		box.shadow_color=Color(0.19,0.29,0.32,0.14);box.shadow_size=3;box.shadow_offset=Vector2(0,3)
		b.add_theme_stylebox_override(name,box)
	b.focus_mode=Control.FOCUS_NONE;b.pressed.connect(callback);add_child(b);buttons[id]=b;return b

func label_child(b: Control,text: String,p: Vector2,size: Vector2,font_size: int,color: Color) -> void:
	var label=Label.new();label.text=text;label.position=p;label.size=size;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font",Art.FONT);label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(label)

func icon(parent: Node,texture: Texture2D,region: Rect2,p: Vector2,size: Vector2) -> void:
	var atlas=AtlasTexture.new();atlas.atlas=texture;atlas.region=region
	var picture=TextureRect.new();picture.texture=atlas;picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_SCALE;picture.position=p;picture.size=size
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var mat=ShaderMaterial.new();mat.shader=preload("res://art/icon_chroma.gdshader");picture.material=mat;parent.add_child(picture);picture.set_deferred("size",size)

func _ready() -> void:
	app=get_parent();material=Art.material()

func notify(message: String) -> void:toast=message;toast_until=clock+3.2

func _process(dt: float) -> void:
	clock+=dt
	if state==null or app==null or app.profile.data.is_empty():return
	var next_key=app.screen+str(state.paused)+str(state.lost)+str(state.slots.size())+str(state.reserve)+str(reserve_page)+str(app.profile.data.mode)+str(app.profile.current().completed)+str(app.receipt)
	if key!=next_key:key=next_key;rebuild()
	if buttons.has("Speed"):buttons.Speed.text="» ×2" if app.speed_multiplier==2 else "» ×1"
	if buttons.has("Mute"):buttons.Mute.text="소리 끔" if app.muted else "소리 켬"
	queue_redraw()

func rebuild() -> void:
	for b in buttons.values():remove_child(b);b.queue_free()
	buttons.clear()
	if app.screen=="home":
		make_button("Challenge","도전 모드",Rect2(44,157,244,48),func():app.switch_mode("challenge"),20,app.profile.data.mode=="challenge")
		make_button("Free","자유 모드",Rect2(304,157,244,48),func():app.switch_mode("free"),20,app.profile.data.mode=="free")
		var next=int(app.profile.current().unlocked)
		make_button("Start","스테이지 %d 시작"%(next+1),Rect2(108,532,376,70),func():app.start_stage(next),27,true)
		for i in range(10):
			var level=i
			var done=app.profile.current().completed.has(i)
			var b=make_button("Level%d"%(i+1),("✓ " if done else "")+"%d  %s"%[i+1,Campaign.TITLES[i]],Rect2(44+(i%2)*260,651+(i/2)*68,244,53),func():app.start_stage(level),17,done)
			b.disabled=i>next
		make_button("Collection","모은 카드",Rect2(44,1042,244,58),func():app.navigate("collection"),21)
		make_button("Growth","고양이 성장",Rect2(304,1042,244,58),func():app.navigate("growth"),21)
	elif app.screen in ["collection","growth"]:
		make_button("Home","홈으로",Rect2(166,1057,260,57),func():app.navigate("home"),23,true)
	elif app.screen=="result":
		make_button("ResultHome","홈으로",Rect2(145,827,302,66),func():app.acknowledge_result(),25,true)
	elif app.screen=="play":
		if state.paused:
			make_button("Resume","계속하기",Rect2(158,548,276,58),func():state.paused=false,24,true)
			make_button("Retry","처음부터 다시",Rect2(158,618,276,52),func():app.start_stage(state.level_index),21)
			make_button("Home","홈으로",Rect2(158,682,276,52),func():app.navigate("home"),21)
			make_button("Mute","소리",Rect2(158,746,276,47),func():app.toggle_sound(),19)
		elif state.lost:
			make_button("Continue","이어하기 · "+("무료" if state.mode=="free" else "100 코인"),Rect2(126,615,340,61),func():app.continue_stage(),23,true)
			make_button("Retry","다시 도전 · 무료",Rect2(126,691,340,55),func():app.start_stage(state.level_index),22)
			make_button("Home","홈으로",Rect2(176,760,240,49),func():app.navigate("home"),20)
		else:
			var gear=make_button("Pause","",Rect2(18,74,58,58),func():state.paused=true)
			for style in ["normal","hover","pressed","focus"]:gear.add_theme_stylebox_override(style,StyleBoxEmpty.new())
			icon(gear,Art.DETAILS,Rect2(702,671,474,471),Vector2.ZERO,Vector2(58,58))
			make_button("Speed","» ×1",Rect2(501,78,70,43),func():app.speed_multiplier=2.0 if app.speed_multiplier==1 else 1.0,19)
			for i in range(4):
				if state.slots.size()>i+4:continue
				var unlock=make_button("Unlock%d"%i,"VIP" if i==0 else "해제",Layout.slot_rect(i+4),func():state.unlock_slot(),21)
				if i>0:
					for name in ["normal","hover","pressed","focus","disabled"]:
						var palette=MapTheme.for_level(state.level_index)
						var box=StyleBoxFlat.new();box.bg_color=Color(palette.well).lightened(0.10);box.border_color=Color(palette.dock).lightened(0.20);box.set_border_width_all(2);box.set_corner_radius_all(7);box.content_margin_left=4;box.content_margin_right=43;unlock.add_theme_stylebox_override(name,box)
					for name in ["font_color","font_hover_color","font_pressed_color"]:unlock.add_theme_color_override(name,Color.WHITE)
					var plus=Panel.new();plus.position=Vector2(95,1);plus.size=Vector2(36,36);plus.mouse_filter=Control.MOUSE_FILTER_IGNORE
					var style=StyleBoxFlat.new();style.bg_color=Color("55c333");style.set_corner_radius_all(7);plus.add_theme_stylebox_override("panel",style);unlock.add_child(plus)
					label_child(plus,"+",Vector2(0,-4),Vector2(36,40),30,Color.WHITE)
			var callbacks=[func():state.unlock_slot(),func():state.free_block(),func():state.sort_yarn(),func():state.strengthen()]
			var labels=["슬롯 추가","제거","정렬","강화"]
			var costs=[100,75,75,100]
			var icons=preload("res://art/booster_icons.res")
			for i in range(4):
				var b=make_button("Tool%d"%i,"",Rect2(28+i*141,1031,113,94),callbacks[i],18)
				var q=icons.get_size()/2
				icon(b,icons,Rect2(Vector2(i%2,i/2)*q,q),Vector2(12,-8),Vector2(89,82))
				label_child(b,labels[i],Vector2(0,62),Vector2(113,20),16,Color("6c5136"))
				label_child(b,"무료" if state.mode=="free" else "%d 코인"%costs[i],Vector2(0,81),Vector2(113,17),12,Color("866e54"))
				b.disabled=state.won
			if not state.reserve.is_empty():
				reserve_page=clampi(reserve_page,0,(state.reserve.size()-1)/7)
				make_button("ReservePrevious","‹",Rect2(9,556,34,34),func():reserve_page=maxi(0,reserve_page-1),23)
				make_button("ReserveNext","›",Rect2(549,556,34,34),func():reserve_page=mini((state.reserve.size()-1)/7,reserve_page+1),23)
				for i in range(7):
					var at=reserve_page*7+i
					if at>=state.reserve.size():break
					var id=state.reserve[at];var b=state.blocks[id]
					var button=make_button("Reserve%d"%id,str(b.remaining),Rect2(53+i*70,556,64,34),func():state.select(id),20)
					for style in ["normal","hover","pressed"]:
						var box=button.get_theme_stylebox(style).duplicate();box.bg_color=Art.COLORS[b.color].lightened(0.12);button.add_theme_stylebox_override(style,box)

func text(value: String,p: Vector2,size: int=22,color: Color=Color("6d513e")) -> void:Art.text(self,value,p,size,color)
func panel(rect: Rect2,color: Color=Color("fff5df")) -> void:Art.box(self,rect,color,24,Color("e6c890"),3)
func cat_art(center: Vector2,scale: float=1.0,happy: bool=true) -> void:
	draw_texture_rect_region(Art.CAST,Rect2(center-Vector2(45,56)*scale,Vector2(90,112)*scale),Rect2(712 if happy else 91,77,452,526))
func dragon_art(center: Vector2,scale: float=1.0) -> void:
	draw_texture_rect_region(Art.DETAILS,Rect2(center-Vector2(52,47)*scale,Vector2(104,94)*scale),Rect2(76,13,511,622))

func header(title: String,subtitle: String) -> void:
	text(title,Vector2(296,86),34)
	text(subtitle,Vector2(296,124),18,Color("7c8c84"))

func _draw() -> void:
	if state==null or app==null or app.profile.data.is_empty():return
	if app.screen!="play":
		draw_rect(Rect2(Vector2.ZERO,Layout.SIZE),Color("e4f0df"))
		for y in range(0,1138,8):draw_line(Vector2(0,y),Vector2(592,y),Color(1,1,1,0.12),1)
		for p in [Vector2(25,58),Vector2(540,194),Vector2(33,965)]:
			for i in range(5):draw_circle(p+Vector2.RIGHT.rotated(i*TAU/5)*14,9,Color("fff4c4"))
		var p=app.profile.current()
		var mode_name="도전 모드" if app.profile.data.mode=="challenge" else "자유 모드"
		if app.screen=="home":
			header("털실 구조대","고양이와 함께, 한 올씩")
			panel(Rect2(44,226,504,273),Color("f5f4dd"))
			var body=[Vector2(495,409),Vector2(486,373),Vector2(460,345),Vector2(423,335)]
			for i in range(body.size()):
				var toward=body[i+1] if i<body.size()-1 else Vector2(369,330)
				Art.stamp(self,Art.CUFF,body[i],Vector2(49,61),Art.COLORS[i],(toward-body[i]).angle()-PI/2)
			cat_art(Vector2(221,342+sin(clock*1.6)*3),1.30)
			dragon_art(Vector2(369,330+sin(clock*1.3)*4),1.4)
			text("%d / 10 구조 완료"%p.completed.size(),Vector2(296,471),20)
			text("%d 코인"%p.coins,Vector2(445,257),19,Color("af7827"))
			text("보상을 모아 도구를 써요" if app.profile.data.mode=="challenge" else "도구와 이어하기를 마음껏 써요",Vector2(296,631),17)
		elif app.screen=="collection":
			header("우리의 추억",mode_name+" · %d / 10장"%p.cards.size())
			for i in range(10):
				var r=Rect2(37+(i%2)*266,174+(i/2)*166,252,151)
				var unlocked=p.cards.has(i)
				panel(r,Art.COLORS[i%6].lightened(0.80) if unlocked else Color("dce3d7"))
				if unlocked:
					cat_art(r.get_center()+Vector2(-35,-15),0.60)
					dragon_art(r.get_center()+Vector2(39,-15),0.65)
				else:text("?",r.get_center()+Vector2(0,5),36,Color("9daa9d"))
				text(Campaign.CARDS[i] if unlocked else "%d 스테이지에서 만나요"%(i+1),r.position+Vector2(126,132),17)
		elif app.screen=="growth":
			header("고양이의 작은 용기",mode_name+"의 성장")
			cat_art(Vector2(296,260+sin(clock*2)*3),1.25)
			var stats=app.profile.stats()
			var names=["튼튼한 마음","빛나는 보호막","시원한 얼음꽃"]
			var details=["현재 하트 %d개"%stats.max_hearts,"5초 동안 보호한 뒤 용을 밀어내요","용이 다가오면 3초 동안 얼려요"]
			var notes=["3·6 스테이지 첫 구조로 하트가 늘어요","2 스테이지 첫 구조로 해금 · 판마다 한 번","7 스테이지 첫 구조로 해금 · 판마다 한 번"]
			for i in range(3):
				panel(Rect2(44,365+i*175,504,147))
				text(names[i],Vector2(221,407+i*175),25)
				var ready=i==0 or (stats.shield if i==1 else stats.freeze)
				text("사용 가능" if ready else "잠김",Vector2(467,406+i*175),16,Color("619743") if ready else Color("a39787"))
				text(details[i],Vector2(296,449+i*175),18)
				text(notes[i],Vector2(296,485+i*175),15,Color("928874"))
			text("해금 완료" if stats.freeze else "다음 구조가 새로운 힘이 돼요",Vector2(296,953),20)
		elif app.screen=="result":
			header("고양이를 구했어요!","스테이지 %d 완료"%(int(app.receipt.get("level",0))+1))
			panel(Rect2(69,199,454,587),Color("fff3d1"))
			cat_art(Vector2(246,330+sin(clock*3)*5),1.5)
			dragon_art(Vector2(389,334),0.85)
			text("+%d 코인"%int(app.receipt.get("coins",0)),Vector2(296,459),35,Color("b47d22"))
			if app.receipt.get("first",false):
				text("새로운 추억을 모았어요",Vector2(296,527),23)
				panel(Rect2(138,558,316,104),Color("ddefd3"))
				text(Campaign.CARDS[int(app.receipt.level)],Vector2(296,620),26)
			else:text("다시 지켜 줘서 고마워요",Vector2(296,565),23)
			if app.receipt.get("first",false):
				var growth={1:"보호막을 배웠어요!",2:"하트가 2개로 늘었어요!",5:"하트가 3개로 늘었어요!",6:"얼음꽃을 배웠어요!"}
				if growth.has(int(app.receipt.level)):text(growth[int(app.receipt.level)],Vector2(296,697),18,Color("679b45"))
			text("진행과 보상을 저장했어요" if app.profile.last_error.is_empty() else app.profile.last_error,Vector2(296,728),18,Color("8a8a74"))
	else:
		var header_color=Color(MapTheme.for_level(state.level_index).stage).darkened(0.10);header_color.a=0.80
		Art.box(self,Rect2(112,10,181,54),header_color,10)
		Art.outlined_text(self,"스테이지 %d / 10"%(state.level_index+1),Vector2(188,32),20)
		Art.outlined_text(self,state.definition.title,Vector2(190,56),17)
		Art.outlined_text(self,"%d 코인"%state.coins if state.mode=="challenge" else "자유 모드",Vector2(425,56),18)
		Art.outlined_text(self,"%d%%"%roundi(100.0*state.collected/maxi(1,state.total)),Vector2(37,411),17)
		if state.time<state.boost_until:text("강화 %d초"%ceili(state.boost_until-state.time),Vector2(444,151),20,Color("795725"))
		if state.reserve.is_empty() and state.time<8:text(str(state.definition.get("lesson","화살표 방향으로 꺼내 같은 색 실을 감아요")),Vector2(296,578),17,Color("668397"))
		if state.stalled_since>=0 and not state.lost:text("감길 색을 기다리고 있어요",Vector2(296,578),17,Color("ba613e"))
		if state.won:
			Art.box(self,Rect2(0,572,592,119),Color("9dde7e"),0,Color("519a37"),4)
			Art.outlined_text(self,"고양이를 구했어요",Vector2(296,647),35,Color.WHITE,Color("59853a"))
		if state.paused or state.lost:
			draw_rect(Rect2(Vector2.ZERO,Layout.SIZE),Color(0.11,0.19,0.23,0.52))
			panel(Rect2(83,327,426,526))
			cat_art(Vector2(296,403),0.83,not state.lost)
			text("잠깐 쉬어 가요" if state.paused else "한 번 더 지켜 줄까요?",Vector2(296,493),27)
			if state.lost:
				text(state.loss_reason,Vector2(296,541),17)
				text("이어하면 실은 보조 선반으로 옮겨져요",Vector2(296,578),16,Color("948270"))
	if clock<toast_until:
		var font_size=17
		while font_size>12 and Art.FONT.get_string_size(toast,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>528:font_size-=1
		var width=minf(556,Art.FONT.get_string_size(toast,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+28)
		Art.box(self,Rect2(296-width/2,930,width,51),Color(0.20,0.30,0.34,0.96),13)
		text(toast,Vector2(296,962),font_size,Color.WHITE)
