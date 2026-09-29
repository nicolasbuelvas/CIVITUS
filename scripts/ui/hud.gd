extends Control

@onready var mobile_layer: Control = $MobileLayer
@onready var virtual_joystick = $MobileLayer/VirtualJoystick
@onready var touch_camera_zone: Control = $MobileLayer/TouchCameraZone
@onready var jump_btn = $MobileLayer/ActionCluster/JumpBtn
@onready var context_action_btn = $MobileLayer/ActionCluster/ContextActionBtn
@onready var sprint_btn = $MobileLayer/ActionCluster/SprintBtn
@onready var cam_toggle_btn = get_node_or_null("MobileLayer/ActionCluster/CamToggleBtn")

var thrust_icon = preload("res://assets/sprites/icon_thrust.png")
var swim_icon = preload("res://assets/sprites/icon_swim.png")

@onready var o2_bar: ProgressBar = $TopLayer/VitalsPod/Margin/VBox/O2Row/O2Bar
@onready var o2_val_label: Label = $TopLayer/VitalsPod/Margin/VBox/O2Row/Val
@onready var fuel_bar: ProgressBar = $TopLayer/VitalsPod/Margin/VBox/FuelRow/FuelBar
@onready var fuel_val_label: Label = $TopLayer/VitalsPod/Margin/VBox/FuelRow/Val
@onready var hull_bar: ProgressBar = $TopLayer/VitalsPod/Margin/VBox/HullRow/HullBar
@onready var hull_val_label: Label = $TopLayer/VitalsPod/Margin/VBox/HullRow/Val

@onready var planet_name_label: Label = $TopLayer/Header/PlanetLabel
@onready var header_node: Control = $TopLayer/Header if has_node("TopLayer/Header") else null
@onready var hyperdrive_badge = $TopLayer/TopBarCluster/HyperdriveBadge if has_node("TopLayer/TopBarCluster/HyperdriveBadge") else $TopLayer/HyperdriveBadge
@onready var pause_btn = $TopLayer/TopBarCluster/PauseBtn if has_node("TopLayer/TopBarCluster/PauseBtn") else $TopLayer/PauseBtn
@onready var radar_btn = $TopLayer/RadarBtn if has_node("TopLayer/RadarBtn") else ($TopLayer/TopBarCluster/RadarBtn if has_node("TopLayer/TopBarCluster/RadarBtn") else null)
@onready var suit_alert_btn = $TopLayer/TopBarCluster/SuitAlertBtn if has_node("TopLayer/TopBarCluster/SuitAlertBtn") else null
@onready var headlamp_btn = $TopLayer/TopBarCluster/HeadlampBtn if has_node("TopLayer/TopBarCluster/HeadlampBtn") else null
@onready var top_layer: Control = $TopLayer
@onready var vitals_pod: Control = $TopLayer/VitalsPod

# Helmet Visor First-Person Overlay
@onready var jarvis_overlay: Control = $JarvisVisorOverlay

# Modals
@onready var pause_modal: Panel = $Modals/PauseModal
@onready var settings_modal: Panel = $Modals/SettingsModal
@onready var storage_modal: Panel = $Modals/StorageModal
@onready var crafting_modal: Panel = $Modals/CraftingModal
@onready var hyperdrive_modal: Panel = $Modals/HyperdriveModal
@onready var starmap_modal: Panel = $Modals/StarmapModal
@onready var game_over_modal: Panel = $Modals/GameOverModal
@onready var victory_modal: Panel = $Modals/VictoryModal
var astronaut_storage_modal: AstronautStorageModal = null

var cockpit_modal: Panel = null
var cockpit_title_lbl: Label = null
var cockpit_telemetry_lbl: Label = null
var cockpit_action_btn: Button = null
var cockpit_starmap_btn: Button = null
var cockpit_stand_btn: Button = null
var cockpit_ship_ref: Node3D = null

# Pause / Settings Buttons
@onready var pause_resume_btn: Button = $Modals/PauseModal/VBox/ResumeBtn
@onready var pause_settings_btn: Button = $Modals/PauseModal/VBox/SettingsBtn
@onready var pause_menu_btn: Button = $Modals/PauseModal/VBox/ExitMenuBtn

@onready var master_slider: HSlider = $Modals/SettingsModal/VBox/MasterSlider
@onready var music_slider: HSlider = $Modals/SettingsModal/VBox/MusicSlider
@onready var reset_defaults_btn: Button = $Modals/SettingsModal/VBox/ResetDefaultsBtn
@onready var close_settings_btn: Button = $Modals/SettingsModal/VBox/CloseSettingsBtn

# Storage UI
@onready var storage_iron_lbl: Label = $Modals/StorageModal/VBox/InvGrid/IronLabel
@onready var storage_copper_lbl: Label = $Modals/StorageModal/VBox/InvGrid/CopperLabel
@onready var storage_silicon_lbl: Label = $Modals/StorageModal/VBox/InvGrid/SiliconLabel
@onready var storage_uranium_lbl: Label = $Modals/StorageModal/VBox/InvGrid/UraniumLabel
@onready var deposit_all_btn: Button = $Modals/StorageModal/VBox/DepositAllBtn
@onready var close_storage_btn: Button = $Modals/StorageModal/VBox/CloseStorageBtn

# Crafting UI labels
@onready var inv_iron_label: Label = $Modals/CraftingModal/VBox/InvGrid/IronLabel
@onready var inv_copper_label: Label = $Modals/CraftingModal/VBox/InvGrid/CopperLabel
@onready var inv_silicon_label: Label = $Modals/CraftingModal/VBox/InvGrid/SiliconLabel
@onready var inv_uranium_label: Label = $Modals/CraftingModal/VBox/InvGrid/UraniumLabel

# Hyperdrive UI
@onready var hyperdrive_status_label: Label = $Modals/HyperdriveModal/VBox/StatusLabel
@onready var hyperdrive_list_container: VBoxContainer = $Modals/HyperdriveModal/VBox/PartsList
@onready var launch_btn: Button = $Modals/HyperdriveModal/VBox/LaunchBtn
@onready var starmap_list: VBoxContainer = $Modals/StarmapModal/VBox/Scroll/PlanetList

var player: CharacterBody3D = null
var current_context_type: String = ""

# Multi-touch camera & pinch zoom tracking
var touch_cam_id: int = -1
var touch_cam_touches: Dictionary = {}
var initial_pinch_dist: float = 0.0
var is_mouse_looking: bool = false

# Mobile Orbital Flight Controls & Interplanetary Telemetry (Space Agency 2138 / KSP)
var orbital_controls_container: Control = null
var flight_pad_left: Control = null
var flight_pad_right: Control = null
var transit_banner: PanelContainer = null
var orbital_telemetry_lbl: Label = null
var orbital_fuel_bar: ProgressBar = null
var orbital_energy_bar: ProgressBar = null
var btn_quick_energy: Button = null
var btn_quick_fuel: Button = null
var transit_info_lbl: Label = null

var is_holding_pitch_up: bool = false
var is_holding_pitch_down: bool = false
var is_holding_yaw_left: bool = false
var is_holding_yaw_right: bool = false
var is_holding_thrust: bool = false
var is_holding_brake: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_all_modals()
	context_action_btn.visible = false
	_setup_orbital_flight_controls()
	_apply_custom_touch_layout()
	if top_layer:
		top_layer.visible = visible
	if mobile_layer:
		mobile_layer.visible = visible
	_update_header()
	_update_localization()
	
	if cam_toggle_btn:
		cam_toggle_btn.pressed.connect(_on_cam_toggle_pressed)
	if radar_btn:
		radar_btn.pressed.connect(toggle_top_radar)
	
	if player and visible:
		_on_first_person_toggled(player.is_first_person)
	else:
		if jarvis_overlay: jarvis_overlay.visible = false
		if vitals_pod: vitals_pod.visible = false
	
	# Sliders initialization
	if master_slider:
		master_slider.value = GameManager.get_setting("master_volume", 85.0)
		master_slider.value_changed.connect(_on_master_slider_changed)
	if music_slider:
		music_slider.value = GameManager.get_setting("music_volume", 70.0)
		music_slider.value_changed.connect(_on_music_slider_changed)
	
	GameManager.language_changed.connect(func(_l): _update_localization())
	GameManager.game_over.connect(_on_game_over)
	GameManager.expedition_completed.connect(_on_expedition_completed)
	GameManager.crafting.inventory_changed.connect(_update_crafting_ui)
	GameManager.crafting.hyperdrive_repaired.connect(func(_p): _update_hyperdrive_ui())
	GameManager.crafting.storage_changed.connect(_update_storage_ui)
	GameManager.crafting.inventory_full.connect(_on_inventory_full)
	
	# Initialize Astronaut Storage & Body Inventory Modal
	if not astronaut_storage_modal:
		astronaut_storage_modal = AstronautStorageModal.new()
		astronaut_storage_modal.name = "AstronautStorageModal"
		astronaut_storage_modal.visible = false
		astronaut_storage_modal.closed.connect(func():
			get_tree().paused = false
		)
		var modals_node = get_node_or_null("Modals")
		if modals_node:
			modals_node.add_child(astronaut_storage_modal)
			
	_setup_backpack_btn()
	_setup_top_bar_buttons()
	_setup_modal_art_styling()
	add_to_group("hud")
	
	_update_crafting_ui()
	_update_hyperdrive_ui()

func _update_localization() -> void:
	_update_header()
	
	# Vitals Pod
	var o2_lbl = get_node_or_null("TopLayer/VitalsPod/Margin/VBox/O2Row/Label")
	if o2_lbl: o2_lbl.text = GameManager.loc("o2_label")
	var fuel_lbl = get_node_or_null("TopLayer/VitalsPod/Margin/VBox/FuelRow/Label")
	if fuel_lbl: fuel_lbl.text = GameManager.loc("fuel_label")
	var hull_lbl = get_node_or_null("TopLayer/VitalsPod/Margin/VBox/HullRow/Label")
	if hull_lbl: hull_lbl.text = GameManager.loc("hull_label")
	
	# Pause Modal
	var pause_title = get_node_or_null("Modals/PauseModal/VBox/Title")
	if pause_title: pause_title.text = GameManager.loc("pause_title")
	if pause_resume_btn: pause_resume_btn.text = GameManager.loc("resume_btn")
	if pause_settings_btn: pause_settings_btn.text = GameManager.loc("settings")
	if pause_menu_btn: pause_menu_btn.text = GameManager.loc("return_menu")
	
	# Storage Modal
	var storage_title = get_node_or_null("Modals/StorageModal/VBox/Title")
	if storage_title: storage_title.text = GameManager.loc("storage_title")
	if deposit_all_btn: deposit_all_btn.text = GameManager.loc("deposit_all")
	if close_storage_btn: close_storage_btn.text = GameManager.loc("close_modal")
	_update_storage_ui()
	
	# Crafting Modal
	var craft_title = get_node_or_null("Modals/CraftingModal/VBox/Title")
	if craft_title: craft_title.text = GameManager.loc("crafting_title")
	var close_craft_btn = get_node_or_null("Modals/CraftingModal/VBox/CloseBtn")
	if close_craft_btn: close_craft_btn.text = GameManager.loc("close_modal")
	_update_crafting_ui()
	
	# Hyperdrive Modal
	var hd_title = get_node_or_null("Modals/HyperdriveModal/VBox/Title")
	if hd_title: hd_title.text = "HYPERDRIVE"
	var close_hd_btn = get_node_or_null("Modals/HyperdriveModal/VBox/CloseHyperBtn")
	if not close_hd_btn:
		close_hd_btn = get_node_or_null("Modals/HyperdriveModal/VBox/CloseBtn")
	if close_hd_btn: close_hd_btn.text = GameManager.loc("close_modal")
	if launch_btn: launch_btn.text = GameManager.loc("hyperdrive_activate")
	_update_hyperdrive_ui()
	
	# Starmap Modal
	var starmap_title = get_node_or_null("Modals/StarmapModal/VBox/Title")
	if starmap_title: starmap_title.text = GameManager.loc("starmap_title")
	var close_sm_btn = get_node_or_null("Modals/StarmapModal/VBox/CloseBtn")
	if close_sm_btn: close_sm_btn.text = GameManager.loc("close_modal")
	
	# GameOver Modal
	var go_title = get_node_or_null("Modals/GameOverModal/VBox/Title")
	if go_title: go_title.text = GameManager.loc("game_over_title")
	var retry_btn = get_node_or_null("Modals/GameOverModal/VBox/RetryBtn")
	if retry_btn: retry_btn.text = "⟳ " + GameManager.loc("retry_btn")
	var menu_btn = get_node_or_null("Modals/GameOverModal/VBox/MenuBtn")
	if menu_btn: menu_btn.text = "⌂ " + GameManager.loc("return_menu")
	
	# Victory Modal
	var vic_title = get_node_or_null("Modals/VictoryModal/VBox/Title")
	if vic_title: vic_title.text = "★ " + GameManager.loc("victory_title")
	var vic_menu_btn = get_node_or_null("Modals/VictoryModal/VBox/MenuBtn")
	if vic_menu_btn: vic_menu_btn.text = "⌂ " + GameManager.loc("return_menu")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M or event.keycode == KEY_R:
			toggle_top_radar()
			return

	if event.is_action_pressed("ui_cancel"):
		if settings_modal.visible:
			_on_close_settings_pressed()
		elif storage_modal.visible:
			_on_close_storage_pressed()
		elif pause_modal.visible:
			_on_pause_resume_pressed()
		else:
			_on_pause_btn_pressed()

