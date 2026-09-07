extends Control

# Clean, Minimalist Tactical Visor HUD (Anti-AI-Slop, 100% Graphical)
const COLOR_CYAN = Color(0.15, 0.85, 1.0, 0.9)
const COLOR_CYAN_DIM = Color(0.15, 0.85, 1.0, 0.25)
const COLOR_AMBER = Color(1.0, 0.72, 0.15, 0.9)
const COLOR_GREEN = Color(0.2, 0.9, 0.4, 0.9)
const COLOR_RED = Color(1.0, 0.2, 0.2, 0.95)

var pulse_time: float = 0.0

func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	if w <= 10 or h <= 10:
		return
	
	var o2 = GameManager.player_stats.oxygen
	var fuel = GameManager.player_stats.fuel
	var hull = GameManager.player_stats.hull

	# 1. Subtle Curved Visor Vignette (Helmet interior glass curvature)
	_draw_helmet_vignette(w, h)
	
	# 2. Tactical Minimal Center Reticle
	_draw_center_reticle(w * 0.5, h * 0.5)

	# 3. Graphical Vitals: O2 Arc (Left), Thruster Arc (Right), Hull Shield (Bottom Center)
	_draw_radial_o2(w, h, o2)
	_draw_radial_rcs(w, h, fuel)
	_draw_hull_indicator(w, h, hull)

func _draw_helmet_vignette(w: float, h: float) -> void:
	# 4 subtle corner vignettes representing the helmet visor rim
	var rim_color = Color(0.02, 0.05, 0.09, 0.35)
	# Top-left corner arc
	draw_arc(Vector2(60, 60), 45, deg_to_rad(180), deg_to_rad(270), 16, COLOR_CYAN_DIM, 2.0, true)
	# Top-right corner arc
	draw_arc(Vector2(w - 60, 60), 45, deg_to_rad(270), deg_to_rad(360), 16, COLOR_CYAN_DIM, 2.0, true)
	# Bottom-left corner arc
	draw_arc(Vector2(60, h - 60), 45, deg_to_rad(90), deg_to_rad(180), 16, COLOR_CYAN_DIM, 2.0, true)
	# Bottom-right corner arc
	draw_arc(Vector2(w - 60, h - 60), 45, deg_to_rad(0), deg_to_rad(90), 16, COLOR_CYAN_DIM, 2.0, true)

func _draw_center_reticle(cx: float, cy: float) -> void:
	var center = Vector2(cx, cy)
	# Subtle central ring
	draw_arc(center, 14.0, 0, TAU, 32, COLOR_CYAN_DIM, 1.2, true)
	draw_circle(center, 2.0, COLOR_CYAN)
	# 4 small tick marks
	draw_line(center + Vector2(-22, 0), center + Vector2(-16, 0), COLOR_CYAN, 1.5)
	draw_line(center + Vector2(16, 0), center + Vector2(22, 0), COLOR_CYAN, 1.5)
	draw_line(center + Vector2(0, -22), center + Vector2(0, -16), COLOR_CYAN, 1.5)
	draw_line(center + Vector2(0, 16), center + Vector2(0, 22), COLOR_CYAN, 1.5)

func _draw_radial_o2(w: float, h: float, o2: float) -> void:
	var center = Vector2(90.0, h * 0.35)
	var radius = 42.0
	var track_start = deg_to_rad(100.0)
	var track_end = deg_to_rad(260.0)
	
	# Background track arc
	draw_arc(center, radius, track_start, track_end, 32, Color(0.1, 0.18, 0.28, 0.4), 5.0, true)
	
	# Fill ratio
	var fill_ratio = clamp(o2 / 100.0, 0.0, 1.0)
	var fill_end = lerp(track_start, track_end, fill_ratio)
	
	var col = COLOR_CYAN
	if o2 < 25.0:
		col = COLOR_RED if fmod(pulse_time * 6.0, 1.0) > 0.3 else Color(0.4, 0.1, 0.1)
	elif o2 < 50.0:
		col = COLOR_AMBER
		
	if fill_ratio > 0.02:
		draw_arc(center, radius, track_start, fill_end, 32, col, 5.0, true)
		var tip = center + Vector2(cos(fill_end), sin(fill_end)) * radius
		draw_circle(tip, 3.0, col)
	
	# Clean O2 symbol / text
	var font = ThemeDB.fallback_font
	draw_string(font, center + Vector2(-12, -2), "O₂", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, col)
	draw_string(font, center + Vector2(-18, 16), "%d%%" % int(o2), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)

func _draw_radial_rcs(w: float, h: float, fuel: float) -> void:
	var center = Vector2(w - 90.0, h * 0.35)
	var radius = 42.0
	var track_start = deg_to_rad(80.0)
	var track_end = deg_to_rad(-80.0)
	
	# Background track arc
	draw_arc(center, radius, track_end, track_start, 32, Color(0.25, 0.18, 0.1, 0.4), 5.0, true)
	
	# Fill ratio
	var fill_ratio = clamp(fuel / 100.0, 0.0, 1.0)
	var fill_end = lerp(track_end, track_start, fill_ratio)
	
	var col = COLOR_AMBER
	if fuel < 20.0:
		col = COLOR_RED
		
	if fill_ratio > 0.02:
		draw_arc(center, radius, track_end, fill_end, 32, col, 5.0, true)
		var tip = center + Vector2(cos(fill_end), sin(fill_end)) * radius
		draw_circle(tip, 3.0, col)
	
	# Clean RCS / Jetpack symbol
	var font = ThemeDB.fallback_font
	draw_string(font, center + Vector2(-14, -2), "RCS", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, col)
	draw_string(font, center + Vector2(-18, 16), "%d%%" % int(fuel), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)

func _draw_hull_indicator(w: float, h: float, hull: float) -> void:
	var center = Vector2(w * 0.5, h - 50.0)
	var bar_w = 140.0
	var bar_h = 6.0
	
	# Background
	draw_rect(Rect2(center.x - bar_w * 0.5, center.y, bar_w, bar_h), Color(0.1, 0.15, 0.2, 0.6))
	
	# Fill
	var fill_w = bar_w * clamp(hull / 100.0, 0.0, 1.0)
	var col = COLOR_GREEN
	if hull < 30.0:
		col = COLOR_RED if fmod(pulse_time * 5.0, 1.0) > 0.35 else Color(0.4, 0.1, 0.1)
	elif hull < 60.0:
		col = COLOR_AMBER
		
	draw_rect(Rect2(center.x - bar_w * 0.5, center.y, fill_w, bar_h), col)
	
	# Subtle shield icon / label
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(center.x - 22, center.y - 6), "SHIELD", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, col)
