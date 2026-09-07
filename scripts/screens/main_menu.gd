extends Control

# View State
enum ViewState {
	ROOT_MENU,
	PLANET_SELECTOR
}

var current_view: ViewState = ViewState.ROOT_MENU

# 3D Node references
@onready var planet_pivot: Node3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot
@onready var planet_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot/PlanetMesh
@onready var rings_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot/RingsMesh
@onready var star_pivot: Node3D = $SubViewportContainer/SubViewport/World3D/StarPivot
@onready var star_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World3D/StarPivot/StarMesh
@onready var orbits_view: Node3D = $SubViewportContainer/SubViewport/World3D/OrbitsView
@onready var sun_light: DirectionalLight3D = $SubViewportContainer/SubViewport/World3D/SunLight
@onready var camera_3d: Camera3D = $SubViewportContainer/SubViewport/World3D/Camera3D

# UI References - Root Menu
@onready var root_layer: Control = $MenuLayer/RootLayer
@onready var title_label: Label = $MenuLayer/RootLayer/BrandBox/Title
@onready var subtitle_label: Label = $MenuLayer/RootLayer/BrandBox/Subtitle

@onready var play_btn: Button = $MenuLayer/RootLayer/ActionButtons/PlayBtn
@onready var settings_btn: Button = $MenuLayer/RootLayer/ActionButtons/SettingsBtn
@onready var store_btn: Button = $MenuLayer/RootLayer/ActionButtons/StoreBtn
@onready var exit_btn: Button = $MenuLayer/RootLayer/ActionButtons/ExitBtn

# UI References - Planet Selector
@onready var selector_layer: Control = $MenuLayer/PlanetSelectorLayer
@onready var system_name_label: Label = $MenuLayer/PlanetSelectorLayer/TopBar/SystemBox/SystemName
@onready var system_coords_label: Label = $MenuLayer/PlanetSelectorLayer/TopBar/SystemBox/SystemCoords
@onready var new_system_btn: Button = $MenuLayer/PlanetSelectorLayer/TopBar/NewSystemBtn

@onready var prev_planet_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/PrevBtn
@onready var next_planet_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/NextBtn
@onready var planet_carousel: HBoxContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/PlanetScroll/PlanetHBox

@onready var planet_tab_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/TabBar/PlanetTabBtn
@onready var system_tab_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/TabBar/SystemTabBtn

@onready var telemetry_card: PanelContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard
@onready var planet_info_box: VBoxContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox
@onready var planet_name_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/HeaderRow/PlanetName
@onready var planet_type_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/HeaderRow/PlanetType

# Graphical Meters
@onready var hab_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/HabBox/Label
@onready var hab_bar: ProgressBar = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/HabBox/Bar
@onready var hab_val: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/HabBox/Val

@onready var atmo_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/AtmoBox/Label
@onready var atmo_bar: ProgressBar = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/AtmoBox/Bar
@onready var atmo_val: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/AtmoBox/Val

@onready var temp_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/TempBox/Label
@onready var temp_bar: ProgressBar = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/TempBox/Bar
@onready var temp_val: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/TempBox/Val

@onready var grav_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/GravBox/Label
@onready var grav_bar: ProgressBar = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/GravBox/Bar
@onready var grav_val: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/GravBox/Val

# System Info Box
@onready var system_info_box: VBoxContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/SystemInfoBox
@onready var star_line: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/SystemInfoBox/StarLine
@onready var hab_zone_line: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/SystemInfoBox/HabZoneLine
@onready var planets_count_line: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/SystemInfoBox/PlanetsCountLine

@onready var back_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/BackBtn
@onready var launch_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/LaunchBtn

# UI References - Settings Modal
@onready var settings_modal: Panel = $MenuLayer/SettingsModal
@onready var settings_title_label: Label = $MenuLayer/SettingsModal/VBox/Title
@onready var lang_label: Label = $MenuLayer/SettingsModal/VBox/LangBox/Label
@onready var lang_option: OptionButton = $MenuLayer/SettingsModal/VBox/LangBox/OptionButton

@onready var master_label: Label = $MenuLayer/SettingsModal/VBox/MasterBox/Label
@onready var master_slider: HSlider = $MenuLayer/SettingsModal/VBox/MasterBox/HSlider
@onready var master_val_label: Label = $MenuLayer/SettingsModal/VBox/MasterBox/ValLabel