func toggle_top_radar() -> void:
	if jarvis_overlay:
		jarvis_overlay.is_radar_expanded = !jarvis_overlay.is_radar_expanded
		jarvis_overlay.visible = jarvis_overlay.is_radar_expanded or (player and player.is_first_person)
		jarvis_overlay.queue_redraw()
		if AudioManager.has_method("play"):
			AudioManager.play("click", 1.0)

func close_all_modals() -> void:
	if pause_modal: pause_modal.visible = false
	if settings_modal: settings_modal.visible = false
	if storage_modal: storage_modal.visible = false
	if astronaut_storage_modal: astronaut_storage_modal.visible = false
	if cockpit_modal: cockpit_modal.visible = false
	crafting_modal.visible = false
	hyperdrive_modal.visible = false
	starmap_modal.visible = false
	game_over_modal.visible = false
	victory_modal.visible = false
	get_tree().paused = false

func init_player(p: CharacterBody3D) -> void:
	player = p
	player.stats_changed.connect(_on_stats_changed)
	player.interaction_available.connect(_on_interaction_available)
	player.interaction_lost.connect(_on_interaction_lost)
	player.first_person_toggled.connect(_on_first_person_toggled)
	if player.has_signal("headlamp_toggled") and not player.headlamp_toggled.is_connected(_on_headlamp_toggled):
		player.headlamp_toggled.connect(_on_headlamp_toggled)
	if visible:
		_on_first_person_toggled(player.is_first_person)
		if headlamp_btn and "is_headlamp_on" in player:
			headlamp_btn.is_active = player.is_headlamp_on

func activate_hud() -> void:
	visible = true
	if top_layer:
		top_layer.visible = true
	if mobile_layer:
		mobile_layer.visible = true
	if player:
		_on_first_person_toggled(player.is_first_person)
		if headlamp_btn and "is_headlamp_on" in player:
			headlamp_btn.is_active = player.is_headlamp_on

func _setup_top_bar_buttons() -> void:
	if suit_alert_btn and not suit_alert_btn.pressed.is_connected(_on_suit_alert_btn_pressed):
		suit_alert_btn.pressed.connect(_on_suit_alert_btn_pressed)
	if headlamp_btn and not headlamp_btn.pressed.is_connected(_on_headlamp_btn_pressed):
		headlamp_btn.pressed.connect(_on_headlamp_btn_pressed)

func _on_headlamp_btn_pressed() -> void:
	if player and player.has_method("toggle_headlamp"):
		var on = player.toggle_headlamp()
		if headlamp_btn:
			headlamp_btn.is_active = on

func _on_headlamp_toggled(is_on: bool) -> void:
	if headlamp_btn:
		headlamp_btn.is_active = is_on

func _on_suit_alert_btn_pressed() -> void:
	AudioManager.play("click")
	if player and player.has_method("toggle_first_person"):
		if not player.is_first_person:
			player.toggle_first_person()
	if suit_alert_btn:
		suit_alert_btn.is_active = false

func trigger_suit_eva_alert(custom_msg: String = "") -> void:
	if suit_alert_btn:
		suit_alert_btn.is_active = true
	var msg = custom_msg if custom_msg != "" else "SISTEMAS EVA ACTIVOS • TRAJE NOMINAL"
	show_status_toast(msg, 2.8)

func _on_cam_toggle_pressed() -> void:
	AudioManager.play("click")
	if player and player.has_method("toggle_first_person"):
		player.toggle_first_person()

func _on_first_person_toggled(is_fps: bool) -> void:
	if not visible:
		return
	if top_layer:
		top_layer.visible = true
	if vitals_pod:
		vitals_pod.visible = is_fps
	if header_node:
		header_node.visible = not is_fps
	if hyperdrive_badge:
		hyperdrive_badge.visible = not is_fps
	if suit_alert_btn:
		suit_alert_btn.visible = not is_fps
		if is_fps:
			suit_alert_btn.is_active = false
	if cam_toggle_btn:
		if "is_active" in cam_toggle_btn:
			cam_toggle_btn.is_active = is_fps
		cam_toggle_btn.text = ""
	if jarvis_overlay:
		jarvis_overlay.visible = is_fps
		if is_fps and visible:
			AudioManager.play("jarvis", 1.0)
			var tween = create_tween()
			jarvis_overlay.modulate.a = 0.0
			tween.tween_property(jarvis_overlay, "modulate:a", 1.0, 0.25)

func _update_header() -> void:
	var p = GameManager.current_planet
	planet_name_label.text = str(p.get("name", "Civitus-Alpha"))

func _on_stats_changed(o2: float, fuel: float, hull: float) -> void:
	if o2_bar: o2_bar.value = o2
	if o2_val_label: o2_val_label.text = "%d%%" % int(o2)
	if fuel_bar: fuel_bar.value = fuel
	if fuel_val_label: fuel_val_label.text = "%d%%" % int(fuel)
	if hull_bar: hull_bar.value = hull
	if hull_val_label: hull_val_label.text = "%d%%" % int(hull)
	
	if player and not player.is_first_person and vitals_pod:
		vitals_pod.visible = (o2 < 20.0 or hull < 25.0)

	# Dynamic Jetpack vs Swim Button Icon
	if jump_btn and is_instance_valid(player):
		var is_swimming_manual = player.is_in_liquid and fuel <= 0.01
		var target_icon = swim_icon if is_swimming_manual else thrust_icon
		if jump_btn.texture_normal != target_icon:
			jump_btn.texture_normal = target_icon

