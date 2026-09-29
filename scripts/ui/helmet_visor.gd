extends Control
class_name HelmetVisor

# High-Grade Diegetic Astronaut Visor Overlay (Anti-AI-Slop, Clean & Minimal Aerospace Telemetry)
const COLOR_CYAN = Color(0.18, 0.85, 1.0, 0.9)
const COLOR_CYAN_SUBTLE = Color(0.18, 0.85, 1.0, 0.35)
const COLOR_AMBER = Color(0.96, 0.66, 0.16, 0.95)
const COLOR_AMBER_SUBTLE = Color(0.96, 0.66, 0.16, 0.35)
const COLOR_RED = Color(1.0, 0.25, 0.25, 0.95)
const COLOR_SHELL = Color(0.05, 0.07, 0.11, 0.94)

var pulse_time: float = 0.0
var visor_droplets: Array = []
var max_droplets: int = 18

func _process(delta: float) -> void:
	if visible:
		pulse_time += delta
		_update_visor_droplets(delta)
		queue_redraw()

func _update_visor_droplets(delta: float) -> void:
	var weather = GameManager.current_weather
	var is_precipitating = weather in ["rain", "acid_rain", "blizzard"]
	
	# Clean up finished droplets
	var i = visor_droplets.size() - 1
	while i >= 0:
		var d = visor_droplets[i]
		d["pos"].y += d["speed"] * delta
		d["speed"] += 45.0 * delta # gravity acceleration on glass
		d["life"] -= delta
		if d["pos"].y > size.y - 45.0 or d["life"] <= 0.0:
			visor_droplets.remove_at(i)
		i -= 1
		
	# Spawn new droplets if raining
	if is_precipitating and visor_droplets.size() < max_droplets and randf() < 0.35:
		var new_d = {
			"pos": Vector2(randf_range(size.x * 0.15, size.x * 0.85), randf_range(40.0, 120.0)),
			"speed": randf_range(30.0, 75.0),
			"radius": randf_range(1.5, 3.2),
			"trail_len": randf_range(4.0, 14.0),
			"alpha": randf_range(0.35, 0.75),
			"life": randf_range(2.5, 5.0)
		}
		visor_droplets.append(new_d)

func _draw() -> void:
	var w = size.x
	var h = size.y
	if w <= 10 or h <= 10:
		return
	
	var player = _get_player()
	var o2 = GameManager.player_stats.oxygen
	
	# Only render helmet curvature if astronaut is wearing space helmet
	var has_helmet = true
	if player and "is_in_space_suit" in player:
		has_helmet = player.is_in_space_suit

	if has_helmet:
		# 1. Authentic Curved Helmet Visor Frame & Polycarbonate Bezel
		_draw_helmet_visor_frame(w, h)
		# Dynamic atmospheric precipitation running down the glass
		_draw_visor_weather_effects(w, h)
	
	# 2. Minimal High-Precision Tactical Reticle
	_draw_center_reticle(w * 0.5, h * 0.5, player)
	
	# 3. Critical Emergency Warnings (Suffocation / Depressurization)
	_draw_tactical_status(w, h, o2)
	
	# 4. Apollo NASA 2D Oxygen Safe Area Map with Compass
	_draw_apollo_eva_minimap(w, h, player, o2)

	# 5. Underwater Submersion Optical Tint & Fluid Distortion
	if player and ("is_in_liquid" in player) and player.is_in_liquid:
		_draw_underwater_visor_effect(w, h)

func _draw_visor_weather_effects(w: float, h: float) -> void:
	if visor_droplets.is_empty():
		return
	var weather = GameManager.current_weather
	var drop_color = Color(0.82, 0.92, 1.0)
	if weather == "acid_rain":
		drop_color = Color(0.72, 0.94, 0.28)
	elif weather == "blizzard":
		drop_color = Color(0.92, 0.96, 1.0)
		
	for d in visor_droplets:
		var col = Color(drop_color.r, drop_color.g, drop_color.b, d["alpha"])
		# Sliding streak
		draw_line(Vector2(d["pos"].x, d["pos"].y - d["trail_len"]), d["pos"], Color(col.r, col.g, col.b, col.a * 0.45), 1.2)
		# Droplet bead
		draw_circle(d["pos"], d["radius"], col)

