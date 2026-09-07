extends Control

@onready var spinner_container: Control = $SpinnerContainer
@onready var spinner: Control = $SpinnerContainer/Spinner
@onready var status_label: Label = $SpinnerContainer/StatusLabel
@onready var stage_label: Label = $SpinnerContainer/StageLabel
@onready var progress_bar: ProgressBar = $SpinnerContainer/ProgressBar
@onready var spinner_action_btn: Button = $SpinnerContainer/SpinnerActionBtn

@onready var minigame_container: Control = $MinigameContainer
@onready var backdrop: Control = $MinigameContainer/Backdrop
@onready var lander_node: Control = $MinigameContainer/Lander
@onready var flame_main: Control = $MinigameContainer/Lander/MainFlame
@onready var flame_left: Control = $MinigameContainer/Lander/LeftFlame
@onready var flame_right: Control = $MinigameContainer/Lander/RightFlame
@onready var target_pad: Control = $MinigameContainer/LandingPad
@onready var altimeter_label: Label = $MinigameContainer/HUD/AltimeterLabel
@onready var speed_label: Label = $MinigameContainer/HUD/SpeedLabel
@onready var fuel_bar: ProgressBar = $MinigameContainer/HUD/FuelBar
@onready var score_label: Label = $MinigameContainer/HUD/ScoreLabel
@onready var planet_name_label: Label = $MinigameContainer/HUD/PlanetNameLabel
@onready var action_btn: Button = $BottomBar/ActionBtn
@onready var bottom_bar: Control = $BottomBar
@onready var minigame_title: Label = $MinigameTitle
@onready var minigame_sub: Label = $MinigameSub

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

var target_scene_path: String = "res://scenes/world/world.tscn"
var is_loading_complete: bool = false
var loaded_resource: PackedScene = null

var elapsed_time: float = 0.0
# International UX standard: 4.5 to 5.0 seconds threshold before showing interactive minigame
const MINIGAME_DISPLAY_THRESHOLD: float = 4.5
var minigame_activated: bool = false

func _ready() -> void:
	# Localization
	status_label.text = GameManager.loc("loading")
	stage_label.text = GameManager.loc("stage_1")
	action_btn.text = GameManager.loc("loading_dots") + "..."
	action_btn.disabled = true
	spinner_action_btn.visible = false
	
	minigame_title.text = GameManager.loc("minigame_title")
	minigame_sub.text = GameManager.loc("minigame_sub")
	
	# Initial visibility: Show clean spinner first, minigame hidden
	spinner_container.visible = true
	minigame_container.visible = false
	bottom_bar.visible = false
	minigame_title.visible = false
	minigame_sub.visible = false
	
	# Initialize 2D procedural backdrop with current planet
	if backdrop:
		backdrop.set_planet_theme_from_data(GameManager.current_planet)
		planet_name_label.text = GameManager.current_planet.get("name", "Sector")
		
	ResourceLoader.load_threaded_request(target_scene_path)
	_reset_lander()
	AudioManager.play("reentry", 1.0, -8.0)
	if AudioManager.has_method("play_gameplay_music"):
		AudioManager.play_gameplay_music(1.2)

func _reset_lander() -> void:
	lander_pos = Vector2(randf_range(320, 960), 75)
	lander_vel = Vector2(randf_range(-25, 25), randf_range(10, 35))
	lander_rot = randf_range(-0.25, 0.25)
	lander_fuel = 100.0

func _process(delta: float) -> void:
	elapsed_time += delta
	_poll_loading_progress()
	
	# Transition to minigame if loading exceeds international threshold (4.5s)
	if not minigame_activated and not is_loading_complete and elapsed_time >= MINIGAME_DISPLAY_THRESHOLD:
		_activate_minigame()
		
	if minigame_activated:
		_update_minigame_physics(delta)
		_update_minigame_ui()

func _activate_minigame() -> void:
	minigame_activated = true
	spinner_container.visible = false
	minigame_container.visible = true
	bottom_bar.visible = true
	minigame_title.visible = true
	minigame_sub.visible = true

