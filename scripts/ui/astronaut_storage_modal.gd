@tool
extends Control
class_name AstronautStorageModal

signal closed()

const LaserPistolBuilder = preload("res://scripts/entities/laser_pistol_builder.gd")

@export var is_ship_storage_accessible: bool = true:
	set(val):
		is_ship_storage_accessible = val
		queue_redraw()
		_refresh_ui()

# Body Slots
var slot_hand_l: CircularArtButton
var slot_hand_r: CircularArtButton
var slot_back_1: CircularArtButton
var slot_back_2: CircularArtButton
var slot_back_3: CircularArtButton
var slot_back_4: CircularArtButton

# Storage Slots Grid
var cargo_slots: Dictionary = {}
var deposit_all_btn: Button
var withdraw_all_btn: Button
var close_btn: CircularArtButton
var main_panel: PanelContainer
var title_label: Label
var cargo_area: VBoxContainer
var capacity_status_label: Label
var helmet_toggle_btn: Button
var drop_zone_bar: PanelContainer

# Field Crafting Buttons
var o2_craft_btn: Button
var fuel_craft_btn: Button
var patch_craft_btn: Button

# 3D Turntable Preview Components
var preview_viewport: SubViewport
var preview_astronaut_root: Node3D
var preview_turntable_rot: Node3D
var preview_helmet: Node3D
var preview_mount_hand_l: Node3D
var preview_mount_hand_r: Node3D
var preview_mount_back_1: Node3D
var preview_mount_back_2: Node3D
var preview_mount_back_3: Node3D
var preview_mount_back_4: Node3D
var turntable_target_yaw: float = 0.0
var turntable_is_dragging: bool = false

var crafting: CraftingSystem:
	get:
		if is_instance_valid(GameManager):
			return GameManager.crafting
		return null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui_hierarchy()
	if crafting:
		crafting.body_slots_changed.connect(_refresh_ui)
		crafting.storage_changed.connect(_refresh_ui)
		crafting.inventory_changed.connect(_refresh_ui)
	_refresh_ui()

func _process(delta: float) -> void:
	if not visible:
		return
	if is_instance_valid(preview_turntable_rot):
		preview_turntable_rot.rotation.y = lerp_angle(preview_turntable_rot.rotation.y, turntable_target_yaw, delta * 10.0)

func open_modal(with_ship_storage: bool = true) -> void:
	is_ship_storage_accessible = with_ship_storage
	visible = true
	turntable_target_yaw = 0.0
	_update_modal_mode()
	_refresh_ui()

func _update_modal_mode() -> void:
	if not main_panel or not title_label:
		return
	if is_ship_storage_accessible:
		main_panel.custom_minimum_size = Vector2(760, 460)
		title_label.text = "📦 BODEGA DE CARGA DE LA NAVE" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "📦 SHIP CARGO CONTAINER"
		if cargo_area:
			cargo_area.visible = true
	else:
		main_panel.custom_minimum_size = Vector2(440, 460)
		title_label.text = "🎒 EQUIPO DEL ASTRONAUTA" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "🎒 ASTRONAUT FIELD GEAR"
		if cargo_area:
			cargo_area.visible = false

func close_modal() -> void:
	visible = false
	closed.emit()

