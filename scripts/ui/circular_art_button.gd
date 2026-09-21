@tool
extends BaseButton
class_name CircularArtButton

signal drag_transferred(from_data: Dictionary, target_slot: String)

enum IconType {
	NONE,
	SPRINT,
	THRUST,
	SWIM,
	MINE,
	STORAGE,
	FABRICATOR,
	PILOT_SEAT,
	HATCH_OPEN,
	HATCH_CLOSE,
	OXYGEN_GEN,
	GRAVITY_DEVICE,
	ATTACK,
	FEED,
	REPAIR,
	STARMAP,
	HYPERDRIVE,
	CAMERA,
	PAUSE,
	BACKPACK,
	CLOSE,
	ARROW_UP,
	ARROW_DOWN,
	ARROW_LEFT,
	ARROW_RIGHT,
	GALAXY,
	PLANET,
	SOLAR_SYSTEM,
	INFO,
	CHEST,
	PLAY,
	SETTINGS,
	EXIT,
	# Inventory Resources
	IRON,
	COPPER,
	SILICON,
	URANIUM,
	WRENCH,
	WIRE,
	MICROCHIP,
	REACTOR_CELL,
	LUNA_COIN
}

@export var icon_type: IconType = IconType.NONE:
	set(val):
		icon_type = val
		queue_redraw()

@export var icon_name: String = "":
	set(val):
		icon_name = val
		_resolve_icon_name()
		queue_redraw()

@export var ring_color: Color = Color(0.96, 0.66, 0.16, 1.0): # Vibrant Amber/Gold
	set(val):
		ring_color = val
		queue_redraw()

@export var bg_color: Color = Color(0.09, 0.08, 0.16, 0.95): # Cosmic Deep Space Indigo
	set(val):
		bg_color = val
		queue_redraw()

@export var ring_thickness: float = 3.5:
	set(val):
		ring_thickness = val
		queue_redraw()

@export var is_active: bool = false:
	set(val):
		is_active = val
		queue_redraw()

@export var text: String = "":
	set(val):
		text = val
		queue_redraw()

@export var badge_text: String = "":
	set(val):
		badge_text = val
		queue_redraw()

@export var slot_id: String = ""
@export var slot_owner: String = "" # "astronaut" or "ship"
@export var enable_drag: bool = false
@export var enable_drop: bool = false

var is_hovered: bool = false
var pulse_time: float = 0.0

func _init() -> void:
	custom_minimum_size = Vector2(64, 64)
	focus_mode = Control.FOCUS_NONE

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_resolve_icon_name()

func _process(delta: float) -> void:
	if is_active or is_hovered or icon_type == IconType.HYPERDRIVE:
		pulse_time += delta * 4.0
		queue_redraw()

func _resolve_icon_name() -> void:
	match icon_name.to_lower():
		"sprint", "run": icon_type = IconType.SPRINT
		"thrust", "rocket", "jump": icon_type = IconType.THRUST
		"swim": icon_type = IconType.SWIM
		"mine": icon_type = IconType.MINE
		"storage": icon_type = IconType.STORAGE
		"fabricator", "craft": icon_type = IconType.FABRICATOR
		"pilot_seat", "pilot": icon_type = IconType.PILOT_SEAT
		"open_hatch": icon_type = IconType.HATCH_OPEN
		"close_hatch": icon_type = IconType.HATCH_CLOSE
		"oxygen_gen", "o2": icon_type = IconType.OXYGEN_GEN
		"gravity_device", "gravity": icon_type = IconType.GRAVITY_DEVICE
		"attack": icon_type = IconType.ATTACK
		"feed": icon_type = IconType.FEED
		"repair": icon_type = IconType.REPAIR
		"starmap": icon_type = IconType.STARMAP
		"hyperdrive": icon_type = IconType.HYPERDRIVE
		"camera", "cam": icon_type = IconType.CAMERA
		"pause": icon_type = IconType.PAUSE
		"backpack", "inv", "inventory": icon_type = IconType.BACKPACK
		"close": icon_type = IconType.CLOSE
		"arrow_up", "withdraw": icon_type = IconType.ARROW_UP
		"arrow_down", "deposit": icon_type = IconType.ARROW_DOWN
		"arrow_left", "back", "return": icon_type = IconType.ARROW_LEFT
		"arrow_right", "next", "forward": icon_type = IconType.ARROW_RIGHT
		"galaxy", "universe", "cosmos", "new_system": icon_type = IconType.GALAXY
		"planet", "world": icon_type = IconType.PLANET
		"solar_system", "system", "orbits": icon_type = IconType.SOLAR_SYSTEM
		"info", "details", "telemetry": icon_type = IconType.INFO
		"chest", "crate": icon_type = IconType.CHEST
		"play", "resume": icon_type = IconType.PLAY
		"settings", "gear": icon_type = IconType.SETTINGS
		"exit", "home", "menu": icon_type = IconType.EXIT
		"iron": icon_type = IconType.IRON
		"copper": icon_type = IconType.COPPER
		"silicon": icon_type = IconType.SILICON
		"uranium": icon_type = IconType.URANIUM
		"wrench": icon_type = IconType.WRENCH
		"wire": icon_type = IconType.WIRE
		"microchip": icon_type = IconType.MICROCHIP
		"reactor_cell": icon_type = IconType.REACTOR_CELL
		"coin", "luna_coin", "luna": icon_type = IconType.LUNA_COIN
		_: pass

func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _on_button_down() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_QUAD)
	pivot_offset = size * 0.5
	queue_redraw()

func _on_button_up() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pivot_offset = size * 0.5
	queue_redraw()

