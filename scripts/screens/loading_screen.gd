extends CanvasLayer

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

# State & Sub-Processes Configuration
const TOTAL_SUBSTEPS: int = 40
const MINIGAME_TRIGGER_TIME: float = 7.0 # Only activate minigame if slow device takes > 7s

var minigame_activated: bool = false
var elapsed_time: float = 0.0

var current_step_name: String = ""
var current_step_index: int = 1

var io_packages: Array = [
	{ "path": "res://scenes/world/world.tscn", "msg_key": "io_sub_1" },
	{ "path": "res://scenes/entities/spaceship_3d.tscn", "msg_key": "io_sub_2" },
	{ "path": "res://scenes/entities/character_3d.tscn", "msg_key": "io_sub_3" },
	{ "path": "res://scenes/entities/paper_tree.tscn", "msg_key": "io_sub_4" },
	{ "path": "res://scenes/entities/resource_chunk.tscn", "msg_key": "io_sub_5" },
	{ "path": "res://scenes/ui/hud.tscn", "msg_key": "io_sub_6" }
]
var loaded_packages: Dictionary = {}

var is_loading_complete: bool = false
var is_world_ready: bool = false
var world_instance: Node = null
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

func _ready() -> void:
	layer = 100 # High layer guarantees zero leaks of 3D or 2D objects behind loader
	
	# Localized texts
	status_label.text = GameManager.loc("loading")
	current_step_name = GameManager.loc("io_sub_1")
	stage_label.text = current_step_name
	top_progress_label.text = current_step_name
	pad_label.text = GameManager.loc("platform")
	ready_btn.text = GameManager.loc("ready_to_land")
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
	
	# Execute asynchronous multi-process I/O pipeline (Process 1: 6 sub-steps)
	_start_io_pipeline()

func _on_viewport_size_changed() -> void:
	_update_layout()

func _update_layout() -> void:
	var vp_sz = get_viewport().get_visible_rect().size
	var screen_w = max(1280.0, vp_sz.x)
	var screen_h = max(720.0, vp_sz.y)
	
	if target_pad:
		target_pad.position = Vector2((screen_w - target_pad.size.x) * 0.5, screen_h - 110.0)

func _reset_lander() -> void:
	var vp_sz = get_viewport().get_visible_rect().size
	var screen_w = max(1280.0, vp_sz.x)
	lander_pos = Vector2(randf_range(screen_w * 0.25, screen_w * 0.75), 85.0)
	lander_vel = Vector2(randf_range(-25.0, 25.0), randf_range(10.0, 35.0))
	lander_rot = randf_range(-0.25, 0.25)
	lander_fuel = 100.0

func _start_io_pipeline() -> void:
	# Load each package asynchronously, yielding frames so cold installs never lock up
	for idx in range(io_packages.size()):
		var pkg = io_packages[idx]
		var sub_step = idx + 1 # 1..6
		current_step_index = sub_step
		current_step_name = GameManager.loc(pkg.msg_key)
		_update_ui_progress(sub_step, current_step_name)
		
		if is_inside_tree():
			await get_tree().process_frame
			
		ResourceLoader.load_threaded_request(pkg.path)
		
		var wait_ticks = 0
		while ResourceLoader.load_threaded_get_status(pkg.path) != ResourceLoader.THREAD_LOAD_LOADED:
			if is_inside_tree():
				await get_tree().process_frame
			else:
				OS.delay_msec(2)
			wait_ticks += 1
			# Safety fallback after 180 frames (~3s)
			if wait_ticks > 180:
				break
				
		var res = ResourceLoader.load_threaded_get(pkg.path)
		if res == null:
			res = load(pkg.path)
		loaded_packages[pkg.path] = res
		
		if is_inside_tree():
			await get_tree().process_frame

	is_loading_complete = true
	_spawn_preloaded_world()

func _spawn_preloaded_world() -> void:
	var world_res: PackedScene = loaded_packages.get("res://scenes/world/world.tscn", null)
	if not world_res:
		world_res = load("res://scenes/world/world.tscn")
	if not world_res:
		return
		
	world_instance = world_res.instantiate()
	
	# Pass pre-loaded resource references into planet before adding to tree
	var planet = world_instance.get_node_or_null("SphericalPlanet")
	if planet:
		planet.spaceship_scene = loaded_packages.get("res://scenes/entities/spaceship_3d.tscn")
		planet.character_scene = loaded_packages.get("res://scenes/entities/character_3d.tscn")
		planet.tree_scene = loaded_packages.get("res://scenes/entities/paper_tree.tscn")
		planet.resource_scene = loaded_packages.get("res://scenes/entities/resource_chunk.tscn")
		planet.hud_scene = loaded_packages.get("res://scenes/ui/hud.tscn")
		
		planet.generation_step_changed.connect(_on_planet_step_changed)
		planet.planet_ready.connect(_on_planet_generation_finished)
	
	if is_inside_tree():
		get_tree().root.add_child(world_instance)
		if get_parent() == get_tree().root:
			get_tree().root.move_child(self, get_tree().root.get_child_count() - 1)
			
	if not planet:
		_on_planet_generation_finished()

func _on_planet_step_changed(step_idx: int, tot_steps: int, step_desc: String) -> void:
	current_step_index = step_idx
	current_step_name = step_desc
	_update_ui_progress(step_idx, step_desc)
	
	# Mobile GPU Alpha 0.99 Pre-Rasterization Trick:
	# Forces mobile TBDR GPUs to render the 3D world, shaders, and shadows behind the loader
	if step_idx >= 39:
		var bg = get_node_or_null("Background")
		if bg:
			bg.modulate.a = 0.99

