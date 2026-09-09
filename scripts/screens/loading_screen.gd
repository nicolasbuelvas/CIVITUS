extends Control

# Spinner Screen Nodes
@onready var spinner_container: Control = $SpinnerContainer
@onready var status_label: Label = $SpinnerContainer/StatusLabel
@onready var stage_label: Label = $SpinnerContainer/StageLabel
@onready var spinner_progress_bar: ProgressBar = $SpinnerContainer/ProgressBar

# Minigame Screen Nodes
@onready var minigame_container: Control = $MinigameContainer
@onready var backdrop: Control = $MinigameContainer/Backdrop
@onready var top_bar: Control = $MinigameContainer/TopBar
@onready var top_progress_label: Label = $MinigameContainer/TopBar/TopProgressLabel
@onready var top_progress_bar: ProgressBar = $MinigameContainer/TopBar/TopProgressBar
@onready var ready_btn: Button = $MinigameContainer/TopBar/ReadyBtn

@onready var lander_node: Control = $MinigameContainer/Lander
@onready var target_pad: Control = $MinigameContainer/LandingPad
@onready var pad_label: Label = $MinigameContainer/LandingPad/PadLabel

@onready var planet_name_label: Label = $MinigameContainer/HUD/PlanetNameLabel
@onready var altimeter_label: Label = $MinigameContainer/HUD/AltimeterLabel
@onready var speed_label: Label = $MinigameContainer/HUD/SpeedLabel
@onready var fuel_bar: ProgressBar = $MinigameContainer/HUD/FuelBar
@onready var score_label: Label = $MinigameContainer/HUD/ScoreLabel
@onready var skin_hint_label: Label = $MinigameContainer/HUD/SkinHintLabel

@onready var left_rcs_btn: BaseButton = $MinigameContainer/MobileControls/LeftRcsBtn
@onready var right_rcs_btn: BaseButton = $MinigameContainer/MobileControls/RightRcsBtn
@onready var main_burn_btn: BaseButton = $MinigameContainer/MobileControls/MainBurnBtn

# State & Thresholds
const MIN_LOADING_TIME: float = 5.0 # Exact 5-second mandatory world preparation period
var minigame_activated: bool = false
var elapsed_time: float = 0.0

var target_scene_path: String = "res://scenes/world/world.tscn"
var is_loading_complete: bool = false
var loaded_resource: PackedScene = null
var has_launched: bool = false

# Minigame Physics
var lander_pos: Vector2 = Vector2(640, 100)
var lander_vel: Vector2 = Vector2.ZERO
var lander_rot: float = 0.0
var lander_fuel: float = 100.0
var score: int = 0
var landings_count: int = 0

var gravity: float = 95.0
var main_thrust_power: float = 240.0
var rcs_torque: float = 3.2

var is_left_rcs: bool = false
var is_right_rcs: bool = false
var is_main_burn: bool = false

var screen_shake_intensity: float = 0.0
var thruster_sound_timer: float = 0.0
var sync_fallback_attempted: bool = false

func _ready() -> void:
	# Localized texts
	status_label.text = GameManager.loc("loading")
	stage_label.text = "1/4 " + GameManager.loc("stage_1")
	top_progress_label.text = GameManager.loc("loading")
	pad_label.text = GameManager.loc("platform")
	ready_btn.text = GameManager.loc("ready_to_land") # "Presionar aquí para empezar"
	ready_btn.visible = false
	skin_hint_label.text = GameManager.loc("points_skins_hint")
	
	# Initial visibility: Spinner screen visible, minigame strictly hidden
	spinner_container.visible = true
	minigame_container.visible = false
	
	# Layout responsive setup
	_update_layout()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	if backdrop:
		backdrop.set_planet_theme_from_data(GameManager.current_planet)
		planet_name_label.text = GameManager.current_planet.get("name", "Sector")
	
	_reset_lander()
	
	# Start background thread loading (file reading only - NO premature SceneTree adding!)
	ResourceLoader.load_threaded_request(target_scene_path)
	
	# Ambient Audio
	AudioManager.play("reentry", 1.0, -8.0)
	if AudioManager.has_method("play_gameplay_music"):
		AudioManager.play_gameplay_music(1.2)

func _on_viewport_size_changed() -> void:
	_update_layout()

func _update_layout() -> void:
	var vp_sz = get_viewport_rect().size
	var screen_w = max(1280.0, vp_sz.x)
	var screen_h = max(720.0, vp_sz.y)
	
	if target_pad:
		target_pad.position = Vector2((screen_w - target_pad.size.x) * 0.5, screen_h - 110.0)