# Multi-Touch Camera Drag & Two-Finger Pinch Zoom (Excluding Joystick)
func _on_touch_camera_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_cam_touches[event.index] = event.position
			if touch_cam_touches.size() == 1:
				touch_cam_id = event.index
			elif touch_cam_touches.size() >= 2:
				touch_cam_id = -1 # Prevent accidental look while pinching!
				var keys = touch_cam_touches.keys()
				initial_pinch_dist = (touch_cam_touches[keys[0]] - touch_cam_touches[keys[1]]).length()
		else:
			touch_cam_touches.erase(event.index)
			if touch_cam_touches.size() == 1:
				touch_cam_id = touch_cam_touches.keys()[0]
			else:
				touch_cam_id = -1
	elif event is InputEventScreenDrag:
		touch_cam_touches[event.index] = event.position
		if touch_cam_touches.size() >= 2:
			var keys = touch_cam_touches.keys()
			var cur_dist = (touch_cam_touches[keys[0]] - touch_cam_touches[keys[1]]).length()
			if initial_pinch_dist > 15.0 and abs(cur_dist - initial_pinch_dist) > 2.0:
				var pinch_delta = (initial_pinch_dist - cur_dist) * 0.05
				if player and player.has_method("zoom_camera"):
					player.zoom_camera(pinch_delta)
			initial_pinch_dist = cur_dist
		elif touch_cam_touches.size() == 1 and event.index == touch_cam_id:
			if player and player.has_method("rotate_camera_by"):
				player.rotate_camera_by(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			is_mouse_looking = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if player and player.has_method("zoom_camera"):
				player.zoom_camera(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if player and player.has_method("zoom_camera"):
				player.zoom_camera(1.0)
	elif event is InputEventMouseMotion:
		if is_mouse_looking or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if player and player.has_method("rotate_camera_by"):
				player.rotate_camera_by(event.relative)

func _on_sprint_btn_pressed() -> void:
	if player:
		player.is_sprinting = not player.is_sprinting
		if sprint_btn:
			if "is_active" in sprint_btn:
				sprint_btn.is_active = player.is_sprinting
			sprint_btn.modulate = Color(1.0, 0.85, 0.2) if player.is_sprinting else Color(1.0, 1.0, 1.0, 0.9)

func _on_jump_down() -> void:
	Input.action_press("jump_thrust")

func _on_jump_up() -> void:
	Input.action_release("jump_thrust")

# Pause Menu
func _on_pause_btn_pressed() -> void:
	AudioManager.play("click")
	pause_modal.visible = true
	get_tree().paused = true

func _on_pause_resume_pressed() -> void:
	AudioManager.play("click")
	pause_modal.visible = false
	get_tree().paused = false

func _on_pause_settings_pressed() -> void:
	AudioManager.play("click")
	_setup_hud_settings_modular()
	_switch_hud_settings_tab(hud_settings_tab_idx)
	settings_modal.visible = true

func _on_pause_menu_pressed() -> void:
	AudioManager.play("click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")

# =============================================================================
# MODULAR 4-SUBSYSTEM PAUSE SETTINGS (AUDIO, VIDEO, CONTROLS, SYSTEM)
# =============================================================================
var hud_settings_initialized: bool = false
var hud_settings_subsystem_container: VBoxContainer = null
var hud_sub_panel_audio: VBoxContainer = null
var hud_sub_panel_graphics: VBoxContainer = null
var hud_sub_panel_controls: VBoxContainer = null
var hud_sub_panel_system: VBoxContainer = null

var hud_tab_btn_audio: Button = null
var hud_tab_btn_graphics: Button = null
var hud_tab_btn_controls: Button = null
var hud_tab_btn_system: Button = null

var hud_master_slider: HSlider = null
var hud_music_slider: HSlider = null
var hud_sfx_slider: HSlider = null
var hud_master_val_label: Label = null
var hud_music_val_label: Label = null
var hud_sfx_val_label: Label = null

var hud_fps_btn_30: Button = null
var hud_fps_btn_60: Button = null
var hud_fps_btn_max: Button = null

var hud_preset_btn_eco: Button = null
var hud_preset_btn_med: Button = null
var hud_preset_btn_high: Button = null

var hud_invert_y_btn: Button = null
var hud_lang_btn_es: Button = null
var hud_lang_btn_en: Button = null
var hud_settings_tab_idx: int = 0

func _on_master_slider_changed(val: float) -> void:
	GameManager.update_setting("master_volume", val)
	_update_hud_slider_labels()

func _on_music_slider_changed(val: float) -> void:
	GameManager.update_setting("music_volume", val)
	_update_hud_slider_labels()

func _on_close_settings_pressed() -> void:
	AudioManager.play("click")
	if is_instance_valid(settings_modal):
		settings_modal.visible = false

func _on_reset_settings_defaults_pressed() -> void:
	AudioManager.play("click")
	GameManager.reset_settings_to_default()
	if is_instance_valid(master_slider): master_slider.value = GameManager.master_volume
	if is_instance_valid(music_slider): music_slider.value = GameManager.music_volume
	_update_hud_slider_labels()

func _setup_hud_settings_modular() -> void:
	if hud_settings_initialized or not is_instance_valid(settings_modal):
		return
	hud_settings_initialized = true
	
	# Stylized Holographic Aerospace Card Style
	var panel_sb = StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.06, 0.05, 0.12, 0.98)
	panel_sb.border_color = Color(0.2, 0.85, 1.0, 0.85)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(14)
	panel_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	panel_sb.shadow_size = 20
	settings_modal.add_theme_stylebox_override("panel", panel_sb)
	settings_modal.custom_minimum_size = Vector2(520, 0)
	
	var vbox = settings_modal.get_node_or_null("VBox") as VBoxContainer
	if not vbox:
		return
	vbox.add_theme_constant_override("separation", 10)
	
	# Title
	var title_lbl = vbox.get_node_or_null("Title") as Label
	if title_lbl:
		title_lbl.text = "[ ⬡  AJUSTES // SETTINGS  ⬡ ]"
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_color_override("font_color", Color(0.96, 0.72, 0.22))
		title_lbl.add_theme_font_size_override("font_size", 16)
		
	# Hide legacy components
	for old_n in ["VolMasterLabel", "MasterSlider", "VolMusicLabel", "MusicSlider", "ResetDefaultsBtn", "CloseSettingsBtn"]:
		var node = vbox.get_node_or_null(old_n)
		if node: node.visible = false
		
	# Tab Header Bar
	var tab_bar = vbox.get_node_or_null("SubsystemTabBar") as HBoxContainer
	if not tab_bar:
		tab_bar = HBoxContainer.new()
		tab_bar.name = "SubsystemTabBar"
		tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		tab_bar.add_theme_constant_override("separation", 8)
		vbox.add_child(tab_bar)
		vbox.move_child(tab_bar, 1)
		
		hud_tab_btn_audio = _create_hud_tab_btn("🔊 AUDIO")
		hud_tab_btn_graphics = _create_hud_tab_btn("🖥️ VIDEO")
		hud_tab_btn_controls = _create_hud_tab_btn("🎮 CONTROLES")
		hud_tab_btn_system = _create_hud_tab_btn("🌐 SISTEMA")
		
		tab_bar.add_child(hud_tab_btn_audio)
		tab_bar.add_child(hud_tab_btn_graphics)
		tab_bar.add_child(hud_tab_btn_controls)
		tab_bar.add_child(hud_tab_btn_system)
		
		hud_tab_btn_audio.pressed.connect(func(): _switch_hud_settings_tab(0))
		hud_tab_btn_graphics.pressed.connect(func(): _switch_hud_settings_tab(1))
		hud_tab_btn_controls.pressed.connect(func(): _switch_hud_settings_tab(2))
		hud_tab_btn_system.pressed.connect(func(): _switch_hud_settings_tab(3))
		
	# Container for the 4 Subsystem Panels
	hud_settings_subsystem_container = vbox.get_node_or_null("Subsystems") as VBoxContainer
	if not hud_settings_subsystem_container:
		hud_settings_subsystem_container = VBoxContainer.new()
		hud_settings_subsystem_container.name = "Subsystems"
		hud_settings_subsystem_container.custom_minimum_size = Vector2(490, 0)
		vbox.add_child(hud_settings_subsystem_container)
		vbox.move_child(hud_settings_subsystem_container, 2)
		_build_hud_subsystem_panels()
		
	# Bottom Action Bar
	var action_bar = vbox.get_node_or_null("SettingsActionBar") as HBoxContainer
	if not action_bar:
		action_bar = HBoxContainer.new()
		action_bar.name = "SettingsActionBar"
		action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		action_bar.add_theme_constant_override("separation", 16)
		vbox.add_child(action_bar)
		
		# Save Button (✓)
		var btn_save = Button.new()
		btn_save.text = "✓"
		btn_save.custom_minimum_size = Vector2(80, 38)
		var save_sb = StyleBoxFlat.new()
		save_sb.bg_color = Color(0.12, 0.38, 0.22, 0.95)
		save_sb.border_color = Color(0.25, 0.95, 0.45)
		save_sb.set_border_width_all(2)
		save_sb.set_corner_radius_all(8)
		btn_save.add_theme_stylebox_override("normal", save_sb)
		btn_save.pressed.connect(func():
			AudioManager.play("click")
			GameManager.save_settings()
			settings_modal.visible = false
		)
		action_bar.add_child(btn_save)
		
		# Reset Defaults Button (↺)
		var btn_reset = Button.new()
		btn_reset.text = "↺"
		btn_reset.custom_minimum_size = Vector2(80, 38)
		var reset_sb = StyleBoxFlat.new()
		reset_sb.bg_color = Color(0.1, 0.2, 0.32, 0.95)
		reset_sb.border_color = Color(0.3, 0.8, 1.0)
		reset_sb.set_border_width_all(2)
		reset_sb.set_corner_radius_all(8)
		btn_reset.add_theme_stylebox_override("normal", reset_sb)
		btn_reset.pressed.connect(func():
			AudioManager.play("click")
			GameManager.reset_settings_to_default()
			if hud_master_slider: hud_master_slider.value = GameManager.master_volume
			if hud_music_slider: hud_music_slider.value = GameManager.music_volume
			if hud_sfx_slider: hud_sfx_slider.value = GameManager.sfx_volume
			_update_hud_slider_labels()
		)
		action_bar.add_child(btn_reset)
		
		# Close Button (✕)
		var btn_close = Button.new()
		btn_close.text = "✕"
		btn_close.custom_minimum_size = Vector2(80, 38)
		var close_sb = StyleBoxFlat.new()
		close_sb.bg_color = Color(0.32, 0.1, 0.12, 0.95)
		close_sb.border_color = Color(0.95, 0.35, 0.35)
		close_sb.set_border_width_all(2)
		close_sb.set_corner_radius_all(8)
		btn_close.add_theme_stylebox_override("normal", close_sb)
		btn_close.pressed.connect(func():
			AudioManager.play("click")
			settings_modal.visible = false
		)
		action_bar.add_child(btn_close)

func _create_hud_tab_btn(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(105, 32)
	btn.focus_mode = Control.FOCUS_NONE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.9)
	sb.border_color = Color(0.3, 0.4, 0.55, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_font_size_override("font_size", 11)
	return btn

func _build_hud_subsystem_panels() -> void:
	var track_sb = StyleBoxFlat.new()
	track_sb.bg_color = Color(0.12, 0.14, 0.22, 0.9)
	track_sb.set_corner_radius_all(4)
	track_sb.content_margin_top = 4
	track_sb.content_margin_bottom = 4

	var fill_sb = StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.2, 0.85, 1.0, 0.95)
	fill_sb.corner_radius_top_left = 4
	fill_sb.corner_radius_bottom_left = 4
	fill_sb.content_margin_top = 4
	fill_sb.content_margin_bottom = 4

	var val_badge_sb = StyleBoxFlat.new()
	val_badge_sb.bg_color = Color(0.09, 0.11, 0.18, 0.9)
	val_badge_sb.border_color = Color(0.2, 0.85, 1.0, 0.6)
	val_badge_sb.set_border_width_all(1)
	val_badge_sb.set_corner_radius_all(6)
	val_badge_sb.content_margin_left = 6
	val_badge_sb.content_margin_right = 6

	# 1. AUDIO PANEL
	hud_sub_panel_audio = VBoxContainer.new()
	hud_sub_panel_audio.name = "AudioPanel"
	hud_sub_panel_audio.add_theme_constant_override("separation", 10)
	hud_settings_subsystem_container.add_child(hud_sub_panel_audio)
	
	hud_master_slider = HSlider.new()
	hud_master_val_label = Label.new()
	hud_music_slider = HSlider.new()
	hud_music_val_label = Label.new()
	hud_sfx_slider = HSlider.new()
	hud_sfx_val_label = Label.new()
	
	hud_sub_panel_audio.add_child(_create_hud_slider_row("🔊", "MASTER", hud_master_slider, hud_master_val_label, track_sb, fill_sb, val_badge_sb))
	hud_sub_panel_audio.add_child(_create_hud_slider_row("🎵", "MÚSICA", hud_music_slider, hud_music_val_label, track_sb, fill_sb, val_badge_sb))
	hud_sub_panel_audio.add_child(_create_hud_slider_row("⚡", "EFECTOS", hud_sfx_slider, hud_sfx_val_label, track_sb, fill_sb, val_badge_sb))
	
	hud_master_slider.value = GameManager.master_volume
	hud_music_slider.value = GameManager.music_volume
	hud_sfx_slider.value = GameManager.sfx_volume
	_update_hud_slider_labels()
	
	hud_master_slider.value_changed.connect(func(v): GameManager.update_setting("master_volume", v); _update_hud_slider_labels())
	hud_music_slider.value_changed.connect(func(v): GameManager.update_setting("music_volume", v); _update_hud_slider_labels())
	hud_sfx_slider.value_changed.connect(func(v): GameManager.update_setting("sfx_volume", v); _update_hud_slider_labels())

	# 2. VIDEO PANEL
	hud_sub_panel_graphics = VBoxContainer.new()
	hud_sub_panel_graphics.name = "GraphicsPanel"
	hud_sub_panel_graphics.add_theme_constant_override("separation", 10)
	hud_settings_subsystem_container.add_child(hud_sub_panel_graphics)
	
	var fps_row = HBoxContainer.new()
	var fps_lbl = Label.new()
	fps_lbl.text = "⏱️ FPS // LÍMITE:"
	fps_lbl.custom_minimum_size = Vector2(170, 28)
	fps_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	fps_row.add_child(fps_lbl)
	hud_fps_btn_30 = _create_hud_pill_btn("30")
	hud_fps_btn_60 = _create_hud_pill_btn("60")
	hud_fps_btn_max = _create_hud_pill_btn("MAX")
	fps_row.add_child(hud_fps_btn_30)
	fps_row.add_child(hud_fps_btn_60)
	fps_row.add_child(hud_fps_btn_max)
	hud_fps_btn_30.pressed.connect(func(): _set_hud_fps_limit(30))
	hud_fps_btn_60.pressed.connect(func(): _set_hud_fps_limit(60))
	hud_fps_btn_max.pressed.connect(func(): _set_hud_fps_limit(0))
	hud_sub_panel_graphics.add_child(fps_row)
	_set_hud_fps_limit(Engine.max_fps)
	
	var pres_row = HBoxContainer.new()
	var pres_lbl = Label.new()
	pres_lbl.text = "🖥️ CALIDAD // SHADERS:"
	pres_lbl.custom_minimum_size = Vector2(170, 28)
	pres_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	pres_row.add_child(pres_lbl)
	hud_preset_btn_eco = _create_hud_pill_btn("ECO")
	hud_preset_btn_med = _create_hud_pill_btn("MEDIO")
	hud_preset_btn_high = _create_hud_pill_btn("ALTO")
	pres_row.add_child(hud_preset_btn_eco)
	pres_row.add_child(hud_preset_btn_med)
	pres_row.add_child(hud_preset_btn_high)
	hud_preset_btn_eco.pressed.connect(func(): _set_hud_quality_preset(0))
	hud_preset_btn_med.pressed.connect(func(): _set_hud_quality_preset(1))
	hud_preset_btn_high.pressed.connect(func(): _set_hud_quality_preset(2))
	hud_sub_panel_graphics.add_child(pres_row)
	_set_hud_quality_preset(1)

	# 3. CONTROLS PANEL
	hud_sub_panel_controls = VBoxContainer.new()
	hud_sub_panel_controls.name = "ControlsPanel"
	hud_sub_panel_controls.add_theme_constant_override("separation", 10)
	hud_settings_subsystem_container.add_child(hud_sub_panel_controls)
	
	var inv_row = HBoxContainer.new()
	var inv_lbl = Label.new()
	inv_lbl.text = "🎮 INVERTIR EJE Y:"
	inv_lbl.custom_minimum_size = Vector2(170, 28)
	inv_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	inv_row.add_child(inv_lbl)
	hud_invert_y_btn = _create_hud_pill_btn("NORMAL")
	inv_row.add_child(hud_invert_y_btn)
	hud_invert_y_btn.pressed.connect(func():
		var is_inv = hud_invert_y_btn.text == "INVERTIDO"
		hud_invert_y_btn.text = "NORMAL" if is_inv else "INVERTIDO"
		_style_hud_pill(hud_invert_y_btn, not is_inv)
		GameManager.update_setting("invert_y", not is_inv)
	)
	hud_sub_panel_controls.add_child(inv_row)

	var scale_row = HBoxContainer.new()
	var scale_lbl = Label.new()
	scale_lbl.text = "📱 TAMAÑO CONTROLES:"
	scale_lbl.custom_minimum_size = Vector2(170, 28)
	scale_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	scale_row.add_child(scale_lbl)
	var scale_s = _create_hud_pill_btn("CHICO")
	var scale_m = _create_hud_pill_btn("NORMAL")
	var scale_l = _create_hud_pill_btn("GRANDE")
	scale_row.add_child(scale_s)
	scale_row.add_child(scale_m)
	scale_row.add_child(scale_l)
	scale_s.pressed.connect(func():
		GameManager.update_setting("touch_scale", 0.85)
		_style_hud_pill(scale_s, true); _style_hud_pill(scale_m, false); _style_hud_pill(scale_l, false)
	)
	scale_m.pressed.connect(func():
		GameManager.update_setting("touch_scale", 1.0)
		_style_hud_pill(scale_s, false); _style_hud_pill(scale_m, true); _style_hud_pill(scale_l, false)
	)
	scale_l.pressed.connect(func():
		GameManager.update_setting("touch_scale", 1.2)
		_style_hud_pill(scale_s, false); _style_hud_pill(scale_m, false); _style_hud_pill(scale_l, true)
	)
	_style_hud_pill(scale_m, true)
	hud_sub_panel_controls.add_child(scale_row)

	# 4. SYSTEM PANEL
	hud_sub_panel_system = VBoxContainer.new()
	hud_sub_panel_system.name = "SystemPanel"
	hud_sub_panel_system.add_theme_constant_override("separation", 10)
	hud_settings_subsystem_container.add_child(hud_sub_panel_system)
	
	var lang_row = HBoxContainer.new()
	var lang_title = Label.new()
	lang_title.text = "🌐 IDIOMA // LANGUAGE:"
	lang_title.custom_minimum_size = Vector2(170, 32)
	lang_title.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	lang_row.add_child(lang_title)
	hud_lang_btn_es = _create_hud_pill_btn("🇪🇸 ESPAÑOL")
	hud_lang_btn_es.custom_minimum_size = Vector2(120, 32)
	hud_lang_btn_en = _create_hud_pill_btn("🇬🇧 ENGLISH")
	hud_lang_btn_en.custom_minimum_size = Vector2(120, 32)
	lang_row.add_child(hud_lang_btn_es)
	lang_row.add_child(hud_lang_btn_en)
	hud_lang_btn_es.pressed.connect(func(): _set_hud_language_pill("es"))
	hud_lang_btn_en.pressed.connect(func(): _set_hud_language_pill("en"))
	hud_sub_panel_system.add_child(lang_row)
	_set_hud_language_pill(GameManager.current_language)

	var unit_row = HBoxContainer.new()
	var unit_lbl = Label.new()
	unit_lbl.text = "🌡️ UNIDADES DE MEDIDA:"
	unit_lbl.custom_minimum_size = Vector2(170, 28)
	unit_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	unit_row.add_child(unit_lbl)
	var unit_c = _create_hud_pill_btn("°C / METRO")
	unit_c.custom_minimum_size = Vector2(120, 32)
	var unit_k = _create_hud_pill_btn("K / KILÓMETRO")
	unit_k.custom_minimum_size = Vector2(120, 32)
	unit_row.add_child(unit_c)
	unit_row.add_child(unit_k)
	unit_c.pressed.connect(func():
		GameManager.update_setting("units", "metric")
		_style_hud_pill(unit_c, true); _style_hud_pill(unit_k, false)
	)
	unit_k.pressed.connect(func():
		GameManager.update_setting("units", "kelvin")
		_style_hud_pill(unit_c, false); _style_hud_pill(unit_k, true)
	)
	_style_hud_pill(unit_c, true)
	hud_sub_panel_system.add_child(unit_row)

func _create_hud_slider_row(icon: String, title: String, slider: HSlider, val_lbl: Label, track_sb: StyleBox, fill_sb: StyleBox, val_badge_sb: StyleBox) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	
	var icon_lbl = Label.new()
	icon_lbl.text = icon
	icon_lbl.custom_minimum_size = Vector2(26, 28)
	row.add_child(icon_lbl)
	
	var t_lbl = Label.new()
	t_lbl.text = title
	t_lbl.custom_minimum_size = Vector2(90, 28)
	t_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	row.add_child(t_lbl)
	
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, 24)
	slider.add_theme_stylebox_override("slider", track_sb)
	slider.add_theme_stylebox_override("grabber_area", fill_sb)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_sb)
	row.add_child(slider)
	
	val_lbl.text = "100%"
	val_lbl.custom_minimum_size = Vector2(50, 24)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_stylebox_override("normal", val_badge_sb)
	val_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	row.add_child(val_lbl)
	
	return row