# ==========================================
# DRAG & DROP HANDLING
# ==========================================
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not enable_drag or icon_type == IconType.NONE:
		return null
		
	var drag_data = {
		"slot_id": slot_id,
		"slot_owner": slot_owner,
		"icon_type": icon_type,
		"icon_name": icon_name,
		"badge_text": badge_text
	}
	
	# Create drag preview (a floating glowing circular button)
	var preview = Control.new()
	var preview_btn = CircularArtButton.new()
	preview_btn.custom_minimum_size = Vector2(56, 56)
	preview_btn.size = Vector2(56, 56)
	preview_btn.icon_type = icon_type
	preview_btn.icon_name = icon_name
	preview_btn.badge_text = badge_text
	preview_btn.position = -Vector2(28, 28)
	preview.add_child(preview_btn)
	if is_inside_tree():
		set_drag_preview(preview)
	
	return drag_data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not enable_drop or not (data is Dictionary):
		return false
	return data.has("slot_id") and (data.get("slot_id") != slot_id or data.get("slot_owner") != slot_owner)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		drag_transferred.emit(data, slot_id)
		queue_redraw()

# ==========================================
# DRAWING ROUTINES (AUTHENTIC PIXEL / VECTOR ART)
# ==========================================
func _draw() -> void:
	var center = size * 0.5
	var radius = min(size.x, size.y) * 0.46
	var is_down = button_pressed
	
	# 1. Outer ambient shadow
	draw_circle(center + Vector2(0, 2.5), radius, Color(0.0, 0.0, 0.0, 0.45))
	
	# 2. Disc Background fill
	var current_bg = bg_color
	if is_hovered:
		current_bg = current_bg.lightened(0.12)
	if is_down:
		current_bg = current_bg.lightened(0.22)
	draw_circle(center, radius - 1.0, current_bg)
	
	# 3. Outer Golden / Amber Rim (The signature look)
	var cur_ring = ring_color
	if is_active:
		var pulse = (sin(pulse_time) + 1.0) * 0.5
		cur_ring = cur_ring.lerp(Color(1.0, 0.95, 0.4, 1.0), pulse * 0.7)
		draw_arc(center, radius + 2.0, 0, TAU, 36, Color(1.0, 0.8, 0.2, 0.35 * pulse), 2.0)
	elif is_hovered:
		cur_ring = cur_ring.lightened(0.2)
		draw_arc(center, radius + 1.5, 0, TAU, 36, Color(0.96, 0.75, 0.25, 0.3), 1.5)
		
	draw_arc(center, radius, 0, TAU, 40, cur_ring, ring_thickness)
	
	# Subtle inner rim bevel for depth
	draw_arc(center, radius - ring_thickness * 0.9, 0, TAU, 36, cur_ring.darkened(0.55), 1.2)
	
	# 4. Draw Central Stylized Vector Icon
	var icon_center = center
	if is_down:
		icon_center += Vector2(0, 1.5)
		
	var icon_scale = radius / 36.0 # Normalize relative to 72px diameter button
	
	match icon_type:
		IconType.SPRINT:
			_draw_sprint_astronaut(icon_center, icon_scale)
		IconType.THRUST:
			_draw_rocket_ship(icon_center, icon_scale)
		IconType.SWIM:
			_draw_swim_fins(icon_center, icon_scale)
		IconType.MINE:
			_draw_mine_pick(icon_center, icon_scale)
		IconType.STORAGE:
			_draw_storage_crate(icon_center, icon_scale)
		IconType.FABRICATOR:
			_draw_fabricator_gear(icon_center, icon_scale)
		IconType.PILOT_SEAT:
			_draw_pilot_helm(icon_center, icon_scale)
		IconType.HATCH_OPEN, IconType.HATCH_CLOSE:
			_draw_airlock_hatch(icon_center, icon_scale, icon_type == IconType.HATCH_OPEN)
		IconType.OXYGEN_GEN:
			_draw_oxygen_canister(icon_center, icon_scale)
		IconType.GRAVITY_DEVICE:
			_draw_gravity_gyro(icon_center, icon_scale)
		IconType.ATTACK:
			_draw_attack_blade(icon_center, icon_scale)
		IconType.FEED:
			_draw_feed_leaf(icon_center, icon_scale)
		IconType.REPAIR:
			_draw_repair_torch(icon_center, icon_scale)
		IconType.STARMAP:
			_draw_starmap_orbits(icon_center, icon_scale)
		IconType.HYPERDRIVE:
			_draw_hyperdrive_core(icon_center, icon_scale)
		IconType.CAMERA:
			_draw_camera_visor(icon_center, icon_scale)
		IconType.PAUSE:
			_draw_pause_bars(icon_center, icon_scale)
		IconType.BACKPACK:
			_draw_backpack_gear(icon_center, icon_scale)
		IconType.CLOSE:
			_draw_close_cross(icon_center, icon_scale)
		IconType.ARROW_UP:
			_draw_arrow_up(icon_center, icon_scale)
		IconType.ARROW_DOWN:
			_draw_arrow_down(icon_center, icon_scale)
		IconType.ARROW_LEFT:
			_draw_arrow_left(icon_center, icon_scale)
		IconType.ARROW_RIGHT:
			_draw_arrow_right(icon_center, icon_scale)
		IconType.GALAXY:
			_draw_galaxy(icon_center, icon_scale)
		IconType.PLANET:
			_draw_planet_icon(icon_center, icon_scale)
		IconType.SOLAR_SYSTEM:
			_draw_solar_system_icon(icon_center, icon_scale)
		IconType.INFO:
			_draw_info_icon(icon_center, icon_scale)
		IconType.CHEST:
			_draw_chest(icon_center, icon_scale)
		IconType.PLAY:
			_draw_play_triangle(icon_center, icon_scale)
		IconType.SETTINGS:
			_draw_settings_gear(icon_center, icon_scale)
		IconType.EXIT:
			_draw_exit_door(icon_center, icon_scale)
		# Resource Ores & Components
		IconType.IRON:
			_draw_ore_iron(icon_center, icon_scale)
		IconType.COPPER:
			_draw_ore_copper(icon_center, icon_scale)
		IconType.SILICON:
			_draw_ore_silicon(icon_center, icon_scale)
		IconType.URANIUM:
			_draw_ore_uranium(icon_center, icon_scale)
		IconType.WRENCH:
			_draw_tool_wrench(icon_center, icon_scale)
		IconType.WIRE:
			_draw_tool_wire(icon_center, icon_scale)
		IconType.MICROCHIP:
			_draw_tool_microchip(icon_center, icon_scale)
		IconType.REACTOR_CELL:
			_draw_tool_reactor_cell(icon_center, icon_scale)
		IconType.LUNA_COIN:
			_draw_luna_coin(icon_center, icon_scale)
			
	# 5. Badge Overlay (e.g. "x4", "100%")
	if badge_text != "":
		_draw_badge(center + Vector2(radius * 0.45, radius * 0.5), badge_text)

	# 6. Minimal Caption underneath
	if text != "":
		_draw_caption(center + Vector2(0, radius + 11.0), text)

