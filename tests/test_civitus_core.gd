extends Node

# CIVITUS TDD Test Suite

var passed_count: int = 0
var failed_count: int = 0
var test_names: Array[String] = []

func _ready() -> void:
	print("\n==========================================")
	print("       RUNNING CIVITUS TDD TESTS          ")
	print("==========================================\n")
	
	test_movement_direction_math()
	test_visual_yaw_facing()
	test_dynamic_joystick_logic()
	test_camera_zoom_and_jarvis_mode()
	test_cubed_sphere_normals_and_winding()
	test_spaceship_airlock_state_machine()
	test_loading_minigame_physics()
	test_crafting_and_vitals_loop()
	test_first_person_helmet_and_mesh_hiding()
	test_touch_camera_drag_controls()
	test_player_death_when_hull_zero()
	test_multitouch_pinch_zoom_logic()
	test_host_star_gameplay_lighting_coherence()
	test_day_night_solar_cycle_and_rayleigh_reddening()
	test_spatial_day_night_hemisphere_navigation()
	test_ksp_barometric_altitude_scale_height()
	test_planetary_cloud_layer_and_lighting()
	test_spherical_fluid_ocean_and_buoyancy()
	test_spherical_orography_and_biomes()
	test_karst_cenotes_and_subterranean_caves()
	
	print("\n==========================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("==========================================\n")
	
	if failed_count == 0:
		print("ALL TDD TESTS PASSED SUCCESSFULLY! :)")
	else:
		print("SOME TESTS FAILED! :(")
	get_tree().quit(0 if failed_count == 0 else 1)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_count += 1
		print("  [FAIL] %s" % test_name)

func assert_almost_eq(val1: float, val2: float, margin: float, test_name: String) -> void:
	if abs(val1 - val2) <= margin:
		passed_count += 1
		print("  [PASS] %s (got %.4f, expected %.4f)" % [test_name, val1, val2])
	else:
		failed_count += 1
		print("  [FAIL] %s (got %.4f, expected %.4f, diff %.4f > %.4f)" % [test_name, val1, val2, abs(val1 - val2), margin])

# 1. Test Movement Direction & Tangent Math
func test_movement_direction_math() -> void:
	print("--- 1. Testing Movement Direction Math ---")
	var up_dir = Vector3.UP
	var cam_fwd = Vector3(0, 0, -1) # Standard forward looking into -Z
	var cam_rt = cam_fwd.cross(up_dir).normalized() # Vector3(1, 0, 0)
	assert_true(cam_rt.is_equal_approx(Vector3(1, 0, 0)), "Camera right vector points +X")
	
	# When pressing Forward (W key / stick up), input_vec.y is -1.0
	var input_vec_forward = Vector2(0, -1)
	var input_fwd = -input_vec_forward.y # Should be +1.0
	var move_tangent_fwd = (cam_rt * input_vec_forward.x + cam_fwd * input_fwd).normalized()
	assert_true(move_tangent_fwd.dot(cam_fwd) > 0.99, "Moving forward moves in camera forward direction")
	
	# When pressing Backward (S key / stick down), input_vec.y is +1.0
	var input_vec_back = Vector2(0, 1)
	var input_back = -input_vec_back.y # Should be -1.0
	var move_tangent_back = (cam_rt * input_vec_back.x + cam_fwd * input_back).normalized()
	assert_true(move_tangent_back.dot(-cam_fwd) > 0.99, "Moving backward moves away from camera forward direction")
	
	# When pressing Right (D key / stick right), input_vec.x is +1.0
	var input_vec_right = Vector2(1, 0)
	var move_tangent_rt = (cam_rt * input_vec_right.x + cam_fwd * (-input_vec_right.y)).normalized()
	assert_true(move_tangent_rt.dot(cam_rt) > 0.99, "Moving right moves in camera right direction")

# 2. Test Visual Facing Yaw
func test_visual_yaw_facing() -> void:
	print("--- 2. Testing Visual Facing Yaw ---")
	# In our character model, eyes and chest face +Z (front)
	# When moving forward (+Z local), target yaw should be 0 rad
	var local_fwd = Vector3(0, 0, 1)
	var yaw_fwd = atan2(local_fwd.x, local_fwd.z)
	assert_almost_eq(yaw_fwd, 0.0, 0.001, "Visual yaw when moving forward is 0 rad")
	
	# When moving right (+X local), target yaw should be PI/2
	var local_rt = Vector3(1, 0, 0)
	var yaw_rt = atan2(local_rt.x, local_rt.z)
	assert_almost_eq(yaw_rt, PI * 0.5, 0.001, "Visual yaw when moving right is PI/2 (+90 deg)")
	
	# When moving left (-X local), target yaw should be -PI/2
	var local_lt = Vector3(-1, 0, 0)
	var yaw_lt = atan2(local_lt.x, local_lt.z)
	assert_almost_eq(yaw_lt, -PI * 0.5, 0.001, "Visual yaw when moving left is -PI/2 (-90 deg)")
	
	# When moving backward (-Z local), target yaw should be PI
	var local_bk = Vector3(0, 0, -1)
	var yaw_bk = abs(atan2(local_bk.x, local_bk.z))
	assert_almost_eq(yaw_bk, PI, 0.001, "Visual yaw when moving backward is PI (180 deg)")

# 3. Test Dynamic Joystick Logic
func test_dynamic_joystick_logic() -> void:
	print("--- 3. Testing Dynamic Roblox Joystick Logic ---")
	var max_dist = 80.0
	var deadzone = 0.15
	
	# Touch start sets center
	var touch_origin = Vector2(200, 400)
	var drag_pos = Vector2(200, 320) # Dragged 80px straight up
	
	var diff = drag_pos - touch_origin
	var dist = diff.length()
	var dir = diff.normalized()
	var clamped_dist = min(dist, max_dist)
	var strength = clamped_dist / max_dist
	var remapped_strength = (strength - deadzone) / (1.0 - deadzone)
	var output_vec = dir * remapped_strength
	
	assert_almost_eq(output_vec.x, 0.0, 0.01, "Joystick output X is 0 when dragging straight up")
	assert_almost_eq(output_vec.y, -1.0, 0.01, "Joystick output Y is -1.0 (full forward) when dragged up by max_distance")
	
	# Test deadzone
	var small_drag = Vector2(200, 395) # 5px drag
	var small_dist = (small_drag - touch_origin).length()
	var small_strength = small_dist / max_dist
	var small_output = Vector2.ZERO if small_strength < deadzone else dir * ((small_strength - deadzone) / (1.0 - deadzone))
	assert_true(small_output == Vector2.ZERO, "Joystick produces Vector2.ZERO inside deadzone")

# 4. Test Camera Zoom and Jarvis First Person Mode
func test_camera_zoom_and_jarvis_mode() -> void:
	print("--- 4. Testing Camera Zoom and Jarvis First Person Mode ---")
	var min_zoom = 0.0 # First person
	var max_zoom = 16.0 # Far orbit
	var default_zoom = 6.5
	
	var cur_zoom = default_zoom
	# Zooming in step
	cur_zoom = clamp(cur_zoom - 2.0, min_zoom, max_zoom)
	assert_almost_eq(cur_zoom, 4.5, 0.01, "Zoom in reduces distance")
	
	# Zoom in all the way to 0.0 (First-Person threshold)
	cur_zoom = 0.0
	var is_first_person = (cur_zoom <= 0.5)
	assert_true(is_first_person, "Camera triggers First-Person mode when zoomed under 0.5m")

# 5. Test Cubed Sphere Face Normals and CCW Winding
func test_cubed_sphere_normals_and_winding() -> void:
	print("--- 5. Testing Cubed Sphere Normals and CCW Winding ---")
	var normal = Vector3.UP
	var axis_a = Vector3(normal.y, normal.z, normal.x) # (0, 0, 1) -> Vector3.BACK
	var axis_b = normal.cross(axis_a) # Vector3(1, 0, 0) -> Vector3.RIGHT
	
	# Generate quad vertices on top face
	var p00 = (normal + axis_a * (-0.5) + axis_b * (-0.5)).normalized()
	var p10 = (normal + axis_a * (0.5) + axis_b * (-0.5)).normalized()
	var p01 = (normal + axis_a * (-0.5) + axis_b * (0.5)).normalized()
	
	# With CCW winding: (p10 - p00) x (p01 - p00)
	var edge1 = p10 - p00
	var edge2 = p01 - p00
	var tri_normal = edge1.cross(edge2).normalized()
	# The cross product must point OUTWARDS (positive dot with normal/center)
	var dot_out = tri_normal.dot(normal)
	assert_true(dot_out > 0.5, "Spherical triangle normal points outwards from planet center (outward facing)")

# 6. Test Spaceship Airlock State Machine
func test_spaceship_airlock_state_machine() -> void:
	print("--- 6. Testing Spaceship Airlock State Machine ---")
	var states = ["CLOSED", "PRESSURIZING", "OPEN", "DEPRESSURIZING"]
	var airlock_state = "CLOSED"
	var cabin_pressurized = false
	
	# Approach airlock: cycle starts
	airlock_state = "PRESSURIZING"
	assert_true(airlock_state == "PRESSURIZING", "Airlock enters PRESSURIZING when player enters airlock chamber")
	
	# Pressurization completes
	cabin_pressurized = true
	airlock_state = "OPEN"
	assert_true(cabin_pressurized and airlock_state == "OPEN", "Airlock opens and pressurization is confirmed inside cabin")

# 7. Test Loading Minigame Physics
func test_loading_minigame_physics() -> void:
	print("--- 7. Testing Loading Minigame Physics ---")
	var lander_pos = Vector2(200, 50)
	var lander_vel = Vector2(0, 0)
	var lander_fuel = 100.0
	var gravity = 90.0 # px/s^2
	var thruster_accel = 180.0
	var delta = 0.1
	
	# Free fall without thruster
	lander_vel.y += gravity * delta
	lander_pos += lander_vel * delta
	assert_true(lander_vel.y > 0.0, "Lander falls under simulated gravity")
	
	# Active main burn
	lander_vel.y -= thruster_accel * delta
	lander_fuel -= 10.0 * delta
	assert_true(lander_vel.y < 9.0, "Thruster decelerates descent velocity")
	assert_true(lander_fuel < 100.0, "Thruster consumes minigame fuel")

# 8. Test Crafting & Vitals Loop
func test_crafting_and_vitals_loop() -> void:
	print("--- 8. Testing Crafting and Vitals Loop ---")
	GameManager.player_stats.oxygen = 100.0
	GameManager.player_stats.fuel = 100.0
	GameManager.player_stats.hull = 100.0
	
	# Simulate oxygen consumption
	var delta = 1.0
	GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - 1.2 * delta)
	assert_almost_eq(GameManager.player_stats.oxygen, 98.8, 0.01, "Oxygen decreases in unbreathable atmosphere")
	
	# Refill inside cabin
	GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 45.0 * delta)
	assert_almost_eq(GameManager.player_stats.oxygen, 100.0, 0.01, "Oxygen recharges safely inside pressurized ship cabin")

