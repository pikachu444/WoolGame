extends RefCounted

var path="user://campaign_v2.json"
var data: Dictionary={}
var last_error=""

func fresh_mode() -> Dictionary:
	return {"coins":300,"completed":[],"cards":[],"unlocked":0,"settled":{},"pending":{}}

func open(storage_path: String="user://campaign_v2.json") -> bool:
	path=storage_path
	data={"version":2,"revision":0,"next_run":1,"mode":"challenge","muted":false,"profiles":{"challenge":fresh_mode(),"free":fresh_mode()}}
	var found=false
	for candidate in [path,path+".tmp",path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var json=JSON.new()
		if json.parse(FileAccess.get_file_as_string(candidate))!=OK:continue
		var parsed=json.data
		if parsed is Dictionary and parsed.get("version",0)==2 and parsed.get("profiles",{}).has("challenge") and parsed.get("profiles",{}).has("free"):
			if not found or int(parsed.get("revision",0))>int(data.revision):data=parsed;found=true
	if not found:
		var legacy=ConfigFile.new()
		if legacy.load("user://progress.cfg")==OK:data.muted=bool(legacy.get_value("game","muted",false))
		return save()
	normalize_indices()
	return true

func normalize_indices() -> void:
	# JSON decodes numbers as float. Canonical integers keep membership stable after restart.
	for mode in ["challenge","free"]:
		var p=current(mode)
		for field in ["completed","cards"]:
			var indices: Array[int]=[]
			for value in p[field]:
				var index=int(value)
				if index>=0 and index<10 and not indices.has(index):indices.append(index)
			p[field]=indices

func save() -> bool:
	last_error="";data.revision=int(data.revision)+1
	var temporary=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if temporary==null:last_error="진행을 저장할 수 없어요";return false
	temporary.store_string(JSON.stringify(data));temporary.flush()
	var write_error=temporary.get_error();temporary.close()
	if write_error!=OK:last_error="진행을 저장할 수 없어요";return false
	if FileAccess.file_exists(path):DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".bak"))
	var error=DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
	if error!=OK:last_error="임시 저장에서 진행을 복구할 수 있어요"
	# A flushed temporary is recoverable; open chooses the newest complete revision.
	return true

func current(mode: String="") -> Dictionary:return data.profiles[data.mode if mode.is_empty() else mode]

func set_mode(mode: String) -> void:
	if mode not in ["challenge","free"]:return
	data.mode=mode;save()

func start_run() -> String:
	var id="%s-%d"%[data.mode,int(data.next_run)]
	data.next_run=int(data.next_run)+1;save();return id

func wallet(coins: int) -> void:current().coins=coins;save()

func stats(mode: String="") -> Dictionary:
	var completed=current(mode).completed
	return {"max_hearts":3 if completed.has(5) else 2 if completed.has(2) else 1,"shield":completed.has(1),"freeze":completed.has(6)}

func settle(run_id: String,level: int,mode: String="") -> Dictionary:
	var p=current(mode)
	if p.settled.has(run_id):return p.settled[run_id].duplicate(true)
	var first=not p.completed.has(level);var amount=50 if first else 20
	var receipt={"run_id":run_id,"level":level,"first":first,"coins":amount,"card":level if first else -1}
	p.coins=int(p.coins)+amount
	if first:p.completed.append(level);p.cards.append(level)
	p.unlocked=mini(9,maxi(int(p.unlocked),level+1));p.settled[run_id]=receipt;p.pending=receipt;save()
	return receipt.duplicate(true)

func acknowledge() -> void:current().pending={};save()
