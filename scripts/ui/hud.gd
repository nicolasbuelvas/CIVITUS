extends Control

@onready var virtual_joystick = $MobileLayer/VirtualJoystick
@onready var touch_camera_zone: Control = $MobileLayer/TouchCameraZone
@onready var jump_btn: TextureButton = $MobileLayer/ActionCluster/JumpBtn
@onready var context_action_btn: Button = $MobileLayer/ActionCluster/ContextActionBtn
@onready var view_toggle_btn: Button = $MobileLayer/ActionCluster/ViewToggleBtn
@onready var zoom_in_btn: Button = $MobileLayer/ActionCluster/ZoomInBtn
@onready var zoom_out_btn: Button = $MobileLayer/ActionCluster/ZoomOutBtn

@onready var o2_bar: ProgressBar = $TopLayer/Vitals/O2Bar
@onready var fuel_bar: ProgressBar = $TopLayer/Vitals/FuelBar
@onready var hull_bar: ProgressBar = $TopLayer/Vitals/HullBar

@onready var planet_name_label: Label = $TopLayer/Header/PlanetLabel
@onready var coords_label: Label = $TopLayer/Header/CoordsLabel
@onready var hyperdrive_badge: Button = $TopLayer/HyperdriveBadge
@onready var top_layer: Control = $TopLayer

# Helmet Visor First-Person Overlay
@onready var jarvis_overlay: Control = $JarvisVisorOverlay

# Modals
@onready var crafting_modal: Panel = $Modals/CraftingModal
@onready var hyperdrive_modal: Panel = $Modals/HyperdriveModal
@onready var starmap_modal: Panel = $Modals/StarmapModal
@onready var game_over_modal: Panel = $Modals/GameOverModal
@onready var victory_modal: Panel = $Modals/VictoryModal

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
	close_all_modals()
	context_action_btn.visible = false
	if jarvis_overlay:
		jarvis_overlay.visible = false
	_update_header()
	
	GameManager.game_over.connect(_on_game_over)
	GameManager.expedition_completed.connect(_on_expedition_completed)
	GameManager.crafting.inventory_changed.connect(_update_crafting_ui)
	GameManager.crafting.hyperdrive_repaired.connect(func(p): _update_hyperdrive_ui())
	
	_update_crafting_ui()
	_update_hyperdrive_ui()

func _process(_delta: float) -> void:
	pass

func close_all_modals() -> void:
	crafting_modal.visible = false
	hyperdrive_modal.visible = false
	starmap_modal.visible = false
	game_over_modal.visible = false
	victory_modal.visible = false

func init_player(p_node: CharacterBody3D) -> void:
	player = p_node
	if jarvis_overlay:
		jarvis_overlay.player = p_node
	player.stats_changed.connect(_on_stats_changed)
	player.interaction_available.connect(_on_interaction_available)
	player.interaction_lost.connect(_on_interaction_lost)
	player.first_person_toggled.connect(_on_first_person_toggled)

func _on_first_person_toggled(is_fps: bool) -> void:
	if top_layer:
		top_layer.visible = not is_fps
	if jarvis_overlay:
		jarvis_overlay.visible = is_fps
		if is_fps:
			AudioManager.play("jarvis", 1.0)
			var tween = create_tween()
			jarvis_overlay.modulate.a = 0.0
			tween.tween_property(jarvis_overlay, "modulate:a", 1.0, 0.35)
	if view_toggle_btn:
		view_toggle_btn.text = "3P ORBIT" if is_fps else "1P CASCO"

func _update_header() -> void:
	var p = GameManager.current_planet
	planet_name_label.text = str(p.get("name", "Civitus-Alpha"))
	coords_label.text = str(p.get("coords_str", ""))

func _on_stats_changed(o2: float, fuel: float, hull: float) -> void:
	o2_bar.value = o2
	fuel_bar.value = fuel
	hull_bar.value = hull

# Smooth Touch Camera Orbit & Pinch Zoom (Right side of screen)
func _on_touch_camera_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_cam_touches[event.index] = event.position
			if touch_cam_touches.size() == 1:
				touch_cam_id = event.index
			elif touch_cam_touches.size() == 2:
				var keys = touch_cam_touches.keys()
				initial_pinch_dist = (touch_cam_touches[keys[0]] - touch_cam_touches[keys[1]]).length()
		else:
			touch_cam_touches.erase(event.index)
			if event.index == touch_cam_id:
				touch_cam_id = -1
	elif event is InputEventScreenDrag:
		touch_cam_touches[event.index] = event.position
		if touch_cam_touches.size() == 1 and event.index == touch_cam_id:
			if player and player.has_method("rotate_camera_by"):
				player.rotate_camera_by(event.relative)
		elif touch_cam_touches.size() >= 2:
			var keys = touch_cam_touches.keys()
			var cur_dist = (touch_cam_touches[keys[0]] - touch_cam_touches[keys[1]]).length()
			if initial_pinch_dist > 10.0:
				var pinch_delta = (initial_pinch_dist - cur_dist) * 0.03
				if player and player.has_method("zoom_camera"):
					player.zoom_camera(pinch_delta)
			initial_pinch_dist = cur_dist
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

func _on_view_toggle_pressed() -> void:
	if player and player.has_method("toggle_first_person"):
		player.toggle_first_person()