func _build_ui_hierarchy() -> void:
	for child in get_children():
		child.queue_free()
		
	# 1. Dark Backdrop Tint with Blur Feel
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_left = 0.0
	bg.offset_top = 0.0
	bg.offset_right = 0.0
	bg.offset_bottom = 0.0
	bg.color = Color(0.04, 0.03, 0.08, 0.88)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# 2. Centering Container to guarantee rock-solid centering on any screen/device
	var center_cont = CenterContainer.new()
	center_cont.name = "CenterContainer"
	center_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_cont.anchor_right = 1.0
	center_cont.anchor_bottom = 1.0
	center_cont.offset_left = 0.0
	center_cont.offset_top = 0.0
	center_cont.offset_right = 0.0
	center_cont.offset_bottom = 0.0
	center_cont.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_cont.grow_vertical = Control.GROW_DIRECTION_BOTH
	center_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_cont)
	
	# 3. Main Holographic Terminal Panel
	main_panel = PanelContainer.new()
	main_panel.name = "MainPanel"
	main_panel.custom_minimum_size = Vector2(760, 460)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.15, 0.96)
	sb.border_color = Color(0.96, 0.66, 0.16, 0.90) # Golden Rim
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	main_panel.add_theme_stylebox_override("panel", sb)
	center_cont.add_child(main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(main_vbox)
	
	# Header Row
	var header = HBoxContainer.new()
	title_label = Label.new()
	title_label.text = "EQUIPAMIENTO CORPÓREO Y CARGA" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "ASTRONAUT GEAR & SHIP CARGO"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	title_label.add_theme_font_size_override("font_size", 16)
	header.add_child(title_label)
	
	close_btn = CircularArtButton.new()
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.icon_type = CircularArtButton.IconType.CLOSE
	close_btn.ring_color = Color(0.95, 0.4, 0.4)
	close_btn.pressed.connect(close_modal)
	header.add_child(close_btn)
	main_vbox.add_child(header)
	
	# Middle Content: Split into Left (Astronaut Body) and Right (Ship Cargo)
	var content_split = HBoxContainer.new()
	content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_split)
	
	# Left: Astronaut Body 3D Turntable Area
	var body_area_box = VBoxContainer.new()
	body_area_box.alignment = BoxContainer.ALIGNMENT_CENTER
	body_area_box.add_theme_constant_override("separation", 6)
	content_split.add_child(body_area_box)
	
	var body_area = Control.new()
	body_area.name = "BodyArea"
	body_area.custom_minimum_size = Vector2(340, 290)
	body_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_area_box.add_child(body_area)
	
	# 3D Turntable Preview
	_setup_3d_preview(body_area)
	
	# Turntable Control & Capacity Row
	var turn_row = HBoxContainer.new()
	turn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	turn_row.add_theme_constant_override("separation", 8)
	body_area_box.add_child(turn_row)
	
	var rot_l_btn = Button.new()
	rot_l_btn.text = "◄ GIRAR"
	rot_l_btn.custom_minimum_size = Vector2(65, 24)
	rot_l_btn.add_theme_font_size_override("font_size", 10)
	rot_l_btn.pressed.connect(func(): turntable_target_yaw -= deg_to_rad(45.0))
	turn_row.add_child(rot_l_btn)
	
	capacity_status_label = Label.new()
	capacity_status_label.text = "GANCHOS: 0/4 • MANOS: 0/2"
	capacity_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	capacity_status_label.add_theme_font_size_override("font_size", 10)
	capacity_status_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	turn_row.add_child(capacity_status_label)
	
	var rot_r_btn = Button.new()
	rot_r_btn.text = "GIRAR ►"
	rot_r_btn.custom_minimum_size = Vector2(65, 24)
	rot_r_btn.add_theme_font_size_override("font_size", 10)
	rot_r_btn.pressed.connect(func(): turntable_target_yaw += deg_to_rad(45.0))
	turn_row.add_child(rot_r_btn)
	
	# Helmet Toggle / Removal Action
	helmet_toggle_btn = Button.new()
	helmet_toggle_btn.text = "🛡 CASCO: PUESTO"
	helmet_toggle_btn.custom_minimum_size = Vector2(0, 26)
	helmet_toggle_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	helmet_toggle_btn.add_theme_font_size_override("font_size", 10)
	helmet_toggle_btn.add_theme_color_override("font_color", Color(0.3, 0.95, 0.6))
	helmet_toggle_btn.pressed.connect(_on_helmet_toggle_pressed)
	body_area_box.add_child(helmet_toggle_btn)
	
	# Field Crafting Bar (Emergency Survival on the Go)
	var craft_row = HBoxContainer.new()
	craft_row.add_theme_constant_override("separation", 6)
	body_area_box.add_child(craft_row)
	
	o2_craft_btn = Button.new()
	o2_craft_btn.text = "+O₂ (2 Fib)"
	o2_craft_btn.custom_minimum_size = Vector2(0, 26)
	o2_craft_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o2_craft_btn.add_theme_font_size_override("font_size", 10)
	o2_craft_btn.pressed.connect(func():
		if crafting and crafting.craft_field_item("emergency_o2"):
			_refresh_ui()
	)
	craft_row.add_child(o2_craft_btn)
	
	fuel_craft_btn = Button.new()
	fuel_craft_btn.text = "+FUEL (2 Fib)"
	fuel_craft_btn.custom_minimum_size = Vector2(0, 26)
	fuel_craft_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuel_craft_btn.add_theme_font_size_override("font_size", 10)
	fuel_craft_btn.pressed.connect(func():
		if crafting and crafting.craft_field_item("small_biofuel"):
			_refresh_ui()
	)
	craft_row.add_child(fuel_craft_btn)
	
	patch_craft_btn = Button.new()
	patch_craft_btn.text = "+TRAJE (1 Fib+1 Fe)"
	patch_craft_btn.custom_minimum_size = Vector2(0, 26)
	patch_craft_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	patch_craft_btn.add_theme_font_size_override("font_size", 10)
	patch_craft_btn.pressed.connect(func():
		if crafting and crafting.craft_field_item("suit_patch"):
			_refresh_ui()
	)
	craft_row.add_child(patch_craft_btn)
	
	# Create Body Slot Buttons positioned around the 3D model
	# Hand Left (left side, mid height)
	slot_hand_l = _create_slot_button("hand_left", "astronaut", Vector2(6, 75), "MANO IZQ")
	body_area.add_child(slot_hand_l)
	
	# Hand Right (right side, mid height)
	slot_hand_r = _create_slot_button("hand_right", "astronaut", Vector2(268, 75), "MANO DER")
	body_area.add_child(slot_hand_r)
	
	# Back 1 (Upper Left dorsal hook)
	slot_back_1 = _create_slot_button("back_1", "astronaut", Vector2(6, 150), "GANCHO (1)")
	body_area.add_child(slot_back_1)
	
	# Back 2 (Upper Right dorsal hook)
	slot_back_2 = _create_slot_button("back_2", "astronaut", Vector2(268, 150), "GANCHO (2)")
	body_area.add_child(slot_back_2)

	# Back 3 (Lower Left dorsal hook)
	slot_back_3 = _create_slot_button("back_3", "astronaut", Vector2(6, 225), "GANCHO (3)")
	body_area.add_child(slot_back_3)
	
	# Back 4 (Lower Right dorsal hook)
	slot_back_4 = _create_slot_button("back_4", "astronaut", Vector2(268, 225), "GANCHO (4)")
	body_area.add_child(slot_back_4)
	
	# Right: Ship Cargo Bay Grid Area
	cargo_area = VBoxContainer.new()
	cargo_area.name = "CargoArea"
	cargo_area.custom_minimum_size = Vector2(400, 310)
	cargo_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_split.add_child(cargo_area)
	
	var cargo_header = Label.new()
	cargo_header.text = "📦 ALMACÉN DE LA NAVE (BODEGA)" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "📦 SHIP CARGO STORAGE"
	cargo_header.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	cargo_header.add_theme_font_size_override("font_size", 13)
	cargo_area.add_child(cargo_header)
	
	var cargo_grid = GridContainer.new()
	cargo_grid.columns = 4
	cargo_grid.add_theme_constant_override("h_separation", 10)
	cargo_grid.add_theme_constant_override("v_separation", 8)
	cargo_area.add_child(cargo_grid)
	
	var cargo_items = ["iron", "copper", "silicon", "uranium", "laser_pistol", "wrench", "wire", "microchip"]
	cargo_slots.clear()
	for item_name in cargo_items:
		var slot_btn = _create_cargo_slot_button(item_name)
		cargo_grid.add_child(slot_btn)
		cargo_slots[item_name] = slot_btn
		
	# Cargo Footer Buttons (Deposit all / Withdraw all)
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	cargo_area.add_child(btn_row)
	
	var btn_style_dep = StyleBoxFlat.new()
	btn_style_dep.bg_color = Color(0.10, 0.14, 0.22, 0.95)
	btn_style_dep.border_color = Color(0.96, 0.66, 0.16)
	btn_style_dep.set_border_width_all(1)
	btn_style_dep.set_corner_radius_all(8)
	
	deposit_all_btn = Button.new()
	deposit_all_btn.text = "⬇ INGRESAR AL COFRE" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "⬇ DEPOSIT TO CHEST"
	deposit_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deposit_all_btn.custom_minimum_size = Vector2(0, 36)
	deposit_all_btn.add_theme_stylebox_override("normal", btn_style_dep)
	deposit_all_btn.add_theme_stylebox_override("hover", btn_style_dep)
	deposit_all_btn.add_theme_color_override("font_color", Color(0.96, 0.75, 0.25))
	deposit_all_btn.add_theme_font_size_override("font_size", 11)
	deposit_all_btn.pressed.connect(_on_deposit_all_pressed)
	btn_row.add_child(deposit_all_btn)
	
	var btn_style_with = StyleBoxFlat.new()
	btn_style_with.bg_color = Color(0.08, 0.16, 0.24, 0.95)
	btn_style_with.border_color = Color(0.2, 0.85, 1.0)
	btn_style_with.set_border_width_all(1)
	btn_style_with.set_corner_radius_all(8)
	
	withdraw_all_btn = Button.new()
	withdraw_all_btn.text = "⬆ SACAR DEL COFRE" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "⬆ WITHDRAW FROM CHEST"
	withdraw_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	withdraw_all_btn.custom_minimum_size = Vector2(0, 36)
	withdraw_all_btn.add_theme_stylebox_override("normal", btn_style_with)
	withdraw_all_btn.add_theme_stylebox_override("hover", btn_style_with)
	withdraw_all_btn.add_theme_color_override("font_color", Color(0.25, 0.9, 1.0))
	withdraw_all_btn.add_theme_font_size_override("font_size", 11)
	withdraw_all_btn.pressed.connect(_on_withdraw_all_pressed)
	btn_row.add_child(withdraw_all_btn)
	
	# Universal Drop Zone Bar at Bottom
	drop_zone_bar = PanelContainer.new()
	drop_zone_bar.name = "DropZoneBar"
	drop_zone_bar.custom_minimum_size = Vector2(0, 26)
	var dz_style = StyleBoxFlat.new()
	dz_style.bg_color = Color(0.12, 0.08, 0.16, 0.85)
	dz_style.border_color = Color(0.85, 0.45, 0.20, 0.70)
	dz_style.set_border_width_all(1)
	dz_style.set_corner_radius_all(6)
	drop_zone_bar.add_theme_stylebox_override("panel", dz_style)
	
	var dz_lbl = Label.new()
	dz_lbl.text = "⬇ SOLTAR AL SUELO (ARRASTRAR O CLIC DERECHO)" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "⬇ DROP TO GROUND (DRAG HERE OR RIGHT-CLICK)"
	dz_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dz_lbl.add_theme_font_size_override("font_size", 10)
	dz_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
	drop_zone_bar.add_child(dz_lbl)
	main_vbox.add_child(drop_zone_bar)
	
	_update_modal_mode()

