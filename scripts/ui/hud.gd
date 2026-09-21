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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_all_modals()
	context_action_btn.visible = false
	if top_layer:
		top_layer.visible = visible
	if mobile_layer:
		mobile_layer.visible = visible
	_update_header()
	_update_localization()
	
	if cam_toggle_btn:
		cam_toggle_btn.pressed.connect(_on_cam_toggle_pressed)
	
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
	if event.is_action_pressed("ui_cancel"):
		if settings_modal.visible:
			_on_close_settings_pressed()
		elif storage_modal.visible:
			_on_close_storage_pressed()
		elif pause_modal.visible:
			_on_pause_resume_pressed()
		else:
			_on_pause_btn_pressed()

func close_all_modals() -> void:
	if pause_modal: pause_modal.visible = false
	if settings_modal: settings_modal.visible = false
	if storage_modal: storage_modal.visible = false
	if astronaut_storage_modal: astronaut_storage_modal.visible = false
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
	settings_modal.visible = true

func _on_pause_menu_pressed() -> void:
	AudioManager.play("click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")

# Settings Menu
func _on_master_slider_changed(val: float) -> void:
	GameManager.update_setting("master_volume", val)

func _on_music_slider_changed(val: float) -> void:
	GameManager.update_setting("music_volume", val)

func _on_reset_defaults_pressed() -> void:
	AudioManager.play("click")
	GameManager.reset_settings_to_default()
	master_slider.value = GameManager.master_volume
	music_slider.value = GameManager.music_volume

func _on_close_settings_pressed() -> void:
	AudioManager.play("click")
	settings_modal.visible = false

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
		"attack":
			context_action_btn.text = "ATACAR" if GameManager.current_language == "es" else "ATTACK"
			context_action_btn.modulate = Color(1.0, 0.25, 0.25)
		"feed":
			context_action_btn.text = "ALIMENTAR" if GameManager.current_language == "es" else "FEED"
			context_action_btn.modulate = Color(0.35, 1.0, 0.45)

func _on_interaction_lost() -> void:
	current_context_type = ""
	context_action_btn.visible = false
	if player:
		player.is_mining = false

func _on_context_btn_down() -> void:
	match current_context_type:
		"attack":
			if player and player.has_method("attack_nearest_target"):
				player.attack_nearest_target()
		"feed":
			if player and is_instance_valid(player.nearby_interactable) and player.nearby_interactable.has_method("feed_creature"):
				player.nearby_interactable.feed_creature()
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
		_style_menu_button(reset_defaults_btn, Color(0.96, 0.66, 0.16))
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
	btn.add_theme_color_override("font_color", rim_col.lightened(0.1))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

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
		var is_current = (p.get("name") == cur_p.get("name"))
		
		var title = Label.new()
		title.text = ("📍 " if is_current else "🪐 ") + ("%s [%s]" % [p["name"], p["type"]])
		if is_current:
			title.modulate = Color(0.3, 0.9, 1.0)
		var coords = Label.new()
		var dist_au = GameManager.calc_transit_distance_au(cur_p, p)
		var fuel_cost = GameManager.calc_transit_fuel_cost(dist_au)
		coords.text = "%s: %.2f AU | %s: -%.0f%% FUEL" % [GameManager.loc("orbit"), p["orbit_au"], ("Combustible" if GameManager.current_language == "es" else "Fuel"), fuel_cost]
		
		vbox.add_child(title)
		vbox.add_child(coords)
		
		if not is_current:
			var btn = Button.new()
			btn.text = "🚀 " + ("DESPEGAR Y VIAJAR" if GameManager.current_language == "es" else "LAUNCH & FLY")
			btn.pressed.connect(func():
				_launch_transit_to(p, fuel_cost)
			)
			vbox.add_child(btn)
			
		card.add_child(vbox)
		starmap_list.add_child(card)

func _launch_transit_to(target_p: Dictionary, fuel_cost: float) -> void:
	starmap_modal.visible = false
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
	if lbl: lbl.text = "%s\n%s: %s\n%s: %s\n\n✨ +%d LUNA POINTS" % [
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