func _draw_underwater_visor_effect(w: float, h: float) -> void:
	var cur_p = GameManager.current_planet if is_instance_valid(GameManager) else {}
	var water_st = str(cur_p.get("water_status", ""))
	var base_tint = Color(0.04, 0.24, 0.40, 0.32) # Submerged oceanic azure
	if water_st.contains("Lava"):
		base_tint = Color(0.50, 0.15, 0.02, 0.36)
	elif water_st.contains("Ácido"):
		base_tint = Color(0.08, 0.42, 0.14, 0.32)
	elif water_st.contains("Hielo"):
		base_tint = Color(0.12, 0.35, 0.52, 0.30)
		
	# Full-screen underwater optical absorption wash
	draw_rect(Rect2(0, 0, w, h), base_tint)
	
	# Caustic light ripples along visor surface
	var caustic_col = Color(base_tint.r + 0.25, base_tint.g + 0.35, base_tint.b + 0.45, 0.15)
	for i in range(4):
		var y_base = (float(i) * 0.24 + 0.14) * h
		var pts = PackedVector2Array()
		for step in range(12):
			var px = float(step) / 11.0 * w
			var py = y_base + sin(px * 0.015 + pulse_time * 2.2 + float(i)) * 14.0
			pts.append(Vector2(px, py))
		draw_polyline(pts, caustic_col, 2.5)

func _get_player() -> Node3D:
	var hud = get_parent()
	if hud and "player" in hud and hud.player != null:
		return hud.player
	return get_tree().get_first_node_in_group("player") as Node3D

func _draw_helmet_visor_frame(w: float, h: float) -> void:
	var samples = 32
	var half_w = w * 0.5
	var half_h = h * 0.5
	
	var top_inner_pts = PackedVector2Array()
	var bot_inner_pts = PackedVector2Array()
	var left_inner_pts = PackedVector2Array()
	var right_inner_pts = PackedVector2Array()
	
	# Compute parabolic curvature of helmet visor
	for i in range(samples + 1):
		var t = float(i) / float(samples)
		var x = t * w
		var norm_x = (x - half_w) / half_w
		var curve_y = 22.0 + (norm_x * norm_x) * 26.0
		top_inner_pts.append(Vector2(x, curve_y))
		
		var bot_curve_y = h - (26.0 + (norm_x * norm_x) * 28.0)
		bot_inner_pts.append(Vector2(x, bot_curve_y))

	# 1. Top Brow Bezel
	var top_poly = PackedVector2Array([Vector2(0, 0), Vector2(w, 0)])
	for i in range(samples, -1, -1):
		top_poly.append(top_inner_pts[i])
	draw_colored_polygon(top_poly, COLOR_SHELL)
	
	# 2. Bottom Chin / Collar Bezel
	var bot_poly = PackedVector2Array([Vector2(w, h), Vector2(0, h)])
	for i in range(samples + 1):
		bot_poly.append(bot_inner_pts[i])
	draw_colored_polygon(bot_poly, COLOR_SHELL)
	
	# 3. Lateral Peripheral Pillars
	for i in range(samples + 1):
		var t = float(i) / float(samples)
		var y = t * h
		var norm_y = (y - half_h) / half_h
		var curve_x = 22.0 + (norm_y * norm_y) * 28.0
		left_inner_pts.append(Vector2(curve_x, y))
		right_inner_pts.append(Vector2(w - curve_x, y))
		
	var left_poly = PackedVector2Array([Vector2(0, 0)])
	for pt in left_inner_pts:
		left_poly.append(pt)
	left_poly.append(Vector2(0, h))
	draw_colored_polygon(left_poly, COLOR_SHELL)
	
	var right_poly = PackedVector2Array([Vector2(w, 0)])
	for pt in right_inner_pts:
		right_poly.append(pt)
	right_poly.append(Vector2(w, h))
	draw_colored_polygon(right_poly, COLOR_SHELL)
	
	# 4. Inner Golden/Cyan Vacuum Seal Bevel Line
	var seal_color = Color(0.96, 0.66, 0.16, 0.45)
	draw_polyline(top_inner_pts, seal_color, 2.0)
	draw_polyline(bot_inner_pts, seal_color, 2.0)
	draw_polyline(left_inner_pts, seal_color, 1.8)
	draw_polyline(right_inner_pts, seal_color, 1.8)
	
	# 5. Aerospace Corner Brackets & Rivets
	var corners = [
		Vector2(55.0, 48.0),
		Vector2(w - 55.0, 48.0),
		Vector2(55.0, h - 52.0),
		Vector2(w - 55.0, h - 52.0)
	]
	for cpt in corners:
		draw_circle(cpt, 2.2, Color(0.35, 0.42, 0.52, 0.8))
		draw_circle(cpt, 1.0, Color(0.1, 0.12, 0.18, 0.9))
		
	# 6. Subtle Upper-Right Curved Glass Glare / Specular Arc
	var glare_pts = PackedVector2Array([
		Vector2(w - 180.0, 36.0),
		Vector2(w - 80.0, 50.0),
		Vector2(w - 45.0, 110.0)
	])
	draw_polyline(glare_pts, Color(1.0, 1.0, 1.0, 0.08), 3.5)

