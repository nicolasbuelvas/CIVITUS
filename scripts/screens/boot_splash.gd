class_name BootSplash
extends Control

const FLAG_FILE: String = "user://intro_viewed.flag"
static var force_play_intro: bool = false

@onready var godot_splash_layer: Control = $GodotSplashLayer
@onready var intro_video_layer: Control = $IntroVideoLayer
@onready var video_player: VideoStreamPlayer = $IntroVideoLayer/VideoStreamPlayer
@onready var skip_btn: Button = $IntroVideoLayer/SkipBtn
@onready var fade_overlay: ColorRect = $FadeOverlay

var is_skipping: bool = false

func _ready() -> void:
	# Check if this is a subsequent launch (not first time)
	if not force_play_intro and FileAccess.file_exists(FLAG_FILE):
		# From the 2nd time onwards: bypass Godot symbol and intro completely!
		get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
		return

	force_play_intro = false

	# First launch flow: Godot symbol -> Intro -> Main Menu
	intro_video_layer.visible = false
	godot_splash_layer.visible = true
	godot_splash_layer.modulate.a = 0.0
	fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)

	_run_first_boot_flow()

func _input(event: InputEvent) -> void:
	if is_skipping:
		return
	if intro_video_layer.visible:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_on_skip_pressed()
		elif event is InputEventScreenTouch and event.pressed:
			_on_skip_pressed()

func _run_first_boot_flow() -> void:
	# 1. Godot symbol splash: Fade in (0.45s) -> Hold (0.85s) -> Fade out (0.45s)
	var tween_in = create_tween()
	tween_in.tween_property(godot_splash_layer, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween_in.finished

	await get_tree().create_timer(0.85).timeout

	var tween_out = create_tween()
	tween_out.tween_property(godot_splash_layer, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween_out.finished

	godot_splash_layer.visible = false

	# 2. Intro sequence: Starts right after the Godot symbol disappears
	_start_intro_video()

func _start_intro_video() -> void:
	intro_video_layer.visible = true
	if video_player.stream:
		video_player.finished.connect(_on_intro_finished)
		video_player.play()
	else:
		_finish_intro_and_enter_game()

func _on_skip_pressed() -> void:
	if is_skipping:
		return
	is_skipping = true
	_finish_intro_and_enter_game()

func _on_intro_finished() -> void:
	if is_skipping:
		return
	_finish_intro_and_enter_game()

func _finish_intro_and_enter_game() -> void:
	# Save the flag so neither Godot icon nor intro ever plays on future runs
	var f = FileAccess.open(FLAG_FILE, FileAccess.WRITE)
	if f:
		f.store_string("1")
		f.close()

	# Smooth fade out to main menu
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD)
	await fade_tween.finished

	if video_player.is_playing():
		video_player.stop()

	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