@onready var music_label: Label = $MenuLayer/SettingsModal/VBox/MusicBox/Label
@onready var music_slider: HSlider = $MenuLayer/SettingsModal/VBox/MusicBox/HSlider
@onready var music_val_label: Label = $MenuLayer/SettingsModal/VBox/MusicBox/ValLabel

@onready var sfx_label: Label = $MenuLayer/SettingsModal/VBox/SfxBox/Label
@onready var sfx_slider: HSlider = $MenuLayer/SettingsModal/VBox/SfxBox/HSlider
@onready var sfx_val_label: Label = $MenuLayer/SettingsModal/VBox/SfxBox/ValLabel

@onready var save_settings_btn: Button = $MenuLayer/SettingsModal/VBox/ButtonRow/SaveSettingsBtn
@onready var close_settings_btn: Button = $MenuLayer/SettingsModal/VBox/ButtonRow/CloseSettingsBtn

# UI References - Store Modal
@onready var store_modal: Panel = $MenuLayer/StoreModal
@onready var store_title: Label = $MenuLayer/StoreModal/VBox/Title
@onready var store_desc: Label = $MenuLayer/StoreModal/VBox/Desc
@onready var buy_monthly_btn: Button = $MenuLayer/StoreModal/VBox/BuyMonthlyBtn
@onready var buy_lifetime_btn: Button = $MenuLayer/StoreModal/VBox/BuyLifetimeBtn
@onready var close_store_btn: Button = $MenuLayer/StoreModal/VBox/CloseStoreBtn

# 360-Degree Free Spherical Rotation (Arcball / Basis model without gimbal lock or pole clamps)
var planet_basis: Basis = Basis.IDENTITY
var rot_velocity: Vector2 = Vector2(0.06, 0.0) # Gentle horizontal idle spin

var is_dragging: bool = false
var last_drag_pos: Vector2 = Vector2.ZERO

var camera_dist: float = 12.0
var target_camera_dist: float = 12.0
var target_planet_pos: Vector3 = Vector3.ZERO

var selected_planet_index: int = 0
var active_info_tab: String = "planet" # "planet" or "system"
var is_transitioning: bool = false

# Cached settings before opening modal for Cancel/Revert
var cached_master: float = 0.85
var cached_music: float = 0.70
var cached_sfx: float = 0.90
var cached_lang: String = "es"

