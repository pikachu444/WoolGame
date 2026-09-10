extends Node2D
const State=preload("res://scripts/state.gd")
const Profile=preload("res://scripts/profile.gd")
var state=State.new()
var profile=Profile.new()
var screen="home"
var focus_suspended=false
var receipt: Dictionary={}
var run_id=""
var muted=false
var speed_multiplier=1.0
var tones: Array[AudioStreamPlayer]=[]
var tone_index=0
var demo=false
var demo_next=2.2
var capture_dir=""
var capture_times=[0.4,2.8,5.0,9.0,15.0,25.0,30.0]
var elapsed=0.0
var quit_at=0.0
var record_fps=0
var record_next=0.0
var record_frame=0
var performance_frames: Array[float]=[]

func _ready() -> void:
	get_tree().quit_on_go_back=false
	var args=OS.get_cmdline_user_args();var storage="user://campaign_v2.json";var requested_level=-1
	for i in range(args.size()):
		if args[i]=="--profile-dir" and i+1<args.size():
			DirAccess.make_dir_recursive_absolute(args[i+1]);storage=args[i+1].path_join("campaign_v2.json")
		elif args[i]=="--demo":demo=true
		elif args[i]=="--level" and i+1<args.size():requested_level=clampi(int(args[i+1]),0,9)
		elif args[i]=="--capture-dir" and i+1<args.size():capture_dir=args[i+1];DirAccess.make_dir_recursive_absolute(capture_dir)
		elif args[i]=="--quit-after" and i+1<args.size():quit_at=float(args[i+1])
		elif args[i]=="--record-fps" and i+1<args.size():record_fps=int(args[i+1])
	profile.open(storage);muted=profile.data.muted
	$World.state=state;$PuzzleBoard.state=state;$Interface.state=state
	state.reset(0,0,options());state.active=false
	state.captured.connect($World.capture)
	state.selected.connect($PuzzleBoard.on_selected)
	$PuzzleBoard.edge_tapped.connect(func():play_tone(290,0.06,0.07))
	state.selected.connect(func(_id):play_tone(540,0.055,0.075))
	state.captured.connect(func(_unit,b):play_tone(330*pow(1.12246,b.color),0.09,0.06))
	state.rejected.connect($Interface.notify)
	state.wallet_changed.connect(func(coins):profile.wallet(coins);check_storage())
	state.hurt.connect(func():play_tone(160,0.22,0.13))
	state.encounter.connect(func(kind):
		if kind=="shield":play_tone(660,0.3,0.09)
		elif kind=="freeze":play_tone(1100,0.2,0.07)
		elif kind=="warning":play_tone(220,0.12,0.08))
	state.rescued.connect(on_rescued)
	for i in range(6):
		var player=AudioStreamPlayer.new();add_child(player);tones.append(player)
	receipt=profile.current().pending.duplicate(true)
	navigate("result" if not receipt.is_empty() else "home")
	if requested_level>=0:start_stage(requested_level,true)
	elif demo:start_stage(int(profile.current().unlocked))
	check_storage()
	print("WOOL_READY profile=",storage," screen=",screen," level=",state.level_index+1," viewport=",get_viewport_rect().size)

func options() -> Dictionary:
	var value=profile.stats();value.mode=profile.data.mode;value.coins=int(profile.current().coins);return value

func check_storage() -> void:
	if not profile.last_error.is_empty():$Interface.notify(profile.last_error)

func start_stage(level: int,qa_override: bool=false) -> void:
	if level<0 or level>9 or (not qa_override and level>int(profile.current().unlocked)):return
	run_id=profile.start_run();receipt={};speed_multiplier=1.0
	state.reset(0,level,options());screen="play";state.active=true;focus_suspended=false
	$World.route=state.route_curve;$World.reset_visuals();$TextileBackdrop.apply_theme(state.level_index)
	$PuzzleBoard.reset_visuals();$Interface.toast_until=0;$Interface.reserve_page=0
	demo_next=state.time+2.2;sync_visibility();check_storage()

