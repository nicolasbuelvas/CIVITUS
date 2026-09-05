extends Node

var sounds: Dictionary = {}
var music_player: AudioStreamPlayer = null
var laser_player: AudioStreamPlayer = null

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
	load_sound("ambient_music", "res://assets/audio/music_space_ambient.wav")

	# Music player setup
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -6.0
	add_child(music_player)
	
	if sounds.has("ambient_music"):
		music_player.stream = sounds["ambient_music"]
		music_player.finished.connect(func(): music_player.play())
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
