extends Camera3D

@export var base_speed: float = 35.0
@export var sprint_multiplier: float = 3.5
@export var mouse_sensitivity: float = 0.003

var fly_speed: float = 35.0
var min_speed: float = 2.0
var max_speed: float = 280.0

var pitch: float = 0.0
var yaw: float = 0.0

var mouse_captured: bool = false
var hud_visible: bool = true

# Telemetry UI nodes
var info_panel: PanelContainer = null
var info_label: Label = null
var status_banner: Label = null
var current_category: int = 0
var is_rotation_frozen: bool = false
var solar_angle: float = 0.0

const CATEGORY_NAMES = [
	"1. HABITABLE (Clase H - Agua y Biósfera)",
	"2. DESÉRTICO (Clase D - Óxido y Cañones)",
	"3. CRIOGÉNICO (Clase K - Metano y Hielo)",
	"4. TÓXICO (Clase V - Ácido Sulfúrico)",
	"5. ÍGNEO (Clase S - Magma y Basalto)",
	"6. VACÍO (Clase D - Lunar / Sin Atmósfera)",
	"7. OCÉANO GLOBAL 100% (Clase O - Acuático Pelágico)",
	"8. SINGULARIDAD (Clase X • PRO - Plasma Cuántico)"
]

func _ready() -> void:
	current = true
	far = 3000.0
	fov = 75.0
	
	# Initial position: in high orbit looking down towards North Pole
	global_position = Vector3(0, 225, 120)
	look_at(Vector3(0, 160, 0), Vector3.UP)
	
	var rot = transform.basis.get_euler()
	pitch = rot.x
	yaw = rot.y
	
	_create_spectator_hud()
	_capture_mouse(true)
	current_category = 0
	
	# Explicitly generate Category 6 (100% Ocean World: Thalassa-777) on startup
	current_category = 6
	call_deferred("_generate_planet_category", 6, 700777)

func _create_spectator_hud() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "SpectatorCanvas"
	canvas.layer = 120
	add_child(canvas)
	
	# Top-Left Telemetry Card
	info_panel = PanelContainer.new()
	info_panel.anchors_preset = Control.PRESET_TOP_LEFT
	info_panel.position = Vector2(24, 20)
	info_panel.custom_minimum_size = Vector2(430, 260)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.12, 0.88)
	style.border_color = Color(0.18, 0.82, 1.0, 0.75)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	info_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	info_panel.add_child(margin)
	
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	margin.add_child(info_label)
	canvas.add_child(info_panel)
	
	# Center Notification Banner for regeneration feedback
	status_banner = Label.new()
	status_banner.anchors_preset = Control.PRESET_TOP_WIDE
	status_banner.offset_top = 25.0
	status_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_banner.add_theme_font_size_override("font_size", 16)
	status_banner.add_theme_color_override("font_color", Color(0.35, 1.0, 0.75))
	status_banner.text = ""
	canvas.add_child(status_banner)
	
	# Bottom Controls Help Bar
	var help_label = Label.new()
	help_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	help_label.offset_top = -54.0
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", 13)
	help_label.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0, 0.95))
	help_label.text = "[WASD] Volar | [Espacio/Ctrl] Subir/Bajar | [1-8] Categorías | [R] Random | [O] Órbita | [P] Superficie | [T] Sol | [F] Giro | [H] HUD"
	canvas.add_child(help_label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_TAB:
				_capture_mouse(not mouse_captured)
			KEY_ESCAPE:
				_capture_mouse(false)
			KEY_H:
				hud_visible = not hud_visible
				if info_panel: info_panel.visible = hud_visible
			KEY_R:
				_generate_planet_category(randi() % 8)
			KEY_1:
				_generate_planet_category(0) # Base: Habitable / Templado
			KEY_2:
				_generate_planet_category(1) # Desértico / Árido
			KEY_3:
				_generate_planet_category(2) # Criogénico / Glaciar
			KEY_4:
				_generate_planet_category(3) # Tóxico / Sulfúrico
			KEY_5:
				_generate_planet_category(4) # Ígneo / Magmático
			KEY_6:
				_generate_planet_category(5) # Vacío / Lunar
			KEY_7:
				_generate_planet_category(6) # Océano Global 100% (Acuático Pelágico)
			KEY_8:
				_generate_planet_category(7) # Singularidad (Clase X • PRO)
			KEY_O:
				_teleport_orbit()
			KEY_P:
				_teleport_surface()
			KEY_T:
				_advance_solar_cycle()
			KEY_F:
				_toggle_planetary_rotation()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			fly_speed = clampf(fly_speed * 1.18, min_speed, max_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			fly_speed = clampf(fly_speed / 1.18, min_speed, max_speed)
		elif event.button_index == MOUSE_BUTTON_LEFT and not mouse_captured:
			_capture_mouse(true)

	if event is InputEventMouseMotion and mouse_captured:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -deg_to_rad(89.0), deg_to_rad(89.0))
		transform.basis = Basis.from_euler(Vector3(pitch, yaw, 0.0))

func _teleport_orbit() -> void:
	global_position = Vector3(0, 240, 130)
	look_at(Vector3.ZERO, Vector3.UP)
	var rot = transform.basis.get_euler()
	pitch = rot.x
	yaw = rot.y
	_notify("🔭 Vista Órbita Global (Altitud: ~110m)")

func _teleport_surface() -> void:
	var p = GameManager.current_planet
	var r = p.get("radius", 160.0)
	global_position = Vector3(0, r + 12.0, 16.0)
	look_at(Vector3(0, r, 0), Vector3.UP)
	var rot = transform.basis.get_euler()
	pitch = rot.x
	yaw = rot.y
	_notify("🌍 Vista Superficie y Relieve (Altitud: ~12m)")

func _toggle_planetary_rotation() -> void:
	is_rotation_frozen = not is_rotation_frozen
	var parent_node = get_parent()
	if parent_node:
		var planet = parent_node.get_node_or_null("SphericalPlanet")
		if planet:
			planet.set_process(not is_rotation_frozen)
	_notify("⏱ Rotación planetaria: %s" % ("PAUSADA" if is_rotation_frozen else "REANUDADA"))

func _advance_solar_cycle() -> void:
	solar_angle += PI * 0.25 # Advance 45 degrees
	var parent_node = get_parent()
	if parent_node:
		var sun = parent_node.get_node_or_null("SunLight") as DirectionalLight3D
		if sun:
			var sun_x = cos(solar_angle) * 0.8
			var sun_y = sin(solar_angle) * 0.75 + 0.25
			var sun_z = sin(solar_angle * 0.7) * 0.6
			sun.transform.basis = Basis.looking_at(Vector3(sun_x, -sun_y, sun_z).normalized(), Vector3.UP)
			_notify("☀️ Posición Solar: %d°" % int(fposmod(rad_to_deg(solar_angle), 360.0)))

func _notify(msg: String) -> void:
	if status_banner:
		status_banner.text = msg
		var tween = create_tween()
		tween.tween_interval(2.5)
		tween.tween_callback(func(): if status_banner and status_banner.text == msg: status_banner.text = "")

func _capture_mouse(capture: bool) -> void:
	mouse_captured = capture
	if capture:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	_handle_movement(delta)
	_update_telemetry()

func _handle_movement(delta: float) -> void:
	var move_dir = Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W):
		move_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		move_dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		move_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		move_dir += transform.basis.x
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E):
		move_dir += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_Q):
		move_dir -= Vector3.UP
		
	if move_dir.length_squared() > 0.001:
		var speed = fly_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= sprint_multiplier
		global_position += move_dir.normalized() * (speed * delta)

