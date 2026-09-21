@tool
extends Control
class_name AstronautStorageModal

signal closed()

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

# Storage Slots Grid
var cargo_slots: Dictionary = {}
var deposit_all_btn: Button
var withdraw_all_btn: Button
var close_btn: CircularArtButton
var main_panel: PanelContainer
var title_label: Label
var cargo_area: VBoxContainer
var capacity_status_label: Label

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

func open_modal(with_ship_storage: bool = true) -> void:
	is_ship_storage_accessible = with_ship_storage
	visible = true
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
	content_split.add_theme_constant_override("separation", 24)
	main_vbox.add_child(content_split)
	
	# Left: Astronaut Body Blueprint Area
	var body_area_box = VBoxContainer.new()
	body_area_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_split.add_child(body_area_box)
	
	var body_area = Control.new()
	body_area.name = "BodyArea"
	body_area.custom_minimum_size = Vector2(310, 310)
	body_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_area.draw.connect(_on_body_area_draw.bind(body_area))
	body_area_box.add_child(body_area)
	
	capacity_status_label = Label.new()
	capacity_status_label.text = "RANURAS DEL TRAJE: 0/4"
	capacity_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	capacity_status_label.add_theme_font_size_override("font_size", 11)
	capacity_status_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	body_area_box.add_child(capacity_status_label)
	
	# Create Body Slot Buttons positioned around the astronaut blueprint
	# Hand Left (anchored left of chest)
	slot_hand_l = _create_slot_button("hand_left", "astronaut", Vector2(18, 90), "MANO IZQ")
	body_area.add_child(slot_hand_l)
	
	# Hand Right (anchored right of chest)
	slot_hand_r = _create_slot_button("hand_right", "astronaut", Vector2(230, 90), "MANO DER")
	body_area.add_child(slot_hand_r)
	
	# Back 1 (Upper dorsal backpack mount)
	slot_back_1 = _create_slot_button("back_1", "astronaut", Vector2(18, 195), "ESPALDA (1)")
	body_area.add_child(slot_back_1)
	
	# Back 2 (Lower dorsal backpack mount)
	slot_back_2 = _create_slot_button("back_2", "astronaut", Vector2(230, 195), "ESPALDA (2)")
	body_area.add_child(slot_back_2)
	
	# Right: Ship Cargo Bay Grid Area
	cargo_area = VBoxContainer.new()
	cargo_area.name = "CargoArea"
	cargo_area.custom_minimum_size = Vector2(380, 310)
	cargo_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_split.add_child(cargo_area)
	
	var cargo_header = Label.new()
	cargo_header.text = "📦 ALMACÉN DE LA NAVE (BODEGA)" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "📦 SHIP CARGO STORAGE"
	cargo_header.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	cargo_header.add_theme_font_size_override("font_size", 13)
	cargo_area.add_child(cargo_header)
	
	var cargo_grid = GridContainer.new()
	cargo_grid.columns = 4
	cargo_grid.add_theme_constant_override("h_separation", 12)
	cargo_grid.add_theme_constant_override("v_separation", 10)
	cargo_area.add_child(cargo_grid)
	
	var cargo_items = ["iron", "copper", "silicon", "uranium", "wrench", "wire", "microchip", "reactor_cell"]
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
	
	_update_modal_mode()

func _create_slot_button(slot_key: String, owner_type: String, pos: Vector2, caption: String) -> CircularArtButton:
	var btn = CircularArtButton.new()
	btn.name = "Slot_" + slot_key
	btn.slot_id = slot_key
	btn.slot_owner = owner_type
	btn.enable_drag = true
	btn.enable_drop = true
	btn.custom_minimum_size = Vector2(62, 62)
	btn.position = pos
	btn.drag_transferred.connect(_on_slot_drag_transferred)
	btn.pressed.connect(_on_body_slot_clicked.bind(slot_key))
	
	# Caption label underneath
	var lbl = Label.new()
	lbl.text = caption
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-15, 62)
	lbl.size = Vector2(92, 20)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 0.75))
	btn.add_child(lbl)
	
	return btn

func _create_cargo_slot_button(item_name: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 3)
	
	var btn = CircularArtButton.new()
	btn.name = "CargoSlot_" + item_name
	btn.slot_id = item_name
	btn.slot_owner = "ship"
	btn.enable_drag = true
	btn.enable_drop = true
	btn.custom_minimum_size = Vector2(58, 58)
	btn.icon_name = item_name
	btn.drag_transferred.connect(_on_slot_drag_transferred)
	btn.pressed.connect(_on_cargo_slot_clicked.bind(item_name))
	container.add_child(btn)
	
	var lbl = Label.new()
	lbl.text = item_name.capitalize()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	container.add_child(lbl)
	
	return container

