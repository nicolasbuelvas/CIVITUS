extends Node

var sounds: Dictionary = {}
var music_player: AudioStreamPlayer = null
var laser_player: AudioStreamPlayer = null

var current_music_track: String = ""
var default_music_volume_db: float = -6.0
var music_fade_tween: Tween = null
var fade_out_player: AudioStreamPlayer = null

func _ready() -> void:
	# Core SFX
	load_sound("hop", "res://assets/audio/sfx_hop.wav")
	load_sound("mine", "res://assets/audio/sfx_mine.wav")
	load_sound("collect", "res://assets/audio/sfx_collect.wav")
	load_sound("thruster", "res://assets/audio/sfx_thruster.wav")
	load_sound("click", "res://assets/audio/sfx_click.wav")
	
	# New Space Audio
	load_sound("craft", "res://assets/audio/sfx_craft.wav")
	load_sound("airlock", "res://assets/audio/sfx_airlock.wav")
	load_sound("hyperdrive", "res://assets/audio/sfx_hyperdrive_charge.wav")
	load_sound("laser", "res://assets/audio/sfx_laser_loop.wav")
	load_sound("jarvis", "res://assets/audio/sfx_jarvis.wav")
	load_sound("docking", "res://assets/audio/sfx_docking.wav")
	load_sound("reentry", "res://assets/audio/sfx_reentry.wav")
	load_sound("ambient_music", "res://assets/audio/music_space_ambient.wav")
	load_sound("music_menu_theme", "res://assets/audio/music_menu_theme.wav")

	# Convenient aliases for explicit music track resolution
	if sounds.has("music_menu_theme"):
		sounds["menu_music"] = sounds["music_menu_theme"]
	if sounds.has("ambient_music"):
		sounds["gameplay_music"] = sounds["ambient_music"]

	# Music player setup
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = default_music_volume_db
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	
	# Default to menu music if available, falling back to ambient gameplay music
	if sounds.has("music_menu_theme"):
		play_menu_music(0.0)
	elif sounds.has("ambient_music"):
		play_gameplay_music(0.0)

func _on_music_finished() -> void:
	if music_player and music_player.stream:
		music_player.play()

func load_sound(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		sounds[key] = load(path)

func play(key: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if sounds.has(key):
		var player = AudioStreamPlayer.new()
		player.stream = sounds[key]
		player.volume_db = volume_db
		player.pitch_scale = pitch_scale + randf_range(-0.05, 0.05)
		player.finished.connect(player.queue_free)
		add_child(player)
		player.play()

func play_menu_music(fade_duration: float = 1.0) -> void:
	var stream: AudioStream = sounds.get("music_menu_theme", null)
	if stream == null:
		stream = sounds.get("menu_music", null)
	if stream:
		_switch_music_track("menu", stream, fade_duration)

func play_gameplay_music(fade_duration: float = 1.0) -> void:
	var stream: AudioStream = sounds.get("gameplay_music", null)
	if stream == null:
		stream = sounds.get("ambient_music", null)
	if stream:
		_switch_music_track("gameplay", stream, fade_duration)

func stop_music(fade_duration: float = 0.5) -> void:
	current_music_track = ""
	if music_fade_tween and music_fade_tween.is_valid():
		music_fade_tween.kill()
		music_fade_tween = null
	if fade_out_player and is_instance_valid(fade_out_player):
		fade_out_player.stop()
		fade_out_player.queue_free()
		fade_out_player = null
	if fade_duration <= 0.0 or not music_player.playing:
		music_player.stop()
		return
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
	music_fade_tween.tween_callback(func():
		music_player.stop()
		music_player.volume_db = default_music_volume_db
	)

func _switch_music_track(track_name: String, new_stream: AudioStream, fade_duration: float = 1.0) -> void:
	if new_stream == null:
		return
	
	# If already playing this track and stream, avoid restarting
	if current_music_track == track_name and music_player and music_player.playing and music_player.stream == new_stream:
		return
	
	current_music_track = track_name
	
	# Clean up any in-flight crossfade tween
	if music_fade_tween and music_fade_tween.is_valid():
		music_fade_tween.kill()
		music_fade_tween = null
	
	if fade_out_player and is_instance_valid(fade_out_player):
		fade_out_player.stop()
		fade_out_player.queue_free()
		fade_out_player = null
	
	# If immediate switch or music was not actively playing
	if fade_duration <= 0.0 or not music_player.playing or music_player.stream == null:
		music_player.stream = new_stream
		music_player.volume_db = default_music_volume_db
		music_player.play()
		return
	
	# Graceful crossfade: transfer previous stream to temporary outgoing player
	fade_out_player = AudioStreamPlayer.new()
	fade_out_player.bus = music_player.bus
	fade_out_player.stream = music_player.stream
	fade_out_player.volume_db = music_player.volume_db
	add_child(fade_out_player)
	var playback_pos: float = music_player.get_playback_position()
	fade_out_player.play(playback_pos)
	
	# Start new track on main music_player from silent
	music_player.stream = new_stream
	music_player.volume_db = -80.0
	music_player.play()
	
	var outgoing: AudioStreamPlayer = fade_out_player
	music_fade_tween = create_tween().set_parallel(true)
	music_fade_tween.tween_property(outgoing, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	music_fade_tween.tween_property(music_player, "volume_db", default_music_volume_db, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	music_fade_tween.chain().tween_callback(func():
		if is_instance_valid(outgoing):
			outgoing.stop()
			outgoing.queue_free()
		if fade_out_player == outgoing:
			fade_out_player = null
	)

func set_music_volume_db(val_db: float) -> void:
	default_music_volume_db = val_db
	if music_player:
		music_player.volume_db = val_db

func get_current_music_track() -> String:
	return current_music_track

func start_laser_loop() -> void:
	if laser_player == null and sounds.has("laser"):
		laser_player = AudioStreamPlayer.new()
		laser_player.stream = sounds["laser"]
		laser_player.volume_db = -4.0
		add_child(laser_player)
		laser_player.play()

func stop_laser_loop() -> void:
	if laser_player != null:
		laser_player.stop()
		laser_player.queue_free()
		laser_player = null
