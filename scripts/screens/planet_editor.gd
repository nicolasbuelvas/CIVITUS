extends Control

const SolarSystemClass = preload("res://scripts/systems/solar_system.gd")

# 3D Node References
@onready var camera_3d: Camera3D = $SubViewportContainer/SubViewport/World3D/Camera3D
@onready var sun_light: DirectionalLight3D = $SubViewportContainer/SubViewport/World3D/SunLight
@onready var planet_pivot: Node3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot
@onready var planet_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot/PlanetMesh
@onready var rings_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot/RingsMesh

# Viewport interaction overlay
@onready var drag_area: Control = $DragArea

# UI References - Top Bar
@onready var title_label: Label = $TopBar/HBox/BrandBox/Title
@onready var subtitle_label: Label = $TopBar/HBox/BrandBox/Subtitle
@onready var class_badge: Label = $TopBar/HBox/StatusBox/ClassBadge
@onready var class_desc_label: Label = $TopBar/HBox/StatusBox/ClassDescLabel

# UI References - Customization Controls
@onready var name_label: Label = $ControlDock/PanelContainer/DockVBox/NameBox/NameLabel
@onready var name_edit: LineEdit = $ControlDock/PanelContainer/DockVBox/NameBox/LineEdit

# Tabs
@onready var tab_surface_btn: Button = $ControlDock/PanelContainer/DockVBox/TabBar/TabSurfaceBtn
@onready var tab_atmo_btn: Button = $ControlDock/PanelContainer/DockVBox/TabBar/TabAtmoBtn
@onready var tab_ocean_btn: Button = $ControlDock/PanelContainer/DockVBox/TabBar/TabOceanBtn
@onready var tab_rings_btn: Button = $ControlDock/PanelContainer/DockVBox/TabBar/TabRingsBtn

@onready var surface_view: VBoxContainer = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView
@onready var atmo_view: VBoxContainer = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView
@onready var ocean_view: VBoxContainer = $ControlDock/PanelContainer/DockVBox/TabViews/OceanView
@onready var rings_view: VBoxContainer = $ControlDock/PanelContainer/DockVBox/TabViews/RingsView

# Surface Controls & Steppers
@onready var radius_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/RadiusBox/Header/Label
@onready var radius_val_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/RadiusBox/Header/ValLabel
@onready var radius_dec_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/RadiusBox/StepperRow/DecBtn
@onready var radius_slider: HSlider = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/RadiusBox/StepperRow/HSlider
@onready var radius_inc_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/RadiusBox/StepperRow/IncBtn

@onready var gravity_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/GravityBox/Header/Label
@onready var gravity_val_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/GravityBox/Header/ValLabel
@onready var gravity_dec_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/GravityBox/StepperRow/DecBtn
@onready var gravity_slider: HSlider = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/GravityBox/StepperRow/HSlider
@onready var gravity_inc_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/GravityBox/StepperRow/IncBtn

@onready var surface_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/SurfaceColorBox/Header/Label
@onready var surface_picker: ColorPickerButton = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/SurfaceColorBox/Header/ColorPicker
@onready var surface_swatches: HBoxContainer = $ControlDock/PanelContainer/DockVBox/TabViews/SurfaceView/SurfaceColorBox/SwatchesRow

# Atmosphere Controls & Steppers
@onready var atmo_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/AtmoBox/Header/Label
@onready var atmo_val_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/AtmoBox/Header/ValLabel
@onready var atmo_dec_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/AtmoBox/StepperRow/DecBtn
@onready var atmo_slider: HSlider = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/AtmoBox/StepperRow/HSlider
@onready var atmo_inc_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/AtmoBox/StepperRow/IncBtn

@onready var temp_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/TempBox/Header/Label
@onready var temp_val_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/TempBox/Header/ValLabel
@onready var temp_dec_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/TempBox/StepperRow/DecBtn
@onready var temp_slider: HSlider = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/TempBox/StepperRow/HSlider
@onready var temp_inc_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/TempBox/StepperRow/IncBtn

@onready var atmo_color_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/AtmoColorBox/Header/Label
@onready var atmo_picker: ColorPickerButton = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/AtmoColorBox/Header/ColorPicker
@onready var atmo_swatches: HBoxContainer = $ControlDock/PanelContainer/DockVBox/TabViews/AtmoView/AtmoColorBox/SwatchesRow