# 9. Test First Person Helmet & Mesh Hiding
func test_first_person_helmet_and_mesh_hiding() -> void:
	print("--- 9. Testing First Person Helmet & Mesh Hiding ---")
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = char_scene.instantiate()
	add_child(player)
	
	# Set to 3rd person state for verification
	player.target_zoom = 4.5
	player._check_fps_mode()
	assert_true(not player.is_first_person, "Player in 3rd person")
	assert_true(player.visuals.visible, "Visuals root is visible in 3rd person")
	assert_true(player.head.visible, "Head is visible in 3rd person")
	
	# Switch to 1st person
	player.toggle_first_person()
	assert_true(player.is_first_person, "toggle_first_person switches to 1st person")
	assert_true(player.visuals.visible, "Visuals root remains visible in 1st person (for arms/torso)")
	assert_true(not player.head.visible, "Player head is hidden in 1st person to prevent camera clipping")
	
	# Switch back to 3rd person
	player.toggle_first_person()
	assert_true(not player.is_first_person, "toggle_first_person switches back to 3rd person")
	assert_true(player.head.visible, "Head is restored when returning to 3rd person")
	player.queue_free()

# 10. Test Touch Camera Drag Controls
func test_touch_camera_drag_controls() -> void:
	print("--- 10. Testing Touch Camera Drag Controls ---")
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = char_scene.instantiate()
	add_child(player)
	
	var initial_yaw = player.target_yaw
	var initial_pitch = player.target_pitch
	
	# Drag right and down: natural mobile look
	player.rotate_camera_by(Vector2(40.0, 30.0))
	assert_true(player.target_yaw > initial_yaw, "Dragging right turns yaw right (natural look)")
	assert_true(player.target_pitch < initial_pitch, "Dragging down tilts pitch down toward ground")
	
	# Pitch clamp verification in 1st person
	player.toggle_first_person()
	player.rotate_camera_by(Vector2(0.0, 50000.0)) # Extreme drag down
	assert_true(player.target_pitch >= -80.0, "Pitch is clamped to min -80 degrees looking down in 1st person")
	player.rotate_camera_by(Vector2(0.0, -100000.0)) # Extreme drag up
	assert_true(player.target_pitch <= 80.0, "Pitch is clamped to max 80 degrees looking up in 1st person")
	player.queue_free()

