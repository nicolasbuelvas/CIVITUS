extends Control
class_name HelmetVisor

var player: CharacterBody3D = null
var pulse_time: float = 0.0

# Scientific NASA / EVA aesthetics (Anti-AI-slop, clean technical palette)
const COLOR_CYAN = Color(0.2, 0.88, 1.0, 0.95)
const COLOR_CYAN_DIM = Color(0.2, 0.88, 1.0, 0.35)
const COLOR_CYAN_GLOW = Color(0.2, 0.88, 1.0, 0.12)
const COLOR_AMBER = Color(1.0, 0.78, 0.18, 0.95)
const COLOR_AMBER_DIM = Color(1.0, 0.78, 0.18, 0.35)
const COLOR_RED = Color(1.0, 0.28, 0.28, 0.95)
const COLOR_BG_PANEL = Color(0.02, 0.05, 0.1, 0.7)
const COLOR_VISOR_VIGNETTE = Color(0.01, 0.03, 0.06, 0.82)
const COLOR_TEXT_WHITE = Color(0.92, 0.96, 1.0, 1.0)
const COLOR_TEXT_MUTED = Color(0.55, 0.72, 0.85, 0.85)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not visible:
		return
	pulse_time += delta
	queue_redraw()

func _draw() -> void:
	var w = size.x if size.x > 0 else 1280.0
	var h = size.y if size.y > 0 else 720.0
	
	var stats = GameManager.player_stats
	var o2 = stats.get("oxygen", 100.0)
	var fuel = stats.get("fuel", 100.0)
	var hull = stats.get("hull", 100.0)
	
	var font = ThemeDB.fallback_font
	
	_draw_visor_frame(w, h, font)
	_draw_radial_o2(w, h, o2, font)
	_draw_suit_vitals_left(w, h, hull, font)
	_draw_radial_rcs(w, h, fuel, font)
	_draw_eva_telemetry_right(w, h, font)
	_draw_heading_tape(w, h, font)
	_draw_reticle_and_horizon(w, h, font)