func _poll_loading_progress() -> void:
	var progress: Array = []
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	var p_val: float = progress[0] * 100.0 if progress.size() > 0 else 25.0
	
	# Dynamic simulated phases for smooth feedback
	var simulated_p = min(100.0, max(p_val, (elapsed_time / 3.0) * 85.0))
	if is_loading_complete:
		simulated_p = 100.0
		
	progress_bar.value = simulated_p
	
	if simulated_p < 25.0:
		stage_label.text = "1/4 " + GameManager.loc("stage_1")
	elif simulated_p < 55.0:
		stage_label.text = "2/4 " + GameManager.loc("stage_2")
	elif simulated_p < 85.0:
		stage_label.text = "3/4 " + GameManager.loc("stage_3")
	else:
		stage_label.text = "4/4 " + GameManager.loc("stage_4")
		
	if status == ResourceLoader.THREAD_LOAD_LOADED and not is_loading_complete:
		is_loading_complete = true
		loaded_resource = ResourceLoader.load_threaded_get(target_scene_path)
		
		# If completed before minigame threshold, present sleek continue affordance
		if not minigame_activated:
			stage_label.text = "4/4 " + GameManager.loc("continue_btn")
			progress_bar.value = 100.0
			spinner_action_btn.text = GameManager.loc("continue_btn")
			spinner_action_btn.visible = true
		else:
			action_btn.text = GameManager.loc("continue_btn")
			action_btn.disabled = false

func _update_minigame_physics(delta: float) -> void:
	# User controls (Keyboard or touch)
	var left = is_left_rcs or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right = is_right_rcs or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var burn = is_main_burn or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_SPACE)

	if left and lander_fuel > 0.0:
		lander_rot -= rcs_torque * delta
		lander_fuel = max(0.0, lander_fuel - 8.0 * delta)
		flame_right.visible = true
	else:
		flame_right.visible = false

	if right and lander_fuel > 0.0:
		lander_rot += rcs_torque * delta
		lander_fuel = max(0.0, lander_fuel - 8.0 * delta)
		flame_left.visible = true
	else:
		flame_left.visible = false

	if burn and lander_fuel > 0.0:
		var thrust_dir = Vector2(sin(lander_rot), -cos(lander_rot))
		lander_vel += thrust_dir * main_thrust_power * delta
		lander_fuel = max(0.0, lander_fuel - 22.0 * delta)
		flame_main.visible = true
	else:
		flame_main.visible = false

	# Gravity & velocity
	lander_vel.y += gravity * delta
	lander_pos += lander_vel * delta

	# Boundaries
	lander_pos.x = clamp(lander_pos.x, 80.0, 1200.0)

	# Check Landing
	var pad_y = target_pad.position.y
	if lander_pos.y >= pad_y - 20:
		var speed = lander_vel.length()
		var pad_center_x = target_pad.position.x + target_pad.size.x * 0.5
		var is_on_pad = abs(lander_pos.x - pad_center_x) < (target_pad.size.x * 0.5 + 24.0)
		var is_upright = abs(lander_rot) < 0.38

		if is_on_pad and speed < 70.0 and is_upright:
			score += int(150 + lander_fuel * 2.5)
			landings_count += 1
			AudioManager.play("docking", 1.0)
			
			# Pick another random planet in the solar system to switch landscape
			_switch_to_next_random_planet()
			_reset_lander()
		else:
			AudioManager.play("click", 0.7)
			_reset_lander()

	lander_node.position = lander_pos
	lander_node.rotation = lander_rot

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
	if spd > 35.0:
		speed_label.modulate = Color(1.0, 0.35, 0.35)
	else:
		speed_label.modulate = Color(0.35, 1.0, 0.45)

	fuel_bar.value = lander_fuel
	score_label.text = "%s: %d | %s: %d" % [GameManager.loc("points"), score, GameManager.loc("landings"), landings_count]

func _on_left_rcs_down() -> void: is_left_rcs = true
func _on_left_rcs_up() -> void: is_left_rcs = false
func _on_right_rcs_down() -> void: is_right_rcs = true
func _on_right_rcs_up() -> void: is_right_rcs = false
func _on_main_burn_down() -> void: is_main_burn = true
func _on_main_burn_up() -> void: is_main_burn = false

func _on_action_btn_pressed() -> void:
	AudioManager.play("click")
	_launch_gameplay()

func _on_spinner_action_btn_pressed() -> void:
	AudioManager.play("click")
	_launch_gameplay()

func _launch_gameplay() -> void:
	if loaded_resource:
		get_tree().change_scene_to_packed(loaded_resource)
	else:
		get_tree().change_scene_to_file(target_scene_path)