# Ocean Controls & Steppers
@onready var water_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/OceanView/WaterBox/Header/Label
@onready var water_val_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/OceanView/WaterBox/Header/ValLabel
@onready var water_dec_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/OceanView/WaterBox/StepperRow/DecBtn
@onready var water_slider: HSlider = $ControlDock/PanelContainer/DockVBox/TabViews/OceanView/WaterBox/StepperRow/HSlider
@onready var water_inc_btn: Button = $ControlDock/PanelContainer/DockVBox/TabViews/OceanView/WaterBox/StepperRow/IncBtn
@onready var ocean_desc_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/OceanView/OceanDescBox/Margin/DescLabel

# Rings Controls
@onready var rings_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/RingsView/RingsBox/Header/Label
@onready var rings_toggle: CheckButton = $ControlDock/PanelContainer/DockVBox/TabViews/RingsView/RingsBox/Header/CheckButton
@onready var rings_color_box: VBoxContainer = $ControlDock/PanelContainer/DockVBox/TabViews/RingsView/RingsColorBox
@onready var rings_color_label: Label = $ControlDock/PanelContainer/DockVBox/TabViews/RingsView/RingsColorBox/Header/Label
@onready var rings_picker: ColorPickerButton = $ControlDock/PanelContainer/DockVBox/TabViews/RingsView/RingsColorBox/Header/ColorPicker
@onready var rings_swatches: HBoxContainer = $ControlDock/PanelContainer/DockVBox/TabViews/RingsView/RingsColorBox/SwatchesRow

# Bottom Action Buttons
@onready var random_btn: Button = $ControlDock/PanelContainer/DockVBox/ActionButtons/RandomBtn
@onready var launch_btn: Button = $ControlDock/PanelContainer/DockVBox/ActionButtons/LaunchBtn
@onready var back_btn: Button = $ControlDock/PanelContainer/DockVBox/ActionButtons/BackBtn

var current_editor_tab: String = "surface"

# 360-Degree Free Spherical Rotation (Arcball / Basis model without gimbal lock)
var planet_basis: Basis = Basis.IDENTITY
var rot_velocity: Vector2 = Vector2(0.06, 0.0) # gentle idle spin
var is_dragging: bool = false
var last_drag_pos: Vector2 = Vector2.ZERO
var camera_dist: float = 11.5
var target_camera_dist: float = 11.5

# Multi-touch pinch-to-zoom tracking
var active_touches: Dictionary = {}
var last_pinch_dist: float = 0.0
var is_pinching: bool = false

# Active State Colors
var current_surface_color: Color = Color(0.20, 0.55, 0.26) # Forest Green default
var current_atmo_color: Color = Color(0.30, 0.70, 1.0)     # Cyan Rayleigh default
var current_ring_color: Color = Color(0.85, 0.92, 1.0)     # Pearly Ice default
var is_volcanic_active: bool = false

# Predefined Preset Palettes
const SURFACE_PRESETS: Array[Dictionary] = [
	{"key": "color_forest_green", "color": Color(0.20, 0.55, 0.26), "volcanic": false},
	{"key": "color_oceanic_blue", "color": Color(0.15, 0.45, 0.75), "volcanic": false},
	{"key": "color_desert_rust", "color": Color(0.78, 0.38, 0.18), "volcanic": false},
	{"key": "color_rocky_grey", "color": Color(0.48, 0.48, 0.50), "volcanic": false},
	{"key": "color_cryo_azure", "color": Color(0.25, 0.55, 0.85), "volcanic": false},
	{"key": "color_volcanic_obsidian", "color": Color(0.22, 0.10, 0.12), "volcanic": true}
]

const ATMO_PRESETS: Array[Dictionary] = [
	{"key": "atmo_earth_cyan", "color": Color(0.30, 0.70, 1.0)},
	{"key": "atmo_golden_dust", "color": Color(0.95, 0.75, 0.30)},
	{"key": "atmo_alien_emerald", "color": Color(0.25, 0.85, 0.45)},
	{"key": "atmo_crimson_haze", "color": Color(0.95, 0.30, 0.25)},
	{"key": "atmo_violet_aurora", "color": Color(0.80, 0.35, 1.0)},
	{"key": "atmo_vacuum", "color": Color(0.02, 0.02, 0.03)}
]

const RINGS_PRESETS: Array[Dictionary] = [
	{"key": "rings_ice", "color": Color(0.85, 0.92, 1.0)},
	{"key": "rings_dust", "color": Color(0.90, 0.80, 0.60)},
	{"key": "rings_obsidian", "color": Color(0.45, 0.40, 0.38)},
	{"key": "rings_plasma", "color": Color(0.85, 0.40, 1.0)}
]