func _create_slot_button(slot_key: String, owner_type: String, pos: Vector2, caption: String) -> CircularArtButton:
	var btn = CircularArtButton.new()
	btn.name = "Slot_" + slot_key
	btn.slot_id = slot_key
	btn.slot_owner = owner_type
	btn.enable_drag = true
	btn.enable_drop = true
	btn.custom_minimum_size = Vector2(58, 58)
	btn.position = pos
	btn.drag_transferred.connect(_on_slot_drag_transferred)
	btn.pressed.connect(_on_body_slot_clicked.bind(slot_key))
	btn.right_clicked.connect(_on_body_slot_right_clicked.bind(slot_key))
	
	# Caption label underneath
	var lbl = Label.new()
	lbl.text = caption
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-15, 58)
	lbl.size = Vector2(88, 18)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 0.75))
	btn.add_child(lbl)
	
	return btn

func _create_cargo_slot_button(item_name: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 2)
	
	var btn = CircularArtButton.new()
	btn.name = "CargoSlot_" + item_name
	btn.slot_id = item_name
	btn.slot_owner = "ship"
	btn.enable_drag = true
	btn.enable_drop = true
	btn.custom_minimum_size = Vector2(54, 54)
	btn.icon_name = item_name
	btn.drag_transferred.connect(_on_slot_drag_transferred)
	btn.pressed.connect(_on_cargo_slot_clicked.bind(item_name))
	btn.right_clicked.connect(_on_cargo_slot_right_clicked.bind(item_name))
	container.add_child(btn)
	
	var lbl = Label.new()
	lbl.text = item_name.replace("_", " ").capitalize()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	container.add_child(lbl)
	
	return container