# ----------------------------------------------------
# 0. LUNA COIN (GOLD CRYSTAL / COSMIC RELIC)
# ----------------------------------------------------
func _draw_luna_coin(c: Vector2, s: float) -> void:
	var gold = Color(0.96, 0.66, 0.16)
	var bright_gold = Color(1.0, 0.90, 0.35)
	var deep_gold = Color(0.72, 0.44, 0.08)
	
	# Outer faceted diamond / crystal coin
	var pts = PackedVector2Array([
		c + Vector2(0.0, -12.0) * s,
		c + Vector2(10.5, -3.5) * s,
		c + Vector2(7.0, 11.0) * s,
		c + Vector2(-7.0, 11.0) * s,
		c + Vector2(-10.5, -3.5) * s
	])
	draw_colored_polygon(pts, gold)
	draw_polyline(pts, bright_gold, 2.0 * s, true)
	
	# Shaded lower facet
	var lower_facet = PackedVector2Array([
		c + Vector2(0.0, 4.0) * s,
		c + Vector2(7.0, 11.0) * s,
		c + Vector2(-7.0, 11.0) * s
	])
	draw_colored_polygon(lower_facet, deep_gold)
	
	# Inner radiant prism
	var inner = PackedVector2Array([
		c + Vector2(0.0, -7.0) * s,
		c + Vector2(5.5, 0.0) * s,
		c + Vector2(0.0, 5.5) * s,
		c + Vector2(-5.5, 0.0) * s
	])
	draw_colored_polygon(inner, bright_gold)

# ----------------------------------------------------
# 1. SPRINT ASTRONAUT (EXACTLY MATCHING USER'S IMAGE)
# ----------------------------------------------------
func _draw_sprint_astronaut(c: Vector2, s: float) -> void:
	var white = Color(0.96, 0.96, 1.0)
	var coral = Color(0.92, 0.28, 0.22) # Orange-red boots & backpack
	var gold = Color(1.0, 0.74, 0.15)  # Visor & speed dashes
	
	# Horizontal speed streaks on the left
	draw_line(c + Vector2(-22.0, -4.0) * s, c + Vector2(-15.0, -4.0) * s, gold, 2.5 * s)
	draw_line(c + Vector2(-24.0, 3.0) * s, c + Vector2(-17.0, 3.0) * s, gold, 2.5 * s)
	
	# Backpack on torso back
	var bpack = PackedVector2Array([
		c + Vector2(-7.0, -10.0) * s,
		c + Vector2(-1.0, -10.0) * s,
		c + Vector2(-2.0, 1.0) * s,
		c + Vector2(-8.0, -1.0) * s
	])
	draw_colored_polygon(bpack, coral)
	
	# White Helmet (Circle with visor cut)
	var head_pos = c + Vector2(4.0, -13.0) * s
	draw_circle(head_pos, 5.0 * s, white)
	
	# Visor (Golden diamond/oval on helmet)
	var visor = PackedVector2Array([
		head_pos + Vector2(1.5, -2.5) * s,
		head_pos + Vector2(5.0, -0.5) * s,
		head_pos + Vector2(2.5, 2.5) * s,
		head_pos + Vector2(0.5, 0.5) * s
	])
	draw_colored_polygon(visor, gold)
	
	# Leaning Torso
	var torso = PackedVector2Array([
		c + Vector2(1.0, -8.0) * s,
		c + Vector2(6.0, -8.0) * s,
		c + Vector2(3.0, 3.0) * s,
		c + Vector2(-2.0, 1.0) * s
	])
	draw_colored_polygon(torso, white)
	
	# Forward Arm driving up
	draw_line(c + Vector2(5.0, -6.0) * s, c + Vector2(13.0, -8.0) * s, white, 2.8 * s)
	draw_line(c + Vector2(13.0, -8.0) * s, c + Vector2(11.0, -14.0) * s, gold, 2.8 * s) # Glove
	
	# Back Arm pumping behind
	draw_line(c + Vector2(0.0, -5.0) * s, c + Vector2(-8.0, -1.0) * s, white, 2.8 * s)
	draw_circle(c + Vector2(-8.0, -1.0) * s, 2.0 * s, coral) # Glove
	
	# Front Leg (bent forward knee driving)
	draw_line(c + Vector2(2.0, 2.0) * s, c + Vector2(8.0, 8.0) * s, white, 3.0 * s)
	draw_line(c + Vector2(8.0, 8.0) * s, c + Vector2(7.0, 16.0) * s, coral, 3.0 * s)
	draw_line(c + Vector2(7.0, 16.0) * s, c + Vector2(12.0, 16.0) * s, gold, 2.5 * s) # Boot tip
	
	# Back Leg (trailing behind with knee kick)
	draw_line(c + Vector2(-1.0, 2.0) * s, c + Vector2(-7.0, 8.0) * s, white, 3.0 * s)
	draw_line(c + Vector2(-7.0, 8.0) * s, c + Vector2(-14.0, 11.0) * s, coral, 3.0 * s)