func _reset_lander() -> void:
	var vp_sz = get_viewport_rect().size
	var screen_w = max(1280.0, vp_sz.x)
	lander_pos = Vector2(randf_range(screen_w * 0.25, screen_w * 0.75), 85.0)
	lander_vel = Vector2(randf_range(-25.0, 25.0), randf_range(10.0, 35.0))
	lander_rot = randf_range(-0.25, 0.25)
	lander_fuel = 100.0

func _process(delta: float) -> void:
	elapsed_time += delta
	_poll_loading_progress()
	
	if not minigame_activated:
		# Spinner 5-second progress bar
		var time_ratio = clamp(elapsed_time / MIN_LOADING_TIME, 0.0, 1.0)
		var simulated_p = time_ratio * 100.0
		if is_loading_complete and elapsed_time >= MIN_LOADING_TIME:
			simulated_p = 100.0
		spinner_progress_bar.value = simulated_p
		
		# Telemetry stages
		if simulated_p < 25.0:
			stage_label.text = "1/4 " + GameManager.loc("stage_1")
		elif simulated_p < 50.0:
			stage_label.text = "2/4 " + GameManager.loc("stage_2")
		elif simulated_p < 75.0:
			stage_label.text = "3/4 " + GameManager.loc("stage_3")
		else:
			stage_label.text = "4/4 " + GameManager.loc("stage_4")
			
		# At 5.0 seconds threshold:
		if elapsed_time >= MIN_LOADING_TIME:
			if is_loading_complete:
				# Fast load: Skip minigame completely and enter world directly!
				if not has_launched:
					has_launched = true
					_launch_gameplay()
			else:
				# Slower mobile load: Activate minigame to entertain player while background loading finishes
				_activate_minigame()
	else:
		_update_minigame_physics(delta)
		_update_minigame_ui()
		_update_screen_shake(delta)
		
		# Pulsing glow effect on start button
		if ready_btn and ready_btn.visible:
			var pulse = (sin(elapsed_time * 5.0) + 1.0) * 0.5
			ready_btn.modulate = Color(1.0, 1.0, 1.0).lerp(Color(0.85, 1.2, 0.95), pulse)

func _activate_minigame() -> void:
	minigame_activated = true
	spinner_container.visible = false
	minigame_container.visible = true
	
	if is_loading_complete:
		_on_load_finished()

func _poll_loading_progress() -> void:
	if is_loading_complete:
		return
		
	var progress: Array = []
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	var raw_percent: float = 0.0
	if progress.size() > 0:
		raw_percent = float(progress[0]) * 100.0
		
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		is_loading_complete = true
		loaded_resource = ResourceLoader.load_threaded_get(target_scene_path)
		_on_load_finished()
	elif status == ResourceLoader.THREAD_LOAD_FAILED or (elapsed_time >= 7.5 and not sync_fallback_attempted):
		sync_fallback_attempted = true
		print("[CIVITUS] Fallback synchronous load for: ", target_scene_path)
		loaded_resource = load(target_scene_path)
		if loaded_resource != null:
			is_loading_complete = true
			_on_load_finished()
			
	if minigame_activated and not is_loading_complete:
		top_progress_bar.value = raw_percent
		top_progress_label.text = "%s %d%%" % [GameManager.loc("loading_dots"), int(raw_percent)]

func _on_load_finished() -> void:
	if not minigame_activated:
		return
		
	top_progress_bar.value = 100.0
	top_progress_label.visible = false
	ready_btn.text = GameManager.loc("ready_to_land") # "Presionar aquí para empezar"
	ready_btn.visible = true
	AudioManager.play("docking", 1.1, -4.0)