func _create_hud_pill_btn(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(70, 28)
	btn.focus_mode = Control.FOCUS_NONE
	_style_hud_pill(btn, false)
	return btn

func _style_hud_pill(btn: Button, active: bool) -> void:
	if not is_instance_valid(btn): return
	var sb = StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.18, 0.36, 0.55, 0.95)
		sb.border_color = Color(0.2, 0.95, 1.0)
		sb.set_border_width_all(2)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	else:
		sb.bg_color = Color(0.08, 0.1, 0.16, 0.8)
		sb.border_color = Color(0.25, 0.3, 0.42, 0.6)
		sb.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)

func _switch_hud_settings_tab(idx: int) -> void:
	hud_settings_tab_idx = idx
	var tabs = [hud_tab_btn_audio, hud_tab_btn_graphics, hud_tab_btn_controls, hud_tab_btn_system]
	var panels = [hud_sub_panel_audio, hud_sub_panel_graphics, hud_sub_panel_controls, hud_sub_panel_system]
	
	for i in range(tabs.size()):
		var btn = tabs[i]
		var pnl = panels[i]
		if not is_instance_valid(btn) or not is_instance_valid(pnl): continue
		var is_active = (i == idx)
		pnl.visible = is_active
		
		var sb = StyleBoxFlat.new()
		if is_active:
			sb.bg_color = Color(0.18, 0.24, 0.38, 0.95)
			sb.border_color = Color(0.96, 0.66, 0.16)
			sb.set_border_width_all(2)
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		else:
			sb.bg_color = Color(0.08, 0.10, 0.16, 0.85)
			sb.border_color = Color(0.25, 0.30, 0.42, 0.6)
			sb.set_border_width_all(1)
			btn.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
		sb.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sb)
		
	_adapt_hud_settings_size()

func _adapt_hud_settings_size() -> void:
	if not is_instance_valid(settings_modal): return
	var vbox = settings_modal.get_node_or_null("VBox") as VBoxContainer
	if not vbox: return
	vbox.reset_size()
	var min_h = vbox.get_combined_minimum_size().y + 44.0
	var min_w = 520.0
	settings_modal.offset_left = -min_w * 0.5
	settings_modal.offset_right = min_w * 0.5
	settings_modal.offset_top = -min_h * 0.5
	settings_modal.offset_bottom = min_h * 0.5

func _update_hud_slider_labels() -> void:
	if hud_master_val_label and hud_master_slider:
		hud_master_val_label.text = "%d%%" % int(hud_master_slider.value * 100.0)
	if hud_music_val_label and hud_music_slider:
		hud_music_val_label.text = "%d%%" % int(hud_music_slider.value * 100.0)
	if hud_sfx_val_label and hud_sfx_slider:
		hud_sfx_val_label.text = "%d%%" % int(hud_sfx_slider.value * 100.0)

func _set_hud_fps_limit(fps: int) -> void:
	Engine.max_fps = fps
	GameManager.update_setting("max_fps", fps)
	_style_hud_pill(hud_fps_btn_30, fps == 30)
	_style_hud_pill(hud_fps_btn_60, fps == 60)
	_style_hud_pill(hud_fps_btn_max, fps == 0)

func _set_hud_quality_preset(preset: int) -> void:
	GameManager.update_setting("quality_preset", preset)
	_style_hud_pill(hud_preset_btn_eco, preset == 0)
	_style_hud_pill(hud_preset_btn_med, preset == 1)
	_style_hud_pill(hud_preset_btn_high, preset == 2)

func _set_hud_language_pill(lang: String) -> void:
	GameManager.set_language(lang)
	_style_hud_pill(hud_lang_btn_es, lang == "es")
	_style_hud_pill(hud_lang_btn_en, lang == "en")

# Interaction & Context Button
func _on_interaction_available(type: String, target: Node3D) -> void:
	current_context_type = type
	context_action_btn.visible = true
	if "icon_name" in context_action_btn:
		context_action_btn.icon_name = type
	match type:
		"open_hatch":
			context_action_btn.text = "ABRIR" if GameManager.current_language == "es" else "OPEN"
			context_action_btn.modulate = Color(0.2, 0.85, 1.0)
		"close_hatch":
			context_action_btn.text = "CERRAR" if GameManager.current_language == "es" else "CLOSE"
			context_action_btn.modulate = Color(1.0, 0.75, 0.2)
		"pilot_seat":
			var ship = get_tree().get_first_node_in_group("spaceship")
			var is_seated = ship.get("is_player_seated") if ship else false
			context_action_btn.text = "SALIR" if is_seated else "CABINA"
			context_action_btn.modulate = Color(0.3, 0.85, 1.0)
		"oxygen_gen":
			context_action_btn.text = "O2"
			context_action_btn.modulate = Color(0.2, 0.9, 0.85)
		"gravity_device":
			context_action_btn.text = "GRAV"
			context_action_btn.modulate = Color(0.75, 0.45, 1.0)
		"mine":
			context_action_btn.text = "MINAR" if GameManager.current_language == "es" else "MINE"
			context_action_btn.modulate = Color(0.2, 0.9, 1.0)
		"fabricator":
			context_action_btn.text = "TALLER" if GameManager.current_language == "es" else "CRAFT"
			context_action_btn.modulate = Color(0.3, 1.0, 0.4)
		"hyperdrive":
			context_action_btn.text = "HYPERDRIVE"
			context_action_btn.modulate = Color(1.0, 0.8, 0.2)
		"starmap":
			context_action_btn.text = "MAPA" if GameManager.current_language == "es" else "STARMAP"
			context_action_btn.modulate = Color(0.8, 0.5, 1.0)
		"storage":
			context_action_btn.text = "BODEGA" if GameManager.current_language == "es" else "CARGO"
			context_action_btn.modulate = Color(0.4, 0.7, 1.0)
		"repair":
			context_action_btn.text = "REPARAR" if GameManager.current_language == "es" else "REPAIR"
			context_action_btn.modulate = Color(1.0, 0.4, 0.2)
		"scavenge":
			context_action_btn.text = "SALVAR" if GameManager.current_language == "es" else "SALVAGE"
			context_action_btn.modulate = Color(1.0, 0.78, 0.22)
		"attack":
			context_action_btn.text = "ATACAR" if GameManager.current_language == "es" else "ATTACK"
			context_action_btn.modulate = Color(1.0, 0.25, 0.25)
		"feed":
			context_action_btn.text = "ALIMENTAR" if GameManager.current_language == "es" else "FEED"
			context_action_btn.modulate = Color(0.35, 1.0, 0.45)
		"lift":
			context_action_btn.text = "CARGAR" if GameManager.current_language == "es" else "LIFT"
			context_action_btn.modulate = Color(0.25, 0.95, 0.45)
		"drop":
			context_action_btn.text = "SOLTAR" if GameManager.current_language == "es" else "DROP"
			context_action_btn.modulate = Color(1.0, 0.85, 0.25)
		"pickup":
			context_action_btn.text = "RECOGER" if GameManager.current_language == "es" else "PICK UP"
			context_action_btn.modulate = Color(0.25, 0.95, 0.55)