const RANDOM_NAMES: Array[String] = [
	"Aurelia Prime", "Kepler-452c", "Gliese-667 Cc", "Epsilon-Eridani II",
	"Verdant Alpha", "Titanis Major", "Tartarus Prime", "Caelum IV",
	"Novus Terra", "Vespera VII", "Cryo-Prometheus", "Solaris Minor",
	"Astraea IX", "Hyperion Beta", "Zenith Sector"
]

func _ready() -> void:
	# Initialize rotation basis
	if planet_pivot:
		planet_basis = planet_pivot.transform.basis.orthonormalized()

	# Connect 3D Arcball drag overlay
	if drag_area:
		drag_area.gui_input.connect(_on_drag_area_gui_input)

	# Connect Sliders
	radius_slider.value_changed.connect(_on_radius_changed)
	gravity_slider.value_changed.connect(_on_gravity_changed)
	temp_slider.value_changed.connect(_on_temp_changed)
	atmo_slider.value_changed.connect(_on_atmo_changed)
	water_slider.value_changed.connect(_on_water_changed)

	# Connect Color Pickers
	surface_picker.color_changed.connect(_on_surface_picker_changed)
	atmo_picker.color_changed.connect(_on_atmo_picker_changed)
	rings_picker.color_changed.connect(_on_rings_picker_changed)

	# Connect Rings Toggle
	rings_toggle.toggled.connect(_on_rings_toggled)

	# Connect Buttons
	random_btn.pressed.connect(_on_random_pressed)
	launch_btn.pressed.connect(_on_launch_pressed)
	back_btn.pressed.connect(_on_back_pressed)

	# Connect Tab Buttons
	tab_surface_btn.pressed.connect(func(): _switch_editor_tab("surface"))
	tab_atmo_btn.pressed.connect(func(): _switch_editor_tab("atmosphere"))
	tab_ocean_btn.pressed.connect(func(): _switch_editor_tab("ocean"))
	tab_rings_btn.pressed.connect(func(): _switch_editor_tab("rings"))

	# Connect Stepper ◄/► Buttons
	radius_dec_btn.pressed.connect(func(): radius_slider.value = clampf(radius_slider.value - 0.2, radius_slider.min_value, radius_slider.max_value))
	radius_inc_btn.pressed.connect(func(): radius_slider.value = clampf(radius_slider.value + 0.2, radius_slider.min_value, radius_slider.max_value))

	gravity_dec_btn.pressed.connect(func(): gravity_slider.value = clampf(gravity_slider.value - 0.5, gravity_slider.min_value, gravity_slider.max_value))
	gravity_inc_btn.pressed.connect(func(): gravity_slider.value = clampf(gravity_slider.value + 0.5, gravity_slider.min_value, gravity_slider.max_value))

	atmo_dec_btn.pressed.connect(func(): atmo_slider.value = clampf(atmo_slider.value - 0.05, atmo_slider.min_value, atmo_slider.max_value))
	atmo_inc_btn.pressed.connect(func(): atmo_slider.value = clampf(atmo_slider.value + 0.05, atmo_slider.min_value, atmo_slider.max_value))

	temp_dec_btn.pressed.connect(func(): temp_slider.value = clampf(temp_slider.value - 5.0, temp_slider.min_value, temp_slider.max_value))
	temp_inc_btn.pressed.connect(func(): temp_slider.value = clampf(temp_slider.value + 5.0, temp_slider.min_value, temp_slider.max_value))

	water_dec_btn.pressed.connect(func(): water_slider.value = clampf(water_slider.value - 0.04, water_slider.min_value, water_slider.max_value))
	water_inc_btn.pressed.connect(func(): water_slider.value = clampf(water_slider.value + 0.04, water_slider.min_value, water_slider.max_value))

	# Create quick swatch buttons
	_build_swatch_buttons()

	# Listen for language change
	GameManager.language_changed.connect(_on_language_changed)

	# Setup initial defaults and shader
	_apply_localization()
	_update_slider_labels()
	_update_planet_shaders()
	_switch_editor_tab("surface")

func _switch_editor_tab(tab_name: String) -> void:
	current_editor_tab = tab_name
	surface_view.visible = (tab_name == "surface")
	atmo_view.visible = (tab_name == "atmosphere")
	ocean_view.visible = (tab_name == "ocean")
	rings_view.visible = (tab_name == "rings")
	
	tab_surface_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab_name == "surface" else Color(0.65, 0.72, 0.85, 0.75)
	tab_atmo_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab_name == "atmosphere" else Color(0.65, 0.72, 0.85, 0.75)
	tab_ocean_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab_name == "ocean" else Color(0.65, 0.72, 0.85, 0.75)
	tab_rings_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tab_name == "rings" else Color(0.65, 0.72, 0.85, 0.75)