func _draw_visor_frame(w: float, h: float, font: Font) -> void:
	# Curved helmet bubble visor corners (EVA vignette)
	var corner_w = 180.0
	var corner_h = 160.0
	
	# Top-Left curved bezel
	var tl_poly = PackedVector2Array([
		Vector2(0, 0), Vector2(corner_w, 0), Vector2(corner_w * 0.6, 25),
		Vector2(30, corner_h * 0.6), Vector2(0, corner_h)
	])
	draw_colored_polygon(tl_poly, COLOR_VISOR_VIGNETTE)
	
	# Top-Right curved bezel
	var tr_poly = PackedVector2Array([
		Vector2(w, 0), Vector2(w - corner_w, 0), Vector2(w - corner_w * 0.6, 25),
		Vector2(w - 30, corner_h * 0.6), Vector2(w, corner_h)
	])
	draw_colored_polygon(tr_poly, COLOR_VISOR_VIGNETTE)
	
	# Bottom-Left curved bezel
	var bl_poly = PackedVector2Array([
		Vector2(0, h), Vector2(corner_w, h), Vector2(corner_w * 0.6, h - 25),
		Vector2(30, h - corner_h * 0.6), Vector2(0, h - corner_h)
	])
	draw_colored_polygon(bl_poly, COLOR_VISOR_VIGNETTE)
	
	# Bottom-Right curved bezel
	var br_poly = PackedVector2Array([
		Vector2(w, h), Vector2(w - corner_w, h), Vector2(w - corner_w * 0.6, h - 25),
		Vector2(w - 30, h - corner_h * 0.6), Vector2(w, h - corner_h)
	])
	draw_colored_polygon(br_poly, COLOR_VISOR_VIGNETTE)
	
	# Glass curvature line (subtle upper reflection arc)
	draw_arc(Vector2(w * 0.5, -h * 0.4), w * 0.7, deg_to_rad(65.0), deg_to_rad(115.0), 32, Color(0.3, 0.9, 1.0, 0.08), 2.0, true)
	
	# Technical HUD corner brackets & readouts
	draw_line(Vector2(40, 24), Vector2(210, 24), COLOR_CYAN_DIM, 1.5, true)
	draw_line(Vector2(40, 24), Vector2(40, 70), COLOR_CYAN_DIM, 1.5, true)
	draw_string(font, Vector2(48, 42), "EVA SUIT MK-IV // LIFE SUPPORT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_CYAN)
	
	draw_line(Vector2(w - 210, 24), Vector2(w - 40, 24), COLOR_CYAN_DIM, 1.5, true)
	draw_line(Vector2(w - 40, 24), Vector2(w - 40, 70), COLOR_CYAN_DIM, 1.5, true)
	draw_string(font, Vector2(w - 180, 42), "RCS MATRIX // ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_AMBER)
	
	draw_line(Vector2(40, h - 35), Vector2(210, h - 35), COLOR_CYAN_DIM, 1.5, true)
	draw_line(Vector2(40, h - 75), Vector2(40, h - 35), COLOR_CYAN_DIM, 1.5, true)
	draw_string(font, Vector2(48, h - 45), "CABIN SEAL 100% // NOMINAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT_MUTED)
	
	draw_line(Vector2(w - 210, h - 35), Vector2(w - 40, h - 35), COLOR_CYAN_DIM, 1.5, true)
	draw_line(Vector2(w - 40, h - 75), Vector2(w - 40, h - 35), COLOR_CYAN_DIM, 1.5, true)
	draw_string(font, Vector2(w - 170, h - 45), "FEED // CH-01 SYNC", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT_MUTED)

func _draw_radial_o2(w: float, h: float, o2: float, font: Font) -> void:
	var center = Vector2(145.0, h * 0.27)
	var radius = 46.0
	var track_start = deg_to_rad(-215.0)
	var track_end = deg_to_rad(35.0)
	
	# Background track arc (250 degrees)
	draw_arc(center, radius, track_start, track_end, 40, Color(0.12, 0.22, 0.35, 0.5), 6.0, true)
	
	# Fill arc
	var fill_ratio = clamp(o2 / 100.0, 0.0, 1.0)
	var fill_end = lerp(track_start, track_end, fill_ratio)
	
	var col = COLOR_CYAN
	if o2 < 25.0:
		col = COLOR_RED if fmod(pulse_time * 5.0, 1.0) > 0.4 else Color(0.5, 0.1, 0.1)
	elif o2 < 50.0:
		col = COLOR_AMBER
		
	if fill_ratio > 0.01:
		draw_arc(center, radius, track_start, fill_end, 40, col, 6.0, true)
		var tip = center + Vector2(cos(fill_end), sin(fill_end)) * radius
		draw_circle(tip, 3.5, col)
	
	# Outer tick marks
	for i in range(9):
		var ang = lerp(track_start, track_end, i / 8.0)
		var p1 = center + Vector2(cos(ang), sin(ang)) * (radius + 5.0)
		var p2 = center + Vector2(cos(ang), sin(ang)) * (radius + 9.0)
		draw_line(p1, p2, COLOR_CYAN_DIM, 1.5, true)
	
	# Text inside arc
	draw_string(font, center + Vector2(-15, -4), "O2", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, col)
	draw_string(font, center + Vector2(-24, 16), "%d%%" % int(o2), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, COLOR_TEXT_WHITE)
	
	# Subtext below
	draw_string(font, Vector2(center.x - 55, center.y + 64), "FLOW: 1.2 L/MIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_TEXT_MUTED)
	draw_string(font, Vector2(center.x - 55, center.y + 78), "STATUS: REGULATED" if o2 > 25.0 else "WARNING: LOW O2", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)

func _draw_suit_vitals_left(w: float, h: float, hull: float, font: Font) -> void:
	var origin = Vector2(85.0, h * 0.44)
	var box_w = 125.0
	var box_h = 86.0
	
	draw_rect(Rect2(origin.x, origin.y, box_w, box_h), COLOR_BG_PANEL)
	draw_rect(Rect2(origin.x, origin.y, box_w, box_h), COLOR_CYAN_DIM, false, 1.0)
	
	# Header
	draw_string(font, origin + Vector2(8, 16), "TRAJE // HULL: %d%%" % int(hull), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_CYAN)
	
	# Segmented bar (8 segments)
	var seg_w = 11.5
	var seg_h = 6.0
	var seg_gap = 2.5
	var fill_segs = int(round((hull / 100.0) * 8.0))
	for s in range(8):
		var sx = origin.x + 8.0 + s * (seg_w + seg_gap)
		var sy = origin.y + 24.0
		var scol = Color(0.2, 0.9, 0.4, 0.9) if s < fill_segs else Color(0.2, 0.25, 0.3, 0.4)
		if hull < 35.0 and s < fill_segs:
			scol = COLOR_RED
		draw_rect(Rect2(sx, sy, seg_w, seg_h), scol)
	
	# Environment Telemetry
	var ext_temp = GameManager.current_planet.get("temperature", 20.0)
	draw_string(font, origin + Vector2(8, 46), "PRESS: 101.3 kPa", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT_MUTED)
	draw_string(font, origin + Vector2(8, 60), "SUIT TEMP: 21.4 C", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT_WHITE)
	draw_string(font, origin + Vector2(8, 74), "EXT TEMP: %.1f C" % ext_temp, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT_MUTED)

func _draw_radial_rcs(w: float, h: float, fuel: float, font: Font) -> void:
	var center = Vector2(w - 145.0, h * 0.27)
	var radius = 46.0
	var track_start = deg_to_rad(145.0)
	var track_end = deg_to_rad(395.0)
	
	# Background track arc
	draw_arc(center, radius, track_start, track_end, 40, Color(0.3, 0.22, 0.1, 0.5), 6.0, true)
	
	# Fill arc
	var fill_ratio = clamp(fuel / 100.0, 0.0, 1.0)
	var fill_end = lerp(track_start, track_end, fill_ratio)
	
	var col = COLOR_AMBER if fuel > 20.0 else COLOR_RED
	if fill_ratio > 0.01:
		draw_arc(center, radius, track_start, fill_end, 40, col, 6.0, true)
		var tip = center + Vector2(cos(fill_end), sin(fill_end)) * radius
		draw_circle(tip, 3.5, col)
	
	# Outer tick marks
	for i in range(9):
		var ang = lerp(track_start, track_end, i / 8.0)
		var p1 = center + Vector2(cos(ang), sin(ang)) * (radius + 5.0)
		var p2 = center + Vector2(cos(ang), sin(ang)) * (radius + 9.0)
		draw_line(p1, p2, COLOR_AMBER_DIM, 1.5, true)
	
	# Text inside arc
	draw_string(font, center + Vector2(-18, -4), "RCS", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, col)
	draw_string(font, center + Vector2(-24, 16), "%d%%" % int(fuel), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, COLOR_TEXT_WHITE)
	
	# Subtext below
	var is_thrusting = Input.is_action_pressed("jump_thrust") and fuel > 0.0
	draw_string(font, Vector2(center.x - 55, center.y + 64), "PROP: N2 COLD GAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_TEXT_MUTED)
	draw_string(font, Vector2(center.x - 55, center.y + 78), "THRUST: FIRING" if is_thrusting else "THRUST: READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_CYAN if is_thrusting else col)

func _draw_eva_telemetry_right(w: float, h: float, font: Font) -> void:
	var origin = Vector2(w - 210.0, h * 0.44)
	var box_w = 125.0
	var box_h = 86.0
	
	draw_rect(Rect2(origin.x, origin.y, box_w, box_h), COLOR_BG_PANEL)
	draw_rect(Rect2(origin.x, origin.y, box_w, box_h), COLOR_AMBER_DIM, false, 1.0)
	
	var g = GameManager.current_planet.get("gravity", 9.8) / 9.8
	var spd = 0.0
	if player:
		spd = player.velocity.length()
	
	draw_string(font, origin + Vector2(8, 16), "TELEMETRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_AMBER)
	draw_string(font, origin + Vector2(8, 34), "GRAV: %.2f G" % g, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT_WHITE)
	draw_string(font, origin + Vector2(8, 48), "VEL: %.1f M/S" % spd, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT_WHITE)
	draw_string(font, origin + Vector2(8, 62), "MODE: EVA VACUUM", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_CYAN)
	draw_string(font, origin + Vector2(8, 76), "RAD: 0.02 mSv/h", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT_MUTED)

func _draw_heading_tape(w: float, h: float, font: Font) -> void:
	var tape_w = 280.0
	var tape_h = 28.0
	var cx = w * 0.5
	var cy = 42.0
	var left_x = cx - tape_w * 0.5
	var right_x = cx + tape_w * 0.5
	
	# Planet name header
	var p_name = GameManager.current_planet.get("name", "Civitus-Alpha")
	draw_string(font, Vector2(cx - 80, cy - 20), str(p_name).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 160, 11, COLOR_TEXT_WHITE)

	# Tape frame
	draw_rect(Rect2(left_x, cy - tape_h * 0.5, tape_w, tape_h), Color(0.02, 0.05, 0.1, 0.6))
	draw_line(Vector2(left_x, cy - tape_h * 0.5), Vector2(right_x, cy - tape_h * 0.5), COLOR_CYAN_DIM, 1.5, true)
	draw_line(Vector2(left_x, cy + tape_h * 0.5), Vector2(right_x, cy + tape_h * 0.5), COLOR_CYAN_DIM, 1.5, true)
	
	# Center pointer caret
	var caret = PackedVector2Array([
		Vector2(cx - 5, cy - tape_h * 0.5),
		Vector2(cx + 5, cy - tape_h * 0.5),
		Vector2(cx, cy - tape_h * 0.5 + 7)
	])
	draw_colored_polygon(caret, COLOR_AMBER)
	
	# Calculate heading based on player yaw
	var yaw_deg = 0.0
	if player:
		yaw_deg = fmod(rad_to_deg(player.cam_yaw) + 3600.0, 360.0)
	
	var pixels_per_deg = 2.4
	var min_deg = floor((yaw_deg - 50.0) / 10.0) * 10.0
	var max_deg = ceil((yaw_deg + 50.0) / 10.0) * 10.0
	
	var d = min_deg
	while d <= max_deg:
		var normalized_d = int(fmod(d + 3600.0, 360.0))
		var offset_x = (d - yaw_deg) * pixels_per_deg
		var tick_x = cx + offset_x
		
		if tick_x >= left_x + 6 and tick_x <= right_x - 6:
			var is_cardinal = (normalized_d % 90 == 0)
			var is_major = (normalized_d % 30 == 0)
			
			var tick_len = 9.0 if (is_cardinal or is_major) else 5.0
			var tcol = COLOR_CYAN if is_cardinal else COLOR_CYAN_DIM
			draw_line(Vector2(tick_x, cy - tape_h * 0.5), Vector2(tick_x, cy - tape_h * 0.5 + tick_len), tcol, 1.5, true)
			
			if is_cardinal:
				var card_str = "N"
				match normalized_d:
					90: card_str = "E"
					180: card_str = "S"
					270: card_str = "W"
				draw_string(font, Vector2(tick_x - 4, cy + 9), card_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, COLOR_AMBER)
			elif is_major:
				draw_string(font, Vector2(tick_x - 9, cy + 9), "%03d" % normalized_d, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, COLOR_TEXT_MUTED)
		d += 10.0
		
	# Digital Heading & Orbital Altitude
	draw_string(font, Vector2(cx - 32, cy + 26), "HDG %03d" % int(yaw_deg), HORIZONTAL_ALIGNMENT_CENTER, -1, 11, COLOR_CYAN)
	
	var alt = 0.0
	if player:
		alt = max(0.0, player.global_position.length() - player.planet_radius)
	draw_string(font, Vector2(cx - 38, cy + 39), "ALT: %d M" % int(alt), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, COLOR_TEXT_MUTED)

func _draw_reticle_and_horizon(w: float, h: float, font: Font) -> void:
	var center = Vector2(w * 0.5, h * 0.5)
	
	# NASA Reticle
	draw_circle(center, 2.0, COLOR_CYAN)
	draw_arc(center, 18.0, 0, TAU, 32, COLOR_CYAN_DIM, 1.5, true)
	
	# Reticle crosshair ticks
	draw_line(center + Vector2(-28, 0), center + Vector2(-19, 0), COLOR_CYAN, 1.5, true)
	draw_line(center + Vector2(19, 0), center + Vector2(28, 0), COLOR_CYAN, 1.5, true)
	draw_line(center + Vector2(0, -28), center + Vector2(0, -19), COLOR_CYAN, 1.5, true)
	draw_line(center + Vector2(0, 19), center + Vector2(0, 28), COLOR_CYAN, 1.5, true)
	
	# Artificial Horizon ladder bars (shifts with camera pitch)
	var pitch_offset = 0.0
	if player:
		pitch_offset = player.cam_pitch * 1.5
	
	var horiz_y = center.y + pitch_offset
	if horiz_y > h * 0.2 and horiz_y < h * 0.8:
		draw_line(Vector2(center.x - 55, horiz_y), Vector2(center.x - 32, horiz_y), COLOR_CYAN_DIM, 1.5, true)
		draw_line(Vector2(center.x + 32, horiz_y), Vector2(center.x + 55, horiz_y), COLOR_CYAN_DIM, 1.5, true)
		draw_line(Vector2(center.x - 55, horiz_y), Vector2(center.x - 55, horiz_y + 4), COLOR_CYAN_DIM, 1.5, true)
		draw_line(Vector2(center.x + 55, horiz_y), Vector2(center.x + 55, horiz_y + 4), COLOR_CYAN_DIM, 1.5, true)

	# Target Lock on interactable
	if player and player.nearby_interactable:
		var target_col = COLOR_AMBER if fmod(pulse_time * 4.0, 1.0) > 0.3 else COLOR_TEXT_WHITE
		var b_size = 32.0
		var b_len = 10.0
		# Brackets [ ]
		draw_line(center + Vector2(-b_size, -b_size), center + Vector2(-b_size + b_len, -b_size), target_col, 2.0, true)
		draw_line(center + Vector2(-b_size, -b_size), center + Vector2(-b_size, -b_size + b_len), target_col, 2.0, true)
		draw_line(center + Vector2(b_size, -b_size), center + Vector2(b_size - b_len, -b_size), target_col, 2.0, true)
		draw_line(center + Vector2(b_size, -b_size), center + Vector2(b_size, -b_size + b_len), target_col, 2.0, true)
		draw_line(center + Vector2(-b_size, b_size), center + Vector2(-b_size + b_len, b_size), target_col, 2.0, true)
		draw_line(center + Vector2(-b_size, b_size), center + Vector2(-b_size, b_size - b_len), target_col, 2.0, true)
		draw_line(center + Vector2(b_size, b_size), center + Vector2(b_size - b_len, b_size), target_col, 2.0, true)
		draw_line(center + Vector2(b_size, b_size), center + Vector2(b_size, b_size - b_len), target_col, 2.0, true)
		
		var t_type = player.current_interactable_type.to_upper()
		draw_string(font, center + Vector2(-60, b_size + 18), "OBJETO: " + t_type, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, target_col)
		draw_string(font, center + Vector2(-60, b_size + 30), "EN RANGO OPERATIVO", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, COLOR_TEXT_MUTED)
