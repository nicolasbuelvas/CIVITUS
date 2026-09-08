extends Control

# High-Grade Diegetic Astronaut Visor Overlay (Anti-AI-Slop, Clean & Minimal)
const COLOR_CYAN = Color(0.18, 0.85, 1.0, 0.9)
const COLOR_CYAN_SUBTLE = Color(0.18, 0.85, 1.0, 0.25)
const COLOR_AMBER = Color(1.0, 0.75, 0.15, 0.9)
const COLOR_RED = Color(1.0, 0.25, 0.25, 0.95)

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

	# 1. Subtle Visor Perimeter Vignette (Authentic helmet curvature without visual clutter)
	_draw_visor_vignette(w, h)
	
	# 2. Minimal High-Precision Tactical Reticle
	_draw_center_reticle(w * 0.5, h * 0.5)
	
	# 3. Critical Emergency Warnings (Only visible during life-support danger or pressure events)
	_draw_tactical_status(w, h, o2)

func _draw_visor_vignette(w: float, h: float) -> void:
	# Subtle edge shading and glass curvature accents at the top and bottom periphery
	var edge_tint = Color(0.04, 0.12, 0.20, 0.18)
	var corner_r = min(w, h) * 0.08
	
	# Top visor subtle rim line
	draw_line(Vector2(corner_r, 4.0), Vector2(w - corner_r, 4.0), edge_tint, 1.5)
	# Bottom visor subtle rim line
	draw_line(Vector2(corner_r, h - 4.0), Vector2(w - corner_r, h - 4.0), edge_tint, 1.5)

func _draw_center_reticle(cx: float, cy: float) -> void:
	var center = Vector2(cx, cy)
	var player = get_parent().get_parent().get_node_or_null("Character3D") if get_parent() and get_parent().get_parent() else null
	var is_targeting = false
	if player and "nearby_interactable" in player and player.nearby_interactable != null:
		is_targeting = true
		
	var reticle_col = COLOR_CYAN if not is_targeting else COLOR_AMBER
	var alpha_mult = 0.85 if is_targeting else 0.5
	reticle_col.a *= alpha_mult
	
	# Tiny center dot
	draw_circle(center, 1.8, reticle_col)
	
	# Precise 4-corner targeting brackets [ · ]
	var b_dist = 14.0 if not is_targeting else 18.0
	var b_len = 4.0
	var b_col = COLOR_CYAN_SUBTLE if not is_targeting else COLOR_AMBER
	
	# Top-left bracket
	draw_line(center + Vector2(-b_dist, -b_dist), center + Vector2(-b_dist + b_len, -b_dist), b_col, 1.2)
	draw_line(center + Vector2(-b_dist, -b_dist), center + Vector2(-b_dist, -b_dist + b_len), b_col, 1.2)
	# Top-right bracket
	draw_line(center + Vector2(b_dist, -b_dist), center + Vector2(b_dist - b_len, -b_dist), b_col, 1.2)
	draw_line(center + Vector2(b_dist, -b_dist), center + Vector2(b_dist, -b_dist + b_len), b_col, 1.2)
	# Bottom-left bracket
	draw_line(center + Vector2(-b_dist, b_dist), center + Vector2(-b_dist + b_len, b_dist), b_col, 1.2)
	draw_line(center + Vector2(-b_dist, b_dist), center + Vector2(-b_dist, b_dist - b_len), b_col, 1.2)
	# Bottom-right bracket
	draw_line(center + Vector2(b_dist, b_dist), center + Vector2(b_dist - b_len, b_dist), b_col, 1.2)
	draw_line(center + Vector2(b_dist, b_dist), center + Vector2(b_dist, b_dist - b_len), b_col, 1.2)

func _draw_tactical_status(w: float, h: float, o2: float) -> void:
	var font = ThemeDB.fallback_font
	
	if o2 <= 0.0:
		var red_flash = COLOR_RED if fmod(pulse_time * 4.0, 1.0) > 0.4 else Color(0.6, 0.1, 0.1, 0.8)
		draw_string(font, Vector2(w * 0.5 - 110.0, 52.0), "[ ! SUFFOCATION IMMINENT ! ]", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, red_flash)
	elif o2 < 20.0:
		var alert_col = COLOR_RED if fmod(pulse_time * 3.0, 1.0) > 0.35 else Color(0.6, 0.2, 0.1, 0.8)
		draw_string(font, Vector2(w * 0.5 - 115.0, 52.0), "[ LIFE SUPPORT O₂ CRITICAL ]", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, alert_col)
