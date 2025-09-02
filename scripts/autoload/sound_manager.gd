extends Node

# Audio bus names
const BUS_MASTER := "Master"
const BUS_MUSIC := "music"
const BUS_SFX := "sfx"
const BUS_UI := "ui"

# Maps for known sounds (graceful fallback if files are missing)
const SFX: Dictionary = {
	"click": "res://assets/audio/sfx/click.ogg",
	"buy_success": "res://assets/audio/sfx/buy_success.ogg",
	"buy_fail": "res://assets/audio/sfx/buy_fail.ogg",
	"achievement_unlock": "res://assets/audio/sfx/achievement_unlock.ogg",
	"ui_open": "res://assets/audio/sfx/ui_open.ogg",
	"ui_close": "res://assets/audio/sfx/ui_close.ogg",
}

# Caches
var sfx_cache: Dictionary = {}
var last_played_ms: Dictionary = {}

# Players
var sfx_pool: Array[AudioStreamPlayer] = []
var ui_player: AudioStreamPlayer

# Settings
const SFX_POOL_SIZE := 12
const THROTTLE_MS := 50

func _ready() -> void:
	_ensure_buses_exist()
	_init_players()
	_connect_signals()

func _ensure_buses_exist() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_UI)

func _ensure_bus(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		var new_index := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(new_index, bus_name)

func _init_players() -> void:
	# UI player (single)
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = BUS_UI
	add_child(ui_player)

	# SFX pool
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		p.autoplay = false
		sfx_pool.append(p)
		add_child(p)

func _connect_signals() -> void:
	if EventBus:
		EventBus.click_performed.connect(_on_click_performed)
		EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
		EventBus.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_click_performed(_amount: int) -> void:
	play_sfx("click", 0.05, 1.0)

func _on_upgrade_purchased(_upgrade_id: String) -> void:
	play_sfx("buy_success")

func _on_achievement_unlocked(_achievement_id: String) -> void:
	print("[SoundManager] Воспроизводим звук достижения для: ", _achievement_id)
	play_sfx("achievement_unlock", 0.0, 1.0)

func play_ui(name: String) -> void:
	# Lightweight UI sounds
	var stream := _get_stream(name)
	if stream == null:
		return
	ui_player.stop()
	ui_player.stream = stream
	ui_player.pitch_scale = 1.0
	ui_player.volume_db = 0.0
	ui_player.play()

func play_sfx(name: String, pitch_variation: float = 0.0, volume_linear: float = 1.0) -> void:
	if not SFX.has(name):
		return
	var now := Time.get_ticks_msec()
	var last := int(last_played_ms.get(name, 0))
	if last + THROTTLE_MS > now:
		return
	last_played_ms[name] = now

	var stream := _get_stream(name)
	if stream == null:
		return

	var p := _get_free_player()
	if p == null:
		return
	p.stream = stream
	p.pitch_scale = 1.0 + (randf() * 2.0 - 1.0) * pitch_variation
	p.volume_db = linear_to_db(clamp(volume_linear, 0.0, 1.0))
	p.play()

func _get_free_player() -> AudioStreamPlayer:
	for p in sfx_pool:
		if not p.playing:
			return p
	return sfx_pool[0]

func _get_stream(name: String) -> AudioStream:
	# Graceful fallback if file missing
	var cached: AudioStream = sfx_cache.get(name, null)
	if cached != null:
		return cached
	var path: String = String(SFX.get(name, ""))
	if path == "" or not FileAccess.file_exists(path):
		# No asset: skip silently in production, print in dev
		print("[SoundManager] Asset not found for '", name, "': ", path)
		return null
	var stream: AudioStream = load(path)
	sfx_cache[name] = stream
	return stream

func set_volume(bus: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(linear_value, 0.0, 1.0)))

func mute(bus: String, v: bool) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, v)