func _ready() -> void:
	# Hide modals
	settings_modal.visible = false
	store_modal.visible = false
	
	# Connect Root Menu buttons
	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	store_btn.pressed.connect(_on_store_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	# Connect Selector buttons
	new_system_btn.pressed.connect(_on_new_system_pressed)
	back_btn.pressed.connect(_on_back_to_menu_pressed)
	launch_btn.pressed.connect(_on_launch_pressed)
	prev_planet_btn.pressed.connect(_on_prev_planet_pressed)
	next_planet_btn.pressed.connect(_on_next_planet_pressed)
	
	planet_tab_btn.pressed.connect(_on_planet_tab_pressed)
	system_tab_btn.pressed.connect(_on_system_tab_pressed)
	
	# Setup Settings UI
	_setup_settings_ui()
	
	# Connect to GameManager signals
	GameManager.language_changed.connect(_on_language_changed)
	GameManager.solar_system_updated.connect(_on_solar_system_updated)
	
	# Initialize rotation basis
	if planet_pivot:
		planet_basis = planet_pivot.transform.basis.orthonormalized()
	
	# Update texts & initial view
	_apply_localization()
	_show_view(ViewState.ROOT_MENU)
	
	# Play distinct ambient menu theme
	if AudioManager.has_method("play_menu_music"):
		AudioManager.play_menu_music()
	
	# Procedural Showcase: Generate fresh solar system and pick a random featured planet on startup
	randomize()
	GameManager.generate_new_solar_system(randi() % 1000000)
	var planets = GameManager.current_solar_system.get("planets", [])
	if planets.size() > 0:
		selected_planet_index = randi() % planets.size()
		_select_planet(selected_planet_index)

func _apply_localization() -> void:
	# Root Menu
	play_btn.text = GameManager.loc("play")
	settings_btn.text = GameManager.loc("settings")
	store_btn.text = GameManager.loc("store")
	exit_btn.text = GameManager.loc("exit")
	
	# Selector Navigation
	new_system_btn.text = GameManager.loc("new_system")
	back_btn.text = GameManager.loc("back_menu")
	planet_tab_btn.text = GameManager.loc("planet_info_tab")
	system_tab_btn.text = GameManager.loc("system_info_tab")
	
	# Settings Modal
	settings_title_label.text = GameManager.loc("settings_title")
	lang_label.text = GameManager.loc("lang_label")
	master_label.text = GameManager.loc("vol_master")
	music_label.text = GameManager.loc("vol_music")
	sfx_label.text = GameManager.loc("vol_sfx")
	save_settings_btn.text = GameManager.loc("save_btn")
	close_settings_btn.text = GameManager.loc("discard_btn")
	
	# Store Modal
	store_title.text = GameManager.loc("store_title")
	buy_monthly_btn.text = GameManager.loc("monthly_pass")
	buy_lifetime_btn.text = GameManager.loc("lifetime_pass")
	close_store_btn.text = GameManager.loc("close")
	
	# Meters Labels
	hab_label.text = "%s:" % GameManager.loc("habitability")
	atmo_label.text = "%s:" % GameManager.loc("atmosphere")
	temp_label.text = "%s:" % GameManager.loc("temp")
	grav_label.text = "%s:" % GameManager.loc("gravity")
	
	_update_launch_button_text()
	_update_telemetry_ui()

func _show_view(new_view: ViewState) -> void:
	current_view = new_view
	match new_view:
		ViewState.ROOT_MENU:
			root_layer.visible = true
			selector_layer.visible = false
			target_camera_dist = 12.0
			target_planet_pos = Vector3.ZERO
			if star_pivot:
				star_pivot.visible = false
		ViewState.PLANET_SELECTOR:
			root_layer.visible = false
			selector_layer.visible = true
			target_camera_dist = 11.2
			target_planet_pos = Vector3(0.0, 0.38, 0.0)
			if star_pivot:
				star_pivot.visible = true
			_refresh_solar_system_ui()

func _process(delta: float) -> void:
	# Full 360-degree free spherical rotation in all directions (poles, equator, diagonals)
	if not is_dragging:
		var delta_rot_y = Basis(Vector3.UP, rot_velocity.x * delta)
		var delta_rot_x = Basis(Vector3.RIGHT, rot_velocity.y * delta)
		planet_basis = (delta_rot_y * delta_rot_x * planet_basis).orthonormalized()
		
		rot_velocity.y = lerp(rot_velocity.y, 0.0, delta * 3.5)
		rot_velocity.x = lerp(rot_velocity.x, 0.06, delta * 1.8)
		
	if planet_pivot:
		planet_pivot.transform.basis = planet_basis
		planet_pivot.position = planet_pivot.position.lerp(target_planet_pos, delta * 8.0)
		
	# Star slow drift
	if star_pivot:
		star_pivot.rotation.y += delta * 0.02
		
	# Smooth camera distance zoom
	camera_dist = lerp(camera_dist, target_camera_dist, delta * 8.0)
	if camera_3d:
		camera_3d.position.z = camera_dist

func _gui_input(event: InputEvent) -> void:
	# Free 360° omnidirectional trackball drag
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_drag_pos = event.position
			else:
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_camera_dist = clamp(target_camera_dist - 0.6, 5.2, 18.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_camera_dist = clamp(target_camera_dist + 0.6, 5.2, 18.0)
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta_pos = event.position - last_drag_pos
		last_drag_pos = event.position
		_apply_free_drag(delta_pos)
		
	elif event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			last_drag_pos = event.position
		else:
			is_dragging = false
			
	elif event is InputEventScreenDrag and is_dragging:
		_apply_free_drag(event.relative)

func _apply_free_drag(delta_pos: Vector2) -> void:
	var rot_speed = 0.0055
	var angle_x = delta_pos.x * rot_speed
	var angle_y = delta_pos.y * rot_speed
	
	var rot_h = Basis(Vector3.UP, angle_x)
	var rot_v = Basis(Vector3.RIGHT, angle_y)
	planet_basis = (rot_h * rot_v * planet_basis).orthonormalized()
	
	rot_velocity = delta_pos * rot_speed * 18.0

# ----------------- Navigation & Button Callbacks -----------------

func _on_play_pressed() -> void:
	AudioManager.play("click")
	_show_view(ViewState.PLANET_SELECTOR)

func _on_back_to_menu_pressed() -> void:
	AudioManager.play("click")
	_show_view(ViewState.ROOT_MENU)

func _on_new_system_pressed() -> void:
	AudioManager.play("hyperdrive", 1.0, -4.0)
	# Warp hyperspace transition: zoom out into space void, generate new system, zoom back in!
	var tween = create_tween()
	is_transitioning = true
	tween.tween_property(self, "target_camera_dist", 22.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		GameManager.generate_new_solar_system()
	)
	tween.tween_property(self, "target_camera_dist", 11.2, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		is_transitioning = false
	)

func _on_prev_planet_pressed() -> void:
	var planets = GameManager.current_solar_system.get("planets", [])
	if planets.is_empty() or is_transitioning:
		return
	var new_idx = (selected_planet_index - 1 + planets.size()) % planets.size()
	_transition_to_planet(new_idx)

func _on_next_planet_pressed() -> void:
	var planets = GameManager.current_solar_system.get("planets", [])
	if planets.is_empty() or is_transitioning:
		return
	var new_idx = (selected_planet_index + 1) % planets.size()
	_transition_to_planet(new_idx)

func _transition_to_planet(new_idx: int) -> void:
	AudioManager.play("click")
	is_transitioning = true
	# Camera zooms out slightly to reveal distant solar system, switches, and zooms in
	var tween = create_tween()
	tween.tween_property(self, "target_camera_dist", 16.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		_select_planet(new_idx)
	)
	tween.tween_property(self, "target_camera_dist", 11.2, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		is_transitioning = false
	)

func _on_solar_system_updated(sys: Dictionary) -> void:
	selected_planet_index = 0
	_update_star_visuals(sys)
	_refresh_solar_system_ui()

func _update_star_visuals(sys: Dictionary) -> void:
	if not star_mesh:
		return
	var star_data = sys.get("star", {})
	var star_col: Color = star_data.get("color", Color(1.0, 0.85, 0.35))
	var star_mat = star_mesh.get_surface_override_material(0) as StandardMaterial3D
	if not star_mat:
		star_mat = StandardMaterial3D.new()
		star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		star_mesh.set_surface_override_material(0, star_mat)
	star_mat.albedo_color = star_col

func _refresh_solar_system_ui() -> void:
	var sys = GameManager.current_solar_system
	if sys.is_empty():
		return
		
	var s_name = sys.get("system_name", "Kepler-452")
	var s_coords = sys.get("coords_str", "[RA: 00h 00m | DEC: +00° 00']")
	
	system_name_label.text = "%s: %s" % [GameManager.loc("system_label"), s_name]
	system_coords_label.text = s_coords
	
	if orbits_view and orbits_view.has_method("setup_system"):
		orbits_view.setup_system(sys, selected_planet_index)
		
	# Clear & populate planet carousel buttons
	for child in planet_carousel.get_children():
		planet_carousel.remove_child(child)
		child.queue_free()
		
	var planets: Array = sys.get("planets", [])
	for i in range(planets.size()):
		var p_data = planets[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 46)
		
		var lvl = p_data.get("level", 0)
		var is_pro = (lvl >= 4)
		
		var btn_title = "P-%d: L%d" % [i + 1, lvl]
		if is_pro:
			btn_title += " [PRO]"
			
		btn.text = btn_title
		btn.focus_mode = Control.FOCUS_NONE
		
		if i == selected_planet_index:
			btn.modulate = Color(0.3, 0.95, 1.0)
		elif is_pro:
			btn.modulate = Color(1.0, 0.65, 0.3)
		else:
			btn.modulate = Color(0.85, 0.90, 0.95)
			
		btn.pressed.connect(_on_planet_button_pressed.bind(i))
		planet_carousel.add_child(btn)
		
	_select_planet(selected_planet_index)

func _on_planet_button_pressed(idx: int) -> void:
	if idx != selected_planet_index:
		_transition_to_planet(idx)

func _select_planet(idx: int) -> void:
	selected_planet_index = idx
	var planets = GameManager.current_solar_system.get("planets", [])
	if idx < 0 or idx >= planets.size():
		return
		
	var p = planets[idx]
	GameManager.select_planet(p)
	
	if orbits_view and orbits_view.has_method("set_selected_planet"):
		orbits_view.set_selected_planet(idx)
		
	# Space Engine / Universe Sandbox real-angle and apparent size of host star
	var sys = GameManager.current_solar_system
	var star_data = sys.get("star", {})
	var r_au = max(0.2, p.get("orbit_au", 1.0))
	var s_lum = star_data.get("luminosity", 1.0)
	
	if star_pivot:
		var p_coords: Vector3 = p.get("coords", Vector3(r_au * 1000.0, 0.0, 0.0))
		var star_dir = -p_coords.normalized()
		if star_dir.length_squared() < 0.001:
			star_dir = Vector3(-0.85, 0.25, -0.45).normalized()
		var star_dist = 42.0 + r_au * 8.0
		star_pivot.position = star_dir * star_dist
		
		# Apparent size: closer = huge radiant sun, far = small brilliant starlight point
		var apparent_r = clamp((3.2 * sqrt(s_lum)) / sqrt(r_au), 0.6, 4.5)
		star_pivot.scale = Vector3.ONE * apparent_r
		
		if sun_light:
			sun_light.look_at_from_position(star_pivot.position, planet_pivot.position, Vector3.UP)
	
	# Update 3D planet appearance via shader uniforms
	_apply_planet_to_3d_mesh(p)
	
	# Update UI & carousel button highlights
	var buttons = planet_carousel.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i] as Button
		if not btn or i >= planets.size():
			continue
		if i == idx:
			btn.modulate = Color(0.2, 0.95, 1.0)
		elif planets[i].get("level", 0) >= 4:
			btn.modulate = Color(1.0, 0.65, 0.3)
		else:
			btn.modulate = Color(0.85, 0.90, 0.95)
				
	_update_telemetry_ui()
	_update_launch_button_text()

func _apply_planet_to_3d_mesh(p: Dictionary) -> void:
	if not planet_mesh:
		return
		
	var mat = planet_mesh.get_surface_override_material(0) as ShaderMaterial
	if not mat:
		mat = planet_mesh.material_override as ShaderMaterial
	if not mat:
		return
		
	mat.set_shader_parameter("ocean_color", p.get("ocean_color", Color(0.04, 0.22, 0.55)))
	mat.set_shader_parameter("shore_color", p.get("shore_color", Color(0.12, 0.48, 0.72)))
	mat.set_shader_parameter("beach_color", p.get("beach_color", Color(0.82, 0.75, 0.52)))
	mat.set_shader_parameter("land_color", p.get("land_color", Color(0.20, 0.55, 0.26)))
	mat.set_shader_parameter("mountain_color", p.get("mountain_color", Color(0.48, 0.42, 0.36)))
	mat.set_shader_parameter("peak_color", p.get("peak_color", Color(0.92, 0.96, 1.0)))
	mat.set_shader_parameter("atmosphere_color", p.get("atmosphere_color", Color(0.30, 0.70, 1.0)))
	mat.set_shader_parameter("cloud_color", p.get("cloud_color", Color(1.0, 1.0, 1.0)))
	mat.set_shader_parameter("emission_color", p.get("emission_color", Color(0, 0, 0)))
	mat.set_shader_parameter("emission_energy", p.get("emission_energy", 0.0))
	mat.set_shader_parameter("water_threshold", p.get("water_threshold", 0.46))
	mat.set_shader_parameter("mountain_threshold", p.get("mountain_threshold", 0.72))
	mat.set_shader_parameter("peak_threshold", p.get("peak_threshold", 0.88))
	mat.set_shader_parameter("cloud_density", p.get("cloud_density", 0.52))
	mat.set_shader_parameter("cloud_speed", p.get("cloud_speed", 0.03))
	mat.set_shader_parameter("noise_scale", p.get("noise_scale", 2.4))
	
	# Planetary Rings
	if rings_mesh:
		var has_rings = p.get("has_rings", false)
		rings_mesh.visible = has_rings
		if has_rings:
			var ring_mat = rings_mesh.material_override as ShaderMaterial
			if ring_mat:
				ring_mat.set_shader_parameter("ring_color", p.get("ring_color", Color(0.8, 0.8, 0.9)))

func _update_telemetry_ui() -> void:
	var p = GameManager.current_planet
	if p.is_empty():
		return
		
	var p_name = p.get("name", "Sector")
	var p_lvl = p.get("level", 0)
	var p_type = p.get("type_label", "Cuerpo Rocoso")
	
	# Planet Tab Data
	planet_name_label.text = "%s [%s %d]" % [p_name, GameManager.loc("level"), p_lvl]
	planet_type_label.text = p_type
	
	var tg = p.get("telemetry_graph", {})
	var hab_score = tg.get("habitability", 0.85) * 100.0
	var atmo_score = tg.get("atmosphere", 0.5) * 100.0
	var temp_score = tg.get("temperature", 0.45) * 100.0
	var grav_score = tg.get("gravity", 0.40) * 100.0
	
	hab_bar.value = hab_score
	hab_val.text = "%d%%" % int(hab_score)
	
	var has_atmo = p.get("has_atmosphere", true)
	if not has_atmo:
		atmo_bar.value = 0.0
		atmo_val.text = "0.00 atm (Vacío)"
	else:
		atmo_bar.value = atmo_score
		atmo_val.text = "%.2f atm" % p.get("atmosphere", 1.0)
		
	temp_bar.value = temp_score
	temp_val.text = "%.0f °C" % p.get("temperature", 21.0)
	
	grav_bar.value = grav_score
	var g = p.get("gravity", 9.8)
	grav_val.text = "%.2f G (%.1f m/s²)" % [g / 9.8, g]
	
	# System Tab Data
	var sys = GameManager.current_solar_system
	var star_data = sys.get("star", {})
	var star_name = star_data.get("name", sys.get("system_name", "Kepler"))
	var spectral = star_data.get("spectral_class", "G2V")
	var s_temp = star_data.get("temperature", 5780)
	star_line.text = "%s: %s (Clase %s • %d K)" % [GameManager.loc("star_type"), star_name, spectral, s_temp]
	
	var hz_in = star_data.get("hz_inner_au", 0.85)
	var hz_out = star_data.get("hz_outer_au", 1.65)
	hab_zone_line.text = "%s (Goldilocks): %.2f AU ───── %.2f AU" % [GameManager.loc("habitable_zone"), hz_in, hz_out]
	
	var sg = sys.get("system_graph", {})
	var num_planets = sg.get("planet_count", sys.get("planets", []).size())
	var hab_count = sg.get("habitable_count", 1)
	planets_count_line.text = "%s: %d planetas (%d en zona habitable) • Radiación: %.2f rad/s" % [
		GameManager.loc("planets_count"), num_planets, hab_count, p.get("radiation", 0.01)
	]

func _on_planet_tab_pressed() -> void:
	AudioManager.play("click")
	active_info_tab = "planet"
	planet_info_box.visible = true
	system_info_box.visible = false
	planet_tab_btn.modulate = Color(1.0, 1.0, 1.0)
	system_tab_btn.modulate = Color(0.65, 0.75, 0.85, 0.6)
	
	# Smooth swoop down to close-up planet view
	var tween = create_tween()
	tween.tween_property(self, "target_camera_dist", 11.2, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	target_planet_pos = Vector3(0.0, 0.38, 0.0)
	if orbits_view:
		orbits_view.visible = false

func _on_system_tab_pressed() -> void:
	AudioManager.play("click")
	active_info_tab = "system"
	planet_info_box.visible = false
	system_info_box.visible = true
	planet_tab_btn.modulate = Color(0.65, 0.75, 0.85, 0.6)
	system_tab_btn.modulate = Color(1.0, 1.0, 1.0)
	
	# Space Engine / Universe Sandbox elevated solar system overview
	var tween = create_tween()
	tween.tween_property(self, "target_camera_dist", 58.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	target_planet_pos = Vector3(0.0, -8.0, -18.0)
	if orbits_view:
		orbits_view.visible = true

func _update_launch_button_text() -> void:
	var p = GameManager.current_planet
	var is_locked = p.get("is_locked", false) and not RevenueCatManager.has_premium_access()
	
	if is_locked:
		launch_btn.text = GameManager.loc("unlock_tier")
		launch_btn.modulate = Color(1.0, 0.7, 0.2)
	else:
		launch_btn.text = GameManager.loc("start_expedition")
		launch_btn.modulate = Color(0.2, 0.9, 0.45)

func _on_launch_pressed() -> void:
	AudioManager.play("click")
	var p = GameManager.current_planet
	var is_locked = p.get("is_locked", false) and not RevenueCatManager.has_premium_access()
	
	if is_locked:
		open_store_modal(GameManager.loc("pro_sector_locked"), GameManager.loc("pro_sector_desc"))
		return
		
	if AudioManager.has_method("play_gameplay_music"):
		AudioManager.play_gameplay_music()
	GameManager.start_expedition()

# ----------------- Settings & Store Modals (Mutual Exclusivity) -----------------

func _setup_settings_ui() -> void:
	lang_option.clear()
	lang_option.add_item("Español", 0)
	lang_option.add_item("English", 1)
	lang_option.selected = 0 if GameManager.current_language == "es" else 1
	lang_option.item_selected.connect(_on_lang_selected)
	
	master_slider.value = GameManager.master_volume
	music_slider.value = GameManager.music_volume
	sfx_slider.value = GameManager.sfx_volume
	
	_update_slider_labels()
	
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

func _update_slider_labels() -> void:
	master_val_label.text = "%d%%" % int(master_slider.value * 100)
	music_val_label.text = "%d%%" % int(music_slider.value * 100)
	sfx_val_label.text = "%d%%" % int(sfx_slider.value * 100)

func _on_settings_pressed() -> void:
	AudioManager.play("click")
	# Mutual exclusivity: Close store if open
	store_modal.visible = false
	
	# Cache current settings for Discard/Close
	cached_master = GameManager.master_volume
	cached_music = GameManager.music_volume
	cached_sfx = GameManager.sfx_volume
	cached_lang = GameManager.current_language
	
	master_slider.value = cached_master
	music_slider.value = cached_music
	sfx_slider.value = cached_sfx
	lang_option.selected = 0 if cached_lang == "es" else 1
	_update_slider_labels()
	
	settings_modal.visible = true

func _on_save_settings_pressed() -> void:
	AudioManager.play("click")
	GameManager.master_volume = master_slider.value
	GameManager.music_volume = music_slider.value
	GameManager.sfx_volume = sfx_slider.value
	GameManager.save_settings()
	settings_modal.visible = false

func _on_close_settings_pressed() -> void:
	AudioManager.play("click")
	# Discard uncommitted changes: revert to cached
	GameManager.master_volume = cached_master
	GameManager.music_volume = cached_music
	GameManager.sfx_volume = cached_sfx
	if GameManager.current_language != cached_lang:
		GameManager.set_language(cached_lang)
	GameManager._apply_audio_bus_volumes()
	settings_modal.visible = false

func _on_lang_selected(idx: int) -> void:
	var lang = "es" if idx == 0 else "en"
	GameManager.set_language(lang)

func _on_language_changed(_new_lang: String) -> void:
	_apply_localization()

func _on_master_slider_changed(val: float) -> void:
	master_val_label.text = "%d%%" % int(val * 100)
	var idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val))

func _on_music_slider_changed(val: float) -> void:
	music_val_label.text = "%d%%" % int(val * 100)

func _on_sfx_slider_changed(val: float) -> void:
	sfx_val_label.text = "%d%%" % int(val * 100)

func _on_store_pressed() -> void:
	AudioManager.play("click")
	# Mutual exclusivity: Close settings if open
	settings_modal.visible = false
	open_store_modal(GameManager.loc("pro_sector_locked"), GameManager.loc("pro_sector_desc"))

func open_store_modal(title: String, desc: String) -> void:
	store_title.text = title
	store_desc.text = desc
	store_modal.visible = true

func _on_close_store_pressed() -> void:
	AudioManager.play("click")
	store_modal.visible = false

func _on_buy_monthly_pressed() -> void:
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_MONTHLY_PASS)
	store_modal.visible = false
	_update_launch_button_text()

func _on_buy_lifetime_pressed() -> void:
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_LIFETIME)
	store_modal.visible = false
	_update_launch_button_text()

func _on_exit_pressed() -> void:
	AudioManager.play("click")
	get_tree().quit(0)