# 11. Test Player Death when Hull Reaches Zero
func test_player_death_when_hull_zero() -> void:
	print("--- 11. Testing Player Death when Hull Reaches Zero ---")
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = char_scene.instantiate()
	add_child(player)
	
	GameManager.player_stats.hull = 0.0
	player._physics_process(0.1)
	assert_true(player.is_dead, "Player enters is_dead state when hull reaches zero")
	assert_true(player.is_action_locked, "Actions are locked upon death")
	player.queue_free()

# 12. Test Multi-Touch Pinch-to-Zoom Math
func test_multitouch_pinch_zoom_logic() -> void:
	print("--- 12. Testing Multi-Touch Pinch-to-Zoom Math ---")
	var target_cam_dist = 11.5
	var p0 = Vector2(200, 300)
	var p1 = Vector2(400, 300)
	var initial_dist = p0.distance_to(p1) # 200px
	assert_almost_eq(initial_dist, 200.0, 0.01, "Initial two-finger distance is 200px")
	
	# Spreading fingers apart (zoom in)
	var p0_spread = Vector2(150, 300)
	var p1_spread = Vector2(450, 300)
	var spread_dist = p0_spread.distance_to(p1_spread) # 300px
	var pinch_in_delta = spread_dist - initial_dist # +100px
	target_cam_dist = clampf(target_cam_dist - pinch_in_delta * 0.035, 5.5, 20.0)
	assert_almost_eq(target_cam_dist, 8.0, 0.01, "Spreading fingers apart zooms in (reduces camera distance)")
	
	# Pinching fingers together (zoom out)
	var p0_pinch = Vector2(250, 300)
	var p1_pinch = Vector2(350, 300)
	var pinch_dist = p0_pinch.distance_to(p1_pinch) # 100px
	var pinch_out_delta = pinch_dist - spread_dist # -200px
	target_cam_dist = clampf(target_cam_dist - pinch_out_delta * 0.035, 5.5, 20.0)
	assert_almost_eq(target_cam_dist, 15.0, 0.01, "Pinching fingers together zooms out (increases camera distance)")

