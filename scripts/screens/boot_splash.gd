class_name BootSplash
extends Control

const FLAG_FILE: String = "user://intro_viewed.flag"
const MAIN_MENU_PATH: String = "res://scenes/screens/main_menu.tscn"
static var force_play_intro: bool = false

@onready var godot_splash_layer: Control = $GodotSplashLayer
@onready var intro_video_layer: Control = $IntroVideoLayer
@onready var video_player: VideoStreamPlayer = $IntroVideoLayer/VideoStreamPlayer
@onready var skip_btn: Button = $IntroVideoLayer/SkipBtn
@onready var fade_overlay: ColorRect = $FadeOverlay

var is_skipping: bool = false

func _ready() -> void:
	# Initiate background threaded preload of Main Menu immediately
	ResourceLoader.load_threaded_request(MAIN_MENU_PATH, "PackedScene", true)

	# Check if this is a subsequent launch (not first time)
	if not force_play_intro and FileAccess.file_exists(FLAG_FILE):
		# From the 2nd time onwards: bypass Godot symbol and intro completely!
		_load_menu_instantly()
		return

	force_play_intro = false

	# First launch flow: Godot symbol -> Intro -> Main Menu
	intro_video_layer.visible = false
	godot_splash_layer.visible = true
	godot_splash_layer.modulate.a = 0.0
	fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

	if skip_btn:
		_style_skip_button()
		skip_btn.pressed.connect(_on_skip_pressed)

	_run_first_boot_flow()

func _style_skip_button() -> void:
	var is_es = false
	if GameManager:
		is_es = (GameManager.current_language == "es")
	skip_btn.text = "[ ⬡ OMITIR ]" if is_es else "[ ⬡ SKIP ]"
	skip_btn.add_theme_font_size_override("font_size", 12)
	
	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.02, 0.05, 0.10, 0.82)
	sb_norm.border_width_left = 1
	sb_norm.border_width_top = 1
	sb_norm.border_width_right = 1
	sb_norm.border_width_bottom = 1
	sb_norm.border_color = Color(0.2, 0.85, 1.0, 0.75)
	sb_norm.corner_radius_top_left = 4
	sb_norm.corner_radius_top_right = 4
	sb_norm.corner_radius_bottom_right = 4
	sb_norm.corner_radius_bottom_left = 4
	sb_norm.content_margin_left = 16
	sb_norm.content_margin_right = 16
	sb_norm.content_margin_top = 6
	sb_norm.content_margin_bottom = 6
	skip_btn.add_theme_stylebox_override("normal", sb_norm)
	
	var sb_hov = sb_norm.duplicate()
	sb_hov.bg_color = Color(0.05, 0.14, 0.24, 0.92)
	sb_hov.border_color = Color(0.4, 0.95, 1.0, 1.0)
	skip_btn.add_theme_stylebox_override("hover", sb_hov)
	skip_btn.add_theme_stylebox_override("pressed", sb_hov)
	skip_btn.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	skip_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

func _load_menu_instantly() -> void:
	var status = ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed = ResourceLoader.load_threaded_get(MAIN_MENU_PATH) as PackedScene
		if packed:
			get_tree().change_scene_to_packed(packed)
			return
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

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

	# Check threaded preload status - zero black screen delay
	var status = ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			status = ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH)

	var packed_menu = ResourceLoader.load_threaded_get(MAIN_MENU_PATH) as PackedScene

	# Seamless 0.15s cross-fade directly into the cached scene
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "color:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD)
	await fade_tween.finished

	if video_player.is_playing():
		video_player.stop()

	if packed_menu:
		get_tree().change_scene_to_packed(packed_menu)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
