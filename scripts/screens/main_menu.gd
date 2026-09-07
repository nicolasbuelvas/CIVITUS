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

@onready var planet_carousel: HBoxContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/PlanetScroll/PlanetHBox
@onready var telemetry_card: PanelContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard
@onready var planet_name_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/VBox/TopRow/PlanetName
@onready var planet_type_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/VBox/TopRow/PlanetType
@onready var stats_grid_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/VBox/StatsGrid
@onready var back_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/BackBtn
@onready var launch_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/LaunchBtn

# UI References - Modals
@onready var settings_modal: Panel = $MenuLayer/SettingsModal
@onready var lang_option: OptionButton = $MenuLayer/SettingsModal/VBox/LangBox/OptionButton
@onready var master_slider: HSlider = $MenuLayer/SettingsModal/VBox/MasterBox/HSlider
@onready var music_slider: HSlider = $MenuLayer/SettingsModal/VBox/MusicBox/HSlider
@onready var sfx_slider: HSlider = $MenuLayer/SettingsModal/VBox/SfxBox/HSlider

@onready var store_modal: Panel = $MenuLayer/StoreModal
@onready var store_title: Label = $MenuLayer/StoreModal/VBox/Title
@onready var store_desc: Label = $MenuLayer/StoreModal/VBox/Desc

# 360-Degree Free Spherical Rotation (Arcball / Basis model without gimbal lock or pole clamps)
var planet_basis: Basis = Basis.IDENTITY
var rot_velocity: Vector2 = Vector2(0.06, 0.0) # Gentle horizontal idle spin

var is_dragging: bool = false
var last_drag_pos: Vector2 = Vector2.ZERO

var camera_dist: float = 12.0
var target_camera_dist: float = 12.0
var target_planet_pos: Vector3 = Vector3.ZERO

var selected_planet_index: int = 0

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
	
	# Setup Settings Modal
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
	play_btn.text = GameManager.loc("play")
	settings_btn.text = GameManager.loc("settings")
	store_btn.text = GameManager.loc("store")
	exit_btn.text = GameManager.loc("exit")
	
	new_system_btn.text = GameManager.loc("new_system")
	back_btn.text = GameManager.loc("back_menu")
	
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
		ViewState.PLANET_SELECTOR:
			root_layer.visible = false
			selector_layer.visible = true
			target_camera_dist = 11.2
			target_planet_pos = Vector3(0.0, 0.38, 0.0)
			_refresh_solar_system_ui()

func _process(delta: float) -> void:
	# Full 360-degree free spherical rotation in all directions (poles, equator, diagonals)
	if not is_dragging:
		# Apply momentum and natural decay towards idle drift
		var delta_rot_y = Basis(Vector3.UP, rot_velocity.x * delta)
		var delta_rot_x = Basis(Vector3.RIGHT, rot_velocity.y * delta)
		planet_basis = (delta_rot_y * delta_rot_x * planet_basis).orthonormalized()
		
		rot_velocity.y = lerp(rot_velocity.y, 0.0, delta * 3.5)
		rot_velocity.x = lerp(rot_velocity.x, 0.06, delta * 1.8)
		
	if planet_pivot:
		planet_pivot.transform.basis = planet_basis
		planet_pivot.position = planet_pivot.position.lerp(target_planet_pos, delta * 8.0)
		
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
			target_camera_dist = clamp(target_camera_dist - 0.6, 5.2, 13.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_camera_dist = clamp(target_camera_dist + 0.6, 5.2, 13.5)
			
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
	
	# Rotate around world UP for horizontal drag, and around camera RIGHT for vertical drag (no pole limits!)
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
	# User requirement: "CUANDO SE CAMBIA DE SISTEMA SOLAR, NO PODRA VER EL ANTERIOR se elimina para siempre."
	GameManager.generate_new_solar_system()

func _on_solar_system_updated(sys: Dictionary) -> void:
	selected_planet_index = 0
	_refresh_solar_system_ui()

func _refresh_solar_system_ui() -> void:
	var sys = GameManager.current_solar_system
	if sys.is_empty():
		return
		
	var s_name = sys.get("system_name", "Kepler-452")
	var s_coords = sys.get("coords_str", "[RA: 00h 00m | DEC: +00° 00']")
	
	system_name_label.text = "%s: %s" % [GameManager.loc("system_label"), s_name]
	system_coords_label.text = s_coords
	
	# Clear & populate planet carousel buttons
	for child in planet_carousel.get_children():
		planet_carousel.remove_child(child)
		child.queue_free()
		
	var planets: Array = sys.get("planets", [])
	for i in range(planets.size()):
		var p_data = planets[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 52)
		
		var lvl = p_data.get("level", 0)
		var is_pro = (lvl >= 4)
		
		var btn_title = "P-%d: L%d" % [i + 1, lvl]
		if is_pro:
			btn_title += " [PRO]"
			
		btn.text = btn_title
		btn.focus_mode = Control.FOCUS_NONE
		
		# Styling for selected & Pro status
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
	AudioManager.play("click")
	_select_planet(idx)

func _select_planet(idx: int) -> void:
	selected_planet_index = idx
	var planets = GameManager.current_solar_system.get("planets", [])
	if idx < 0 or idx >= planets.size():
		return
		
	var p = planets[idx]
	GameManager.select_planet(p)
	
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
	var g = p.get("gravity", 9.8)
	var g_rel = g / 9.8
	var temp = p.get("temperature", 21.0)
	var atmo = p.get("atmosphere", 1.0)
	var rad = p.get("radiation", 0.01)
	var orbit = p.get("orbit_au", 1.0)
	var ore = p.get("primary_ore", "Hierro")
	
	# Detailed Card on Selector Menu
	planet_name_label.text = "%s [%s %d]" % [p_name, GameManager.loc("level"), p_lvl]
	planet_type_label.text = p_type
	stats_grid_label.text = "%s: %.1f m/s² (%.2f G)  |  %s: %.0f °C  |  %s: %.2f atm\n%s: %.2f rad/s  |  %s: %.2f AU  |  %s: %s" % [
		GameManager.loc("gravity"), g, g_rel,
		GameManager.loc("temp"), temp,
		GameManager.loc("atmosphere"), atmo,
		GameManager.loc("radiation"), rad,
		GameManager.loc("orbit"), orbit,
		GameManager.loc("primary_ore"), ore
	]

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

# ----------------- Settings & Store Modals -----------------

func _setup_settings_ui() -> void:
	lang_option.clear()
	lang_option.add_item("Español", 0)
	lang_option.add_item("English", 1)
	lang_option.selected = 0 if GameManager.current_language == "es" else 1
	lang_option.item_selected.connect(_on_lang_selected)
	
	master_slider.value = GameManager.master_volume
	music_slider.value = GameManager.music_volume
	sfx_slider.value = GameManager.sfx_volume
	
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

func _on_settings_pressed() -> void:
	AudioManager.play("click")
	settings_modal.visible = true

func _on_close_settings_pressed() -> void:
	AudioManager.play("click")
	settings_modal.visible = false
	GameManager.save_settings()

func _on_lang_selected(idx: int) -> void:
	var lang = "es" if idx == 0 else "en"
	GameManager.set_language(lang)

func _on_language_changed(_new_lang: String) -> void:
	_apply_localization()

func _on_master_slider_changed(val: float) -> void:
	GameManager.master_volume = val
	var idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val))

func _on_music_slider_changed(val: float) -> void:
	GameManager.music_volume = val

func _on_sfx_slider_changed(val: float) -> void:
	GameManager.sfx_volume = val

func _on_store_pressed() -> void:
	AudioManager.play("click")
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