# =============================================================================
# 3D ASTRONAUT PREVIEW TURNTABLE
# =============================================================================
func _setup_3d_preview(parent: Control) -> void:
	var vp_container = SubViewportContainer.new()
	vp_container.name = "TurntableContainer"
	vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_container.stretch = true
	vp_container.gui_input.connect(_on_turntable_gui_input)
	parent.add_child(vp_container)
	
	preview_viewport = SubViewport.new()
	preview_viewport.name = "PreviewSubViewport"
	preview_viewport.own_world_3d = true
	preview_viewport.transparent_bg = true
	preview_viewport.size = Vector2i(340, 290)
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_container.add_child(preview_viewport)
	
	# Camera3D
	var cam = Camera3D.new()
	cam.position = Vector3(0.0, 0.88, 2.25)
	cam.fov = 38.0
	preview_viewport.add_child(cam)
	cam.look_at(Vector3(0.0, 0.85, 0.0), Vector3.UP)
	
	# Key Light (Warm White)
	var key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-25.0, 35.0, 0.0)
	key_light.light_color = Color(1.0, 0.96, 0.90)
	key_light.light_energy = 1.4
	preview_viewport.add_child(key_light)
	
	# Rim Light (Sci-Fi Cyan)
	var rim_light = DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(20.0, -145.0, 0.0)
	rim_light.light_color = Color(0.20, 0.85, 1.0)
	rim_light.light_energy = 0.95
	preview_viewport.add_child(rim_light)
	
	# Turntable Rotation Root
	preview_turntable_rot = Node3D.new()
	preview_turntable_rot.name = "TurntableRot"
	preview_viewport.add_child(preview_turntable_rot)
	
	_build_procedural_astronaut_preview()