func _update_minigame_physics(delta: float) -> void:
	var vp_sz = get_viewport_rect().size
	var screen_w = max(1280.0, vp_sz.x)
	
	var left = is_left_rcs or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right = is_right_rcs or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var burn = is_main_burn or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_SPACE)

	# RCS torque
	if left and lander_fuel > 0.0:
		lander_rot -= rcs_torque * delta
		lander_fuel = max(0.0, lander_fuel - 7.0 * delta)
		if lander_node.has_method("set_rcs"):
			lander_node.set_rcs(true, false)
	elif right and lander_fuel > 0.0:
		lander_rot += rcs_torque * delta
		lander_fuel = max(0.0, lander_fuel - 7.0 * delta)
		if lander_node.has_method("set_rcs"):
			lander_node.set_rcs(false, true)
	else:
		if lander_node.has_method("set_rcs"):
			lander_node.set_rcs(false, false)

	# Main burn
	if burn and lander_fuel > 0.0:
		var thrust_dir = Vector2(sin(lander_rot), -cos(lander_rot))
		lander_vel += thrust_dir * main_thrust_power * delta
		lander_fuel = max(0.0, lander_fuel - 20.0 * delta)
		if lander_node.has_method("set_thrust"):
			lander_node.set_thrust(true)
			
		thruster_sound_timer -= delta
		if thruster_sound_timer <= 0.0:
			thruster_sound_timer = 0.28
			AudioManager.play("thruster", randf_range(0.95, 1.05), -6.0)
	else:
		if lander_node.has_method("set_thrust"):
			lander_node.set_thrust(false)

	# Gravity and position
	lander_vel.y += gravity * delta
	lander_pos += lander_vel * delta

	# Boundaries
	lander_pos.x = clamp(lander_pos.x, 35.0, screen_w - 35.0)

	# Landing pad check
	var pad_y = target_pad.position.y
	var pad_center_x = target_pad.position.x + target_pad.size.x * 0.5
	var pad_half_w = target_pad.size.x * 0.5 + 24.0

	if lander_pos.y >= pad_y - 20.0:
		var speed = lander_vel.length()
		var is_on_pad = abs(lander_pos.x - pad_center_x) < pad_half_w
		var is_upright = abs(lander_rot) < 0.40

		if is_on_pad and speed < 65.0 and is_upright:
			score += int(150 + lander_fuel * 2.5)
			landings_count += 1
			AudioManager.play("docking", 1.0)
			
			if is_loading_complete and not has_launched:
				has_launched = true
				_launch_gameplay()
				return
				
			_switch_to_next_random_planet()
			_reset_lander()
		else:
			_trigger_crash()

	lander_node.position = lander_pos
	lander_node.rotation = lander_rot

func _trigger_crash() -> void:
	screen_shake_intensity = 16.0
	AudioManager.play("click", 0.5, 4.0)
	_reset_lander()

func _update_screen_shake(delta: float) -> void:
	if screen_shake_intensity > 0.1:
		screen_shake_intensity = lerp(screen_shake_intensity, 0.0, delta * 8.0)
		minigame_container.position = Vector2(
			randf_range(-screen_shake_intensity, screen_shake_intensity),
			randf_range(-screen_shake_intensity, screen_shake_intensity)
		)
	else:
		minigame_container.position = Vector2.ZERO

func _switch_to_next_random_planet() -> void:
	var planets = GameManager.current_solar_system.get("planets", [])
	if planets.size() > 1:
		var idx = randi() % planets.size()
		var p = planets[idx]
		backdrop.set_planet_theme_from_data(p)
		planet_name_label.text = p.get("name", "Sector")
	else:
		backdrop.generate_landscape(randi() % 100000)

func _update_minigame_ui() -> void:
	var alt = max(0.0, (target_pad.position.y - lander_pos.y) * 2.2)
	altimeter_label.text = "%s: %.0f m" % [GameManager.loc("altitude"), alt]
	
	var spd = lander_vel.length() * 0.5
	speed_label.text = "%s: %.1f m/s" % [GameManager.loc("speed"), spd]
	if spd > 32.0:
		speed_label.modulate = Color(1.0, 0.35, 0.35)
	else:
		speed_label.modulate = Color(0.35, 1.0, 0.45)

	fuel_bar.value = lander_fuel
	score_label.text = "%s: %d | %s: %d" % [GameManager.loc("points"), score, GameManager.loc("landings"), landings_count]

# Inputs
func _on_left_rcs_down() -> void: is_left_rcs = true
func _on_left_rcs_up() -> void: is_left_rcs = false
func _on_right_rcs_down() -> void: is_right_rcs = true
func _on_right_rcs_up() -> void: is_right_rcs = false
func _on_main_burn_down() -> void: is_main_burn = true
func _on_main_burn_up() -> void: is_main_burn = false

func _on_ready_btn_pressed() -> void:
	if is_loading_complete and not has_launched:
		has_launched = true
		AudioManager.play("click")
		_launch_gameplay()

func _launch_gameplay() -> void:
	if loaded_resource:
		get_tree().change_scene_to_packed(loaded_resource)
	else:
		get_tree().change_scene_to_file(target_scene_path)
