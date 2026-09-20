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

const CATEGORY_NAMES = [
	"1. HABITABLE (Clase H - Agua y Biósfera)",
	"2. DESÉRTICO (Clase D - Óxido y Cañones)",
	"3. CRIOGÉNICO (Clase K - Metano y Hielo)",
	"4. TÓXICO (Clase V - Ácido Sulfúrico)",
	"5. ÍGNEO (Clase S - Magma y Basalto)",
	"6. VACÍO (Clase D - Lunar / Sin Atmósfera)"
]

func _ready() -> void:
	current = true
	far = 2500.0
	fov = 75.0
	
	# Initial position: in high orbit looking down towards North Pole
	global_position = Vector3(0, 220, 110)
	look_at(Vector3(0, 160, 0), Vector3.UP)
	
	var rot = transform.basis.get_euler()
	pitch = rot.x
	yaw = rot.y
	
	_create_spectator_hud()
	_capture_mouse(true)
	current_category = 0
	
	# Explicitly generate Category 0 (Habitable / Ocean) on startup once scene tree is ready
	call_deferred("_generate_planet_category", 0)

func _create_spectator_hud() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "SpectatorCanvas"
	canvas.layer = 120
	add_child(canvas)
	
	# Top-Left Telemetry Card
	info_panel = PanelContainer.new()
	info_panel.anchors_preset = Control.PRESET_TOP_LEFT
	info_panel.position = Vector2(24, 20)
	info_panel.custom_minimum_size = Vector2(380, 230)
	
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
	status_banner.add_theme_color_override("font_color", Color(0.4, 1.0, 0.7))
	status_banner.text = ""
	canvas.add_child(status_banner)
	
	# Bottom Controls Help Bar
	var help_label = Label.new()
	help_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	help_label.offset_top = -52.0
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", 13)
	help_label.add_theme_color_override("font_color", Color(0.80, 0.92, 1.0, 0.95))
	help_label.text = "[WASD] Volar | [Espacio/Ctrl] Subir/Bajar | [Rueda] Velocidad | [1-6] Categorías (Pulsa de nuevo para re-generar) | [Tab] Ratón"
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
				_generate_planet_category(randi() % 6)
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
	var water_stat = p.get("water_status", "Seco")
	var p_seed = p.get("seed", 1337)
	
	var cat_name = CATEGORY_NAMES[current_category] if current_category < CATEGORY_NAMES.size() else "Desconocida"
	
	info_label.text = (
		"★ INSPECTOR PROCEDURAL CIVITUS ★\n" +
		"---------------------------------------------------\n" +
		"Categoría Activa: %s\n" +
		"Planeta: %s\n" +
		"Clasificación: %s\n" +
		"Semilla Procedural: %d\n" +
		"---------------------------------------------------\n" +
		"Temperatura: %.1f °C | Gravedad: %.2f G\n" +
		"Presión Atmosférica: %.2f atm | Fluido: %s\n" +
		"---------------------------------------------------\n" +
		"Altitud radial: %.1f m | Velocidad: %.0f m/s\n" +
		"(Tip: Pulsa la misma tecla para regenerar otro)\n"
	) % [
		cat_name, p_name, p_type, p_seed,
		temp, grav, atmo, water_stat,
		alt, fly_speed
	]

func _generate_planet_category(category_idx: int) -> void:
	current_category = category_idx
	var new_seed = randi() % 900000 + 100
	
	var p = SolarSystem.generate_procedural_planet_for_archetype(category_idx, new_seed)
	GameManager.select_planet(p)
	
	if status_banner:
		var cat_name = CATEGORY_NAMES[category_idx] if category_idx < CATEGORY_NAMES.size() else ""
		status_banner.text = "⚡ Regenerado: %s (Semilla #%d)" % [p.get("name", ""), new_seed]
		# Clear banner after 2.5 seconds
		var tween = create_tween()
		tween.tween_interval(2.5)
		tween.tween_callback(func(): if status_banner: status_banner.text = "")
		
	_reload_planet_scene()

func _reload_planet_scene() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var old_planet = parent_node.get_node_or_null("SphericalPlanet")
	if old_planet:
		old_planet.free() # Immediate free so name isn't duplicated
		
	var scene = load("res://scenes/world/spherical_planet.tscn")
	var new_planet = scene.instantiate()
	new_planet.name = "SphericalPlanet"
	parent_node.add_child(new_planet)
	
	if "planet" in parent_node:
		parent_node.planet = new_planet
		
	if parent_node.has_method("_init_celestial_atmosphere"):
		parent_node._init_celestial_atmosphere()