func _process(delta: float) -> void:
	# Full 360-degree free spherical rotation in all directions
	if not is_dragging:
		var delta_rot_y = Basis(Vector3.UP, rot_velocity.x * delta)
		var delta_rot_x = Basis(Vector3.RIGHT, rot_velocity.y * delta)
		planet_basis = (delta_rot_y * delta_rot_x * planet_basis).orthonormalized()
		
		rot_velocity.y = lerp(rot_velocity.y, 0.0, delta * 3.5)
		rot_velocity.x = lerp(rot_velocity.x, 0.06, delta * 1.8)

	if planet_pivot:
		planet_pivot.transform.basis = planet_basis

	# Camera zoom interpolation
	camera_dist = lerp(camera_dist, target_camera_dist, delta * 8.0)
	if camera_3d:
		camera_3d.position.z = camera_dist

# ----------------- Arcball Drag Interaction -----------------

func _on_drag_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_drag_pos = event.position
			else:
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_camera_dist = clampf(target_camera_dist - 0.6, 5.5, 18.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_camera_dist = clampf(target_camera_dist + 0.6, 5.5, 18.0)

	elif event is InputEventMouseMotion and is_dragging:
		var delta_pos = event.position - last_drag_pos
		last_drag_pos = event.position
		_apply_free_drag(delta_pos)

	elif event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			if active_touches.size() == 1:
				is_dragging = true
				last_drag_pos = event.position
				is_pinching = false
			elif active_touches.size() >= 2:
				is_pinching = true
				is_dragging = false
				var keys = active_touches.keys()
				last_pinch_dist = active_touches[keys[0]].distance_to(active_touches[keys[1]])
		else:
			active_touches.erase(event.index)
			if active_touches.size() == 1:
				is_pinching = false
				is_dragging = true
				var remaining_key = active_touches.keys()[0]
				last_drag_pos = active_touches[remaining_key]
			elif active_touches.size() == 0:
				is_pinching = false
				is_dragging = false

	elif event is InputEventScreenDrag:
		active_touches[event.index] = event.position
		if active_touches.size() >= 2:
			is_pinching = true
			is_dragging = false
			var keys = active_touches.keys()
			var current_dist = active_touches[keys[0]].distance_to(active_touches[keys[1]])
			if last_pinch_dist > 0.0:
				var pinch_delta = current_dist - last_pinch_dist
				target_camera_dist = clampf(target_camera_dist - pinch_delta * 0.035, 5.5, 18.0)
			last_pinch_dist = current_dist
		elif is_dragging and not is_pinching:
			_apply_free_drag(event.relative)

func _apply_free_drag(delta_pos: Vector2) -> void:
	var rot_speed = 0.0055
	var angle_x = delta_pos.x * rot_speed
	var angle_y = delta_pos.y * rot_speed

	var rot_h = Basis(Vector3.UP, angle_x)
	var rot_v = Basis(Vector3.RIGHT, angle_y)
	planet_basis = (rot_h * rot_v * planet_basis).orthonormalized()
	rot_velocity = delta_pos * rot_speed * 18.0

# ----------------- Swatch Buttons Generation -----------------

func _build_swatch_buttons() -> void:
	# Surface swatches
	for s in SURFACE_PRESETS:
		var btn = _create_swatch_button(s["color"], s["key"])
		var c: Color = s["color"]
		var is_volc: bool = s.get("volcanic", false)
		btn.pressed.connect(func():
			_set_surface_preset(c, is_volc)
		)
		surface_swatches.add_child(btn)

	# Atmosphere swatches
	for a in ATMO_PRESETS:
		var btn = _create_swatch_button(a["color"], a["key"])
		var c: Color = a["color"]
		btn.pressed.connect(func():
			_set_atmo_preset(c)
		)
		atmo_swatches.add_child(btn)

	# Rings swatches
	for r in RINGS_PRESETS:
		var btn = _create_swatch_button(r["color"], r["key"])
		var c: Color = r["color"]
		btn.pressed.connect(func():
			_set_rings_preset(c)
		)
		rings_swatches.add_child(btn)

func _create_swatch_button(color: Color, tooltip_key: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(34, 30)
	btn.tooltip_text = GameManager.loc(tooltip_key)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 1.0, 1.0, 0.45)
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	return btn

# ----------------- Preset Selectors -----------------

func _set_surface_preset(color: Color, is_volcanic: bool) -> void:
	AudioManager.play("click")
	current_surface_color = color
	surface_picker.color = color
	is_volcanic_active = is_volcanic
	_update_planet_shaders()

func _set_atmo_preset(color: Color) -> void:
	AudioManager.play("click")
	current_atmo_color = color
	atmo_picker.color = color
	_update_planet_shaders()

func _set_rings_preset(color: Color) -> void:
	AudioManager.play("click")
	current_ring_color = color
	rings_picker.color = color
	_update_planet_shaders()

# ----------------- Slider & Color Callbacks -----------------

func _on_radius_changed(_val: float) -> void:
	_update_slider_labels()
	_update_planet_shaders()

func _on_gravity_changed(_val: float) -> void:
	_update_slider_labels()
	_update_planet_shaders()

func _on_temp_changed(_val: float) -> void:
	_update_slider_labels()
	_update_planet_shaders()

func _on_atmo_changed(_val: float) -> void:
	_update_slider_labels()
	_update_planet_shaders()

func _on_water_changed(_val: float) -> void:
	_update_slider_labels()
	_update_planet_shaders()

func _on_surface_picker_changed(color: Color) -> void:
	current_surface_color = color
	is_volcanic_active = false
	_update_planet_shaders()

func _on_atmo_picker_changed(color: Color) -> void:
	current_atmo_color = color
	_update_planet_shaders()

func _on_rings_picker_changed(color: Color) -> void:
	current_ring_color = color
	_update_planet_shaders()

func _on_rings_toggled(button_pressed: bool) -> void:
	AudioManager.play("click")
	rings_color_box.visible = button_pressed
	if rings_mesh:
		rings_mesh.visible = button_pressed
	_update_planet_shaders()

# ----------------- Live Shader & Mesh Updates -----------------

func _update_slider_labels() -> void:
	var r_val = radius_slider.value
	radius_val_label.text = "%.1f R⊕" % r_val

	var g_val = gravity_slider.value
	var g_norm = g_val / 9.8
	gravity_val_label.text = "%.1f m/s² (%.2f G)" % [g_val, g_norm]

	var t_val = temp_slider.value
	temp_val_label.text = "%+d °C" % int(t_val)
	if t_val < -40:
		temp_val_label.modulate = Color(0.4, 0.8, 1.0)
	elif t_val > 50:
		temp_val_label.modulate = Color(1.0, 0.5, 0.2)
	else:
		temp_val_label.modulate = Color(0.3, 1.0, 0.5)

	var a_val = atmo_slider.value
	atmo_val_label.text = "%.2f atm" % a_val

	var w_val = water_slider.value
	water_val_label.text = "%d %%" % int(w_val * 100.0)

func _update_planet_shaders() -> void:
	if not planet_mesh:
		return

	var mat = planet_mesh.get_surface_override_material(0) as ShaderMaterial
	if not mat:
		mat = planet_mesh.material_override as ShaderMaterial
	if not mat:
		return

	var r_val = radius_slider.value
	var atmo_val = atmo_slider.value
	var has_atmo = atmo_val > 0.05
	var temp_val = temp_slider.value
	var water_val = water_slider.value

	# Update sphere mesh geometry radius dynamically
	if planet_mesh.mesh is SphereMesh:
		var sp = planet_mesh.mesh as SphereMesh
		sp.radius = r_val
		sp.height = r_val * 2.0

	# Update rings mesh geometry size proportionally
	if rings_mesh and rings_mesh.mesh is QuadMesh:
		var qm = rings_mesh.mesh as QuadMesh
		qm.size = Vector2(r_val * 4.0, r_val * 4.0)

	# Derive terrain and environmental colors
	var land_col = current_surface_color
	var mountain_col = current_surface_color.darkened(0.28).lerp(Color(0.40, 0.36, 0.32), 0.35)
	var beach_col = current_surface_color.lightened(0.25).lerp(Color(0.80, 0.74, 0.52), 0.40)
	var peak_col = Color(0.92, 0.96, 1.0)
	var ocean_col = Color(0.04, 0.22, 0.55)
	var shore_col = Color(0.12, 0.48, 0.72)
	var emission_col = Color.BLACK
	var emission_energy = 0.0

	if is_volcanic_active or temp_val >= 95.0:
		ocean_col = Color(1.0, 0.32, 0.02) # glowing magma
		shore_col = Color(1.0, 0.65, 0.05)
		beach_col = Color(0.85, 0.40, 0.05)
		peak_col = Color(0.55, 0.22, 0.15)
		emission_col = Color(1.0, 0.40, 0.05)
		emission_energy = 3.8
	elif temp_val <= -40.0:
		ocean_col = Color(0.08, 0.28, 0.55) # frozen cryogenic sea
		shore_col = Color(0.20, 0.52, 0.75)
		beach_col = Color(0.70, 0.88, 0.98)
		peak_col = Color(0.96, 0.98, 1.0)

	var cloud_col = Color.WHITE
	var cloud_density = 0.0
	var fresnel_intensity = 0.0
	var atmo_color_final = Color.BLACK

	if has_atmo:
		cloud_density = clampf(atmo_val * 0.42, 0.08, 0.88)
		fresnel_intensity = clampf(atmo_val * 1.5, 0.6, 3.8)
		atmo_color_final = current_atmo_color
	else:
		cloud_density = 0.0
		fresnel_intensity = 0.0
		atmo_color_final = Color.BLACK

	# Apply shader parameters to planet
	mat.set_shader_parameter("ocean_color", ocean_col)
	mat.set_shader_parameter("shore_color", shore_col)
	mat.set_shader_parameter("beach_color", beach_col)
	mat.set_shader_parameter("land_color", land_col)
	mat.set_shader_parameter("mountain_color", mountain_col)
	mat.set_shader_parameter("peak_color", peak_col)
	mat.set_shader_parameter("atmosphere_color", atmo_color_final)
	mat.set_shader_parameter("cloud_color", cloud_col)
	mat.set_shader_parameter("emission_color", emission_col)
	mat.set_shader_parameter("emission_energy", emission_energy)
	mat.set_shader_parameter("water_threshold", water_val)
	mat.set_shader_parameter("mountain_threshold", clampf(water_val + 0.22, 0.45, 0.82))
	mat.set_shader_parameter("peak_threshold", clampf(water_val + 0.38, 0.65, 0.94))
	mat.set_shader_parameter("cloud_density", cloud_density)
	mat.set_shader_parameter("fresnel_intensity", fresnel_intensity)

	# Update Rings Material
	if rings_mesh:
		rings_mesh.visible = rings_toggle.button_pressed
		if rings_toggle.button_pressed:
			var ring_mat = rings_mesh.material_override as ShaderMaterial
			if ring_mat:
				ring_mat.set_shader_parameter("ring_color", current_ring_color)

	_update_classification_badge()

func _update_classification_badge() -> void:
	var temp_dict = _get_preview_state_dict()
	var lvl = SolarSystemClass.determine_level(temp_dict)
	
	var lvl_text = "%s %d" % [GameManager.loc("level"), lvl]
	var type_name = ""
	var badge_color = Color.WHITE

	match lvl:
		0:
			type_name = "HABITABLE (Clase H)"
			badge_color = Color(0.25, 0.95, 0.45)
		1:
			type_name = "DESÉRTICO / VACÍO (Clase D)"
			badge_color = Color(0.95, 0.65, 0.25)
		2:
			type_name = "TÓXICO CORROSIVO (Clase V)"
			badge_color = Color(0.85, 0.85, 0.15)
		3:
			type_name = "GLACIAR CRIOGÉNICO (Clase K)"
			badge_color = Color(0.35, 0.85, 1.0)
		4:
			type_name = "SINGULARIDAD (Clase X • PRO)"
			badge_color = Color(0.85, 0.35, 1.0)
		5:
			type_name = "INFIERNO ÍGNEO (Clase S • PRO)"
			badge_color = Color(1.0, 0.25, 0.15)

	class_badge.text = "[ %s • %s ]" % [lvl_text, type_name]
	class_badge.modulate = badge_color

	var tg = SolarSystemClass.calculate_telemetry_graph(temp_dict)
	var hab_pct = int(tg.get("habitability", 0.0) * 100.0)
	var danger_pct = int(tg.get("danger", 0.5) * 100.0)
	class_desc_label.text = "Habitabilidad: %d%%  |  Riesgo: %d%%" % [hab_pct, danger_pct]

func _get_preview_state_dict() -> Dictionary:
	var atmo_val = atmo_slider.value
	var has_atmo = atmo_val > 0.05
	var temp_val = temp_slider.value
	var water_val = water_slider.value
	var grav_ms2 = gravity_slider.value
	var grav_g = grav_ms2 / 9.8

	var water_status = "Seco / Desolado"
	if water_val > 0.05:
		if temp_val <= -40.0:
			water_status = "Hielo Criogénico"
		elif temp_val >= 90.0 or is_volcanic_active:
			water_status = "Lava Fundida"
		else:
			water_status = "Líquida"

	var has_oxy = (has_atmo and atmo_val >= 0.7 and atmo_val <= 1.6 and temp_val >= -15.0 and temp_val <= 45.0 and water_status == "Líquida")
	var is_molten = (water_status == "Lava Fundida" or is_volcanic_active)
	var is_singularity = (grav_g >= 2.25)

	return {
		"is_in_habitable_zone": has_oxy,
		"has_atmosphere": has_atmo,
		"has_oxygen": has_oxy,
		"water_status": water_status,
		"temperature": temp_val,
		"gravity_g": grav_g,
		"gravity": grav_ms2,
		"radiation": 0.02 if has_oxy else (0.85 if is_singularity else 0.25),
		"atmosphere": atmo_val,
		"is_molten": is_molten,
		"is_singularity": is_singularity
	}

# ----------------- Actions & Navigation -----------------

func _on_random_pressed() -> void:
	AudioManager.play("click")
	
	# Random name
	name_edit.text = RANDOM_NAMES[randi() % RANDOM_NAMES.size()]

	# Random parameters
	radius_slider.value = round(randf_range(2.2, 5.5) * 10.0) / 10.0
	gravity_slider.value = round(randf_range(2.0, 22.0) * 10.0) / 10.0
	temp_slider.value = round(randf_range(-140.0, 105.0))
	atmo_slider.value = round(randf_range(0.0, 3.8) * 100.0) / 100.0
	water_slider.value = round(randf_range(0.0, 0.78) * 100.0) / 100.0

	# Random surface preset
	var s_preset = SURFACE_PRESETS[randi() % SURFACE_PRESETS.size()]
	current_surface_color = s_preset["color"]
	surface_picker.color = current_surface_color
	is_volcanic_active = s_preset.get("volcanic", false)

	# Random atmo preset
	var a_preset = ATMO_PRESETS[randi() % ATMO_PRESETS.size()]
	current_atmo_color = a_preset["color"]
	atmo_picker.color = current_atmo_color

	# Random rings
	var rings_active = randf() > 0.65
	rings_toggle.button_pressed = rings_active
	rings_color_box.visible = rings_active
	var r_preset = RINGS_PRESETS[randi() % RINGS_PRESETS.size()]
	current_ring_color = r_preset["color"]
	rings_picker.color = current_ring_color

	_update_slider_labels()
	_update_planet_shaders()

func _on_launch_pressed() -> void:
	AudioManager.play("click")
	var custom_planet = build_planet_data()
	GameManager.select_planet(custom_planet)
	if AudioManager.has_method("play_gameplay_music"):
		AudioManager.play_gameplay_music()
	GameManager.start_expedition()

func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")

func build_planet_data() -> Dictionary:
	var state = _get_preview_state_dict()
	var lvl = SolarSystemClass.determine_level(state)

	var p_name = name_edit.text.strip_edges()
	if p_name.is_empty():
		p_name = "Genesis-01"

	var r_val = radius_slider.value
	var grav_ms2 = gravity_slider.value
	var grav_g = grav_ms2 / 9.8
	var temp_val = temp_slider.value
	var atmo_val = atmo_slider.value
	var water_val = water_slider.value
	var has_atmo = state["has_atmosphere"]
	var has_oxy = state["has_oxygen"]
	var water_status = state["water_status"]
	var is_molten = state["is_molten"]
	var is_singularity = state["is_singularity"]

	var type_label = "Personalizado (Arquitecto)"
	var type_str = "Arquitecto"
	match lvl:
		0:
			type_label = "Rocoso Templado (Clase H)"
			type_str = "Habitable"
		1:
			type_label = "Desierto Árido (Clase D)"
			type_str = "Desértico"
		2:
			type_label = "Sulfúrico Denso (Clase V)"
			type_str = "Tóxico"
		3:
			type_label = "Criogénico Glaciar (Clase K)"
			type_str = "Glaciar"
		4:
			type_label = "Abismo Singular (Clase X • PRO)"
			type_str = "Singularidad"
		5:
			type_label = "Infierno Ígneo (Clase S • PRO)"
			type_str = "Ígneo"

	var land_col = current_surface_color
	var mountain_col = current_surface_color.darkened(0.28).lerp(Color(0.40, 0.36, 0.32), 0.35)
	var beach_col = current_surface_color.lightened(0.25).lerp(Color(0.80, 0.74, 0.52), 0.40)
	var peak_col = Color(0.92, 0.96, 1.0)
	var ocean_col = Color(0.04, 0.22, 0.55)
	var shore_col = Color(0.12, 0.48, 0.72)
	var emission_col = Color.BLACK
	var emission_energy = 0.0

	if is_molten or temp_val >= 95.0:
		ocean_col = Color(1.0, 0.32, 0.02)
		shore_col = Color(1.0, 0.65, 0.05)
		beach_col = Color(0.85, 0.40, 0.05)
		peak_col = Color(0.55, 0.22, 0.15)
		emission_col = Color(1.0, 0.40, 0.05)
		emission_energy = 3.8
	elif temp_val <= -40.0:
		ocean_col = Color(0.08, 0.28, 0.55)
		shore_col = Color(0.20, 0.52, 0.75)
		beach_col = Color(0.70, 0.88, 0.98)
		peak_col = Color(0.96, 0.98, 1.0)

	var p: Dictionary = {
		"name": p_name,
		"index": 0,
		"level": lvl,
		"radius": r_val,
		"gravity": grav_ms2,
		"gravity_g": grav_g,
		"temperature": temp_val,
		"atmosphere": atmo_val,
		"has_atmosphere": has_atmo,
		"has_oxygen": has_oxy,
		"water_status": water_status,
		"water_threshold": water_val,
		"surface_color": current_surface_color,
		"land_color": land_col,
		"mountain_color": mountain_col,
		"beach_color": beach_col,
		"peak_color": peak_col,
		"ocean_color": ocean_col,
		"shore_color": shore_col,
		"atmosphere_color": current_atmo_color if has_atmo else Color.BLACK,
		"sky_color": (current_atmo_color.darkened(0.65) if has_atmo else Color.BLACK),
		"cloud_color": Color.WHITE if has_atmo else Color.BLACK,
		"cloud_density": (clampf(atmo_val * 0.42, 0.08, 0.88) if has_atmo else 0.0),
		"cloud_speed": 0.03,
		"emission_color": emission_col,
		"emission_energy": emission_energy,
		"noise_scale": 2.4,
		"mountain_threshold": clampf(water_val + 0.22, 0.45, 0.82),
		"peak_threshold": clampf(water_val + 0.38, 0.65, 0.94),
		"has_rings": rings_toggle.button_pressed,
		"ring_color": current_ring_color,
		"type_label": type_label,
		"type": type_str,
		"description": GameManager.loc("editor_custom_desc"),
		"seed": randi() % 1000000 + 7,
		"coords_str": "[MODO ARQUITECTO]",
		"orbit_au": 1.0,
		"radiation": 0.02 if has_oxy else (0.85 if is_singularity else 0.25),
		"is_locked": false,
		"is_molten": is_molten,
		"is_singularity": is_singularity,
		"is_architect_custom": true
	}
	p["telemetry_graph"] = SolarSystemClass.calculate_telemetry_graph(p)
	return p

# ----------------- Localization -----------------

func _apply_localization() -> void:
	title_label.text = GameManager.loc("architect_mode")
	subtitle_label.text = GameManager.loc("editor_subtitle")
	
	tab_surface_btn.text = "[ %s ]" % GameManager.loc("tab_surface")
	tab_atmo_btn.text = "[ %s ]" % GameManager.loc("tab_atmosphere")
	tab_ocean_btn.text = "[ %s ]" % GameManager.loc("tab_ocean")
	tab_rings_btn.text = "[ %s ]" % GameManager.loc("tab_rings")
	if name_label:
		name_label.text = "PLANETA:" if GameManager.current_language == "es" else "PLANET:"
	
	radius_label.text = GameManager.loc("radius_size")
	gravity_label.text = GameManager.loc("gravity_label")
	temp_label.text = GameManager.loc("temp_label")
	atmo_label.text = GameManager.loc("atmosphere_density")
	water_label.text = GameManager.loc("water_coverage")
	
	surface_label.text = GameManager.loc("surface_color")
	atmo_color_label.text = GameManager.loc("atmosphere_tint")
	rings_label.text = GameManager.loc("planetary_rings")
	rings_color_label.text = GameManager.loc("rings_tint")
	
	random_btn.text = GameManager.loc("randomize")
	launch_btn.text = GameManager.loc("launch_custom")
	back_btn.text = GameManager.loc("back_menu")
	
	name_edit.placeholder_text = GameManager.loc("planet_name")

func _on_language_changed(_new_lang: String) -> void:
	_apply_localization()
	_update_classification_badge()