# ----------------------------------------------------
# 2. ROCKET SHIP (EXACTLY MATCHING USER'S IMAGE)
# ----------------------------------------------------
func _draw_rocket_ship(c: Vector2, s: float) -> void:
	var white = Color(0.96, 0.96, 1.0)
	var red = Color(0.91, 0.25, 0.21)    # Coral-red nose & wings
	var yellow = Color(0.98, 0.76, 0.16) # Thruster flame tip
	
	# Top Red Diamond Cockpit
	var diamond = PackedVector2Array([
		c + Vector2(0.0, -22.0) * s,
		c + Vector2(4.5, -11.0) * s,
		c + Vector2(0.0, -4.0) * s,
		c + Vector2(-4.5, -11.0) * s
	])
	draw_colored_polygon(diamond, red)
	
	# Central White Fuselage (Stealth Hexagonal capsule)
	var fuselage = PackedVector2Array([
		c + Vector2(0.0, -13.0) * s,
		c + Vector2(7.0, -1.0) * s,
		c + Vector2(5.5, 11.0) * s,
		c + Vector2(-5.5, 11.0) * s,
		c + Vector2(-7.0, -1.0) * s
	])
	draw_colored_polygon(fuselage, white)
	
	# Left Red Triangular Fin
	var left_fin = PackedVector2Array([
		c + Vector2(-6.0, 0.0) * s,
		c + Vector2(-16.0, 10.5) * s,
		c + Vector2(-5.5, 10.5) * s
	])
	draw_colored_polygon(left_fin, red)
	
	# Right Red Triangular Fin
	var right_fin = PackedVector2Array([
		c + Vector2(6.0, 0.0) * s,
		c + Vector2(16.0, 10.5) * s,
		c + Vector2(5.5, 10.5) * s
	])
	draw_colored_polygon(right_fin, red)
	
	# Bottom Yellow Thrust Flame Tip
	var flame = PackedVector2Array([
		c + Vector2(-4.5, 11.0) * s,
		c + Vector2(4.5, 11.0) * s,
		c + Vector2(0.0, 21.0) * s
	])
	draw_colored_polygon(flame, yellow)

# ----------------------------------------------------
# 3. INTERACTION ICONS
# ----------------------------------------------------
func _draw_swim_fins(c: Vector2, s: float) -> void:
	var cyan = Color(0.2, 0.85, 1.0)
	var white = Color(0.9, 0.95, 1.0)
	# Dual curved hydrodynamic flippers
	draw_arc(c + Vector2(-6.0, 0.0) * s, 12.0 * s, -PI*0.4, PI*0.6, 16, cyan, 3.5 * s)
	draw_arc(c + Vector2(6.0, 0.0) * s, 12.0 * s, PI*0.4, PI*1.4, 16, cyan, 3.5 * s)
	draw_circle(c, 4.0 * s, white)

func _draw_mine_pick(c: Vector2, s: float) -> void:
	var cyan = Color(0.25, 0.9, 1.0)
	var gold = Color(1.0, 0.8, 0.2)
	# Futuristic Mining Pick / Beam Emitter
	draw_line(c + Vector2(-12.0, 12.0) * s, c + Vector2(8.0, -8.0) * s, Color(0.7, 0.75, 0.85), 3.0 * s)
	var head = PackedVector2Array([
		c + Vector2(-3.0, -16.0) * s,
		c + Vector2(16.0, -13.0) * s,
		c + Vector2(13.0, 3.0) * s,
		c + Vector2(7.0, -4.0) * s
	])
	draw_colored_polygon(head, cyan)
	draw_circle(c + Vector2(16.0, -13.0) * s, 3.0 * s, gold)

func _draw_storage_crate(c: Vector2, s: float) -> void:
	var amber = Color(1.0, 0.75, 0.2)
	var dark_box = Color(0.18, 0.22, 0.35)
	# Hexagonal Cargo Crate
	var box = PackedVector2Array([
		c + Vector2(-14.0, -10.0) * s,
		c + Vector2(14.0, -10.0) * s,
		c + Vector2(14.0, 11.0) * s,
		c + Vector2(-14.0, 11.0) * s
	])
	draw_colored_polygon(box, dark_box)
	draw_polyline(box, amber, 2.5 * s, true)
	draw_line(c + Vector2(-14.0, 0.0) * s, c + Vector2(14.0, 0.0) * s, amber, 1.8 * s)
	draw_circle(c, 3.5 * s, Color(0.2, 0.9, 1.0)) # Central cyber lock

func _draw_fabricator_gear(c: Vector2, s: float) -> void:
	var green = Color(0.3, 0.95, 0.45)
	var white = Color(0.95, 0.95, 1.0)
	# Crossed Wrench & Screwdriver
	draw_line(c + Vector2(-12.0, 12.0) * s, c + Vector2(12.0, -12.0) * s, white, 3.5 * s)
	draw_line(c + Vector2(12.0, 12.0) * s, c + Vector2(-12.0, -12.0) * s, green, 3.0 * s)
	draw_circle(c + Vector2(12.0, -12.0) * s, 5.0 * s, white)
	draw_circle(c + Vector2(12.0, -12.0) * s, 2.5 * s, bg_color)

