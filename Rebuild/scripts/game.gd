extends Node2D
const WoolState = preload("res://scripts/state.gd")

var state = WoolState.new()
var muted=false
var speed_multiplier=1.0
var tones: Array[AudioStreamPlayer] = []
var tone_index=0
var demo=false
var demo_next=2.2
var capture_dir=""
var capture_times=[0.4,2.8,5.0,9.0,15.0,25.0,30.0]
var progress_captures=[82,85,92,95,99]
var elapsed=0.0
var quit_at=0.0
var record_fps=0
var record_next=0.0
var record_frame=0
var performance_frames: Array[float]=[]

func _ready() -> void:
	get_tree().quit_on_go_back=false
	$World.state=state; $PuzzleBoard.state=state; $Interface.state=state
	var preferences=ConfigFile.new()
	preferences.load("user://progress.cfg")
	muted=preferences.get_value("game","muted",false)
	$Interface.muted=muted
	state.route_curve=$World.route
	state.reset($World.route.get_baked_length(),int(preferences.get_value("game","level",0)))
	state.captured.connect($World.capture)
	state.selected.connect($PuzzleBoard.on_selected)
	state.selected.connect(func(_id): play_tone(540,0.055,0.075))
	state.captured.connect(func(_unit,b): play_tone(330*pow(1.12246,b.color),0.09,0.06))
	state.rejected.connect($Interface.notify)
	state.hurt.connect(func(): $Interface.notify("고양이를 지켜 주세요!"); play_tone(160,0.22,0.13))
	state.rescued.connect(func(): $World.celebrate(); play_tone(880,0.4,0.08))
	state.rescued.connect(func():
		if not capture_dir.is_empty():
			get_tree().create_timer(1.2).timeout.connect(func(): capture("success.png")))
	$Interface.speed_requested.connect(func(): speed_multiplier=2.0 if speed_multiplier==1 else 1.0; $Interface.fast=speed_multiplier==2)
	$Interface.restart_requested.connect(restart)
	$Interface.next_requested.connect(func():
		state.level_index=(state.level_index+1)%WoolState.LEVELS.size(); restart(); save_preferences())
	$Interface.pause_requested.connect(func(): state.paused=not state.paused)
	$Interface.hint_requested.connect(func():
		if state.request_hint()<0: $Interface.notify("실이 감기는 동안 잠깐 기다려 주세요"))
	$Interface.sound_requested.connect(func(): muted=not muted; $Interface.muted=muted; save_preferences())
	for i in range(6):
		var player=AudioStreamPlayer.new(); add_child(player); tones.append(player)
	var args=OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i]=="--demo": demo=true
		elif args[i]=="--capture-dir" and i+1<args.size(): capture_dir=args[i+1]; DirAccess.make_dir_recursive_absolute(capture_dir)
		elif args[i]=="--quit-after" and i+1<args.size(): quit_at=float(args[i+1])
		elif args[i]=="--record-fps" and i+1<args.size(): record_fps=int(args[i+1])
		elif args[i]=="--level" and i+1<args.size(): state.reset($World.route.get_baked_length(),int(args[i+1]))
		elif args[i]=="--case" and i+1<args.size():
			if args[i+1]=="pause": state.paused=true
			elif args[i+1]=="loss": state.hearts=1; state.head=state.route_length-85.01
	print("WOOL_READY route=",state.route_length," blocks=",state.blocks.size()," yarn=",state.total," viewport=",get_viewport_rect().size)

func restart() -> void:
	state.reset($World.route.get_baked_length(),state.level_index); $World.reset_visuals(); $Interface.toast_until=0
	$PuzzleBoard.press_id=-1; $PuzzleBoard.bounce.clear(); demo_next=state.time+2.2

func save_preferences() -> void:
	var config=ConfigFile.new()
	config.set_value("game","level",state.level_index)
	config.set_value("game","muted",muted)
	config.save("user://progress.cfg")

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

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not state.won and not state.lost: state.paused=not state.paused

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and not demo and not state.won and not state.lost: state.paused=true
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST and not state.won and not state.lost: state.paused=not state.paused

func _process(dt: float) -> void:
	elapsed+=dt
	state.advance(minf(dt,0.1)*speed_multiplier)
	if elapsed>2: performance_frames.append(dt)
	if demo and not state.paused and not state.won and not state.lost and state.time>=demo_next:
		# Demonstration uses the same public move validation as a real tap.
		var id=state.request_hint()
		if id>=0: state.select(id)
		demo_next=state.time+1.35
	if not capture_dir.is_empty():
		if not progress_captures.is_empty() and state.collected*100.0/maxi(1,state.total)>=progress_captures[0]:
			var milestone=progress_captures.pop_front();capture.call_deferred("progress_%02d.png"%milestone)
		if record_fps>0 and elapsed>=record_next:
			record_next+=1.0/record_fps; record_frame+=1
			capture.call_deferred("frame_%05d.png"%record_frame)
		elif record_fps==0 and not capture_times.is_empty() and elapsed>=capture_times[0]:
			var time=capture_times.pop_front(); capture.call_deferred("game_%04.1fs.png"%time)
	if quit_at>0 and elapsed>=quit_at:
		quit_at=0
		finish.call_deferred()

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join(filename))

func finish() -> void:
	var sum=0.0
	for value in performance_frames: sum+=value
	print("WOOL_RESULT ",JSON.stringify({"elapsed":elapsed,"collected":state.collected,"total":state.total,"hearts":state.hearts,"won":state.won,"won_at":state.won_at,"lost":state.lost,"avg_fps":performance_frames.size()/maxf(sum,0.01)}))
	await get_tree().process_frame
	get_tree().quit()