func _update_telemetry() -> void:
	if not info_label or not hud_visible:
		return
		
	var p = GameManager.current_planet
	var r = p.get("radius", 160.0)
	var cam_dist = global_position.length()
	var alt = maxf(0.0, cam_dist - r)
	
	var p_name = p.get("name", "Sector Procedural")
	var p_type = p.get("type_label", "Desconocido")
	var temp = p.get("temperature", 22.0)
	var atmo = p.get("atmosphere", 1.0)
	var grav = p.get("gravity_g", 1.0)
	var grav_ms2 = grav * 9.8
	var water_stat = p.get("water_status", "Seco")
	var is_ocean = bool(p.get("is_ocean_world", false))
	var ocean_cov = float(p.get("ocean_coverage", 1.0 if is_ocean else (0.68 if water_stat != "Seco / Desolado" and water_stat != "" else 0.0)))
	var p_seed = p.get("seed", 1337)
	var rad = p.get("radiation", 0.02)
	
	var ocean_text = "0.0% (Seco / Desolado)"
	if is_ocean or ocean_cov >= 0.99:
		ocean_text = "100.0% (Océano Global Pelágico)"
	elif ocean_cov > 0.0:
		ocean_text = "%.1f%% (Océanos y Mares)" % (ocean_cov * 100.0)
	
	var cat_name = CATEGORY_NAMES[current_category] if current_category < CATEGORY_NAMES.size() else "Desconocida"
	
	info_label.text = (
		"★ INSPECTOR PROCEDURAL CIVITUS ★\n" +
		"---------------------------------------------------\n" +
		"Categoría: %s\n" +
		"Planeta: %s | Semilla: #%d\n" +
		"Clasificación: %s\n" +
		"Cobertura Líquida: %s\n" +
		"---------------------------------------------------\n" +
		"Temperatura: %.1f °C | Gravedad: %.2f G (%.1f m/s²)\n" +
		"Atmósfera: %.2f atm | Radiación: %.2f rad/s\n" +
		"Estado del Fluido: %s\n" +
		"---------------------------------------------------\n" +
		"Altitud radial: %.1f m | Velocidad vuelo: %.0f m/s\n" +
		"[1-8] Categorías | [R] Random | [O] Órbita | [P] Superficie\n" +
		"[T] Hora Solar | [F] Rotación | [H] Ocultar HUD\n"
	) % [
		cat_name, p_name, p_seed,
		p_type, ocean_text,
		temp, grav, grav_ms2,
		atmo, rad,
		water_stat,
		alt, fly_speed
	]

func _generate_planet_category(category_idx: int, forced_seed: int = -1) -> void:
	current_category = category_idx
	var new_seed = forced_seed if forced_seed > 0 else (randi() % 900000 + 100)
	
	var p = SolarSystem.generate_procedural_planet_for_archetype(category_idx, new_seed)
	GameManager.select_planet(p)
	
	var cat_name = CATEGORY_NAMES[category_idx] if category_idx < CATEGORY_NAMES.size() else ""
	_notify("⚡ Regenerado: %s (Semilla #%d)" % [p.get("name", ""), new_seed])
		
	_reload_planet_scene()

func _reload_planet_scene() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var old_planet = parent_node.get_node_or_null("SphericalPlanet")
	if old_planet:
		if old_planet.has_method("abort_generation"):
			old_planet.abort_generation()
		old_planet.free() # Immediate free so name isn't duplicated
		
	var scene = load("res://scenes/world/spherical_planet.tscn")
	var new_planet = scene.instantiate()
	new_planet.name = "SphericalPlanet"
	parent_node.add_child(new_planet)
	
	# Assert spectator camera priority
	current = true
	
	if "planet" in parent_node:
		parent_node.planet = new_planet
		
	if parent_node.has_method("_init_celestial_atmosphere"):
		parent_node._init_celestial_atmosphere()