func navigate(page: String) -> void:
	screen=page;state.active=false;state.paused=false;focus_suspended=false;sync_visibility()

func sync_visibility() -> void:
	$World.visible=screen=="play";$PuzzleBoard.visible=screen=="play";$TextileBackdrop.visible=screen=="play"
	$Interface.key=""

func switch_mode(mode: String) -> void:
	profile.set_mode(mode);receipt=profile.current().pending.duplicate(true)
	navigate("result" if not receipt.is_empty() else "home");check_storage()

func on_rescued() -> void:
	# Persist the receipt at victory, before animation or navigation can be interrupted.
	receipt=profile.settle(run_id,state.level_index);state.coins=int(profile.current().coins)
	$World.celebrate();play_tone(880,0.4,0.08);check_storage()

func acknowledge_result() -> void:
	profile.acknowledge();receipt={};navigate("home");check_storage()

func continue_stage() -> void:
	if state.continue_run():$World.reset_visuals();$Interface.toast_until=0

func toggle_sound() -> void:
	muted=not muted;profile.data.muted=muted;profile.save();check_storage()

func back() -> void:
	if screen=="play" and not state.won and not state.lost:state.paused=not state.paused
	elif screen in ["collection","growth"]:navigate("home")
	elif screen=="result":acknowledge_result()
	elif screen=="play" and state.lost:navigate("home")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):back()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and not demo and screen=="play" and not state.won and not state.lost:
		# Background suspension must not replace the board with a clickable menu.
		focus_suspended=true;state.active=false;$PuzzleBoard.press_id=-1;$PuzzleBoard.cancelled=true
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN and focus_suspended:
		focus_suspended=false;state.active=screen=="play"
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:back()

func _process(dt: float) -> void:
	elapsed+=dt
	if screen=="play":
		state.advance(minf(dt,0.1)*speed_multiplier)
		if state.won and state.time-state.won_at>=2.0:navigate("result")
	if elapsed>2:performance_frames.append(dt)
	if demo and screen=="play" and state.playable() and state.time>=demo_next:
		var id=state.request_hint()
		if id>=0:state.select(id)
		demo_next=state.time+1.35
	if not capture_dir.is_empty():
		if record_fps>0 and elapsed>=record_next:
			record_next+=1.0/record_fps;record_frame+=1;capture.call_deferred("frame_%05d.png"%record_frame)
		elif record_fps==0 and not capture_times.is_empty() and elapsed>=capture_times[0]:
			var time=capture_times.pop_front();capture.call_deferred("game_%04.1fs.png"%time)
	if quit_at>0 and elapsed>=quit_at:quit_at=0;finish.call_deferred()

func play_tone(frequency: float, duration: float, volume: float) -> void:
	if muted: return
	var rate=22050
	var samples=int(rate*duration)
	var data=PackedByteArray(); data.resize(samples*2)
	for i in range(samples):
		var t=float(i)/rate
		var envelope=minf(t/0.008,1)*pow(maxf(0,1-t/duration),2)
		var value=(sin(TAU*frequency*t)+0.15*sin(TAU*frequency*2*t))*envelope*volume
		data.encode_s16(i*2,int(clampf(value,-1,1)*32760))
	var stream=AudioStreamWAV.new(); stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=rate; stream.data=data
	var player=tones[tone_index%tones.size()]; tone_index+=1; player.stream=stream; player.play()


func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join(filename))

func finish() -> void:
	var sum=0.0
	for value in performance_frames: sum+=value
	print("WOOL_RESULT ",JSON.stringify({"elapsed":elapsed,"collected":state.collected,"total":state.total,"hearts":state.hearts,"won":state.won,"won_at":state.won_at,"lost":state.lost,"avg_fps":performance_frames.size()/maxf(sum,0.01)}))
	await get_tree().process_frame
	get_tree().quit()