func _build_procedural_astronaut_preview() -> void:
	preview_astronaut_root = Node3D.new()
	preview_astronaut_root.name = "AstronautModel"
	preview_turntable_rot.add_child(preview_astronaut_root)
	
	var suit_mat = StandardMaterial3D.new()
	suit_mat.albedo_color = Color(0.92, 0.94, 0.97)
	suit_mat.roughness = 0.38
	suit_mat.metallic = 0.12
	
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.18, 0.20, 0.24)
	dark_mat.metallic = 0.80
	dark_mat.roughness = 0.35
	
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.98, 0.72, 0.15)
	gold_mat.metallic = 0.95
	gold_mat.roughness = 0.12
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(0.98, 0.72, 0.15) * 0.35
	
	var hook_mat = StandardMaterial3D.new()
	hook_mat.albedo_color = Color(0.96, 0.66, 0.16)
	hook_mat.metallic = 0.92
	hook_mat.roughness = 0.20
	
	# Torso
	var torso = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(0.44, 0.54, 0.28)
	t_mesh.material = suit_mat
	torso.mesh = t_mesh
	torso.position = Vector3(0.0, 0.88, 0.0)
	preview_astronaut_root.add_child(torso)
	
	# Pelvis & Belt
	var belt = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.46, 0.08, 0.30)
	b_mesh.material = dark_mat
	belt.mesh = b_mesh
	belt.position = Vector3(0.0, 0.58, 0.0)
	preview_astronaut_root.add_child(belt)
	
	# Legs
	var leg_l = MeshInstance3D.new()
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(0.16, 0.52, 0.18)
	l_mesh.material = suit_mat
	leg_l.mesh = l_mesh
	leg_l.position = Vector3(-0.13, 0.28, 0.0)
	preview_astronaut_root.add_child(leg_l)
	
	var leg_r = MeshInstance3D.new()
	leg_r.mesh = l_mesh
	leg_r.position = Vector3(0.13, 0.28, 0.0)
	preview_astronaut_root.add_child(leg_r)
	
	# Left & Right Arms
	var arm_l = MeshInstance3D.new()
	var a_mesh = BoxMesh.new()
	a_mesh.size = Vector3(0.12, 0.44, 0.14)
	a_mesh.material = suit_mat
	arm_l.mesh = a_mesh
	arm_l.position = Vector3(-0.31, 0.82, 0.08)
	arm_l.rotation.x = deg_to_rad(22.0)
	preview_astronaut_root.add_child(arm_l)
	
	var arm_r = MeshInstance3D.new()
	arm_r.mesh = a_mesh
	arm_r.position = Vector3(0.31, 0.82, 0.08)
	arm_r.rotation.x = deg_to_rad(22.0)
	preview_astronaut_root.add_child(arm_r)
	
	# Hand Mounts
	preview_mount_hand_l = Node3D.new()
	preview_mount_hand_l.name = "PreviewHandL"
	preview_mount_hand_l.position = Vector3(-0.31, 0.62, 0.20)
	preview_astronaut_root.add_child(preview_mount_hand_l)
	
	preview_mount_hand_r = Node3D.new()
	preview_mount_hand_r.name = "PreviewHandR"
	preview_mount_hand_r.position = Vector3(0.31, 0.62, 0.20)
	preview_astronaut_root.add_child(preview_mount_hand_r)
	
	# Helmet
	preview_helmet = Node3D.new()
	preview_helmet.name = "PreviewHelmet"
	preview_helmet.position = Vector3(0.0, 1.32, 0.0)
	preview_astronaut_root.add_child(preview_helmet)
	
	var helmet_mesh = MeshInstance3D.new()
	var h_sph = SphereMesh.new()
	h_sph.radius = 0.20
	h_sph.height = 0.38
	h_sph.material = suit_mat
	helmet_mesh.mesh = h_sph
	preview_helmet.add_child(helmet_mesh)
	
	var visor_mesh = MeshInstance3D.new()
	var v_sph = SphereMesh.new()
	v_sph.radius = 0.16
	v_sph.height = 0.26
	v_sph.material = gold_mat
	visor_mesh.mesh = v_sph
	visor_mesh.position = Vector3(0.0, 0.01, 0.08)
	preview_helmet.add_child(visor_mesh)
	
	# Backpack (PLSS) on the back featuring the 4 physical suit hooks
	var backpack = MeshInstance3D.new()
	var bp_mesh = BoxMesh.new()
	bp_mesh.size = Vector3(0.38, 0.48, 0.20)
	bp_mesh.material = dark_mat
	backpack.mesh = bp_mesh
	backpack.position = Vector3(0.0, 0.92, -0.22)
	preview_astronaut_root.add_child(backpack)
	
	# 4 Physical Back Hooks on Backpack: Upper L/R, Lower L/R
	_create_preview_hook(backpack, Vector3(-0.14, 0.14, -0.11), hook_mat)
	_create_preview_hook(backpack, Vector3(0.14, 0.14, -0.11), hook_mat)
	_create_preview_hook(backpack, Vector3(-0.14, -0.14, -0.11), hook_mat)
	_create_preview_hook(backpack, Vector3(0.14, -0.14, -0.11), hook_mat)
	
	preview_mount_back_1 = Node3D.new()
	preview_mount_back_1.name = "PreviewBack1"
	preview_mount_back_1.position = Vector3(-0.14, 0.14, -0.14)
	backpack.add_child(preview_mount_back_1)
	
	preview_mount_back_2 = Node3D.new()
	preview_mount_back_2.name = "PreviewBack2"
	preview_mount_back_2.position = Vector3(0.14, 0.14, -0.14)
	backpack.add_child(preview_mount_back_2)
	
	preview_mount_back_3 = Node3D.new()
	preview_mount_back_3.name = "PreviewBack3"
	preview_mount_back_3.position = Vector3(-0.14, -0.14, -0.14)
	backpack.add_child(preview_mount_back_3)
	
	preview_mount_back_4 = Node3D.new()
	preview_mount_back_4.name = "PreviewBack4"
	preview_mount_back_4.position = Vector3(0.14, -0.14, -0.14)
	backpack.add_child(preview_mount_back_4)

