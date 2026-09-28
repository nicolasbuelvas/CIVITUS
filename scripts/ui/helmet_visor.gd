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