# ==========================================
# DRAW HOLOGRAPHIC ASTRONAUT BLUEPRINT
# ==========================================
func _on_body_area_draw(area: Control) -> void:
	var c = Vector2(area.size.x * 0.5, area.size.y * 0.5 - 10.0)
	var cyan_line = Color(0.2, 0.85, 1.0, 0.45)
	var gold_line = Color(0.96, 0.66, 0.16, 0.55)
	
	# Connecting circuit lines from slots to astronaut body
	# Left Hand line
	area.draw_line(Vector2(65, 120), c + Vector2(-22, 10), cyan_line, 1.5)
	area.draw_circle(c + Vector2(-22, 10), 3.0, cyan_line)
	
	# Right Hand line
	area.draw_line(Vector2(245, 120), c + Vector2(22, 10), cyan_line, 1.5)
	area.draw_circle(c + Vector2(22, 10), 3.0, cyan_line)
	
	# Back 1 line
	area.draw_line(Vector2(65, 225), c + Vector2(-15, -12), gold_line, 1.5)
	area.draw_circle(c + Vector2(-15, -12), 3.0, gold_line)
	
	# Back 2 line
	area.draw_line(Vector2(245, 225), c + Vector2(15, -12), gold_line, 1.5)
	area.draw_circle(c + Vector2(15, -12), 3.0, gold_line)
	
	# Stylized Holographic Astronaut Silhouette in Center
	var holo_col = Color(0.25, 0.8, 1.0, 0.30)
	var holo_rim = Color(0.4, 0.9, 1.0, 0.75)
	
	# Helmet
	var head_c = c + Vector2(0, -50)
	area.draw_circle(head_c, 18.0, holo_col)
	area.draw_arc(head_c, 18.0, 0, TAU, 24, holo_rim, 1.8)
	# Visor
	var visor_pts = PackedVector2Array([
		head_c + Vector2(-9, -4),
		head_c + Vector2(9, -4),
		head_c + Vector2(6, 7),
		head_c + Vector2(-6, 7)
	])
	area.draw_colored_polygon(visor_pts, Color(1.0, 0.75, 0.2, 0.8))
	
	# Backpack outline
	var bpack = Rect2(c + Vector2(-22, -32), Vector2(44, 48))
	area.draw_rect(bpack, Color(0.96, 0.66, 0.16, 0.18), true)
	area.draw_rect(bpack, Color(0.96, 0.66, 0.16, 0.55), false, 1.5)
	
	# Torso
	var torso_pts = PackedVector2Array([
		c + Vector2(-16, -30),
		c + Vector2(16, -30),
		c + Vector2(12, 25),
		c + Vector2(-12, 25)
	])
	area.draw_colored_polygon(torso_pts, holo_col)
	area.draw_polyline(torso_pts, holo_rim, 1.8, true)
	
	# Legs
	area.draw_line(c + Vector2(-7, 25), c + Vector2(-10, 75), holo_rim, 3.5)
	area.draw_line(c + Vector2(7, 25), c + Vector2(10, 75), holo_rim, 3.5)
	
	# Arms
	area.draw_line(c + Vector2(-15, -24), c + Vector2(-26, 12), holo_rim, 3.0)
	area.draw_line(c + Vector2(15, -24), c + Vector2(26, 12), holo_rim, 3.0)

# ==========================================
# REFRESH UI & STATE BINDING
# ==========================================
func _refresh_ui() -> void:
	if not crafting:
		return
		
	# Refresh Body Slots
	var b_slots = crafting.body_slots
	_update_body_slot_btn(slot_hand_l, b_slots.get("hand_left", {}))
	_update_body_slot_btn(slot_hand_r, b_slots.get("hand_right", {}))
	_update_body_slot_btn(slot_back_1, b_slots.get("back_1", {}))
	_update_body_slot_btn(slot_back_2, b_slots.get("back_2", {}))
	
	if capacity_status_label:
		var occupied = 0
		for s in b_slots.values():
			if s.get("count", 0) > 0:
				occupied += 1
		capacity_status_label.text = ("RANURAS DEL TRAJE: %d/4" % occupied) if (is_instance_valid(GameManager) and GameManager.current_language == "es") else ("SUIT SLOTS: %d/4" % occupied)
		capacity_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4) if occupied >= 4 else Color(0.2, 0.85, 1.0))
	
	# Refresh Ship Storage Grid
	var store = crafting.ship_storage
	for item_name in cargo_slots.keys():
		var v_container = cargo_slots[item_name]
		var btn: CircularArtButton = v_container.get_child(0)
		var count = store.get(item_name, 0)
		btn.badge_text = ("x%d" % count) if count > 0 else ""
		btn.ring_color = Color(0.96, 0.66, 0.16) if count > 0 else Color(0.35, 0.35, 0.45)
		btn.bg_color = Color(0.09, 0.08, 0.16) if count > 0 else Color(0.06, 0.06, 0.09)

func _update_body_slot_btn(btn: CircularArtButton, slot_data: Dictionary) -> void:
	if not is_instance_valid(btn):
		return
	var item = slot_data.get("item", "")
	var count = slot_data.get("count", 0)
	
	btn.icon_name = item
	btn.badge_text = ("x%d" % count) if count > 0 else ""
	btn.ring_color = Color(0.96, 0.66, 0.16) if count > 0 else Color(0.35, 0.4, 0.55, 0.6)
	btn.is_active = (count > 0)

# ==========================================
# INTERACTION & DRAG-AND-DROP DISPATCH
# ==========================================
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
	# Clicking an astronaut body slot deposits it to ship storage (if open)
	var s = crafting.get_body_slot(slot_key)
	if s["count"] > 0:
		crafting.deposit_body_slot_to_storage(slot_key)
		AudioManager.play("craft", 1.0)
		_refresh_ui()

func _on_cargo_slot_clicked(item_name: String) -> void:
	if not crafting:
		return
	# Clicking a cargo slot equips it to the first free astronaut body slot
	if crafting.ship_storage.get(item_name, 0) > 0:
		if crafting.equip_storage_to_body_slot(item_name):
			AudioManager.play("click")
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