func _create_preview_hook(parent: Node3D, pos: Vector3, mat: Material) -> void:
	var hook_root = Node3D.new()
	hook_root.position = pos
	parent.add_child(hook_root)
	
	# Base plate
	var plate = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.045, 0.065, 0.015)
	plate.mesh = p_mesh
	plate.material_override = mat
	hook_root.add_child(plate)
	
	# Titanium Carabiner D-Ring
	var ring = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 0.018
	t_mesh.outer_radius = 0.035
	ring.mesh = t_mesh
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0.0, -0.025, -0.015)
	ring.material_override = mat
	hook_root.add_child(ring)
	
	# Amber Safety Latch
	var latch = MeshInstance3D.new()
	var l_mesh = CylinderMesh.new()
	l_mesh.top_radius = 0.008
	l_mesh.bottom_radius = 0.008
	l_mesh.height = 0.038
	latch.mesh = l_mesh
	latch.position = Vector3(0.018, -0.025, -0.015)
	var latch_mat = StandardMaterial3D.new()
	latch_mat.albedo_color = Color(0.96, 0.66, 0.16)
	latch_mat.metallic = 0.95
	latch_mat.roughness = 0.2
	latch.material_override = latch_mat
	hook_root.add_child(latch)

func _on_turntable_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			turntable_is_dragging = event.pressed
	elif event is InputEventMouseMotion and turntable_is_dragging:
		turntable_target_yaw += event.relative.x * 0.015