func _draw_pilot_helm(c: Vector2, s: float) -> void:
	var cyan = Color(0.3, 0.85, 1.0)
	var white = Color(0.95, 0.95, 1.0)
	# Spaceship steering yoke / cockpit seat
	draw_arc(c, 13.0 * s, -PI*0.75, -PI*0.25, 16, cyan, 3.0 * s)
	draw_arc(c, 13.0 * s, PI*0.25, PI*0.75, 16, cyan, 3.0 * s)
	draw_line(c + Vector2(-9.0, 0.0) * s, c + Vector2(9.0, 0.0) * s, white, 2.5 * s)
	draw_circle(c, 3.5 * s, Color(1.0, 0.75, 0.2))

func _draw_airlock_hatch(c: Vector2, s: float, is_open: bool) -> void:
	var col = Color(0.2, 0.9, 1.0) if is_open else Color(1.0, 0.6, 0.2)
	# Hexagonal portal
	var hex = PackedVector2Array([
		c + Vector2(0.0, -14.0) * s,
		c + Vector2(12.0, -7.0) * s,
		c + Vector2(12.0, 7.0) * s,
		c + Vector2(0.0, 14.0) * s,
		c + Vector2(-12.0, 7.0) * s,
		c + Vector2(-12.0, -7.0) * s
	])
	draw_polyline(hex, col, 2.5 * s, true)
	if is_open:
		draw_line(c + Vector2(-6.0, 0) * s, c + Vector2(6.0, 0) * s, col, 3.0 * s)
	else:
		draw_circle(c, 4.0 * s, col)

func _draw_oxygen_canister(c: Vector2, s: float) -> void:
	var cyan = Color(0.2, 0.9, 0.85)
	# Twin cylinders
	draw_rect(Rect2(c + Vector2(-9.0, -10.0) * s, Vector2(7.0, 20.0) * s), cyan, true)
	draw_rect(Rect2(c + Vector2(2.0, -10.0) * s, Vector2(7.0, 20.0) * s), cyan, true)
	draw_circle(c + Vector2(-5.5, -10.0) * s, 3.5 * s, Color(1, 1, 1))
	draw_circle(c + Vector2(5.5, -10.0) * s, 3.5 * s, Color(1, 1, 1))

func _draw_gravity_gyro(c: Vector2, s: float) -> void:
	var purple = Color(0.8, 0.5, 1.0)
	var cyan = Color(0.3, 0.9, 1.0)
	draw_arc(c, 14.0 * s, 0, TAU, 32, purple, 2.2 * s)
	draw_arc(c, 9.0 * s, pulse_time, pulse_time + PI*1.4, 20, cyan, 2.5 * s)
	draw_circle(c, 3.5 * s, Color(1.0, 0.95, 0.4))

func _draw_attack_blade(c: Vector2, s: float) -> void:
	var red = Color(1.0, 0.25, 0.25)
	var white = Color(1.0, 0.9, 0.9)
	draw_line(c + Vector2(-10.0, 10.0) * s, c + Vector2(12.0, -12.0) * s, red, 4.0 * s)
	draw_line(c + Vector2(-10.0, 10.0) * s, c + Vector2(12.0, -12.0) * s, white, 1.8 * s)
	draw_line(c + Vector2(-6.0, 11.0) * s, c + Vector2(-11.0, 6.0) * s, Color(1.0, 0.8, 0.2), 3.0 * s)

func _draw_feed_leaf(c: Vector2, s: float) -> void:
	var green = Color(0.35, 1.0, 0.45)
	var pts = PackedVector2Array([
		c + Vector2(-11.0, 11.0) * s,
		c + Vector2(-3.0, -8.0) * s,
		c + Vector2(11.0, -12.0) * s,
		c + Vector2(6.0, 4.0) * s
	])
	draw_colored_polygon(pts, green)
	draw_line(c + Vector2(-11.0, 11.0) * s, c + Vector2(8.0, -8.0) * s, Color(0.9, 1.0, 0.8), 2.0 * s)

func _draw_repair_torch(c: Vector2, s: float) -> void:
	var orange = Color(1.0, 0.55, 0.2)
	draw_line(c + Vector2(-10.0, 10.0) * s, c + Vector2(4.0, -4.0) * s, Color(0.7, 0.75, 0.85), 3.5 * s)
	draw_circle(c + Vector2(8.0, -8.0) * s, 4.5 * s, orange)
	draw_circle(c + Vector2(8.0, -8.0) * s, 2.0 * s, Color(1.0, 0.95, 0.5))

func _draw_starmap_orbits(c: Vector2, s: float) -> void:
	var purple = Color(0.85, 0.55, 1.0)
	draw_arc(c, 13.0 * s, 0, TAU, 32, purple * 0.7, 1.5 * s)
	draw_circle(c, 5.0 * s, Color(1.0, 0.8, 0.2)) # Central Sun
	draw_circle(c + Vector2(9.0, -9.0) * s, 3.0 * s, Color(0.3, 0.85, 1.0)) # Planet

func _draw_hyperdrive_core(c: Vector2, s: float) -> void:
	var cyan = Color(0.2, 0.9, 1.0)
	var gold = Color(1.0, 0.8, 0.2)
	# Hyperspace Diamond Warp
	var diamond = PackedVector2Array([
		c + Vector2(0.0, -15.0) * s,
		c + Vector2(12.0, 0.0) * s,
		c + Vector2(0.0, 15.0) * s,
		c + Vector2(-12.0, 0.0) * s
	])
	draw_polyline(diamond, cyan, 2.5 * s, true)
	draw_circle(c, 5.0 * s, gold)

func _draw_camera_visor(c: Vector2, s: float) -> void:
	var white = Color(0.95, 0.95, 1.0)
	var cyan = Color(0.2, 0.85, 1.0)
	# Sleek Visor Outline
	var visor = PackedVector2Array([
		c + Vector2(-13.0, -5.0) * s,
		c + Vector2(13.0, -5.0) * s,
		c + Vector2(9.0, 6.0) * s,
		c + Vector2(-9.0, 6.0) * s
	])
	draw_colored_polygon(visor, cyan)
	draw_polyline(visor, white, 2.0 * s, true)