func _on_interaction_lost() -> void:
	current_context_type = ""
	context_action_btn.visible = false
	if player:
		player.is_mining = false

func _on_context_btn_down() -> void:
	match current_context_type:
		"lift":
			if player and player.has_method("lift_creature"):
				player.lift_creature()
		"drop":
			if player and player.has_method("drop_carried_creature"):
				player.drop_carried_creature()
		"pickup":
			if player and is_instance_valid(player.nearby_interactable) and player.nearby_interactable.has_method("pick_up"):
				player.nearby_interactable.pick_up(player)
		"attack":
			if player and player.has_method("attack_nearest_target"):
				player.attack_nearest_target()
		"feed":
			if player and is_instance_valid(player.nearby_interactable):
				var held_food = player.get_held_food_item() if player.has_method("get_held_food_item") else {}
				if held_food.is_empty():
					AudioManager.play("click", 0.7, 4.0)
					show_status_toast("⚠ MANOS VACÍAS: Sostén alimento en la mano (madera/fibras, bayas, biogel o ración).")
				else:
					var food_item = player.consume_held_food() if player.has_method("consume_held_food") else "plant_fibers"
					if player.nearby_interactable.has_method("feed_creature"):
						player.nearby_interactable.feed_creature(food_item)
		"open_hatch":
			var ship = get_tree().get_first_node_in_group("spaceship")
			if ship and ship.has_method("open_hatch"):
				ship.open_hatch()
		"close_hatch":
			var ship = get_tree().get_first_node_in_group("spaceship")
			if ship and ship.has_method("close_hatch"):
				ship.close_hatch()
		"pilot_seat":
			var ship = get_tree().get_first_node_in_group("spaceship")
			if ship and ship.has_method("toggle_pilot_seat"):
				ship.toggle_pilot_seat(player)
		"oxygen_gen":
			var ship = get_tree().get_first_node_in_group("spaceship")
			if ship and ship.has_method("activate_oxygen_generator"):
				ship.activate_oxygen_generator(player)
		"gravity_device":
			var ship = get_tree().get_first_node_in_group("spaceship")
			if ship and ship.has_method("activate_gravity_device"):
				ship.activate_gravity_device(player)
		"mine":
			if player:
				player.is_mining = true
		"scavenge":
			if player and is_instance_valid(player.nearby_interactable) and player.nearby_interactable.has_method("scavenge"):
				player.nearby_interactable.scavenge(player)
		"fabricator":
			crafting_modal.visible = true
			_update_crafting_ui()
			AudioManager.play("click")
		"hyperdrive":
			hyperdrive_modal.visible = true
			_update_hyperdrive_ui()
			AudioManager.play("click")
		"starmap":
			starmap_modal.visible = true
			_build_starmap_ui()
			AudioManager.play("click")
		"storage":
			var is_in_ship = false
			var ship = get_tree().get_first_node_in_group("spaceship")
			if ship and ship.get("is_player_in_cabin"):
				is_in_ship = true
			if astronaut_storage_modal:
				astronaut_storage_modal.open_modal(is_in_ship)
			elif storage_modal:
				storage_modal.visible = true
				_update_storage_ui()
			AudioManager.play("click")
		"repair":
			var ship = get_tree().get_first_node_in_group("spaceship")
			if ship and ship.has_method("repair_hull_modules"):
				ship.repair_hull_modules()

func _on_context_btn_up() -> void:
	if current_context_type == "mine" and player:
		player.is_mining = false

func _on_hyperdrive_badge_pressed() -> void:
	hyperdrive_modal.visible = not hyperdrive_modal.visible
	if hyperdrive_modal.visible:
		_update_hyperdrive_ui()
		AudioManager.play("click")

# Storage / Cajón de Recursos & Mochila
var active_toast_panel: PanelContainer = null

func _setup_backpack_btn() -> void:
	var bpack = get_node_or_null("TopLayer/TopBarCluster/BackpackBtn")
	if bpack:
		if not bpack.pressed.is_connected(_on_backpack_btn_pressed):
			bpack.pressed.connect(_on_backpack_btn_pressed)
		return
	if not top_layer or top_layer.get_node_or_null("BackpackBtn"):
		return
	var bpack_new = CircularArtButton.new()
	bpack_new.name = "BackpackBtn"
	bpack_new.icon_name = "backpack"
	bpack_new.custom_minimum_size = Vector2(46, 46)
	bpack_new.size = Vector2(46, 46)
	bpack_new.pressed.connect(_on_backpack_btn_pressed)
	top_layer.add_child(bpack_new)

func _on_backpack_btn_pressed() -> void:
	if astronaut_storage_modal:
		if astronaut_storage_modal.visible:
			astronaut_storage_modal.close_modal()
		else:
			# Opening personal field gear (backpack & hands)
			astronaut_storage_modal.open_modal(false)
			AudioManager.play("click")
	elif storage_modal:
		storage_modal.visible = not storage_modal.visible
		if storage_modal.visible:
			_update_storage_ui()
			AudioManager.play("click")

func _setup_modal_art_styling() -> void:
	var modal_card_sb = StyleBoxFlat.new()
	modal_card_sb.bg_color = Color(0.08, 0.07, 0.15, 0.96)
	modal_card_sb.border_color = Color(0.96, 0.66, 0.16, 0.90) # Golden Rim
	modal_card_sb.set_border_width_all(2)
	modal_card_sb.set_corner_radius_all(12)
	modal_card_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	modal_card_sb.shadow_size = 6
	
	if pause_modal:
		pause_modal.add_theme_stylebox_override("panel", modal_card_sb)
		_style_menu_button(pause_resume_btn, Color(0.96, 0.66, 0.16))
		_style_menu_button(pause_settings_btn, Color(0.2, 0.85, 1.0))
		_style_menu_button(pause_menu_btn, Color(0.95, 0.4, 0.35))
		
	if settings_modal:
		settings_modal.add_theme_stylebox_override("panel", modal_card_sb)
		var master_lbl = settings_modal.get_node_or_null("VBox/MasterLabel")
		if master_lbl: master_lbl.text = "🔊"
		var music_lbl = settings_modal.get_node_or_null("VBox/MusicLabel")
		if music_lbl: music_lbl.text = "🎵"
		if reset_defaults_btn:
			reset_defaults_btn.text = "↺"
			_style_menu_button(reset_defaults_btn, Color(0.96, 0.66, 0.16))
		if close_settings_btn:
			close_settings_btn.text = "✕"
			_style_menu_button(close_settings_btn, Color(0.95, 0.4, 0.35))
		
	if crafting_modal:
		crafting_modal.add_theme_stylebox_override("panel", modal_card_sb)
		var close_craft = get_node_or_null("Modals/CraftingModal/VBox/CloseCraftBtn")
		if close_craft is Button:
			_style_menu_button(close_craft, Color(0.95, 0.4, 0.35))
			
	if hyperdrive_modal:
		hyperdrive_modal.add_theme_stylebox_override("panel", modal_card_sb)
		var close_hd = get_node_or_null("Modals/HyperdriveModal/VBox/CloseHyperBtn")
		if close_hd is Button:
			_style_menu_button(close_hd, Color(0.95, 0.4, 0.35))
		if launch_btn:
			_style_menu_button(launch_btn, Color(0.2, 1.0, 0.4))

func _style_menu_button(btn: Button, rim_col: Color) -> void:
	if not is_instance_valid(btn):
		return
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.10, 0.14, 0.22, 0.95)
	sb_normal.border_color = rim_col
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(8)
	sb_normal.content_margin_left = 12
	sb_normal.content_margin_right = 12
	sb_normal.content_margin_top = 8
	sb_normal.content_margin_bottom = 8
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = Color(0.15, 0.20, 0.32, 1.0)
	sb_hover.border_color = rim_col.lightened(0.25)
	sb_hover.set_border_width_all(2)
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)

func _setup_cockpit_modal() -> void:
	if cockpit_modal:
		return
	cockpit_modal = Panel.new()
	cockpit_modal.name = "CockpitModal"
	cockpit_modal.visible = false
	cockpit_modal.set_anchors_preset(Control.PRESET_CENTER)
	cockpit_modal.offset_left = -220
	cockpit_modal.offset_right = 220
	cockpit_modal.offset_top = -140
	cockpit_modal.offset_bottom = 140
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.95)
	sb.border_color = Color(0.2, 0.85, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	sb.shadow_size = 10
	cockpit_modal.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 18
	vbox.offset_top = 16
	vbox.offset_right = -18
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 10)
	cockpit_modal.add_child(vbox)
	
	cockpit_title_lbl = Label.new()
	cockpit_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cockpit_title_lbl.text = "CABINA DE MANDO ORBITAL"
	cockpit_title_lbl.add_theme_font_size_override("font_size", 16)
	cockpit_title_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	vbox.add_child(cockpit_title_lbl)
	
	cockpit_telemetry_lbl = Label.new()
	cockpit_telemetry_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cockpit_telemetry_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cockpit_telemetry_lbl.add_theme_font_size_override("font_size", 12)
	cockpit_telemetry_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	vbox.add_child(cockpit_telemetry_lbl)
	
	cockpit_action_btn = Button.new()
	_style_menu_button(cockpit_action_btn, Color(0.2, 1.0, 0.4))
	cockpit_action_btn.pressed.connect(_on_cockpit_action_pressed)
	vbox.add_child(cockpit_action_btn)
	
	cockpit_starmap_btn = Button.new()
	cockpit_starmap_btn.text = "MAPA ESTELAR (STARMAP)"
	_style_menu_button(cockpit_starmap_btn, Color(0.96, 0.66, 0.16))
	cockpit_starmap_btn.pressed.connect(func():
		close_cockpit_dialog()
		starmap_modal.visible = true
		_build_starmap_ui()
	)
	vbox.add_child(cockpit_starmap_btn)
	
	cockpit_stand_btn = Button.new()
	cockpit_stand_btn.text = "LEVANTARSE DEL ASIENTO"
	_style_menu_button(cockpit_stand_btn, Color(0.95, 0.4, 0.35))
	cockpit_stand_btn.pressed.connect(func():
		if is_instance_valid(cockpit_ship_ref) and is_instance_valid(player):
			cockpit_ship_ref.stand_up_from_pilot_seat(player)
		close_cockpit_dialog()
	)
	vbox.add_child(cockpit_stand_btn)
	
	var modals_node = get_node_or_null("Modals")
	if modals_node:
		modals_node.add_child(cockpit_modal)
	else:
		add_child(cockpit_modal)

func open_cockpit_dialog(ship_ref: Node3D) -> void:
	cockpit_ship_ref = ship_ref
	_setup_cockpit_modal()
	_update_cockpit_dialog()
	if cockpit_modal:
		cockpit_modal.visible = true

func close_cockpit_dialog() -> void:
	if cockpit_modal:
		cockpit_modal.visible = false