# =============================================================================
# REFRESH UI & PREVIEW STATE
# =============================================================================
func _refresh_ui() -> void:
	if not crafting:
		return
		
	# Refresh Body Slots
	var b_slots = crafting.body_slots
	_update_body_slot_btn(slot_hand_l, b_slots.get("hand_left", {}))
	_update_body_slot_btn(slot_hand_r, b_slots.get("hand_right", {}))
	_update_body_slot_btn(slot_back_1, b_slots.get("back_1", {}))
	_update_body_slot_btn(slot_back_2, b_slots.get("back_2", {}))
	_update_body_slot_btn(slot_back_3, b_slots.get("back_3", {}))
	_update_body_slot_btn(slot_back_4, b_slots.get("back_4", {}))
	
	# Update 3D Preview props mounted on astronaut
	_update_preview_props()
	
	# Update Helmet button state
	var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if helmet_toggle_btn:
		var is_suit = player.is_in_space_suit if is_instance_valid(player) else true
		var is_es = is_instance_valid(GameManager) and GameManager.current_language == "es"
		if is_suit:
			helmet_toggle_btn.text = "🛡 CASCO: PUESTO" if is_es else "🛡 HELMET: ON"
			helmet_toggle_btn.add_theme_color_override("font_color", Color(0.3, 0.95, 0.6))
		else:
			helmet_toggle_btn.text = "👤 CASCO: QUITADO" if is_es else "👤 HELMET: OFF"
			helmet_toggle_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25))
	
	# Update Field Crafting Button states
	var fibers = crafting.inventory.get("plant_fibers", 0)
	var silicon = crafting.inventory.get("silicon", 0)
	var iron = crafting.inventory.get("iron", 0)
	if o2_craft_btn:
		o2_craft_btn.disabled = (fibers < 2 and silicon < 1)
	if fuel_craft_btn:
		fuel_craft_btn.disabled = (fibers < 2)
	if patch_craft_btn:
		patch_craft_btn.disabled = (fibers < 1 or iron < 1)
	
	if capacity_status_label:
		var occupied_hooks = 0
		for h in ["back_1", "back_2", "back_3", "back_4"]:
			if b_slots.get(h, {}).get("count", 0) > 0:
				occupied_hooks += 1
		var occupied_hands = 0
		for h in ["hand_left", "hand_right"]:
			if b_slots.get(h, {}).get("count", 0) > 0:
				occupied_hands += 1
		var is_es = is_instance_valid(GameManager) and GameManager.current_language == "es"
		capacity_status_label.text = ("GANCHOS: %d/4 • MANOS: %d/2" % [occupied_hooks, occupied_hands]) if is_es else ("HOOKS: %d/4 • HANDS: %d/2" % [occupied_hooks, occupied_hands])
	
	# Refresh Ship Storage Grid
	var store = crafting.ship_storage
	for item_name in cargo_slots.keys():
		var v_container = cargo_slots[item_name]
		var btn: CircularArtButton = v_container.get_child(0)
		var count = store.get(item_name, 0)
		btn.badge_text = ("x%d" % count) if count > 0 else ""
		btn.ring_color = Color(0.96, 0.66, 0.16) if count > 0 else Color(0.35, 0.35, 0.45)
		btn.bg_color = Color(0.09, 0.08, 0.16) if count > 0 else Color(0.06, 0.06, 0.09)

func _update_preview_props() -> void:
	if not crafting:
		return
	var b_slots = crafting.body_slots
	_attach_preview_prop(preview_mount_hand_l, b_slots.get("hand_left", {}))
	_attach_preview_prop(preview_mount_hand_r, b_slots.get("hand_right", {}))
	_attach_preview_prop(preview_mount_back_1, b_slots.get("back_1", {}))
	_attach_preview_prop(preview_mount_back_2, b_slots.get("back_2", {}))
	_attach_preview_prop(preview_mount_back_3, b_slots.get("back_3", {}))
	_attach_preview_prop(preview_mount_back_4, b_slots.get("back_4", {}))
	
	var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if is_instance_valid(player) and is_instance_valid(preview_helmet):
		preview_helmet.visible = player.is_in_space_suit

func _attach_preview_prop(mount: Node3D, slot_data: Dictionary) -> void:
	if not is_instance_valid(mount):
		return
	for c in mount.get_children():
		c.queue_free()
	var item = slot_data.get("item", "")
	var count = slot_data.get("count", 0)
	if count <= 0 or item == "":
		return
		
	var prop: Node3D = null
	if item == "laser_pistol":
		prop = LaserPistolBuilder.create_laser_pistol()
		prop.scale = Vector3(0.85, 0.85, 0.85)
		if mount != preview_mount_hand_l and mount != preview_mount_hand_r:
			prop.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			prop.position = Vector3(0.0, -0.04, 0.0)
	else:
		prop = _create_simple_preview_mesh(item)
		if mount != preview_mount_hand_l and mount != preview_mount_hand_r:
			prop.position = Vector3(0.0, -0.05, 0.0)
	if prop:
		mount.add_child(prop)

func _create_simple_preview_mesh(item_name: String) -> Node3D:
	var root = Node3D.new()
	var m_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	var mesh: Mesh = null
	
	match item_name:
		"iron":
			var b = BoxMesh.new()
			b.size = Vector3(0.12, 0.12, 0.12)
			mat.albedo_color = Color(0.72, 0.76, 0.84)
			mat.metallic = 0.90
			mesh = b
		"copper":
			var c = CylinderMesh.new()
			c.top_radius = 0.05
			c.bottom_radius = 0.05
			c.height = 0.14
			mat.albedo_color = Color(0.92, 0.52, 0.22)
			mat.metallic = 0.85
			mesh = c
		"silicon":
			var pr = PrismMesh.new()
			pr.size = Vector3(0.10, 0.14, 0.10)
			mat.albedo_color = Color(0.18, 0.78, 0.95)
			mat.emission_enabled = true
			mat.emission = Color(0.18, 0.78, 0.95)
			mesh = pr
		"uranium":
			var c = CylinderMesh.new()
			c.top_radius = 0.06
			c.bottom_radius = 0.06
			c.height = 0.15
			mat.albedo_color = Color(0.25, 0.95, 0.35)
			mat.emission_enabled = true
			mat.emission = Color(0.25, 0.95, 0.35)
			mesh = c
		_:
			var b = BoxMesh.new()
			b.size = Vector3(0.10, 0.10, 0.10)
			mat.albedo_color = Color(0.8, 0.75, 0.65)
			mesh = b
			
	m_inst.mesh = mesh
	m_inst.material_override = mat
	root.add_child(m_inst)
	return root

