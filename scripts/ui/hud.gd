extends Control

@onready var virtual_joystick = $MobileLayer/VirtualJoystick
@onready var o2_bar: ProgressBar = $TopLayer/Vitals/O2Bar
@onready var fuel_bar: ProgressBar = $TopLayer/Vitals/FuelBar
@onready var hull_bar: ProgressBar = $TopLayer/Vitals/HullBar

@onready var planet_name_label: Label = $TopLayer/Header/PlanetLabel
@onready var coords_label: Label = $TopLayer/Header/CoordsLabel
@onready var hyperdrive_badge: Button = $TopLayer/HyperdriveBadge

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

# Hyperdrive UI labels
@onready var hyperdrive_status_label: Label = $Modals/HyperdriveModal/VBox/StatusLabel
@onready var hyperdrive_list_container: VBoxContainer = $Modals/HyperdriveModal/VBox/PartsList
@onready var launch_btn: Button = $Modals/HyperdriveModal/VBox/LaunchBtn

# Starmap list
@onready var starmap_list: VBoxContainer = $Modals/StarmapModal/VBox/Scroll/PlanetList

var player: CharacterBody3D = null

func _ready() -> void:
	close_all_modals()
	_update_header()
	
	GameManager.game_over.connect(_on_game_over)
	GameManager.expedition_completed.connect(_on_expedition_completed)
	GameManager.crafting.inventory_changed.connect(_update_crafting_ui)
	GameManager.crafting.hyperdrive_repaired.connect(func(p): _update_hyperdrive_ui())
	
	_update_crafting_ui()
	_update_hyperdrive_ui()

func close_all_modals() -> void:
	crafting_modal.visible = false
	hyperdrive_modal.visible = false
	starmap_modal.visible = false
	game_over_modal.visible = false
	victory_modal.visible = false

func init_player(p_node: CharacterBody3D) -> void:
	player = p_node
	player.stats_changed.connect(_on_stats_changed)

func _update_header() -> void:
	var p = GameManager.current_planet
	planet_name_label.text = str(p.get("name", "Civitus-Alpha"))
	coords_label.text = str(p.get("coords_str", "[X: 0.0, Y: 0.0, Z: 0.0]"))

func _on_stats_changed(o2: float, fuel: float, hull: float) -> void:
	o2_bar.value = o2
	fuel_bar.value = fuel
	hull_bar.value = hull

# Mobile Button Handlers
func _on_thrust_down() -> void:
	Input.action_press("jump_thrust")

func _on_thrust_up() -> void:
	Input.action_release("jump_thrust")

func _on_mine_down() -> void:
	if player and player.has_method("set_mining_active"):
		player.set_mining_active(true)

func _on_mine_up() -> void:
	if player and player.has_method("set_mining_active"):
		player.set_mining_active(false)

func _on_cam_left_pressed() -> void:
	if player:
		player.rotate_camera(-PI / 4.0)

func _on_cam_right_pressed() -> void:
	if player:
		player.rotate_camera(PI / 4.0)

func _on_craft_toggle_pressed() -> void:
	crafting_modal.visible = not crafting_modal.visible
	if crafting_modal.visible:
		_update_crafting_ui()
		AudioManager.play("click")

func _on_hyperdrive_badge_pressed() -> void:
	hyperdrive_modal.visible = not hyperdrive_modal.visible
	if hyperdrive_modal.visible:
		_update_hyperdrive_ui()
		AudioManager.play("click")

func _on_starmap_pressed() -> void:
	starmap_modal.visible = not starmap_modal.visible
	if starmap_modal.visible:
		_build_starmap_ui()
		AudioManager.play("click")

# Crafting Handlers
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

# Hyperdrive Handlers
func _update_hyperdrive_ui() -> void:
	var prog = GameManager.crafting.get_hyperdrive_progress()
	hyperdrive_badge.text = "⚡ HYPERDRIVE: %d%%" % int(prog * 100)
	
	if GameManager.crafting.is_hyperdrive_complete():
		hyperdrive_status_label.text = "¡HYPERDRIVE 100% OPERATIVO! LISTO PARA SALTO"
		launch_btn.visible = true
	else:
		hyperdrive_status_label.text = "ESTADO: DAÑADO - PIEZAS REQUERIDAS:"
		launch_btn.visible = false
		
	# Rebuild parts list
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
		lbl.text = "%s: %d / %d (En mochila: %d)" % [part.capitalize(), cur, needed, inv.get(part, 0)]
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
	var ship = get_tree().get_first_node_in_group("spaceship")
	if ship and ship.has_method("trigger_hyperjump"):
		ship.trigger_hyperjump()

# Starmap UI
func _build_starmap_ui() -> void:
	for c in starmap_list.get_children():
		c.queue_free()
		
	var sys = GameManager.current_solar_system
	var planets = sys.get("planets", [])
	for p in planets:
		var card = PanelContainer.new()
		var hb = HBoxContainer.new()
		var info = Label.new()
		info.text = "%s (%s)\n%s | Recurso: %s" % [
			p["name"], p["type"], p["coords_str"], p["primary_ore"]
		]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(info)
		card.add_child(hb)
		starmap_list.add_child(card)

# Game Over & Victory
func _on_game_over(reason: String) -> void:
	game_over_modal.visible = true

func _on_expedition_completed(summary: Dictionary) -> void:
	victory_modal.visible = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