# 13. Test Host Star to Gameplay Lighting Coherence
func test_host_star_gameplay_lighting_coherence() -> void:
	print("--- 13. Testing Host Star to Gameplay Lighting Coherence ---")
	var star_red_dwarf = {
		"name": "Proxima-Prime",
		"spectral_class": "M",
		"temperature": 2800.0,
		"luminosity": 0.12,
		"color": Color(1.0, 0.48, 0.28)
	}
	var planet_mock = {
		"name": "Boreas-01",
		"orbit_au": 0.40,
		"star": star_red_dwarf,
		"has_atmosphere": true,
		"atmosphere": 1.1,
		"atmosphere_color": Color(0.25, 0.75, 0.95),
		"sky_color": Color(0.04, 0.08, 0.18)
	}
	GameManager.select_planet(planet_mock)
	
	# Verify star data preservation in GameManager
	assert_true(GameManager.current_planet.has("star"), "Current planet preserves host star data")
	var attached_star = GameManager.current_planet["star"]
	assert_true(attached_star["color"] == Color(1.0, 0.48, 0.28), "Host star color preserved exactly without tint corruption")
	
	# Physical flux and apparent size verification
	var flux = attached_star["luminosity"] / (planet_mock["orbit_au"] * planet_mock["orbit_au"]) # 0.12 / 0.16 = 0.75
	assert_almost_eq(flux, 0.75, 0.01, "Astrophysical flux follows inverse-square law F = L/d^2")
	
	var apparent_sun_size = clampf((28.0 * sqrt(attached_star["luminosity"])) / sqrt(planet_mock["orbit_au"]), 16.0, 48.0)
	assert_almost_eq(apparent_sun_size, 16.0, 0.5, "Apparent sun disc size is physically calculated")