func _update_body_slot_btn(btn: CircularArtButton, slot_data: Dictionary) -> void:
	if not is_instance_valid(btn):
		return
	var item = slot_data.get("item", "")
	var count = slot_data.get("count", 0)
	
	btn.icon_name = item
	btn.badge_text = ("x%d" % count) if count > 0 else ""
	btn.ring_color = Color(0.96, 0.66, 0.16) if count > 0 else Color(0.35, 0.4, 0.55, 0.6)
	btn.is_active = (count > 0)

# =============================================================================
# INTERACTIONS & DRAG-AND-DROP DISPATCH
# =============================================================================
func _on_slot_drag_transferred(from_data: Dictionary, target_slot_id: String) -> void:
	if not crafting:
		return
		
	var source_owner = from_data.get("slot_owner", "")
	var source_slot = from_data.get("slot_id", "")
	var item = from_data.get("icon_name", "")
	
	# Case 1: Body to Body swap/move
	if source_owner == "astronaut" and crafting.body_slots.has(target_slot_id):
		crafting.swap_body_slots(source_slot, target_slot_id)
		AudioManager.play("click")
		_refresh_ui()
		return
		
	# Case 2: Body to Ship Cargo deposit
	if source_owner == "astronaut" and (target_slot_id in cargo_slots.keys() or target_slot_id == "ship"):
		crafting.deposit_body_slot_to_storage(source_slot)
		AudioManager.play("craft", 1.0)
		_refresh_ui()
		return
		
	# Case 3: Ship Cargo to Body equip
	if source_owner == "ship" and crafting.body_slots.has(target_slot_id):
		crafting.equip_storage_to_body_slot(source_slot, target_slot_id)
		AudioManager.play("click")
		_refresh_ui()
		return

func _on_body_slot_clicked(slot_key: String) -> void:
	if not crafting:
		return
	var s = crafting.get_body_slot(slot_key)
	if s["count"] <= 0:
		return
	if is_ship_storage_accessible:
		crafting.deposit_body_slot_to_storage(slot_key)
		AudioManager.play("craft", 1.0)
	else:
		# Field gear: Click drops item to ground!
		var dropped = crafting.drop_body_slot(slot_key)
		if not dropped.is_empty():
			var player = get_tree().get_first_node_in_group("player")
			if is_instance_valid(player) and player.has_method("drop_item_to_world"):
				player.drop_item_to_world(dropped["item"], dropped["count"])
			AudioManager.play("click", 0.9)
	_refresh_ui()

func _on_body_slot_right_clicked(slot_key: String) -> void:
	if not crafting:
		return
	var s = crafting.get_body_slot(slot_key)
	if s["count"] <= 0:
		return
	var dropped = crafting.drop_body_slot(slot_key)
	if not dropped.is_empty():
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player.has_method("drop_item_to_world"):
			player.drop_item_to_world(dropped["item"], dropped["count"])
		AudioManager.play("click", 0.9)
	_refresh_ui()

func _on_cargo_slot_clicked(item_name: String) -> void:
	if not crafting:
		return
	if crafting.ship_storage.get(item_name, 0) > 0:
		if crafting.equip_storage_to_body_slot(item_name):
			AudioManager.play("click")
			_refresh_ui()

func _on_cargo_slot_right_clicked(item_name: String) -> void:
	if not crafting:
		return
	if crafting.ship_storage.get(item_name, 0) <= 0:
		return
	var dropped = crafting.drop_storage_item(item_name, 1)
	if not dropped.is_empty():
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player.has_method("drop_item_to_world"):
			player.drop_item_to_world(dropped["item"], dropped["count"])
		AudioManager.play("click", 0.9)
	_refresh_ui()

func _on_helmet_toggle_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("attempt_toggle_helmet"):
		player.attempt_toggle_helmet()
		_refresh_ui()

func _on_deposit_all_pressed() -> void:
	if crafting:
		crafting.deposit_all_to_storage()
		AudioManager.play("craft", 1.0)
		_refresh_ui()

func _on_withdraw_all_pressed() -> void:
	if crafting:
		crafting.withdraw_all_from_storage()
		AudioManager.play("click")
		_refresh_ui()
