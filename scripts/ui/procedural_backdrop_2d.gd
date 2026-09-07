extends Control
class_name ProceduralBackdrop2D

var sky_top_color: Color = Color(0.02, 0.04, 0.08)
var sky_horizon_color: Color = Color(0.10, 0.22, 0.40)
var mountain_back_color: Color = Color(0.08, 0.16, 0.28)
var mountain_mid_color: Color = Color(0.05, 0.12, 0.20)
var terrain_front_color: Color = Color(0.03, 0.08, 0.14)

var planet_name: String = "Terranova"
var has_moon: bool = true
var moon_color: Color = Color(0.9, 0.9, 0.95, 0.75)
var moon_pos: Vector2 = Vector2(850, 140)
var moon_radius: float = 40.0

var stars: Array = []
var back_mountains: PackedVector2Array = []
var mid_mountains: PackedVector2Array = []
var front_hills: PackedVector2Array = []

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var pulse_timer: float = 0.0

func _ready() -> void:
	_init_stars()
	generate_landscape(randi() % 100000)

func _process(delta: float) -> void:
	pulse_timer += delta * 3.0
	queue_redraw()

func _init_stars() -> void:
	stars.clear()
	var s_rng = RandomNumberGenerator.new()
	s_rng.seed = 9999
	for i in range(120):
		stars.append({
			"pos": Vector2(s_rng.randf_range(0, 1280), s_rng.randf_range(0, 480)),
			"radius": s_rng.randf_range(0.8, 2.2),
			"alpha": s_rng.randf_range(0.3, 0.95),
			"speed": s_rng.randf_range(1.0, 4.0)
		})

func set_planet_theme_from_data(p: Dictionary) -> void:
	planet_name = p.get("name", "Sector")
	var surf_col: Color = p.get("surface_color", Color(0.3, 0.6, 0.4))
	var sky_col: Color = p.get("sky_color", Color(0.1, 0.2, 0.4))
	var atmo_col: Color = p.get("atmosphere_color", Color(0.3, 0.7, 1.0))
	
	sky_top_color = sky_col.darkened(0.7)
	sky_horizon_color = atmo_col.darkened(0.35)
	
	mountain_back_color = surf_col.darkened(0.55).lerp(sky_horizon_color, 0.45)
	mountain_mid_color = surf_col.darkened(0.70)
	terrain_front_color = surf_col.darkened(0.85)
	
	has_moon = (p.get("level", 0) != 1) # Mars has smaller moons
	moon_color = atmo_col.lightened(0.5)
	moon_color.a = 0.85
	
	var seed_val = p.get("seed", randi() % 100000) + randi() % 500
	generate_landscape(seed_val)

func generate_landscape(seed_val: int) -> void:
	rng.seed = seed_val
	moon_pos = Vector2(rng.randf_range(200, 1080), rng.randf_range(90, 200))
	moon_radius = rng.randf_range(28.0, 52.0)
	
	var w = 1280.0
	var h = 720.0
	var ground_base = h - 90.0
	
	# 1. Back mountain ridge
	back_mountains.clear()
	back_mountains.append(Vector2(0, h))
	var steps_back = 24
	for i in range(steps_back + 1):
		var x = (float(i) / float(steps_back)) * w
		var ny = sin(i * 0.75 + rng.randf() * 0.3) * 70.0 + cos(i * 1.5) * 45.0
		var y = ground_base - 180.0 + ny
		back_mountains.append(Vector2(x, y))
	back_mountains.append(Vector2(w, h))
	
	# 2. Mid mountain crags
	mid_mountains.clear()
	mid_mountains.append(Vector2(0, h))
	var steps_mid = 32
	for i in range(steps_mid + 1):
		var x = (float(i) / float(steps_mid)) * w
		var ny = sin(i * 1.1 + seed_val * 0.01) * 55.0 + sin(i * 2.8) * 28.0
		var y = ground_base - 110.0 + ny
		mid_mountains.append(Vector2(x, y))
	mid_mountains.append(Vector2(w, h))
	
	# 3. Front terrain hills & landing plain
	front_hills.clear()
	front_hills.append(Vector2(0, h))
	var steps_front = 40
	for i in range(steps_front + 1):
		var x = (float(i) / float(steps_front)) * w
		var ny = sin(i * 0.6) * 20.0 + cos(i * 1.8) * 12.0
		# Flatten slightly around center landing area
		if x > 400.0 and x < 880.0:
			ny *= 0.25
		var y = ground_base - 30.0 + ny
		front_hills.append(Vector2(x, y))
	front_hills.append(Vector2(w, h))
	
	queue_redraw()

func _draw() -> void:
	var w = size.x if size.x > 0 else 1280.0
	var h = size.y if size.y > 0 else 720.0
	
	# 1. Sky Gradient (Vertical color interpolation)
	var sky_poly = PackedVector2Array([
		Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)
	])
	var sky_colors = PackedColorArray([
		sky_top_color, sky_top_color, sky_horizon_color, sky_horizon_color
	])
	draw_polygon(sky_poly, sky_colors)
	
	# 2. Stars
	for star in stars:
		var twinkle = 0.5 + 0.5 * sin(pulse_timer * star["speed"] + star["pos"].x)
		var c = Color(1.0, 1.0, 1.0, star["alpha"] * twinkle)
		draw_circle(star["pos"], star["radius"], c)
		
	# 3. Moon / Sibling Planet
	if has_moon:
		# Atmosphere glow
		draw_circle(moon_pos, moon_radius * 1.25, Color(moon_color.r, moon_color.g, moon_color.b, 0.12))
		# Moon body
		draw_circle(moon_pos, moon_radius, moon_color)
		# Crater details
		var c1 = moon_pos + Vector2(-moon_radius * 0.25, -moon_radius * 0.2)
		var c2 = moon_pos + Vector2(moon_radius * 0.35, moon_radius * 0.25)
		draw_circle(c1, moon_radius * 0.22, moon_color.darkened(0.25))
		draw_circle(c2, moon_radius * 0.16, moon_color.darkened(0.28))
		
	# 4. Back Mountain Ridge
	if back_mountains.size() >= 3:
		draw_colored_polygon(back_mountains, mountain_back_color)
		
	# 5. Mid Mountain Crags
	if mid_mountains.size() >= 3:
		draw_colored_polygon(mid_mountains, mountain_mid_color)
		
	# 6. Foreground Terrain Hills
	if front_hills.size() >= 3:
		draw_colored_polygon(front_hills, terrain_front_color)
		
	# 7. Runway Landing Light Beacons
	var pad_center_x = w * 0.5
	var beacon_y = h - 110.0
	var beacon_glow = (sin(pulse_timer * 4.0) + 1.0) * 0.5
	var beacon_color = Color(0.2, 0.9, 0.5, 0.4 + beacon_glow * 0.6)
	
	draw_circle(Vector2(pad_center_x - 110.0, beacon_y), 5.0, beacon_color)
	draw_circle(Vector2(pad_center_x + 110.0, beacon_y), 5.0, beacon_color)
	draw_circle(Vector2(pad_center_x - 110.0, beacon_y), 12.0, Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.2 * beacon_glow))
	draw_circle(Vector2(pad_center_x + 110.0, beacon_y), 12.0, Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.2 * beacon_glow))