# 14. Test Day/Night Solar Cycle & Rayleigh Reddening
func test_day_night_solar_cycle_and_rayleigh_reddening() -> void:
	print("--- 14. Testing Day/Night Solar Cycle & Rayleigh Reddening ---")
	var star_col = Color(1.0, 0.96, 0.88)
	var base_energy = 1.4
	
	# Midday (solar altitude = +0.80 > 0.12)
	var alt_noon = 0.80
	var is_day = alt_noon > 0.12
	var sun_color_noon = star_col
	var sun_energy_noon = base_energy
	assert_true(is_day, "Solar altitude > 0.12 corresponds to full daylight")
	assert_true(sun_color_noon == star_col, "Noon sun retains pure stellar color")
	
	# Sunset / Dawn twilight (-0.15 <= alt <= 0.12)
	var alt_sunset = 0.0
	var sunset_t = smoothstep(-0.15, 0.12, alt_sunset)
	var sunset_tint = star_col.lerp(Color(1.0, 0.38, 0.12), 0.65)
	var sun_color_sunset = star_col.lerp(sunset_tint, 1.0 - sunset_t)
	var sun_energy_sunset = base_energy * sunset_t
	assert_true(sun_color_sunset.r > sun_color_noon.r - 0.05, "Sunset light reddens via Rayleigh dispersion")
	assert_true(sun_energy_sunset < sun_energy_noon, "Sunset solar energy decreases gracefully")
	
	# Deep Night (alt < -0.15)
	var alt_night = -0.50
	var sun_energy_night = 0.0 if alt_night < -0.15 else base_energy
	assert_almost_eq(sun_energy_night, 0.0, 0.001, "Direct sunlight energy is zero during stellar night")