func _draw_pause_bars(c: Vector2, s: float) -> void:
	var gold = ring_color
	draw_rect(Rect2(c + Vector2(-7.0, -10.0) * s, Vector2(5.0, 20.0) * s), gold, true)
	draw_rect(Rect2(c + Vector2(2.0, -10.0) * s, Vector2(5.0, 20.0) * s), gold, true)

func _draw_backpack_gear(c: Vector2, s: float) -> void:
	var gold = Color(0.96, 0.72, 0.22)
	var dark_gold = Color(0.65, 0.42, 0.12)
	var white = Color(0.95, 0.95, 1.0)
	var cyan = Color(0.2, 0.85, 1.0)
	
	# 1. Top Canister / Bedroll cylinder
	var canister = Rect2(c + Vector2(-9.0, -13.0) * s, Vector2(18.0, 5.0) * s)
	draw_rect(canister, dark_gold, true)
	draw_rect(canister, gold, false, 1.5 * s)
	
	# 2. Main Backpack Body (Curved outline)
	var bag_rect = Rect2(c + Vector2(-11.0, -8.0) * s, Vector2(22.0, 20.0) * s)
	draw_rect(bag_rect, Color(0.12, 0.18, 0.26), true)
	draw_rect(bag_rect, gold, false, 2.0 * s)
	
	# 3. Flap / Pockets
	draw_line(c + Vector2(-11.0, 0.0) * s, c + Vector2(11.0, 0.0) * s, gold, 1.8 * s)
	
	# 4. Central Buckle (Cyan glowing square)
	var buckle = Rect2(c + Vector2(-3.0, -2.0) * s, Vector2(6.0, 5.0) * s)
	draw_rect(buckle, cyan, true)
	
	# 5. Twin Straps
	draw_line(c + Vector2(-6.0, -8.0) * s, c + Vector2(-6.0, 12.0) * s, white, 1.2 * s)
	draw_line(c + Vector2(6.0, -8.0) * s, c + Vector2(6.0, 12.0) * s, white, 1.2 * s)

func _draw_arrow_up(c: Vector2, s: float) -> void:
	var gold = Color(0.96, 0.72, 0.22)
	var pts = PackedVector2Array([
		c + Vector2(0.0, -11.0) * s,
		c + Vector2(9.0, -1.0) * s,
		c + Vector2(4.0, -1.0) * s,
		c + Vector2(4.0, 10.0) * s,
		c + Vector2(-4.0, 10.0) * s,
		c + Vector2(-4.0, -1.0) * s,
		c + Vector2(-9.0, -1.0) * s
	])
	draw_colored_polygon(pts, gold)
	draw_polyline(pts, Color(1.0, 0.9, 0.5), 1.2 * s, true)

func _draw_arrow_down(c: Vector2, s: float) -> void:
	var cyan = Color(0.2, 0.85, 1.0)
	var pts = PackedVector2Array([
		c + Vector2(0.0, 11.0) * s,
		c + Vector2(9.0, 1.0) * s,
		c + Vector2(4.0, 1.0) * s,
		c + Vector2(4.0, -10.0) * s,
		c + Vector2(-4.0, -10.0) * s,
		c + Vector2(-4.0, 1.0) * s,
		c + Vector2(-9.0, 1.0) * s
	])
	draw_colored_polygon(pts, cyan)
	draw_polyline(pts, Color(0.6, 0.95, 1.0), 1.2 * s, true)