func _update_ui_progress(sub_step: int, desc: String) -> void:
	if stage_label:
		stage_label.text = desc
	if top_progress_label and not is_world_ready:
		top_progress_label.text = desc
	var p_val = clamp(float(sub_step) / float(TOTAL_SUBSTEPS) * 100.0, 0.0, 100.0)
	if spinner_progress_bar:
		spinner_progress_bar.value = p_val
	if top_progress_bar and not is_world_ready:
		top_progress_bar.value = p_val

func _on_planet_generation_finished() -> void:
	is_world_ready = true
	current_step_name = GameManager.loc("thread_step_ready")
	_update_ui_progress(TOTAL_SUBSTEPS, current_step_name)
	if spinner_progress_bar: spinner_progress_bar.value = 100.0
	if top_progress_bar: top_progress_bar.value = 100.0
	
	if minigame_activated:
		_on_load_finished()
	else:
		# Auto-launch cleanly into gameplay
		_launch_gameplay()

func _on_load_finished() -> void:
	if not minigame_activated:
		return
		
	top_progress_bar.value = 100.0
	top_progress_label.text = GameManager.loc("thread_step_ready")
	ready_btn.text = GameManager.loc("ready_to_land")
	ready_btn.visible = true
	AudioManager.play("docking", 1.1, -4.0)
	
	# Auto launch after 1.2s so player is never trapped
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		if is_world_ready and not has_launched:
			_launch_gameplay()
	)

func _process(delta: float) -> void:
	elapsed_time += delta
	
	if not minigame_activated:
		if is_world_ready and not has_launched:
			_launch_gameplay()
		elif elapsed_time >= MINIGAME_TRIGGER_TIME and not is_world_ready:
			_activate_minigame()
	else:
		_update_minigame_physics(delta)
		_update_minigame_ui()
		_update_screen_shake(delta)
		
		if ready_btn and ready_btn.visible:
			var pulse = (sin(elapsed_time * 5.0) + 1.0) * 0.5
			ready_btn.modulate = Color(1.0, 1.0, 1.0).lerp(Color(0.85, 1.2, 0.95), pulse)
			
	# Watchdog: Under no circumstance stay in loading > 10s
	if elapsed_time >= 10.0 and not has_launched:
		print("[CIVITUS] Loading safety watchdog triggered - executing gameplay launch")
		_launch_gameplay()

func _activate_minigame() -> void:
	if minigame_activated:
		return
	minigame_activated = true
	spinner_container.visible = false
	minigame_container.visible = true
	
	if is_world_ready:
		_on_load_finished()

func _update_minigame_physics(delta: float) -> void:
	var vp_sz = get_viewport().get_visible_rect().size
	var screen_w = max(1280.0, vp_sz.x)
	
	var left = is_left_rcs or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right = is_right_rcs or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var burn = is_main_burn or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_SPACE)

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

	lander_vel.y += gravity * delta
	lander_pos += lander_vel * delta
	lander_pos.x = clamp(lander_pos.x, 35.0, screen_w - 35.0)

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
			
			if is_world_ready and not has_launched:
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
	if is_world_ready and not has_launched:
		AudioManager.play("click")
		_launch_gameplay()

func _launch_gameplay() -> void:
	if has_launched:
		return
	has_launched = true
	
	if world_instance and is_instance_valid(world_instance) and world_instance.is_inside_tree():
		var p_planet = world_instance.get_node_or_null("SphericalPlanet")
		var is_cinematic_managed = false
		if p_planet and p_planet.has_method("start_landing_cinematic"):
			p_planet.start_landing_cinematic()
			is_cinematic_managed = true
			
		var player = world_instance.get_node_or_null("Character3D")
		if not player and p_planet:
			player = p_planet.get_node_or_null("Character3D")
		if not player and p_planet and "player_instance" in p_planet and is_instance_valid(p_planet.player_instance):
			player = p_planet.player_instance
				
		if player and not is_cinematic_managed:
			player.set_physics_process(true)
			player.set_process(true)
			
		var hud = world_instance.get_node_or_null("HUD")
		if hud and not is_cinematic_managed:
			if hud.has_method("activate_hud"):
				hud.activate_hud()
			else:
				hud.visible = true
		elif hud and is_cinematic_managed:
			hud.visible = false
				
		if AudioManager.has_method("play_gameplay_music"):
			AudioManager.play_gameplay_music(1.0)
			
		get_tree().current_scene = world_instance
		
		# Smooth alpha dissolve transition (100ms) - reveals already pre-warmed 60 FPS gameplay
		var tw = create_tween().set_parallel(true)
		if spinner_container: tw.tween_property(spinner_container, "modulate:a", 0.0, 0.10)
		if minigame_container: tw.tween_property(minigame_container, "modulate:a", 0.0, 0.10)
		var bg = get_node_or_null("Background")
		if bg: tw.tween_property(bg, "modulate:a", 0.0, 0.10)
		tw.chain().tween_callback(func():
			# Instantly hide from display (0.0ms CPU destruction overhead during gameplay entry)
			visible = false
			# Lazy cleanup: defer garbage collection by 2.0 seconds so memory is freed
			# quietly in the background without affecting gameplay FPS!
			var timer = get_tree().create_timer(2.0)
			timer.timeout.connect(queue_free)
		)
	else:
		if AudioManager.has_method("play_gameplay_music"):
			AudioManager.play_gameplay_music(1.0)
		get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func _exit_tree() -> void:
	if not has_launched and world_instance and is_instance_valid(world_instance) and world_instance.is_inside_tree():
		world_instance.queue_free()