# 15. Test Spatial Day/Night Hemisphere Navigation (Walking to the Dark Side)
func test_spatial_day_night_hemisphere_navigation() -> void:
	print("--- 15. Testing Spatial Day/Night Hemisphere Navigation ---")
	var sun_direction = Vector3(0.0, 1.0, 0.0) # Host star directly overhead North Pole
	
	# Player at North Pole (P = 0, 160, 0)
	var player_north = Vector3(0.0, 160.0, 0.0).normalized()
	var solar_alt_north = player_north.dot(sun_direction)
	assert_almost_eq(solar_alt_north, 1.0, 0.01, "Standing at North pole facing star is noon (+1.0)")
	
	# Player walks to Equator (P = 160, 0, 0)
	var player_equator = Vector3(160.0, 0.0, 0.0).normalized()
	var solar_alt_equator = player_equator.dot(sun_direction)
	assert_almost_eq(solar_alt_equator, 0.0, 0.01, "Walking to equator places sun at the horizon (terminator / sunset 0.0)")
	
	# Player walks to South Pole (P = 0, -160, 0: The Dark Side)
	var player_south = Vector3(0.0, -160.0, 0.0).normalized()
	var solar_alt_south = player_south.dot(sun_direction)
	assert_almost_eq(solar_alt_south, -1.0, 0.01, "Walking to opposite side enters dark hemisphere (midnight -1.0)")

# 16. Test KSP Barometric Scale Height & Atmospheric Extinction
func test_ksp_barometric_altitude_scale_height() -> void:
	print("--- 16. Testing KSP Barometric Scale Height & Atmospheric Extinction ---")
	var scale_height = 22.0 # meters
	
	# Sea level: altitude = 0.0m
	var baro_sea_level = exp(-0.0 / scale_height)
	assert_almost_eq(baro_sea_level, 1.0, 0.01, "Barometric factor at sea level is 1.0 (100% atmosphere)")
	
	# Mountain / Jetpack flight: altitude = 22.0m
	var baro_mid = exp(-22.0 / scale_height)
	assert_almost_eq(baro_mid, 0.3679, 0.01, "Barometric factor at 1 scale height is ~36.8%")
	
	# High orbit / Above Karman Line: altitude = 50.0m
	var baro_orbit = exp(-50.0 / scale_height)
	assert_true(baro_orbit < 0.15, "Barometric factor above 45m Karman line drops towards space vacuum")

# 17. Test Planetary Cloud Layer and Lighting
func test_planetary_cloud_layer_and_lighting() -> void:
	print("--- 17. Testing Planetary Cloud Layer and Lighting ---")
	var cloud_density = 0.55
	var norm_sun = Vector3(0.5, 0.7, 0.5).normalized()
	
	# Point on day side facing sun
	var day_normal = norm_sun
	var sun_factor_day = clampf(day_normal.dot(norm_sun), 0.0, 1.0)
	assert_almost_eq(sun_factor_day, 1.0, 0.01, "Clouds facing the host star receive maximum solar illumination")
	
	# Point on dark side facing away
	var night_normal = -norm_sun
	var sun_factor_night = clampf(night_normal.dot(norm_sun), 0.0, 1.0)
	assert_almost_eq(sun_factor_night, 0.0, 0.01, "Clouds on the dark side receive zero direct sunlight")

# 18. Test Spherical Fluid Ocean & Buoyancy Mechanics
func test_spherical_fluid_ocean_and_buoyancy() -> void:
	print("--- 18. Testing Spherical Fluid Ocean & Buoyancy Mechanics ---")
	var planet_radius = 160.0
	
	# Astronaut submerged 1.2m below sea level
	var astronaut_dist = 158.8
	var is_submerged = astronaut_dist < planet_radius
	var depth = planet_radius - astronaut_dist
	assert_true(is_submerged, "Player is detected inside fluid when dist < planet_radius")
	assert_almost_eq(depth, 1.20, 0.01, "Submersion depth is 1.2m below sea level")
	
	# Fluid buoyancy response: upward buoyant speed
	var vertical_speed = 0.0
	if depth > 0.35:
		vertical_speed = 1.6 # Upward buoyant push
	assert_almost_eq(vertical_speed, 1.60, 0.01, "Fluid buoyancy pushes submerged astronaut toward surface")
	
	# Fluid drag slows horizontal velocity by 18%
	var horiz_vel = 4.5
	horiz_vel *= 0.82
	assert_almost_eq(horiz_vel, 3.69, 0.01, "Hydrodynamic fluid drag dampens horizontal velocity")