func _update_cockpit_dialog() -> void:
	if not is_instance_valid(cockpit_ship_ref) or not cockpit_modal:
		return
	var f_state = cockpit_ship_ref.get("flight_state")
	var p_energy = int(cockpit_ship_ref.get("current_energy"))
	var is_landed = (f_state == 0) # FlightState.LANDED
	
	if is_landed:
		cockpit_title_lbl.text = "CABINA: SUPERFICIE PLANETARIA"
		cockpit_telemetry_lbl.text = "Altitud: 0.0 km • Energía: %d%%\nSistemas de despegue y telemetría nominales." % p_energy
		cockpit_action_btn.text = "🚀 DESPEGAR A ÓRBITA SEGURA"
		cockpit_starmap_btn.visible = false
	else:
		cockpit_title_lbl.text = "CABINA: ÓRBITA KEPLERIANA ESTABLE"
		cockpit_telemetry_lbl.text = "Altitud Orbital: 220 km • Velocidad: 7.8 km/s • Energía: %d%%\nMicrogravedad activa. Libre de la atracción superficial." % p_energy
		cockpit_action_btn.text = "🛬 INICIAR ATERRIZAJE AUTOMÁTICO"
		cockpit_starmap_btn.visible = true

func _on_cockpit_action_pressed() -> void:
	if not is_instance_valid(cockpit_ship_ref):
		return
	var f_state = cockpit_ship_ref.get("flight_state")
	if f_state == 0: # LANDED
		cockpit_ship_ref.launch_to_safe_orbit()
		close_cockpit_dialog()
		show_status_toast("DESPEGUE ORBITAL INICIADO: Ascenso a órbita segura.")
	elif f_state == 2: # PARKING_ORBIT
		cockpit_ship_ref.initiate_automatic_landing()
		close_cockpit_dialog()
		show_status_toast("REENTRADA INICIADA: Aterrizaje guiado en superficie.")

func _apply_custom_touch_layout() -> void:
	if not is_instance_valid(GameManager): return
	var scale_factor = float(GameManager.get_setting("touch_scale", 1.0))
	if mobile_layer:
		mobile_layer.scale = Vector2(scale_factor, scale_factor)
	var layout = GameManager.get_setting("custom_touch_layout", {})
	if not (layout is Dictionary) or layout.is_empty(): return
	if layout.has("joystick") and virtual_joystick:
		virtual_joystick.position = layout["joystick"]
	if layout.has("jump") and jump_btn:
		jump_btn.position = layout["jump"]
	if layout.has("laser") and context_action_btn:
		context_action_btn.position = layout["laser"]
	if layout.has("sprint") and sprint_btn:
		sprint_btn.position = layout["sprint"]

func _setup_orbital_flight_controls() -> void:
	if orbital_controls_container:
		return
	
	orbital_controls_container = Control.new()
	orbital_controls_container.name = "OrbitalFlightControls"
	orbital_controls_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	orbital_controls_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orbital_controls_container.visible = false
	add_child(orbital_controls_container)
	
	# Top Telemetry & Energy/Fuel Bar
	var top_panel = PanelContainer.new()
	top_panel.name = "OrbitalTelemetryPanel"
	top_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.offset_left = -310
	top_panel.offset_right = 310
	top_panel.offset_top = 18
	top_panel.offset_bottom = 100
	
	var sb_top = StyleBoxFlat.new()
	sb_top.bg_color = Color(0.04, 0.07, 0.12, 0.92)
	sb_top.border_color = Color(0.20, 0.85, 1.0, 0.85)
	sb_top.set_border_width_all(2)
	sb_top.set_corner_radius_all(10)
	sb_top.content_margin_left = 14
	sb_top.content_margin_right = 14
	sb_top.content_margin_top = 8
	sb_top.content_margin_bottom = 8
	top_panel.add_theme_stylebox_override("panel", sb_top)
	orbital_controls_container.add_child(top_panel)
	
	var vbox_top = VBoxContainer.new()
	vbox_top.add_theme_constant_override("separation", 5)
	top_panel.add_child(vbox_top)
	
	orbital_telemetry_lbl = Label.new()
	orbital_telemetry_lbl.text = "ÓRBITA CIRCULAR ESTABLE • 220 km • VEL: 18.0 km/s"
	orbital_telemetry_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	orbital_telemetry_lbl.add_theme_font_size_override("font_size", 13)
	orbital_telemetry_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0))
	vbox_top.add_child(orbital_telemetry_lbl)
	
	# Meters HBox: Fuel + Ship Energy + Quick Refuel
	var meters_hbox = HBoxContainer.new()
	meters_hbox.add_theme_constant_override("separation", 10)
	meters_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_top.add_child(meters_hbox)
	
	# Fuel Section
	var fuel_vbox = VBoxContainer.new()
	fuel_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fuel_lbl = Label.new()
	fuel_lbl.text = "⛽ COMBUSTIBLE"
	fuel_lbl.add_theme_font_size_override("font_size", 10)
	fuel_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	fuel_vbox.add_child(fuel_lbl)
	orbital_fuel_bar = ProgressBar.new()
	orbital_fuel_bar.max_value = 100.0
	orbital_fuel_bar.value = 100.0
	orbital_fuel_bar.custom_minimum_size = Vector2(100, 14)
	orbital_fuel_bar.show_percentage = true
	var sb_f_bg = StyleBoxFlat.new()
	sb_f_bg.bg_color = Color(0.08, 0.10, 0.14)
	sb_f_bg.set_corner_radius_all(3)
	orbital_fuel_bar.add_theme_stylebox_override("background", sb_f_bg)
	var sb_f_fill = StyleBoxFlat.new()
	sb_f_fill.bg_color = Color(1.0, 0.70, 0.15)
	sb_f_fill.set_corner_radius_all(3)
	orbital_fuel_bar.add_theme_stylebox_override("fill", sb_f_fill)
	fuel_vbox.add_child(orbital_fuel_bar)
	meters_hbox.add_child(fuel_vbox)
	
	# Ship Energy Section
	var energy_vbox = VBoxContainer.new()
	energy_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var energy_lbl = Label.new()
	energy_lbl.text = "⚡ ENERGÍA NAVE"
	energy_lbl.add_theme_font_size_override("font_size", 10)
	energy_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 0.8))
	energy_vbox.add_child(energy_lbl)
	orbital_energy_bar = ProgressBar.new()
	orbital_energy_bar.max_value = 100.0
	orbital_energy_bar.value = 100.0
	orbital_energy_bar.custom_minimum_size = Vector2(100, 14)
	orbital_energy_bar.show_percentage = true
	var sb_e_bg = StyleBoxFlat.new()
	sb_e_bg.bg_color = Color(0.08, 0.10, 0.14)
	sb_e_bg.set_corner_radius_all(3)
	orbital_energy_bar.add_theme_stylebox_override("background", sb_e_bg)
	var sb_e_fill = StyleBoxFlat.new()
	sb_e_fill.bg_color = Color(0.2, 0.95, 0.5)
	sb_e_fill.set_corner_radius_all(3)
	orbital_energy_bar.add_theme_stylebox_override("fill", sb_e_fill)
	energy_vbox.add_child(orbital_energy_bar)
	meters_hbox.add_child(energy_vbox)
	
	# Quick Refuel buttons
	btn_quick_energy = Button.new()
	btn_quick_energy.text = "+ ⚡ CÉLULA"
	btn_quick_energy.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_quick_energy, Color(0.2, 0.9, 0.6))
	btn_quick_energy.custom_minimum_size = Vector2(85, 26)
	btn_quick_energy.pressed.connect(_on_quick_energy_pressed)
	meters_hbox.add_child(btn_quick_energy)
	
	btn_quick_fuel = Button.new()
	btn_quick_fuel.text = "+ ⛽ REPOSTAR"
	btn_quick_fuel.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_quick_fuel, Color(1.0, 0.7, 0.2))
	btn_quick_fuel.custom_minimum_size = Vector2(85, 26)
	btn_quick_fuel.pressed.connect(_on_quick_fuel_pressed)
	meters_hbox.add_child(btn_quick_fuel)
	
	# Left Cluster: Attitude D-Pad (Pitch & Yaw)
	flight_pad_left = Control.new()
	flight_pad_left.name = "FlightPadLeft"
	flight_pad_left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	flight_pad_left.offset_left = 32
	flight_pad_left.offset_bottom = -32
	flight_pad_left.offset_right = 212
	flight_pad_left.offset_top = -212
	orbital_controls_container.add_child(flight_pad_left)
	
	var btn_pitch_up = Button.new()
	btn_pitch_up.text = "▲\nPITCH"
	btn_pitch_up.offset_left = 60
	btn_pitch_up.offset_right = 120
	btn_pitch_up.offset_top = 0
	btn_pitch_up.offset_bottom = 56
	btn_pitch_up.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_pitch_up, Color(0.2, 0.85, 1.0))
	btn_pitch_up.button_down.connect(func(): is_holding_pitch_up = true)
	btn_pitch_up.button_up.connect(func(): is_holding_pitch_up = false)
	flight_pad_left.add_child(btn_pitch_up)
	
	var btn_pitch_down = Button.new()
	btn_pitch_down.text = "▼\nPITCH"
	btn_pitch_down.offset_left = 60
	btn_pitch_down.offset_right = 120
	btn_pitch_down.offset_top = 124
	btn_pitch_down.offset_bottom = 180
	btn_pitch_down.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_pitch_down, Color(0.2, 0.85, 1.0))
	btn_pitch_down.button_down.connect(func(): is_holding_pitch_down = true)
	btn_pitch_down.button_up.connect(func(): is_holding_pitch_down = false)
	flight_pad_left.add_child(btn_pitch_down)
	
	var btn_yaw_left = Button.new()
	btn_yaw_left.text = "◄\nYAW"
	btn_yaw_left.offset_left = 0
	btn_yaw_left.offset_right = 56
	btn_yaw_left.offset_top = 62
	btn_yaw_left.offset_bottom = 118
	btn_yaw_left.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_yaw_left, Color(0.2, 0.85, 1.0))
	btn_yaw_left.button_down.connect(func(): is_holding_yaw_left = true)
	btn_yaw_left.button_up.connect(func(): is_holding_yaw_left = false)
	flight_pad_left.add_child(btn_yaw_left)
	
	var btn_yaw_right = Button.new()
	btn_yaw_right.text = "►\nYAW"
	btn_yaw_right.offset_left = 124
	btn_yaw_right.offset_right = 180
	btn_yaw_right.offset_top = 62
	btn_yaw_right.offset_bottom = 118
	btn_yaw_right.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_yaw_right, Color(0.2, 0.85, 1.0))
	btn_yaw_right.button_down.connect(func(): is_holding_yaw_right = true)
	btn_yaw_right.button_up.connect(func(): is_holding_yaw_right = false)
	flight_pad_left.add_child(btn_yaw_right)
	
	# Right Cluster: Propulsion, Brake, Landing, Stand, Starmap
	flight_pad_right = Control.new()
	flight_pad_right.name = "FlightPadRight"
	flight_pad_right.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	flight_pad_right.offset_right = -24
	flight_pad_right.offset_bottom = -24
	flight_pad_right.offset_left = -260
	flight_pad_right.offset_top = -240
	orbital_controls_container.add_child(flight_pad_right)
	
	var vbox_r = VBoxContainer.new()
	vbox_r.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox_r.add_theme_constant_override("separation", 8)
	flight_pad_right.add_child(vbox_r)
	
	var hbox_thrust = HBoxContainer.new()
	hbox_thrust.add_theme_constant_override("separation", 8)
	vbox_r.add_child(hbox_thrust)
	
	var btn_thrust = Button.new()
	btn_thrust.text = "🚀 IMPULSO"
	btn_thrust.custom_minimum_size = Vector2(110, 48)
	btn_thrust.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_thrust.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_thrust, Color(0.2, 1.0, 0.45))
	btn_thrust.button_down.connect(func(): is_holding_thrust = true)
	btn_thrust.button_up.connect(func(): is_holding_thrust = false)
	hbox_thrust.add_child(btn_thrust)
	
	var btn_brake = Button.new()
	btn_brake.text = "🛑 FRENO"
	btn_brake.custom_minimum_size = Vector2(110, 48)
	btn_brake.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_brake.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_brake, Color(1.0, 0.4, 0.3))
	btn_brake.button_down.connect(func(): is_holding_brake = true)
	btn_brake.button_up.connect(func(): is_holding_brake = false)
	hbox_thrust.add_child(btn_brake)
	
	var btn_land = Button.new()
	btn_land.text = "🛬 ATERRIZAJE POLAR"
	btn_land.custom_minimum_size = Vector2(230, 42)
	btn_land.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_land, Color(0.3, 0.9, 1.0))
	btn_land.pressed.connect(_on_orbital_land_pressed)
	vbox_r.add_child(btn_land)
	
	var hbox_bottom = HBoxContainer.new()
	hbox_bottom.add_theme_constant_override("separation", 8)
	vbox_r.add_child(hbox_bottom)
	
	var btn_starmap = Button.new()
	btn_starmap.text = "🗺️ STARMAP"
	btn_starmap.custom_minimum_size = Vector2(110, 38)
	btn_starmap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_starmap.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_starmap, Color(0.96, 0.66, 0.16))
	btn_starmap.pressed.connect(func():
		starmap_modal.visible = true
		_build_starmap_ui()
	)
	hbox_bottom.add_child(btn_starmap)
	
	var btn_stand = Button.new()
	btn_stand.text = "🚶 LEVANTARSE"
	btn_stand.custom_minimum_size = Vector2(110, 38)
	btn_stand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_stand.focus_mode = Control.FOCUS_NONE
	_style_menu_button(btn_stand, Color(0.85, 0.5, 0.95))
	btn_stand.pressed.connect(_on_orbital_stand_pressed)
	hbox_bottom.add_child(btn_stand)
	
	# Transit Banner (Center Screen Overlay during Interplanetary Travel)
	transit_banner = PanelContainer.new()
	transit_banner.name = "TransitBanner"
	transit_banner.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	transit_banner.anchor_left = 0.5
	transit_banner.anchor_right = 0.5
	transit_banner.offset_left = -260
	transit_banner.offset_right = 260
	transit_banner.offset_bottom = -130
	transit_banner.offset_top = -215
	var sb_tr = StyleBoxFlat.new()
	sb_tr.bg_color = Color(0.03, 0.06, 0.12, 0.95)
	sb_tr.border_color = Color(0.4, 0.7, 1.0, 0.9)
	sb_tr.set_border_width_all(2)
	sb_tr.set_corner_radius_all(10)
	sb_tr.content_margin_left = 16
	sb_tr.content_margin_right = 16
	sb_tr.content_margin_top = 10
	sb_tr.content_margin_bottom = 10
	transit_banner.add_theme_stylebox_override("panel", sb_tr)
	transit_banner.visible = false
	orbital_controls_container.add_child(transit_banner)
	
	var vbox_tr = VBoxContainer.new()
	vbox_tr.add_theme_constant_override("separation", 6)
	transit_banner.add_child(vbox_tr)
	
	var tr_title = Label.new()
	tr_title.text = "🚀 TRÁNSITO INTERPLANETARIO EN CURSO"
	tr_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tr_title.add_theme_font_size_override("font_size", 14)
	tr_title.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	vbox_tr.add_child(tr_title)
	
	transit_info_lbl = Label.new()
	transit_info_lbl.text = "Destino: Planeta • ETA: 01:20\nEscala: 1 AU = 1 min a vel. máx."
	transit_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transit_info_lbl.add_theme_font_size_override("font_size", 12)
	transit_info_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	vbox_tr.add_child(transit_info_lbl)