# Zoom Buttons for quick UI controls
func _on_zoom_in_pressed() -> void:
	if player and player.has_method("zoom_camera"):
		player.zoom_camera(-1.5)

func _on_zoom_out_pressed() -> void:
	if player and player.has_method("zoom_camera"):
		player.zoom_camera(1.5)

# Jump / Jetpack
func _on_jump_down() -> void:
	Input.action_press("jump_thrust")

func _on_jump_up() -> void:
	Input.action_release("jump_thrust")

# Context-Sensitive Interaction
func _on_interaction_available(type: String, target: Node3D) -> void:
	current_context_type = type
	context_action_btn.visible = true
	match type:
		"mine":
			context_action_btn.text = "MINAR"
			context_action_btn.modulate = Color(0.2, 0.9, 1.0)
		"fabricator":
			context_action_btn.text = "FABRICAR"
			context_action_btn.modulate = Color(0.3, 1.0, 0.4)
		"hyperdrive":
			context_action_btn.text = "HYPERDRIVE"
			context_action_btn.modulate = Color(1.0, 0.8, 0.2)
		"starmap":
			context_action_btn.text = "MAPA ESTELAR"
			context_action_btn.modulate = Color(0.8, 0.5, 1.0)
		"airlock":
			context_action_btn.text = "ESCLUSA"
			context_action_btn.modulate = Color(0.2, 0.8, 1.0)

func _on_interaction_lost() -> void:
	current_context_type = ""
	context_action_btn.visible = false
	if player:
		player.is_mining = false

func _on_context_btn_down() -> void:
	match current_context_type:
		"mine":
			if player:
				player.is_mining = true
		"fabricator":
			crafting_modal.visible = true
			AudioManager.play("click")
		"hyperdrive":
			hyperdrive_modal.visible = true
			AudioManager.play("click")
		"starmap":
			starmap_modal.visible = true
			_build_starmap_ui()
			AudioManager.play("click")
		"airlock":
			AudioManager.play("airlock", 1.0)

func _on_context_btn_up() -> void:
	if current_context_type == "mine" and player:
		player.is_mining = false

func _on_hyperdrive_badge_pressed() -> void:
	hyperdrive_modal.visible = not hyperdrive_modal.visible
	if hyperdrive_modal.visible:
		_update_hyperdrive_ui()
		AudioManager.play("click")

# Crafting
func _update_crafting_ui() -> void:
	var inv = GameManager.crafting.inventory
	inv_iron_label.text = "Hierro: %d" % inv.get("iron", 0)
	inv_copper_label.text = "Cobre: %d" % inv.get("copper", 0)
	inv_silicon_label.text = "Silicio: %d" % inv.get("silicon", 0)
	inv_uranium_label.text = "Uranio: %d" % inv.get("uranium", 0)

func _on_craft_item_pressed(item_name: String) -> void:
	if GameManager.crafting.craft(item_name):
		AudioManager.play("craft", 1.0)
		_update_crafting_ui()
		_update_hyperdrive_ui()

# Hyperdrive
func _update_hyperdrive_ui() -> void:
	var prog = GameManager.crafting.get_hyperdrive_progress()
	hyperdrive_badge.text = "HYPERDRIVE: %d%%" % int(prog * 100)
	
	if GameManager.crafting.is_hyperdrive_complete():
		hyperdrive_status_label.text = "¡HYPERDRIVE 100% OPERATIVO! LISTO PARA SALTO"
		launch_btn.visible = true
	else:
		hyperdrive_status_label.text = "ESTADO: DAÑADO - PIEZAS REQUERIDAS:"
		launch_btn.visible = false
		
	for child in hyperdrive_list_container.get_children():
		child.queue_free()
		
	var reqs = GameManager.crafting.hyperdrive_requirements
	var installed = GameManager.crafting.installed_parts
	var inv = GameManager.crafting.inventory
	
	for part in reqs.keys():
		var row = HBoxContainer.new()
		var lbl = Label.new()
		var needed = reqs[part]
		var cur = installed.get(part, 0)
		lbl.text = "%s: %d / %d (Mochila: %d)" % [part.capitalize(), cur, needed, inv.get(part, 0)]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		
		if cur < needed:
			var btn = Button.new()
			btn.text = "Instalar"
			btn.disabled = inv.get(part, 0) <= 0
			btn.pressed.connect(func():
				GameManager.crafting.install_part(part)
				_update_hyperdrive_ui()
			)
			row.add_child(btn)
			
		hyperdrive_list_container.add_child(row)

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
	for p in planets:
		var card = PanelContainer.new()
		var vbox = VBoxContainer.new()
		var title = Label.new()
		title.text = "%s [%s]" % [p["name"], p["type"]]
		var coords = Label.new()
		coords.text = "%s | Órbita: %.2f AU" % [p["coords_str"], p["orbit_au"]]
		vbox.add_child(title)
		vbox.add_child(coords)
		card.add_child(vbox)
		starmap_list.add_child(card)

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
	var lbl = $Modals/VictoryModal/VBox/SummaryLabel
	if lbl: lbl.text = "¡Salto Hiperespacial Exitoso!\nPlaneta: %s\nNivel: %s\nHyperdrive: %s" % [
		summary.get("planet", ""), str(summary.get("difficulty", 0)), summary.get("hyperdrive", "")
	]

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_return_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
