extends Node

var sounds: Dictionary = {}

func _ready() -> void:
	load_sound("hop", "res://assets/audio/sfx_hop.wav")
	load_sound("mine", "res://assets/audio/sfx_mine.wav")
	load_sound("collect", "res://assets/audio/sfx_collect.wav")
	load_sound("thruster", "res://assets/audio/sfx_thruster.wav")
	load_sound("click", "res://assets/audio/sfx_click.wav")

func load_sound(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		sounds[key] = load(path)

func play(key: String, pitch_scale: float = 1.0) -> void:
	if sounds.has(key):
		var player = AudioStreamPlayer.new()
		player.stream = sounds[key]
		player.pitch_scale = pitch_scale + randf_range(-0.06, 0.06)
		player.finished.connect(player.queue_free)
		add_child(player)
		player.play()