func _process(delta: float) -> void:
	var ship = get_tree().get_first_node_in_group("spaceship")
	if not is_instance_valid(ship):
		if orbital_controls_container:
			orbital_controls_container.visible = false
		return
		
	var f_state = int(ship.get("flight_state"))
	var is_seated = bool(ship.get("is_player_seated"))
	
	if f_state == 2 and is_seated: # PARKING_ORBIT
		if not orbital_controls_container:
			_setup_orbital_flight_controls()
		orbital_controls_container.visible = true
		if transit_banner: transit_banner.visible = false
		if flight_pad_left: flight_pad_left.visible = true
		if flight_pad_right: flight_pad_right.visible = true
		
		# Input calculation
		var pitch = 0.0
		if is_holding_pitch_up or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): pitch += 1.0
		if is_holding_pitch_down or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): pitch -= 1.0
		var yaw = 0.0
		if is_holding_yaw_left or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): yaw += 1.0
		if is_holding_yaw_right or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): yaw -= 1.0
		var thrust = 0.0
		if is_holding_thrust or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT): thrust += 1.0
		if is_holding_brake or Input.is_key_pressed(KEY_B) or Input.is_key_pressed(KEY_CTRL): thrust -= 1.0
		
		if absf(pitch) > 0.01 or absf(yaw) > 0.01 or absf(thrust) > 0.01:
			ship.apply_space_flight_controls(thrust, pitch, yaw, 0.0, delta)
			
		_update_orbital_meters(ship)
	elif f_state == 3: # INTERPLANETARY_TRANSIT
		if not orbital_controls_container:
			_setup_orbital_flight_controls()
		orbital_controls_container.visible = true
		if flight_pad_left: flight_pad_left.visible = false
		if flight_pad_right: flight_pad_right.visible = is_seated
		if transit_banner: transit_banner.visible = true
		_update_transit_banner(ship)
		_update_orbital_meters(ship)
	else:
		if orbital_controls_container:
			orbital_controls_container.visible = false

func _update_orbital_meters(ship: Node3D) -> void:
	if not is_instance_valid(ship) or not orbital_telemetry_lbl:
		return
	var speed = float(ship.get("orbital_cruise_speed"))
	var p_name = GameManager.current_planet.get("name", "Planeta")
	orbital_telemetry_lbl.text = "ÓRBITA • %s (220 km) • VEL: %.1f km/s" % [p_name, speed]
	
	if orbital_fuel_bar:
		orbital_fuel_bar.value = GameManager.player_stats.fuel
	if orbital_energy_bar:
		orbital_energy_bar.value = float(ship.get("current_energy"))

func _update_transit_banner(ship: Node3D) -> void:
	if not is_instance_valid(ship) or not transit_info_lbl:
		return
	var t_timer = float(ship.get("transit_timer"))
	var t_dur = float(ship.get("transit_duration_sec"))
	var rem = maxf(0.0, t_dur - t_timer)
	var mins = int(rem) / 60
	var secs = int(rem) % 60
	var dest = ship.get("target_destination_planet")
	var d_name = dest.get("name", "Destino Estelar") if dest is Dictionary else "Destino"
	var d_au = GameManager.calc_transit_distance_au(GameManager.current_planet, dest) if dest is Dictionary else 1.0
	var is_hyper = bool(ship.get("is_hyperdrive_transit"))
	var mode_name = "HIPERDRIVE (2x Consumo Eléctrico, 3.5x Vel)" if is_hyper else "CRUCERO MANUAL (1 AU = 60s)"
	transit_info_lbl.text = "Rumbo a: %s (%.2f AU) • %s\nTiempo Restante: %02d:%02d" % [d_name, d_au, mode_name, mins, secs]

func update_flight_mode_ui() -> void:
	var ship = get_tree().get_first_node_in_group("spaceship")
	if is_instance_valid(ship):
		_update_cockpit_dialog()

func _on_orbital_land_pressed() -> void:
	var ship = get_tree().get_first_node_in_group("spaceship")
	if is_instance_valid(ship) and ship.has_method("initiate_atmospheric_reentry"):
		ship.initiate_atmospheric_reentry(GameManager.current_planet)
		show_status_toast("REENTRADA INICIADA • Maniobra de descenso polar activada.")

func _on_orbital_stand_pressed() -> void:
	var ship = get_tree().get_first_node_in_group("spaceship")
	if is_instance_valid(ship) and is_instance_valid(player) and ship.has_method("stand_up_from_pilot_seat"):
		ship.stand_up_from_pilot_seat(player)
		close_cockpit_dialog()
		show_status_toast("CABINA DE NAVE • Astronauta de pie. Muévete libremente por la cabina.")

func _on_quick_energy_pressed() -> void:
	var ship = get_tree().get_first_node_in_group("spaceship")
	if not is_instance_valid(ship):
		return
	if GameManager.crafting.get_item_count("reactor_cell") > 0:
		ship.convert_item_to_ship_energy("reactor_cell")
	elif GameManager.crafting.get_item_count("energy_cell") > 0:
		ship.convert_item_to_ship_energy("energy_cell")
	else:
		show_status_toast("SIN CÉLULAS • Fabrica células de energía o reactor en el Fabricador.")

func _on_quick_fuel_pressed() -> void:
	var ship = get_tree().get_first_node_in_group("spaceship")
	if not is_instance_valid(ship):
		return
	if GameManager.crafting.get_item_count("bio_fuel") > 0:
		ship.convert_item_to_fuel("bio_fuel")
	else:
		show_status_toast("SIN COMBUSTIBLE • Fabrica biocombustible en el Fabricador.")

func _on_inventory_full(_item: String) -> void:
	var msg = "¡INVENTARIO LLENO! (Manos y espalda ocupadas)" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "INVENTORY FULL! (Hands and back occupied)"
	show_status_toast(msg, 2.8)

func show_status_toast(message: String, duration: float = 2.8) -> void:
	if is_instance_valid(active_toast_panel):
		active_toast_panel.queue_free()
		
	var toast = PanelContainer.new()
	toast.name = "StatusToast"
	toast.anchors_preset = Control.PRESET_CENTER_TOP
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.offset_left = -280.0
	toast.offset_top = 68.0
	toast.offset_right = 280.0
	toast.offset_bottom = 108.0
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.14, 0.92)
	sb.border_color = Color(0.2, 0.85, 1.0, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	toast.add_theme_stylebox_override("panel", sb)
	
	var lbl = Label.new()
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	lbl.add_theme_font_size_override("font_size", 12)
	toast.add_child(lbl)
	
	add_child(toast)
	active_toast_panel = toast
	
	toast.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.20)
	tw.tween_interval(duration)
	tw.tween_property(toast, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		if is_instance_valid(toast):
			toast.queue_free()
	)

func _update_storage_ui() -> void:
	var inv = GameManager.crafting.inventory
	var store = GameManager.crafting.ship_storage
	
	if storage_iron_lbl:
		storage_iron_lbl.text = "%s: %d [Nave: %d]" % [GameManager.loc("iron"), inv.get("iron", 0), store.get("iron", 0)]
	if storage_copper_lbl:
		storage_copper_lbl.text = "%s: %d [Nave: %d]" % [GameManager.loc("copper"), inv.get("copper", 0), store.get("copper", 0)]
	if storage_silicon_lbl:
		storage_silicon_lbl.text = "%s: %d [Nave: %d]" % [GameManager.loc("silicon"), inv.get("silicon", 0), store.get("silicon", 0)]
	if storage_uranium_lbl:
		storage_uranium_lbl.text = "%s: %d [Nave: %d]" % [GameManager.loc("uranium"), inv.get("uranium", 0), store.get("uranium", 0)]

func _on_deposit_all_pressed() -> void:
	AudioManager.play("craft", 1.0)
	GameManager.crafting.deposit_all_to_storage()
	_update_storage_ui()
	deposit_all_btn.text = "✓ " + GameManager.loc("deposit_all")
	var tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(func():
		if deposit_all_btn: deposit_all_btn.text = GameManager.loc("deposit_all")
	)

func _on_close_storage_pressed() -> void:
	AudioManager.play("click")
	storage_modal.visible = false

# Crafting
func _update_crafting_ui() -> void:
	var inv = GameManager.crafting.inventory
	if inv_iron_label: inv_iron_label.text = "%s: %d" % [GameManager.loc("iron"), inv.get("iron", 0)]
	if inv_copper_label: inv_copper_label.text = "%s: %d" % [GameManager.loc("copper"), inv.get("copper", 0)]
	if inv_silicon_label: inv_silicon_label.text = "%s: %d" % [GameManager.loc("silicon"), inv.get("silicon", 0)]
	if inv_uranium_label: inv_uranium_label.text = "%s: %d" % [GameManager.loc("uranium"), inv.get("uranium", 0)]