func _draw_tactical_telemetry(w: float, h: float, player: Node3D) -> void:
	var font = ThemeDB.fallback_font
	var p_data = GameManager.current_planet
	var stats = GameManager.player_stats
	var font_size = 11
	var cyan = COLOR_CYAN_SUBTLE
	var amber = COLOR_AMBER
	
	# 1. LEFT DIAGNOSTIC CLUSTER (Below top bar & vitals pod, clear of joystick)
	var yaw_deg = 0
	var pitch_deg = 0
	var lamp_on = false
	if player:
		if "cam_yaw" in player:
			yaw_deg = int(rad_to_deg(player.cam_yaw)) % 360
			if yaw_deg < 0: yaw_deg += 360
		if "cam_pitch" in player:
			pitch_deg = int(rad_to_deg(player.cam_pitch))
		if "is_headlamp_on" in player:
			lamp_on = player.is_headlamp_on
			
	var compass_dir = _get_cardinal(yaw_deg)
	var nav_str = "AZM: %03d° [%s]  |  ELEV: %+03d°" % [yaw_deg, compass_dir, pitch_deg]
	draw_string(font, Vector2(48.0, 110.0), nav_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, cyan)
	
	var lamp_str = "HEADLAMP: " + ("ACTIVO" if lamp_on else "STANDBY")
	var lamp_col = amber if lamp_on else Color(0.45, 0.52, 0.62, 0.7)
	draw_string(font, Vector2(48.0, 127.0), lamp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, lamp_col)
	
	var temp = int(p_data.get("temperature", 18.0))
	var press = float(p_data.get("pressure", 1.0))
	var has_o2 = bool(p_data.get("has_oxygen", false))
	var atm_name = "RESPIRABLE" if has_o2 else "TÓXICA / INERTE"
	if press <= 0.01:
		atm_name = "VACÍO"
		
	var env_str = "TEMP: %+d°C  |  PRES: %.2f ATM" % [temp, press]
	draw_string(font, Vector2(48.0, 144.0), env_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, cyan)
	
	var atm_str = "ATMÓSFERA: " + atm_name
	var atm_col = COLOR_CYAN if has_o2 else (amber if press > 0.01 else Color(0.7, 0.3, 0.3, 0.8))
	draw_string(font, Vector2(48.0, 161.0), atm_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, atm_col)
	
	# 2. RIGHT DIAGNOSTIC CLUSTER (Below top buttons, clear of action cluster)
	var o2_val = int(stats.oxygen)
	var fuel_val = int(stats.fuel)
	var suit_str = "TRAJE EVA-1 NOMINAL  |  O₂: %d%%" % [o2_val]
	var suit_size = font.get_string_size(suit_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
	draw_string(font, Vector2(w - 48.0 - suit_size.x, 110.0), suit_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size, cyan)
	
	var grav_val = float(p_data.get("gravity", 9.8)) / 9.8
	var rad_val = float(p_data.get("radiation", 0.02))
	var p_type = str(p_data.get("type", "Planeta"))
	var rad_str = "GRAV: %.2fG  |  RAD: %.2f mSv/h" % [grav_val, rad_val]
	var rad_size = font.get_string_size(rad_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10)
	draw_string(font, Vector2(w - 48.0 - rad_size.x, 127.0), rad_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, cyan)
	
	var world_str = "ENTORNO: %s" % p_type.to_upper()
	var world_size = font.get_string_size(world_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10)
	draw_string(font, Vector2(w - 48.0 - world_size.x, 144.0), world_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, cyan)

func _get_cardinal(deg: int) -> String:
	if deg >= 338 or deg < 23: return "N"
	elif deg < 68: return "NE"
	elif deg < 113: return "E"
	elif deg < 158: return "SE"
	elif deg < 203: return "S"
	elif deg < 248: return "SW"
	elif deg < 293: return "W"
	return "NW"

func _draw_center_reticle(cx: float, cy: float, player: Node3D) -> void:
	var center = Vector2(cx, cy)
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
	draw_line(center + Vector2(-b_dist, b_dist), center + Vector2(-b_dist, -b_dist + b_len), b_col, 1.2)
	# Bottom-right bracket
	draw_line(center + Vector2(b_dist, b_dist), center + Vector2(b_dist - b_len, b_dist), b_col, 1.2)
	draw_line(center + Vector2(b_dist, b_dist), center + Vector2(b_dist, b_dist - b_len), b_col, 1.2)

	# Visor Scanner HUD overlay when reticle targets resource or creature
	if is_targeting and player and "nearby_interactable" in player and player.nearby_interactable != null:
		var target = player.nearby_interactable
		var scan_str = ""
		if target.has_method("get_scanner_data"):
			var data = target.get_scanner_data()
			scan_str = "%s  •  %s  •  %s" % [data.get("name", "RECURSO"), data.get("purity", ""), data.get("density", "")]
		elif target.is_in_group("creatures"):
			var comp = "MAGMA" if target.get("elemental_type") == 2 else ("RADIACTIVO" if target.get("elemental_type") == 3 else "CARBONO")
			var arch = "AGRESIVO" if target.get("is_aggressive") else "PACÍFICO"
			scan_str = "BIOFORMA  •  BASE %s  •  %s" % [comp, arch]
		if scan_str != "":
			var font = ThemeDB.fallback_font
			var str_size = font.get_string_size(scan_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 9)
			draw_string(font, Vector2(center.x - str_size.x * 0.5, center.y + 32.0), scan_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, COLOR_CYAN)

func _draw_tactical_status(w: float, h: float, o2: float) -> void:
	var font = ThemeDB.fallback_font
	var ship = get_tree().get_first_node_in_group("spaceship")
	
	if ship and ship.get("is_equalizing_pressure"):
		var amber_pulse = COLOR_AMBER if fmod(pulse_time * 4.0, 1.0) > 0.3 else Color(0.5, 0.35, 0.05, 0.8)
		draw_string(font, Vector2(w * 0.5 - 130.0, 52.0), "[ EQUALIZANDO PRESIÓN ATMOSFÉRICA... ]", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, amber_pulse)
	elif o2 <= 0.0:
		var red_flash = COLOR_RED if fmod(pulse_time * 4.0, 1.0) > 0.4 else Color(0.6, 0.1, 0.1, 0.8)
		draw_string(font, Vector2(w * 0.5 - 110.0, 52.0), "[ PELIGRO: ASFIXIA INMINENTE ]", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, red_flash)
	elif o2 < 20.0:
		var alert_col = COLOR_RED if fmod(pulse_time * 3.0, 1.0) > 0.35 else Color(0.6, 0.2, 0.1, 0.8)
		draw_string(font, Vector2(w * 0.5 - 115.0, 52.0), "[ SOPORTE VITAL O₂ CRÍTICO ]", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, alert_col)

var is_radar_expanded: bool = false
var current_map_center: Vector2 = Vector2.ZERO
var current_map_radius: float = 46.0

func _gui_input(event: InputEvent) -> void:
	if not is_radar_expanded:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var close_pos = current_map_center + Vector2(current_map_radius * 0.72, -current_map_radius * 0.72)
		if event.position.distance_to(close_pos) <= 24.0:
			toggle_radar()
			accept_event()
			return
		var dist = event.position.distance_to(current_map_center)
		if dist > current_map_radius + 15.0:
			toggle_radar()
			accept_event()

func toggle_radar() -> void:
	is_radar_expanded = !is_radar_expanded
	queue_redraw()

func _draw_apollo_eva_minimap(w: float, h: float, player: Node3D, o2: float) -> void:
	# Diegetic radar is hidden by default; strictly toggled on-demand via radar button
	if not is_radar_expanded:
		current_map_radius = 0.0
		return
		
	var ship = get_tree().get_first_node_in_group("spaceship")
	if not ship:
		return
		
	var cur_p = GameManager.current_planet if is_instance_valid(GameManager) else {}
	var atmo_stat = str(cur_p.get("atmosphere_status", ""))
	var has_free_o2 = atmo_stat.contains("Respirable") or atmo_stat.contains("Oxígeno")
	var rad_val = float(cur_p.get("radiation", 0.02))
	var temp = int(cur_p.get("temperature", 18.0))
	var press = float(cur_p.get("pressure", 1.0))
	var p_type = str(cur_p.get("type", ""))
	var is_molten = cur_p.get("is_molten", false) or p_type.contains("Volcán") or p_type.contains("Magma")
	var is_cryo = p_type.contains("Criogénico") or p_type.contains("Hielo")
	var is_toxic = p_type.contains("Tóxico") or p_type.contains("Ácido") or atmo_stat.contains("Ácido") or atmo_stat.contains("Tóxico")
	
	# Large Expanded Radar positioned at top center
	var map_radius = minf(w * 0.40, minf(h * 0.38, 160.0))
	var map_center = Vector2(w * 0.5, map_radius + 36.0)
		
	current_map_center = map_center
	current_map_radius = map_radius
	
	# 1. Dark Aerospace Radar Plate
	draw_circle(map_center, map_radius, Color(0.02, 0.05, 0.09, 0.92 if is_radar_expanded else 0.85))
	
	# 2. Outer Compass Ring & Ticks (Strictly ICONIC, NO TEXT)
	var compass_col = COLOR_CYAN_SUBTLE
	draw_arc(map_center, map_radius, 0.0, TAU, 48 if is_radar_expanded else 36, compass_col, 2.0 if is_radar_expanded else 1.5)
	draw_arc(map_center, map_radius * 0.5, 0.0, TAU, 32, Color(compass_col.r, compass_col.g, compass_col.b, 0.2), 1.0)
	draw_arc(map_center, map_radius * 0.75, 0.0, TAU, 32, Color(compass_col.r, compass_col.g, compass_col.b, 0.12), 1.0)
	
	# Crosshairs
	draw_line(Vector2(map_center.x - map_radius, map_center.y), Vector2(map_center.x + map_radius, map_center.y), Color(compass_col.r, compass_col.g, compass_col.b, 0.18), 1.0)
	draw_line(Vector2(map_center.x, map_center.y - map_radius), Vector2(map_center.x, map_center.y + map_radius), Color(compass_col.r, compass_col.g, compass_col.b, 0.18), 1.0)
	
	# Directional Triangles for Cardinals (NO TEXT, PURE DIEGETIC ICONS)
	var card_angles = [-PI * 0.5, 0.0, PI * 0.5, PI]
	for idx in range(4):
		var ang = card_angles[idx]
		var c_pos = map_center + Vector2(cos(ang), sin(ang)) * (map_radius - (6.0 if not is_radar_expanded else 10.0))
		var fwd = Vector2(cos(ang), sin(ang))
		var side = Vector2(-fwd.y, fwd.x)
		var t_size = 4.0 if not is_radar_expanded else 7.0
		var tri = PackedVector2Array([
			c_pos + fwd * t_size,
			c_pos - fwd * (t_size * 0.5) + side * (t_size * 0.6),
			c_pos - fwd * (t_size * 0.5) - side * (t_size * 0.6)
		])
		var c_col = COLOR_AMBER if idx == 0 else Color(0.6, 0.75, 0.85, 0.65)
		draw_colored_polygon(tri, c_col)
		
	# 3. Center Anchor: The Spaceship (Apollo Beacon Blip with radiating pulse)
	var ship_pos_2d = map_center
	var s_size = 5.0 if not is_radar_expanded else 8.5
	
	# Radiating Apollo beacon pulse rings
	for r_i in range(3):
		var p_r = fmod(pulse_time * 26.0 + float(r_i) * 16.0, map_radius * 0.75)
		var p_alpha = (1.0 - p_r / (map_radius * 0.75)) * 0.45
		draw_arc(ship_pos_2d, p_r, 0.0, TAU, 28, Color(COLOR_AMBER.r, COLOR_AMBER.g, COLOR_AMBER.b, p_alpha), 1.2)
		
	var ship_diamond = PackedVector2Array([
		ship_pos_2d + Vector2(0, -s_size),
		ship_pos_2d + Vector2(s_size, 0),
		ship_pos_2d + Vector2(0, s_size),
		ship_pos_2d + Vector2(-s_size, 0)
	])
	draw_colored_polygon(ship_diamond, COLOR_AMBER)
	draw_circle(ship_pos_2d, 1.8 if not is_radar_expanded else 3.0, Color.WHITE)
	
	# 4. Safe Radius Walkback Limit (ONLY on airless / hazardous planets!)
	var max_safe_m: float = 65.0
	var current_safe_m: float = max_safe_m * clampf(o2 / 100.0, 0.0, 1.0)
	var px_per_m: float = (map_radius * 0.82) / max_safe_m
	var safe_r_px: float = maxf(4.0, current_safe_m * px_per_m)
	
	var is_outside_safe_zone = false
	if not has_free_o2:
		var is_o2_low = o2 < 30.0
		var safe_border_col = Color(0.2, 0.95, 0.65, 0.8) if not is_o2_low else (COLOR_RED if fmod(pulse_time * 3.0, 1.0) > 0.35 else Color(0.8, 0.2, 0.1, 0.85))
		var safe_fill_col = Color(0.1, 0.85, 0.45, 0.08) if not is_o2_low else Color(0.8, 0.2, 0.1, 0.06)
		
		# Draw safe disc & boundary
		draw_circle(ship_pos_2d, safe_r_px, safe_fill_col)
		draw_arc(ship_pos_2d, safe_r_px, 0.0, TAU, 36, safe_border_col, 1.6)
	
	# 5. Points of Interest: Cave Entrances (Cavern portal archway icons)
	for cave in get_tree().get_nodes_in_group("caves"):
		if is_instance_valid(cave):
			var rel = cave.global_position - ship.global_position
			var cx = rel.dot(ship.global_transform.basis.x)
			var cy = rel.dot(-ship.global_transform.basis.z)
			var c_off = Vector2(cx, -cy) * px_per_m
			if c_off.length() <= map_radius - 4.0:
				var c_pos = ship_pos_2d + c_off
				var cave_col = Color(0.2, 0.85, 1.0) # Default cyan
				if is_molten: cave_col = Color(1.0, 0.4, 0.1)
				elif is_toxic: cave_col = Color(0.2, 1.0, 0.4)
				elif is_cryo: cave_col = Color(0.3, 0.7, 1.0)
				
				# Cavern archway portal glyph
				var arch_w = 4.0 if not is_radar_expanded else 7.0
				var arch_h = 4.5 if not is_radar_expanded else 8.0
				draw_arc(c_pos - Vector2(0, arch_h * 0.3), arch_w * 0.5, PI, TAU, 16, cave_col, 1.8)
				draw_line(c_pos - Vector2(arch_w * 0.5, arch_h * 0.3), c_pos - Vector2(arch_w * 0.5, -arch_h * 0.5), cave_col, 1.8)
				draw_line(c_pos + Vector2(arch_w * 0.5, arch_h * 0.3), c_pos + Vector2(arch_w * 0.5, -arch_h * 0.5), cave_col, 1.8)
				draw_line(c_pos - Vector2(arch_w * 0.8, -arch_h * 0.5), c_pos + Vector2(arch_w * 0.8, -arch_h * 0.5), cave_col, 1.5)
				draw_circle(c_pos + Vector2(0, -arch_h * 0.1), 1.5, Color.WHITE)

	# 6. Mineral Radar Blips (Iron, Copper, Silicon, Uranium)
	for ore in get_tree().get_nodes_in_group("resource_nodes"):
		if is_instance_valid(ore):
			var rel = ore.global_position - ship.global_position
			var ox = rel.dot(ship.global_transform.basis.x)
			var oy = rel.dot(-ship.global_transform.basis.z)
			var o_off = Vector2(ox, -oy) * px_per_m
			if o_off.length() <= map_radius - 4.0:
				var ore_pos = ship_pos_2d + o_off
				var o_type = ore.get("ore_type")
				var blip_sz = 3.0 if not is_radar_expanded else 5.5
				match o_type:
					0: # Iron: Silver-white metallic diamond
						var dia = PackedVector2Array([
							ore_pos + Vector2(0, -blip_sz),
							ore_pos + Vector2(blip_sz, 0),
							ore_pos + Vector2(0, blip_sz),
							ore_pos + Vector2(-blip_sz, 0)
						])
						draw_colored_polygon(dia, Color(0.9, 0.92, 0.98))
						draw_circle(ore_pos, 1.2, Color.WHITE)
					1: # Copper: Warm bronze/orange circle
						draw_circle(ore_pos, blip_sz, Color(1.0, 0.55, 0.2))
						draw_arc(ore_pos, blip_sz * 1.3, 0, TAU, 12, Color(1.0, 0.8, 0.4, 0.6), 1.0)
					2: # Silicon: Electric cyan crystalline diamond
						var si_dia = PackedVector2Array([
							ore_pos + Vector2(0, -blip_sz * 1.2),
							ore_pos + Vector2(blip_sz * 0.8, 0),
							ore_pos + Vector2(0, blip_sz * 1.2),
							ore_pos + Vector2(-blip_sz * 0.8, 0)
						])
						draw_colored_polygon(si_dia, Color(0.2, 0.9, 1.0))
					3: # Uranium: Pulsing lime-green radioactive diamond
						var u_pulse = 1.0 + sin(pulse_time * 6.0) * 0.25
						draw_circle(ore_pos, blip_sz * u_pulse, Color(0.3, 1.0, 0.4))
						draw_circle(ore_pos, blip_sz * 0.4, Color.WHITE)
					_:
						draw_circle(ore_pos, blip_sz, Color(0.85, 0.85, 0.9))
				
	# 7. Abandoned Shipwrecks
	for wreck in get_tree().get_nodes_in_group("abandoned_ships"):
		if is_instance_valid(wreck):
			var rel = wreck.global_position - ship.global_position
			var wx = rel.dot(ship.global_transform.basis.x)
			var wy = rel.dot(-ship.global_transform.basis.z)
			var w_off = Vector2(wx, -wy) * px_per_m
			if w_off.length() <= map_radius - 4.0:
				var w_col = Color(1.0, 0.8, 0.2) if not wreck.get("is_looted") else Color(0.4, 0.7, 0.4, 0.6)
				var w_sz = 4.0 if not is_radar_expanded else 7.0
				draw_rect(Rect2(ship_pos_2d + w_off - Vector2(w_sz * 0.5, w_sz * 0.5), Vector2(w_sz, w_sz)), w_col)

	# 8. Astronaut Position & Heading Trajectory
	if player:
		var ship_trans = ship.global_transform
		var rel_3d = player.global_position - ship.global_position
		var dx = rel_3d.dot(ship_trans.basis.x)
		var dy = rel_3d.dot(-ship_trans.basis.z)
		var p_dist_m = sqrt(dx * dx + dy * dy)
		
		if not has_free_o2:
			is_outside_safe_zone = (p_dist_m > current_safe_m)
		
		var raw_offset = Vector2(dx, -dy) * px_per_m
		var p_offset = raw_offset
		if p_offset.length() > map_radius - 6.0:
			p_offset = p_offset.normalized() * (map_radius - 6.0)
		var p_pos_2d = ship_pos_2d + p_offset
		
		# Lifeline connecting astronaut to ship
		var line_col = Color(0.2, 0.85, 1.0, 0.45) if not is_outside_safe_zone else Color(1.0, 0.25, 0.2, 0.8)
		draw_line(ship_pos_2d, p_pos_2d, line_col, 1.4)
		
		# Astronaut blip & direction cone
		var p_col = COLOR_CYAN if not is_outside_safe_zone else (COLOR_RED if fmod(pulse_time * 4.0, 1.0) > 0.4 else Color.WHITE)
		var blip_r = 3.5 if not is_radar_expanded else 6.0
		draw_circle(p_pos_2d, blip_r, p_col)
		draw_circle(p_pos_2d, blip_r * 0.4, Color.WHITE)
		
		if "cam_yaw" in player:
			var heading_ang = player.cam_yaw - PI * 0.5
			var head_vec = Vector2(cos(heading_ang), sin(heading_ang)) * (blip_r + 5.0)
			draw_line(p_pos_2d, p_pos_2d + head_vec, p_col, 1.6)

	# 9. Contextual Aerospace Icon Ribbon (PURE ICONOGRAPHY, ZERO TEXT)
	var icon_y = map_center.y + map_radius + (12.0 if not is_radar_expanded else 22.0)
	var icon_spacing = 22.0 if not is_radar_expanded else 32.0
	var icons_to_draw: Array = []
	
	# Atmosphere / Oxygen contextual warning icon (Strictly omitted on breathable worlds with oxygen)
	if not has_free_o2:
		icons_to_draw.append({"type": "o2_cylinder", "col": COLOR_RED if is_outside_safe_zone else COLOR_AMBER})
		
	# Radiation warning icon
	if rad_val > 0.02:
		icons_to_draw.append({"type": "radiation", "col": Color(1.0, 0.85, 0.2) if rad_val < 0.1 else COLOR_RED})
		
	# Thermal / Extreme Heat
	if temp > 50 or is_molten:
		icons_to_draw.append({"type": "heat", "col": Color(1.0, 0.35, 0.1)})
	# Cryo / Extreme Cold
	elif temp < -20 or is_cryo:
		icons_to_draw.append({"type": "cold", "col": Color(0.2, 0.85, 1.0)})
		
	# Toxic / Sulfuric
	if is_toxic:
		icons_to_draw.append({"type": "toxic", "col": Color(0.2, 1.0, 0.35)})
		
	# Vacuum / High pressure
	if press <= 0.02:
		icons_to_draw.append({"type": "vacuum", "col": Color(0.9, 0.6, 0.3)})
	elif press > 3.0:
		icons_to_draw.append({"type": "hyperbaric", "col": Color(0.95, 0.3, 0.3)})
		
	# Safe Haven Ping
	if is_outside_safe_zone:
		icons_to_draw.append({"type": "alert_triangle", "col": COLOR_RED if fmod(pulse_time * 4.0, 1.0) > 0.35 else Color(1.0, 0.8, 0.2)})
	else:
		icons_to_draw.append({"type": "beacon_ping", "col": COLOR_CYAN})
		
	var start_x = map_center.x - float(icons_to_draw.size() - 1) * 0.5 * icon_spacing
	for i in range(icons_to_draw.size()):
		var ic = icons_to_draw[i]
		var ix = start_x + float(i) * icon_spacing
		_draw_context_telemetry_icon(Vector2(ix, icon_y), ic["type"], ic["col"], 1.0 if not is_radar_expanded else 1.4)

	# Close Button [ ✕ ] in top-right of expanded radar
	if is_radar_expanded:
		var close_pos = map_center + Vector2(map_radius * 0.72, -map_radius * 0.72)
		draw_circle(close_pos, 15.0, Color(0.12, 0.08, 0.16, 0.95))
		draw_arc(close_pos, 15.0, 0.0, TAU, 24, Color(0.95, 0.35, 0.35, 0.9), 1.8)
		draw_line(close_pos + Vector2(-5.5, -5.5), close_pos + Vector2(5.5, 5.5), Color(1.0, 0.45, 0.45), 2.2)
		draw_line(close_pos + Vector2(-5.5, 5.5), close_pos + Vector2(5.5, -5.5), Color(1.0, 0.45, 0.45), 2.2)

func _draw_context_telemetry_icon(pos: Vector2, icon_type: String, col: Color, s: float) -> void:
	match icon_type:
		"breathable_atmo":
			# Crisp atmospheric dome with serene breeze waves
			draw_arc(pos, 7.0 * s, PI * 0.8, PI * 2.2, 16, col, 1.4 * s)
			draw_line(pos + Vector2(-5.0, 0.0) * s, pos + Vector2(5.0, 0.0) * s, col, 1.2 * s)
			draw_line(pos + Vector2(-3.0, 2.5) * s, pos + Vector2(3.0, 2.5) * s, col, 1.0 * s)
		"o2_cylinder":
			# Oxygen bottle glyph with top valve
			var w_box = 4.0 * s
			var h_box = 9.0 * s
			draw_rect(Rect2(pos - Vector2(w_box * 0.5, h_box * 0.5), Vector2(w_box, h_box)), col, false, 1.4 * s)
			draw_line(pos - Vector2(w_box * 0.3, h_box * 0.5 + 2.0 * s), pos + Vector2(w_box * 0.3, -h_box * 0.5 - 2.0 * s), col, 1.5 * s)
		"radiation":
			# Clean trefoil ion radiation symbol
			draw_circle(pos, 1.8 * s, col)
			for b in range(3):
				var ang = float(b) * (TAU / 3.0) - PI * 0.5
				var pt1 = pos + Vector2(cos(ang - 0.35), sin(ang - 0.35)) * 6.5 * s
				var pt2 = pos + Vector2(cos(ang + 0.35), sin(ang + 0.35)) * 6.5 * s
				var blade = PackedVector2Array([pos, pt1, pt2])
				draw_colored_polygon(blade, col)
		"heat":
			# High-temp flame chevrons
			var flame = PackedVector2Array([
				pos + Vector2(0.0, -8.0 * s),
				pos + Vector2(4.5 * s, 0.0),
				pos + Vector2(2.0 * s, 6.0 * s),
				pos + Vector2(-2.0 * s, 6.0 * s),
				pos + Vector2(-4.5 * s, 0.0)
			])
			draw_colored_polygon(flame, col)
			draw_circle(pos + Vector2(0.0, 1.5 * s), 1.8 * s, Color.WHITE)
		"cold":
			# 6-pointed ice snowflake crystal
			for arm in range(3):
				var ang = float(arm) * (PI / 3.0)
				var v = Vector2(cos(ang), sin(ang)) * 6.5 * s
				draw_line(pos - v, pos + v, col, 1.4 * s)
				var b1 = Vector2(cos(ang + 0.5), sin(ang + 0.5)) * 2.5 * s
				draw_line(pos + v * 0.6, pos + v * 0.6 + b1, col, 1.2 * s)
				draw_line(pos - v * 0.6, pos - v * 0.6 - b1, col, 1.2 * s)
		"toxic":
			# Sulfuric toxic droplet with vapor lines
			var drop = PackedVector2Array([
				pos + Vector2(0.0, -7.0 * s),
				pos + Vector2(4.5 * s, 2.0 * s),
				pos + Vector2(0.0, 6.5 * s),
				pos + Vector2(-4.5 * s, 2.0 * s)
			])
			draw_colored_polygon(drop, col)
			draw_circle(pos + Vector2(0.0, 1.5 * s), 1.5 * s, Color.BLACK)
		"vacuum":
			# Expanding 4-way depressurization arrows
			draw_arc(pos, 4.0 * s, 0, TAU, 16, col, 1.2 * s)
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(pos + d * 4.0 * s, pos + d * 8.0 * s, col, 1.4 * s)
		"hyperbaric":
			# Compressing 4-way hyperbaric arrows
			draw_circle(pos, 3.0 * s, col)
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(pos + d * 8.0 * s, pos + d * 4.5 * s, col, 1.5 * s)
		"alert_triangle":
			# Hazard warning triangle
			var tri_pts = PackedVector2Array([
				pos + Vector2(0, -6.5 * s),
				pos + Vector2(7.5 * s, 6.5 * s),
				pos + Vector2(-7.5 * s, 6.5 * s)
			])
			draw_colored_polygon(tri_pts, col)
			draw_line(pos + Vector2(0, -2.0 * s), pos + Vector2(0, 2.0 * s), Color.BLACK, 1.5 * s)
			draw_circle(pos + Vector2(0, 4.0 * s), 0.8 * s, Color.BLACK)
		"beacon_ping":
			# Serene radio ping waves
			draw_arc(pos, 4.0 * s, -PI * 0.75, -PI * 0.25, 8, COLOR_CYAN_SUBTLE, 1.5 * s)
			draw_arc(pos, 8.0 * s, -PI * 0.75, -PI * 0.25, 8, COLOR_CYAN_SUBTLE, 1.5 * s)
			draw_circle(pos, 1.8 * s, col)
		_:
			draw_circle(pos, 2.0 * s, col)