func _draw_arrow_left(c: Vector2, s: float) -> void:
	var col = Color(0.95, 0.95, 1.0)
	var pts = PackedVector2Array([
		c + Vector2(-11.0, 0.0) * s,
		c + Vector2(-1.0, -9.0) * s,
		c + Vector2(-1.0, -4.0) * s,
		c + Vector2(10.0, -4.0) * s,
		c + Vector2(10.0, 4.0) * s,
		c + Vector2(-1.0, 4.0) * s,
		c + Vector2(-1.0, 9.0) * s
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts, Color(0.6, 0.85, 1.0), 1.2 * s, true)

func _draw_arrow_right(c: Vector2, s: float) -> void:
	var col = Color(0.95, 0.95, 1.0)
	var pts = PackedVector2Array([
		c + Vector2(11.0, 0.0) * s,
		c + Vector2(1.0, -9.0) * s,
		c + Vector2(1.0, -4.0) * s,
		c + Vector2(-10.0, -4.0) * s,
		c + Vector2(-10.0, 4.0) * s,
		c + Vector2(1.0, 4.0) * s,
		c + Vector2(1.0, 9.0) * s
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts, Color(0.6, 0.85, 1.0), 1.2 * s, true)

func _draw_galaxy(c: Vector2, s: float) -> void:
	var cyan = Color(0.2, 0.85, 1.0)
	var purple = Color(0.75, 0.45, 1.0)
	var gold = Color(1.0, 0.85, 0.3)
	draw_circle(c, 3.5 * s, gold)
	for arm in range(2):
		var arm_angle = arm * PI
		var arm_pts = PackedVector2Array()
		for i in range(8):
			var r = (3.0 + i * 1.4) * s
			var a = arm_angle + i * 0.45
			arm_pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_polyline(arm_pts, cyan if arm == 0 else purple, 1.6 * s)
	draw_circle(c + Vector2(-7.0, -6.0) * s, 1.2 * s, Color.WHITE)
	draw_circle(c + Vector2(8.0, 5.0) * s, 1.2 * s, Color.WHITE)

func _draw_planet_icon(c: Vector2, s: float) -> void:
	var cyan = Color(0.2, 0.8, 1.0)
	var green = Color(0.2, 0.85, 0.45)
	draw_circle(c, 7.5 * s, cyan)
	draw_circle(c + Vector2(-2.0, -1.0) * s, 3.0 * s, green)
	draw_arc(c, 10.5 * s, -0.4, PI + 0.4, 20, Color(1.0, 0.85, 0.3, 0.8), 1.6 * s)

func _draw_solar_system_icon(c: Vector2, s: float) -> void:
	var gold = Color(1.0, 0.8, 0.2)
	var cyan = Color(0.2, 0.8, 1.0)
	draw_circle(c, 3.5 * s, gold)
	draw_arc(c, 7.0 * s, 0, TAU, 24, Color(0.6, 0.7, 0.9, 0.5), 1.2 * s)
	draw_arc(c, 11.0 * s, 0, TAU, 24, Color(0.6, 0.7, 0.9, 0.5), 1.2 * s)
	draw_circle(c + Vector2(7.0, 0) * s, 1.8 * s, cyan)
	draw_circle(c + Vector2(-5.5, 9.5) * s, 1.5 * s, Color(0.9, 0.4, 0.4))

func _draw_info_icon(c: Vector2, s: float) -> void:
	var cyan = Color(0.2, 0.85, 1.0)
	draw_arc(c, 9.0 * s, 0, TAU, 24, Color(0.4, 0.7, 0.9, 0.6), 1.4 * s)
	draw_circle(c + Vector2(0, -4.0) * s, 1.8 * s, cyan)
	draw_line(c + Vector2(0, -1.0) * s, c + Vector2(0, 5.0) * s, cyan, 2.2 * s)

func _draw_chest(c: Vector2, s: float) -> void:
	var gold = Color(0.96, 0.72, 0.22)
	var cyan = Color(0.2, 0.85, 1.0)
	# Cargo Crate Box
	var box = Rect2(c + Vector2(-11.0, -6.0) * s, Vector2(22.0, 16.0) * s)
	draw_rect(box, Color(0.1, 0.16, 0.24), true)
	draw_rect(box, gold, false, 2.0 * s)
	# Crate Lid
	var lid = Rect2(c + Vector2(-13.0, -11.0) * s, Vector2(26.0, 5.0) * s)
	draw_rect(lid, Color(0.18, 0.24, 0.32), true)
	draw_rect(lid, gold, false, 1.5 * s)
	# Center Lock / Core
	draw_circle(c + Vector2(0.0, 1.0) * s, 3.0 * s, cyan)

func _draw_play_triangle(c: Vector2, s: float) -> void:
	var gold = Color(1.0, 0.82, 0.25)
	var pts = PackedVector2Array([
		c + Vector2(-6.0, -10.0) * s,
		c + Vector2(10.0, 0.0) * s,
		c + Vector2(-6.0, 10.0) * s
	])
	draw_colored_polygon(pts, gold)

func _draw_settings_gear(c: Vector2, s: float) -> void:
	var gold = Color(0.96, 0.72, 0.22)
	draw_circle(c, 7.5 * s, gold)
	draw_circle(c, 3.5 * s, Color(0.08, 0.1, 0.16)) # Center hole
	for i in range(6):
		var ang = i * TAU / 6.0
		var dir = Vector2(cos(ang), sin(ang))
		draw_rect(Rect2(c + dir * 8.0 * s - Vector2(2, 2) * s, Vector2(4, 4) * s), gold, true)

func _draw_exit_door(c: Vector2, s: float) -> void:
	var coral = Color(0.95, 0.4, 0.35)
	var white = Color(0.95, 0.95, 1.0)
	var door = Rect2(c + Vector2(-8.0, -11.0) * s, Vector2(12.0, 22.0) * s)
	draw_rect(door, Color(0.15, 0.08, 0.12), true)
	draw_rect(door, coral, false, 1.8 * s)
	draw_line(c + Vector2(0.0, 0.0) * s, c + Vector2(10.0, 0.0) * s, white, 2.0 * s)
	draw_line(c + Vector2(7.0, -4.0) * s, c + Vector2(11.0, 0.0) * s, white, 2.0 * s)
	draw_line(c + Vector2(7.0, 4.0) * s, c + Vector2(11.0, 0.0) * s, white, 2.0 * s)

func _draw_close_cross(c: Vector2, s: float) -> void:
	var coral = Color(0.95, 0.35, 0.35)
	draw_line(c + Vector2(-8.0, -8.0) * s, c + Vector2(8.0, 8.0) * s, coral, 3.0 * s)
	draw_line(c + Vector2(8.0, -8.0) * s, c + Vector2(-8.0, 8.0) * s, coral, 3.0 * s)

# ----------------------------------------------------
# 4. RESOURCE ICONS (FOR INVENTORY & STORAGE SLOTS)
# ----------------------------------------------------
func _draw_ore_iron(c: Vector2, s: float) -> void:
	var silver = Color(0.72, 0.78, 0.88)
	var dark_silver = Color(0.42, 0.48, 0.58)
	var pts = PackedVector2Array([
		c + Vector2(-11.0, -4.0) * s,
		c + Vector2(-3.0, -13.0) * s,
		c + Vector2(11.0, -7.0) * s,
		c + Vector2(12.0, 7.0) * s,
		c + Vector2(2.0, 13.0) * s,
		c + Vector2(-9.0, 8.0) * s
	])
	draw_colored_polygon(pts, silver)
	draw_line(c + Vector2(-3.0, -13.0) * s, c + Vector2(2.0, 13.0) * s, dark_silver, 2.0 * s)

func _draw_ore_copper(c: Vector2, s: float) -> void:
	var copper = Color(0.92, 0.48, 0.22)
	var gold = Color(1.0, 0.72, 0.35)
	var pts = PackedVector2Array([
		c + Vector2(-10.0, 2.0) * s,
		c + Vector2(-6.0, -10.0) * s,
		c + Vector2(8.0, -11.0) * s,
		c + Vector2(11.0, 3.0) * s,
		c + Vector2(0.0, 12.0) * s
	])
	draw_colored_polygon(pts, copper)
	draw_circle(c + Vector2(2.0, -3.0) * s, 3.0 * s, gold)

func _draw_ore_silicon(c: Vector2, s: float) -> void:
	var cyan = Color(0.2, 0.85, 1.0)
	var light_cyan = Color(0.7, 0.95, 1.0)
	# Crystal prism
	var pts = PackedVector2Array([
		c + Vector2(0.0, -14.0) * s,
		c + Vector2(10.0, -2.0) * s,
		c + Vector2(0.0, 14.0) * s,
		c + Vector2(-10.0, -2.0) * s
	])
	draw_colored_polygon(pts, cyan)
	draw_line(c + Vector2(0.0, -14.0) * s, c + Vector2(0.0, 14.0) * s, light_cyan, 2.0 * s)

func _draw_ore_uranium(c: Vector2, s: float) -> void:
	var neon_green = Color(0.25, 1.0, 0.35)
	# Glowing isotope rod
	var rod = PackedVector2Array([
		c + Vector2(-5.0, -12.0) * s,
		c + Vector2(5.0, -12.0) * s,
		c + Vector2(5.0, 12.0) * s,
		c + Vector2(-5.0, 12.0) * s
	])
	draw_colored_polygon(rod, neon_green)
	draw_arc(c, 13.0 * s, 0, TAU, 24, Color(0.25, 1.0, 0.35, 0.4), 1.5 * s)

func _draw_tool_wrench(c: Vector2, s: float) -> void:
	var white = Color(0.9, 0.95, 1.0)
	draw_line(c + Vector2(-10.0, 10.0) * s, c + Vector2(6.0, -6.0) * s, white, 3.5 * s)
	draw_circle(c + Vector2(8.0, -8.0) * s, 5.5 * s, white)
	draw_circle(c + Vector2(8.0, -8.0) * s, 2.5 * s, bg_color)

func _draw_tool_wire(c: Vector2, s: float) -> void:
	var copper = Color(0.95, 0.5, 0.2)
	draw_arc(c + Vector2(-3.0, 0) * s, 8.0 * s, -PI*0.5, PI*0.7, 16, copper, 2.8 * s)
	draw_arc(c + Vector2(3.0, 0) * s, 8.0 * s, PI*0.5, PI*1.7, 16, copper, 2.8 * s)

func _draw_tool_microchip(c: Vector2, s: float) -> void:
	var green = Color(0.12, 0.55, 0.3)
	var gold = Color(1.0, 0.78, 0.2)
	draw_rect(Rect2(c + Vector2(-9.0, -9.0) * s, Vector2(18.0, 18.0) * s), green, true)
	draw_rect(Rect2(c + Vector2(-5.0, -5.0) * s, Vector2(10.0, 10.0) * s), Color(0.2, 0.25, 0.3), true)
	# Pins
	draw_line(c + Vector2(-12.0, -4.0) * s, c + Vector2(-9.0, -4.0) * s, gold, 1.8 * s)
	draw_line(c + Vector2(-12.0, 4.0) * s, c + Vector2(-9.0, 4.0) * s, gold, 1.8 * s)
	draw_line(c + Vector2(9.0, -4.0) * s, c + Vector2(12.0, -4.0) * s, gold, 1.8 * s)
	draw_line(c + Vector2(9.0, 4.0) * s, c + Vector2(12.0, 4.0) * s, gold, 1.8 * s)

func _draw_tool_reactor_cell(c: Vector2, s: float) -> void:
	var blue = Color(0.2, 0.75, 1.0)
	var core = Color(0.4, 1.0, 0.5)
	draw_rect(Rect2(c + Vector2(-8.0, -11.0) * s, Vector2(16.0, 22.0) * s), Color(0.2, 0.25, 0.35), true)
	draw_rect(Rect2(c + Vector2(-4.0, -7.0) * s, Vector2(8.0, 14.0) * s), core, true)
	draw_polyline(PackedVector2Array([
		c + Vector2(-8.0, -11.0) * s,
		c + Vector2(8.0, -11.0) * s,
		c + Vector2(8.0, 11.0) * s,
		c + Vector2(-8.0, 11.0) * s
	]), blue, 2.0 * s, true)

func _draw_badge(pos: Vector2, b_text: String) -> void:
	var font = ThemeDB.fallback_font
	var font_size = 11
	var str_size = font.get_string_size(b_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pad = Vector2(5, 2)
	var rect = Rect2(pos - str_size * 0.5 - pad, str_size + pad * 2)
	
	draw_rect(rect, Color(0.08, 0.08, 0.15, 0.95), true)
	draw_rect(rect, ring_color, false, 1.5)
	draw_string(font, pos - Vector2(str_size.x * 0.5, -str_size.y * 0.35), b_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _draw_caption(pos: Vector2, c_text: String) -> void:
	var clean_text = c_text.strip_edges()
	# Strip leading emojis if any for clean presentation
	if clean_text.length() > 2 and clean_text.unicode_at(0) > 1000:
		clean_text = clean_text.substr(2).strip_edges()
	if clean_text == "":
		return
		
	var font = ThemeDB.fallback_font
	var font_size = 11
	var str_size = font.get_string_size(clean_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pad = Vector2(8, 2)
	var rect = Rect2(pos - str_size * 0.5 - pad, str_size + pad * 2)
	
	draw_rect(rect, Color(0.06, 0.05, 0.12, 0.85), true)
	draw_rect(rect, Color(0.96, 0.66, 0.16, 0.6), false, 1.0)
	draw_string(font, pos - Vector2(str_size.x * 0.5, -str_size.y * 0.32), clean_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.95, 0.96, 1.0))