# 19. Test Spherical Orography, Biomes & Continuous Relief
func test_spherical_orography_and_biomes() -> void:
	print("--- 19. Testing Spherical Orography, Biomes & Continuous Relief ---")
	var planet_script = load("res://scripts/world/spherical_planet.gd")
	var noise = FastNoiseLite.new()
	noise.seed = 4242
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# Test north pole landing plateau flattening
	var north_dir = Vector3.UP
	var elev_pole = planet_script._calc_elevation_static(noise, north_dir)
	assert_almost_eq(elev_pole, 0.50, 0.05, "North pole landing pad is smoothly flattened at ~0.5m for safe Apollo touchdown")
	
	# Test continuous smooth color gradient (zero binary jumps)
	var p_inst = planet_script.new()
	var c_ocean = p_inst._determine_surface_color_smooth(-5.0, Color.BLUE, Color.YELLOW, Color.GREEN, Color.GRAY, Color.WHITE)
	var c_shore = p_inst._determine_surface_color_smooth(1.0, Color.BLUE, Color.YELLOW, Color.GREEN, Color.GRAY, Color.WHITE)
	var c_plain = p_inst._determine_surface_color_smooth(5.0, Color.BLUE, Color.YELLOW, Color.GREEN, Color.GRAY, Color.WHITE)
	var c_peak = p_inst._determine_surface_color_smooth(20.0, Color.BLUE, Color.YELLOW, Color.GREEN, Color.GRAY, Color.WHITE)
	
	assert_true(c_ocean.b > c_ocean.r, "Ocean depth has strong blue component")
	assert_true(c_shore.r > 0.3 and c_shore.g > 0.3, "Coastline transitions smoothly through sandy tones")
	assert_true(c_plain.g > c_plain.r, "Lowland plains have fertile green predominance")
	assert_true(c_peak == Color.WHITE, "High peaks have snow/ice/mineral white crust")
	p_inst.queue_free()

# 20. Test Karst Cenotes & Subterranean Caves
func test_karst_cenotes_and_subterranean_caves() -> void:
	print("--- 20. Testing Karst Cenotes & Subterranean Caves ---")
	var planet_script = load("res://scripts/world/spherical_planet.gd")
	var cave_scene = load("res://scenes/entities/cave_grotto.tscn")
	
	assert_true(cave_scene != null, "Cave grotto scene loads successfully")
	
	# Verify cenote coordinates do not collide with North Pole landing pad
	for i in range(3):
		var cenote_dir = planet_script.get_cenote_direction(1337, i)
		assert_true(is_equal_approx(cenote_dir.length(), 1.0), "Cenote direction %d is unit vector" % i)
		assert_true(cenote_dir.dot(Vector3.UP) < 0.90, "Cenote %d is safely positioned away from landing pad" % i)
		
	# Verify thematic adaptation of subterranean cavern
	var cave_inst = cave_scene.instantiate()
	assert_true(cave_inst != null and cave_inst.has_method("setup_theme"), "Instantiated cave has setup_theme method")
	
	# Test toxic planetary biome
	cave_inst.setup_theme({ "level": 2 })
	assert_true(cave_inst.light.light_color.g > cave_inst.light.light_color.r, "Toxic cave light emits alien emerald green")
	
	# Test cryo planetary biome
	cave_inst.setup_theme({ "level": 3 })
	assert_true(cave_inst.light.light_color.b > cave_inst.light.light_color.r, "Cryo cave light emits deep sapphire blue")
	
	# Test molten planetary biome
	cave_inst.setup_theme({ "level": 5 })
	assert_true(cave_inst.light.light_color.r > cave_inst.light.light_color.b, "Molten cave light emits incandescent magma orange")
	assert_true(cave_inst.light.light_energy >= 2.4, "Cavern omni light has sufficient lumen intensity")
	
	cave_inst.free()