func _on_craft_item_pressed(item_name: String) -> void:
	if GameManager.crafting.craft(item_name):
		AudioManager.play("craft", 1.0)
		_update_crafting_ui()
		_update_hyperdrive_ui()

# Hyperdrive
func _update_hyperdrive_ui() -> void:
	# Automatically install any available crafted parts from inventory/storage into hyperdrive
	if is_instance_valid(GameManager) and GameManager.crafting:
		GameManager.crafting.install_all_available_parts()

	var prog = GameManager.crafting.get_hyperdrive_progress()
	if "progress" in hyperdrive_badge:
		hyperdrive_badge.progress = prog
	else:
		hyperdrive_badge.text = "HYPERDRIVE %d%%" % int(prog * 100)
	
	var is_es = (is_instance_valid(GameManager) and GameManager.current_language == "es")
	var is_complete = GameManager.crafting.is_hyperdrive_complete()
	
	var hd_title = get_node_or_null("Modals/HyperdriveModal/VBox/Title")
	if hd_title:
		hd_title.text = "HYPERDRIVE"
		
	if is_complete:
		hyperdrive_status_label.text = "ESTADO: OPERATIVO (100%)" if is_es else "STATUS: OPERATIONAL (100%)"
		hyperdrive_status_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45))
		launch_btn.visible = true
	else:
		hyperdrive_status_label.text = ("ESTADO: DAÑADO (%d%%)" % int(prog * 100)) if is_es else ("STATUS: DAMAGED (%d%%)" % int(prog * 100))
		hyperdrive_status_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		launch_btn.visible = false
		
	for child in hyperdrive_list_container.get_children():
		child.queue_free()
		
	var reqs = GameManager.crafting.hyperdrive_requirements
	var installed = GameManager.crafting.installed_parts
	
	var part_display_names = {
		"wrench": ("Llave Inglesa" if is_es else "Pressure Wrench"),
		"wire": ("Cables Conductores" if is_es else "Conductive Wire"),
		"microchip": ("Microprocesador" if is_es else "Microprocessor"),
		"reactor_cell": ("Celda de Reactor" if is_es else "Reactor Cell"),
		"uranium": ("Uranio Enriquecido" if is_es else "Enriched Uranium"),
	}
	
	for part in reqs.keys():
		var needed: int = reqs[part]
		var cur: int = installed.get(part, 0)
		var pct: int = int(clamp(float(cur) / float(maxi(1, needed)), 0.0, 1.0) * 100.0)
		var missing: int = maxi(0, needed - cur)
		var display_name: String = part_display_names.get(part, part.capitalize())
		
		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.06, 0.08, 0.14, 0.95)
		card_sb.border_color = Color(0.25, 1.0, 0.45, 0.8) if missing == 0 else Color(0.35, 0.28, 0.18, 0.7)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(8)
		card_sb.content_margin_left = 12
		card_sb.content_margin_right = 12
		card_sb.content_margin_top = 8
		card_sb.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", card_sb)
		
		var v_box = VBoxContainer.new()
		v_box.add_theme_constant_override("separation", 6)
		card.add_child(v_box)
		
		# Top Row: Name, Count, Progress % and Status
		var top_row = HBoxContainer.new()
		
		var name_lbl = Label.new()
		name_lbl.text = display_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		top_row.add_child(name_lbl)
		
		var count_lbl = Label.new()
		count_lbl.text = "%d / %d  (%d%%)" % [cur, needed, pct]
		count_lbl.add_theme_font_size_override("font_size", 12)
		count_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
		top_row.add_child(count_lbl)
		
		var status_lbl = Label.new()
		if missing == 0:
			status_lbl.text = "  [COMPLETO ✓]" if is_es else "  [COMPLETE ✓]"
			status_lbl.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45))
		else:
			status_lbl.text = ("  [Falta: %d]" % missing) if is_es else ("  [Missing: %d]" % missing)
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
		status_lbl.add_theme_font_size_override("font_size", 12)
		top_row.add_child(status_lbl)
		
		v_box.add_child(top_row)
		
		# Bottom Row: Graphical Progress Bar
		var pbar = ProgressBar.new()
		pbar.custom_minimum_size = Vector2(0, 8)
		pbar.min_value = 0.0
		pbar.max_value = 100.0
		pbar.value = pct
		pbar.show_percentage = false
		
		var pbar_bg = StyleBoxFlat.new()
		pbar_bg.bg_color = Color(0.04, 0.04, 0.08, 0.95)
		pbar_bg.set_corner_radius_all(4)
		pbar.add_theme_stylebox_override("background", pbar_bg)
		
		var pbar_fill = StyleBoxFlat.new()
		pbar_fill.bg_color = Color(0.25, 1.0, 0.45) if missing == 0 else Color(0.2, 0.85, 1.0).lerp(Color(1.0, 0.78, 0.2), float(pct) / 100.0)
		pbar_fill.set_corner_radius_all(4)
		pbar.add_theme_stylebox_override("fill", pbar_fill)
		
		v_box.add_child(pbar)
		
		hyperdrive_list_container.add_child(card)

func _on_launch_hyperdrive_pressed() -> void:
	hyperdrive_modal.visible = false
	var spaceship = get_tree().get_first_node_in_group("spaceship")
	if spaceship and spaceship.has_method("trigger_hyperjump"):
		spaceship.trigger_hyperjump()

# Starmap
func _build_starmap_ui() -> void:
	for child in starmap_list.get_children():
		child.queue_free()
		
	var sys = GameManager.current_solar_system
	var planets = sys.get("planets", [])
	var cur_p = GameManager.current_planet
	for p in planets:
		var card = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		var is_current = (p.get("name") == cur_p.get("name"))
		
		var title = Label.new()
		title.text = ("📍 " if is_current else "🪐 ") + ("%s [%s]" % [p["name"], p["type"]])
		if is_current:
			title.modulate = Color(0.3, 0.9, 1.0)
		var coords = Label.new()
		var dist_au = GameManager.calc_transit_distance_au(cur_p, p)
		var manual_dur_s = maxf(8.0, dist_au * 60.0) # 1 AU = 1 min = 60s
		var hyper_dur_s = maxf(4.0, manual_dur_s / 3.5)
		var fuel_cost = clampf(dist_au * 25.0, 15.0, 60.0)
		var energy_cost_man = clampf(dist_au * 20.0, 10.0, 45.0)
		var energy_cost_hyp = clampf(dist_au * 40.0, 20.0, 90.0) # 2x energy
		
		coords.text = "Distancia: %.2f AU | Órbita: %.2f AU\nManual: %.0fs (-%.0f%% Fuel, -%.0f%% E)\nHiperdrive: %.0fs (-%.0f%% E [2x])" % [
			dist_au, p["orbit_au"], manual_dur_s, fuel_cost, energy_cost_man, hyper_dur_s, energy_cost_hyp
		]
		
		vbox.add_child(title)
		vbox.add_child(coords)
		
		if not is_current:
			var hbox_btns = HBoxContainer.new()
			hbox_btns.add_theme_constant_override("separation", 6)
			
			var btn_man = Button.new()
			btn_man.text = "🚀 CRUCERO (1 AU=60s)"
			btn_man.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn_man.focus_mode = Control.FOCUS_NONE
			_style_menu_button(btn_man, Color(0.25, 0.85, 1.0))
			btn_man.pressed.connect(func():
				_launch_transit_to(p, fuel_cost, energy_cost_man, false)
			)
			hbox_btns.add_child(btn_man)
			
			var btn_hyp = Button.new()
			btn_hyp.text = "⚡ HIPERDRIVE (2X E)"
			btn_hyp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn_hyp.focus_mode = Control.FOCUS_NONE
			_style_menu_button(btn_hyp, Color(0.95, 0.70, 0.2))
			btn_hyp.pressed.connect(func():
				_launch_transit_to(p, fuel_cost * 0.5, energy_cost_hyp, true)
			)
			hbox_btns.add_child(btn_hyp)
			
			vbox.add_child(hbox_btns)
			
		card.add_child(vbox)
		starmap_list.add_child(card)

func _launch_transit_to(target_p: Dictionary, fuel_cost: float, energy_cost: float = 20.0, use_hyperdrive: bool = false) -> void:
	starmap_modal.visible = false
	var ship = get_tree().get_first_node_in_group("spaceship")
	if is_instance_valid(ship):
		var cur_fuel = GameManager.player_stats.fuel
		var cur_energy = float(ship.get("current_energy"))
		if cur_fuel < fuel_cost or cur_energy < energy_cost:
			show_status_toast("ENERGÍA O PROPELENTE INSUFICIENTE • Convierte células de energía o biocombustible.")
			AudioManager.play("click")
			return
		if ship.has_method("start_interplanetary_transfer"):
			ship.start_interplanetary_transfer(target_p, use_hyperdrive)
			return
			
	if GameManager.player_stats.fuel < fuel_cost:
		AudioManager.play("click")
		return
	GameManager.player_stats.fuel -= fuel_cost
	AudioManager.play("thruster", 1.0, 2.0)
	GameManager.start_interplanetary_transit(target_p)
	get_tree().change_scene_to_file("res://scenes/screens/loading_screen.tscn")

# Close Modals
func _on_close_crafting_pressed() -> void: crafting_modal.visible = false
func _on_close_hyperdrive_pressed() -> void: hyperdrive_modal.visible = false
func _on_close_starmap_pressed() -> void: starmap_modal.visible = false

# Game Over & Victory
func _on_game_over(reason: String) -> void:
	game_over_modal.visible = true
	var lbl = $Modals/GameOverModal/VBox/ReasonLabel
	if lbl: lbl.text = reason

func _on_expedition_completed(summary: Dictionary) -> void:
	victory_modal.visible = true
	var reward_points = GameManager.award_hyperdrive_victory(int(GameManager.current_difficulty))
	var lbl = $Modals/VictoryModal/VBox/SummaryLabel
	var title_lbl = get_node_or_null("Modals/VictoryModal/VBox/Title") as Label
	
	if summary.get("homeworld_restored", false) or summary.get("status", "").contains("EVENT HORIZON") or summary.get("escaped_systems_count", 0) >= 10:
		if title_lbl:
			title_lbl.text = "ESCAPED THE EVENT HORIZON - HOMEWORLD RESTORED"
		var credits_lines: Array = summary.get("credits", [])
		var credits_txt = "\n".join(credits_lines)
		if lbl:
			lbl.text = "¡MISIÓN CUMPLIDA! • CORREDOR GALÁCTICO 10/10\n%s\n\n[ TELEMETRÍA DE VICTORIA ]\n• Singularidad: Gargantua superada\n• Planeta de Miller: Relatividad y megamareas superadas\n• Dilatación Temporal: x61,320 superada\n• Estado: Coordenadas del Hogar Restauradas\n\n[ CRÉDITOS ]\n%s\n\n✨ +%d LUNA POINTS" % [
				summary.get("status", "ESCAPED THE EVENT HORIZON - HOMEWORLD RESTORED"),
				credits_txt,
				reward_points
			]
	else:
		if title_lbl:
			title_lbl.text = GameManager.loc("victory_title")
		if lbl:
			lbl.text = "%s\n%s: %s\n%s: %s\n\n✨ +%d LUNA POINTS" % [
				GameManager.loc("victory_title"),
				GameManager.loc("planet_label"), summary.get("planet", ""),
				GameManager.loc("hazard"), str(summary.get("difficulty", 0)),
				reward_points
			]

func _on_retry_pressed() -> void:
	AudioManager.play("click")
	get_tree().paused = false
	GameManager.reset_player_stats()
	game_over_modal.visible = false
	get_tree().change_scene_to_file("res://scenes/screens/loading_screen.tscn")

func _on_return_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
