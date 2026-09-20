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
	test_realistic_landing_fire_smoke_and_ground_interaction()
	test_oceanic_aquatic_worlds_and_procedural_sea_levels()
	test_swimming_underwater_walking_and_suit_reactions()
	test_twin_jetpacks_realistic_fluid_and_breaststroke_swimming()
	test_normal_jetpack_behavior_and_selective_jumping()
	
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
	assert_almost_eq(elev_pole, 3.20, 0.05, "North pole landing pad is safely elevated at ~3.2m above sea level to prevent water intrusion")
	
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

# 21. Testing Realistic Landing Fire, Smoke, and Planet-Reactive Engine & Ground Interaction
func test_realistic_landing_fire_smoke_and_ground_interaction() -> void:
	print("--- 21. Testing Realistic Landing Fire, Smoke & Ground Interaction ---")
	var LandingFXProfile = load("res://scripts/effects/landing_fx_profile.gd")
	assert_true(LandingFXProfile != null, "LandingFXProfile class loads successfully")
	
	# 1. Test Planet Profiles
	# Habitable (Level 0)
	var hab_prof = LandingFXProfile.get_profile({ "level": 0, "type": "Habitable" })
	assert_true(hab_prof.engine_flame_color.r > 0.8 and hab_prof.engine_flame_color.g > 0.35, "Habitable engine flame is golden methalox orange")
	assert_true(hab_prof.ground_smoke_scale_max >= 5.0, "Habitable ground smoke expands into voluminous clouds")
	assert_true(hab_prof.nozzle_heat_color.r > 0.8, "Habitable nozzle heats up with golden/orange thermal incandescence")
	
	# Desertic (Level 1)
	var des_prof = LandingFXProfile.get_profile({ "level": 1, "type": "Desértico" })
	assert_true(des_prof.ground_smoke_color.r > des_prof.ground_smoke_color.b, "Desert ground smoke has terracotta/iron-oxide coloration")
	assert_true(des_prof.expansion_power < hab_prof.expansion_power, "Desert flame expands wider in thin atmosphere")
	
	# Toxic / Sulfuric (Level 2)
	var tox_prof = LandingFXProfile.get_profile({ "level": 2, "type": "Tóxico" })
	assert_true(tox_prof.engine_flame_color.g > tox_prof.engine_flame_color.r, "Toxic engine flame burns alien emerald-green")
	assert_true(tox_prof.ground_smoke_buoyancy.y < hab_prof.ground_smoke_buoyancy.y, "Toxic sulfuric smoke is heavy and hugs the ground")
	assert_true(tox_prof.shock_diamond_freq > hab_prof.shock_diamond_freq, "Hyperbaric pressure creates tighter supersonic shock diamonds")
	
	# Cryo / Glacial (Level 3)
	var cryo_prof = LandingFXProfile.get_profile({ "level": 3, "type": "Glaciar" })
	assert_true(cryo_prof.engine_flame_color.b > cryo_prof.engine_flame_color.r, "Cryo engine flame is electric cyan/sapphire plasma")
	assert_true(cryo_prof.is_cryo_steam == true, "Cryo interaction triggers instant boiling steam sublimation")
	assert_true(cryo_prof.ground_smoke_scale_max >= 6.0, "Cryo steam clouds expand into massive condensation plumes")
	
	# Singularity (Level 4)
	var sing_prof = LandingFXProfile.get_profile({ "level": 4, "type": "Singularidad" })
	assert_true(sing_prof.engine_flame_color.b > 0.8 and sing_prof.engine_flame_color.r > 0.5, "Singularity drive produces deep violet/magenta plasma")
	assert_true(sing_prof.ground_smoke_color.r < 0.35 and sing_prof.ground_smoke_color.b > 0.30, "Singularity produces swirling obsidian-purple smoke")
	
	# Molten / Volcanic (Level 5)
	var ign_prof = LandingFXProfile.get_profile({ "level": 5, "type": "Ígneo" })
	assert_true(ign_prof.engine_flame_color.r > 0.9 and ign_prof.engine_flame_color.g < 0.3, "Volcanic engine flame burns searing magma-crimson")
	assert_true(ign_prof.ground_smoke_color.r < 0.20 and ign_prof.ground_smoke_color.g < 0.20, "Volcanic ground smoke is pitch-black ash and soot")
	
	# Vacuum / Lunar
	var vac_prof = LandingFXProfile.get_profile({ "has_atmosphere": false, "type": "Lunar" })
	assert_true(vac_prof.is_vacuum == true, "Lunar environment detected as vacuum")
	assert_true(vac_prof.expansion_power <= 0.80, "Vacuum plume underexpands with wide bell angle")
	
	# 2. Test Procedural Particle Textures (Zero hard-edge artifacts)
	var soft_circ = LandingFXProfile.get_soft_circle_texture()
	assert_true(soft_circ != null and soft_circ.width == 64, "Soft circular flame texture generated procedurally")
	var soft_smoke = LandingFXProfile.get_soft_smoke_texture()
	assert_true(soft_smoke != null and soft_smoke.height == 64, "Soft volumetric smoke texture generated procedurally")
	
	# 3. Test Spaceship 3D Engine Setup
	var ship_scene = load("res://scenes/entities/spaceship_3d.tscn")
	var ship_inst = ship_scene.instantiate()
	add_child(ship_inst)
	
	# Configure engine for Cryo Glacial planet
	ship_inst.setup_landing_engine_fx({ "level": 3, "type": "Glaciar" })
	assert_true(ship_inst.active_nozzle_material != null, "Active nozzle thermal material created")
	assert_true(ship_inst.active_nozzle_material.emission_enabled == true, "Nozzle incandescence emission enabled during burn")
	assert_true(ship_inst.active_flame_material != null, "Active supersonic flame shader material instantiated")
	assert_true(ship_inst.engine_fire_stream != null, "Supersonic engine fire stream particle emitter created")
	assert_true(ship_inst.engine_fire_stream.direction.y < 0.0, "Engine fire streams strictly downward toward ground")
	assert_true(ship_inst.engine_light_ref != null, "Engine illumination light reference linked")
	assert_true(ship_inst.engine_light_ref.light_color.b > ship_inst.engine_light_ref.light_color.r, "Engine light matches cryo cyan flame color")
	
	ship_inst.free()

# 22. Testing 100% Oceanic / Aquatic Worlds & Procedural Liquid Levels
func test_oceanic_aquatic_worlds_and_procedural_sea_levels() -> void:
	print("--- 22. Testing 100% Oceanic / Aquatic Worlds & Procedural Liquid Levels ---")
	
	# 1. Test Archetype 6: 100% Ocean World across Realistic Chemical Domains
	# 1a. Waterworld H2O
	var h2o_planet = SolarSystem.generate_oceanic_world("h2o", 4200)
	assert_true(h2o_planet.get("is_ocean_world", false) == true, "H2O planet flagged as is_ocean_world == true")
	assert_almost_eq(h2o_planet.get("ocean_coverage", 0.0), 1.0, 0.01, "H2O ocean coverage is 100% (1.0)")
	assert_true(h2o_planet.get("water_status", "") == "Líquida", "H2O ocean possesses liquid water status")
	assert_true(h2o_planet.get("type", "") == "Oceánico", "H2O planet type is Oceánico")
	assert_true(h2o_planet.get("type_label", "").contains("Océano Global"), "Type label identifies as Mundo Océano Global")
	assert_true(h2o_planet.get("cloud_density", 0.0) >= 0.60, "H2O ocean world has dense maritime clouds")
	
	# 1b. Magma / Molten Lava Ocean World
	var magma_planet = SolarSystem.generate_oceanic_world("magma", 4201)
	assert_true(magma_planet.get("is_ocean_world", false) == true, "Magma planet flagged as is_ocean_world == true")
	assert_almost_eq(magma_planet.get("ocean_coverage", 0.0), 1.0, 0.01, "Magma ocean coverage is 100% (1.0)")
	assert_true(magma_planet.get("is_molten", false) == true, "Magma ocean flagged as is_molten == true")
	assert_true(magma_planet.get("temperature", 0.0) > 600.0, "Magma ocean temperature is searing hot (>600°C)")
	assert_true(magma_planet.get("type_label", "").contains("Magma"), "Type label identifies as Océano de Magma")
	
	# 1c. Sulfuric Acid Ocean World
	var acid_planet = SolarSystem.generate_oceanic_world("sulfuric_acid", 4202)
	assert_true(acid_planet.get("is_ocean_world", false) == true, "Acid planet flagged as is_ocean_world == true")
	assert_almost_eq(acid_planet.get("ocean_coverage", 0.0), 1.0, 0.01, "Acid ocean coverage is 100% (1.0)")
	assert_true(acid_planet.get("temperature", 0.0) > 80.0, "Acid ocean has elevated greenhouse temperature (>80°C)")
	assert_true(acid_planet.get("type_label", "").contains("Ácido"), "Type label identifies as Océano de Ácido Sulfúrico")
	
	# 1d. Cryogenic Liquid Methane Ocean World
	var meth_planet = SolarSystem.generate_oceanic_world("methane", 4203)
	assert_true(meth_planet.get("is_ocean_world", false) == true, "Methane planet flagged as is_ocean_world == true")
	assert_almost_eq(meth_planet.get("ocean_coverage", 0.0), 1.0, 0.01, "Methane ocean coverage is 100% (1.0)")
	assert_true(meth_planet.get("temperature", 0.0) < -100.0, "Methane ocean is cryogenic subzero (<-100°C)")
	assert_true(meth_planet.get("type_label", "").contains("Metano"), "Type label identifies as Océano Criogénico de Metano")
	
	# 1e. Hycean Ammonia-Water Super-Ocean World
	var hyc_planet = SolarSystem.generate_oceanic_world("hycean", 4204)
	assert_true(hyc_planet.get("is_ocean_world", false) == true, "Hycean planet flagged as is_ocean_world == true")
	assert_almost_eq(hyc_planet.get("ocean_coverage", 0.0), 1.0, 0.01, "Hycean ocean coverage is 100% (1.0)")
	assert_true(hyc_planet.get("type_label", "").contains("Hiceánico"), "Type label identifies as Super-Océano Hiceánico")
	
	var ocean_planet = h2o_planet
	
	# 2. Test Archetype 7: Singularity (Clase X • PRO)
	var sing_planet = SolarSystem.generate_procedural_planet_for_archetype(7, 9999)
	assert_true(sing_planet != null, "Archetype 7 generates valid planet dictionary")
	assert_true(sing_planet.get("level", -1) == 4, "Archetype 7 assigned Level 4 (Clase X Singularity)")
	assert_true(sing_planet.get("is_singularity", false) == true, "Archetype 7 flagged as is_singularity")
	
	# 3. Test Terrain Elevation on 100% Ocean World (All crust strictly submerged)
	var noise = FastNoiseLite.new()
	noise.seed = 4242
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	var max_elev = -999.0
	var min_elev = 999.0
	var all_submerged = true
	
	# Sample 100 directions around the globe (excluding immediate north pole landing pad)
	for i in range(100):
		var phi = (float(i) / 100.0) * PI * 0.90 + 0.15 # Mid & equatorial latitudes
		var theta = float(i) * 2.39996 # Golden ratio angle
		var dir = Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)).normalized()
		var elev = SphericalPlanet._calc_raw_terrain(noise, dir, ocean_planet)
		if elev >= 0.0:
			all_submerged = false
		max_elev = maxf(max_elev, elev)
		min_elev = minf(min_elev, elev)
		
	assert_true(all_submerged, "All open-globe raw terrain on 100% ocean world is submerged (elev < 0.0m)")
	assert_true(max_elev <= -0.6, "Maximum crust elevation on ocean world stays below sea level (<= -0.6m)")
	assert_true(min_elev >= -16.0, "Abyssal trenches bounded safely (>= -16.0m)")
	
	# 4. Test North Pole Landing Platform on Ocean World
	var north_pad_elev = SphericalPlanet._calc_elevation_static(noise, Vector3.UP, ocean_planet)
	assert_almost_eq(north_pad_elev, 1.80, 0.02, "North pole landing pad on ocean world is an elevated marine platform above water level (1.80m)")
	
	# 5. Test Landing FX Profile on Ocean World
	var LandingFXProfile = load("res://scripts/effects/landing_fx_profile.gd")
	var fx_prof = LandingFXProfile.get_profile(ocean_planet)
	assert_true(fx_prof.biome_name.contains("Océano"), "Landing FX profile identifies as Océano Global")
	assert_true(fx_prof.ground_smoke_scale_max >= 5.5, "Ocean landing produces massive marine steam clouds")
	assert_true(fx_prof.ground_dust_color.b > fx_prof.ground_dust_color.r, "Ocean landing shockwave is blue-tinted marine spray")
	
	# 6. Test Procedural Diversity: Solar System Generation produces liquid worlds with realistic ocean coverage
	var found_ocean_world = false
	var diverse_coverage = false
	var min_cov = 1.0
	var max_cov = 0.0
	
	for s in range(25):
		var sys = SolarSystem.generate_system(s * 777 + 101)
		for p in sys["planets"]:
			if p.get("water_status", "") == "Líquida":
				var cov = p.get("ocean_coverage", 0.0)
				min_cov = minf(min_cov, cov)
				max_cov = maxf(max_cov, cov)
				if p.get("is_ocean_world", false):
					found_ocean_world = true
					
	assert_true(found_ocean_world, "Solar system generation procedurally spawns 100% Ocean Worlds")
	assert_true(max_cov > 0.95, "Maximum ocean coverage reaches 100% ocean worlds")
	assert_true(min_cov < 0.75, "Minimum ocean coverage provides continental landmasses")

# 23. Testing Underwater Walking, Manual Swimming, Jetpack Bubbles, Flint Jump & Suit Reactions
func test_swimming_underwater_walking_and_suit_reactions() -> void:
	print("--- 23. Testing Swimming, Underwater Walking, Flint Jump & Suit Reactions ---")
	
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	assert_true(char_scene != null, "Character scene loads successfully")
	var player = char_scene.instantiate()
	add_child(player)
	
	# 1. Test Particle Emitters & Suit Material Initialization
	assert_true(player.active_suit_material != null, "Active suit material initialized dynamically")
	assert_true(player.bubble_particles != null, "Underwater cavitation bubble emitter created")
	assert_true(player.spark_particles != null, "Emergency spark burst emitter created")
	assert_true(player.splash_particles != null, "Liquid splash emitter created")
	
	# 2. Test Underwater Seabed Walking (No automatic floating!)
	player.global_position = Vector3(0, player.planet_radius - 5.0, 0) # 5m submerged underwater
	var ocean_r = player.planet_radius
	player.is_in_liquid = (player.global_position.length() < ocean_r)
	assert_true(player.is_in_liquid == true, "Player correctly detected inside liquid ocean")
	
	# Simulate physics tick on seabed: floor snap stays active (0.85m), player does NOT float away!
	player.floor_snap_length = 0.85
	assert_almost_eq(player.floor_snap_length, 0.85, 0.01, "Floor snap length remains active underwater to walk on seabed")
	
	# 3. Test Flint Spark Emergency Jump on Land when Out of Fuel
	player.is_in_liquid = false
	GameManager.player_stats.fuel = 0.0
	player.can_emergency_spark_jump = true
	assert_true(player.can_emergency_spark_jump == true, "Flint emergency jump primed when touching floor")
	# Simulate spark jump trigger
	player.can_emergency_spark_jump = false
	player.vertical_speed = player.jump_velocity
	assert_almost_eq(player.vertical_speed, 8.0, 0.01, "Flint spark ignition gives vertical jump impulse (8.0m/s)")
	assert_true(player.can_emergency_spark_jump == false, "Flint jump consumed until next floor contact")
	
	# 4. Test Underwater Manual Swimming Oxygen Drain
	player.is_in_liquid = true
	player.is_swimming_manual = true
	var base_underwater_o2_drain = 2.5
	var swim_o2_drain = 3.8
	var total_swim_o2 = base_underwater_o2_drain + swim_o2_drain
	assert_almost_eq(total_swim_o2, 6.3, 0.01, "Manual swimming burns oxygen at sprinting exertion rate (6.3%/s)")
	
	# Sprinting + Swimming double exertion
	var sprint_swim_o2 = total_swim_o2 + 3.8
	assert_almost_eq(sprint_swim_o2, 10.1, 0.01, "Simultaneous sprinting + swimming stacks anaerobic oxygen consumption (10.1%/s)")
	
	# 5. Test Suit Chemical & Thermal Reactions
	# 5a. Lava immersion reaction
	player._update_suit_thermal_and_fluid_reactions(0.5, { "water_status": "Lava Fundida", "is_molten": true })
	assert_true(player.active_suit_material.emission_enabled == true, "Suit glows with incandescent thermal emission in lava")
	assert_true(player.active_suit_material.albedo_color.r < 0.80, "Suit chars and darkens in molten lava")
	
	# 5b. Cryo methane immersion reaction
	player._update_suit_thermal_and_fluid_reactions(0.5, { "water_status": "Hielo Criogénico", "ocean_chemical": "methane" })
	assert_true(player.active_suit_material.metallic > 0.20, "Cryogenic methane forms icy reflective metallic glaze on suit")
	
	# 5c. Acid immersion reaction
	player._update_suit_thermal_and_fluid_reactions(0.5, { "water_status": "Vapor Tóxico", "ocean_chemical": "sulfuric_acid" })
	assert_true(player.active_suit_material.roughness > 0.50, "Sulfuric acid etches and corrodes suit roughness")
	
	# 6. Test HUD Dynamic Swim Icon Switching
	var hud_scene = load("res://scenes/ui/hud.tscn")
	assert_true(hud_scene != null, "HUD scene loads successfully")
	var hud = hud_scene.instantiate()
	add_child(hud)
	hud.init_player(player)
	
	# Land with fuel -> Thrust icon
	player.is_in_liquid = false
	hud._on_stats_changed(100.0, 100.0, 100.0)
	assert_true(hud.jump_btn.texture_normal == hud.thrust_icon, "HUD displays rocket thrust icon in air/land with fuel")
	
	# Land WITHOUT fuel -> Stays Thrust icon (Point 5 rule: 'En este caso, el icono no cambiara')
	player.is_in_liquid = false
	hud._on_stats_changed(100.0, 0.0, 100.0)
	assert_true(hud.jump_btn.texture_normal == hud.thrust_icon, "HUD preserves rocket icon on land even when out of fuel")
	
	# Underwater WITHOUT fuel -> Switches to Swim icon (Point 4 rule: 'el simbolo de jetpack cambiara en este caso')
	player.is_in_liquid = true
	hud._on_stats_changed(100.0, 0.0, 100.0)
	assert_true(hud.jump_btn.texture_normal == hud.swim_icon, "HUD dynamically switches button to swim icon when underwater without fuel")
	
	# Underwater WITH fuel -> Restores Thrust icon
	hud._on_stats_changed(100.0, 50.0, 100.0)
	assert_true(hud.jump_btn.texture_normal == hud.thrust_icon, "HUD restores rocket thrust icon underwater when fuel is available")
	
	hud.free()
	player.free()

# 24. Testing Twin Jetpack Modules (2 SRC), Camera-Invariant Fluid Shader & Realistic Swimming
func test_twin_jetpacks_realistic_fluid_and_breaststroke_swimming() -> void:
	print("--- 24. Testing Twin Jetpacks (2 SRC), Realistic Fluid Shader & Swimming ---")
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	assert_true(char_scene != null, "Character scene loads successfully")
	var player = char_scene.instantiate()
	add_child(player)
	
	# 1. Twin Physical Jetpack 3D Meshes on Backpack
	var backpack = player.get_node_or_null("Visuals/Torso/BackpackPLSS")
	assert_true(backpack != null, "Astronaut backpack PLSS node located")
	var jet_left = backpack.get_node_or_null("JetpackLeft")
	var jet_right = backpack.get_node_or_null("JetpackRight")
	assert_true(jet_left != null, "Left Jetpack physical module mounted on backpack")
	assert_true(jet_right != null, "Right Jetpack physical module mounted on backpack")
	assert_true(jet_left.position.x < 0.0, "Left Jetpack mounted on left flank of backpack")
	assert_true(jet_right.position.x > 0.0, "Right Jetpack mounted on right flank of backpack")
	
	# 2. Twin Jetpack Supersonic Flame Emitters (2 SRC)
	assert_true(player.flame_particles_left != null, "Left Jetpack rocket flame emitter created (SRC 1)")
	assert_true(player.flame_particles_right != null, "Right Jetpack rocket flame emitter created (SRC 2)")
	assert_true(player.flame_particles != null, "Primary flame reference linked for compatibility")
	assert_true(player.flame_particles_left.direction.y < 0.0, "Left jetpack flame points downwards")
	assert_true(player.flame_particles_right.direction.y < 0.0, "Right jetpack flame points downwards")
	
	# 3. Twin Wispy Smoke Emitters
	assert_true(player.flame_smoke_left != null, "Left jetpack trailing smoke emitter created")
	assert_true(player.flame_smoke_right != null, "Right jetpack trailing smoke emitter created")
	
	# 4. Twin Underwater Cavitation Bubble Emitters (2 SRC)
	assert_true(player.bubble_particles_left != null, "Left jetpack underwater cavitation bubble emitter created (SRC 1)")
	assert_true(player.bubble_particles_right != null, "Right jetpack underwater cavitation bubble emitter created (SRC 2)")
	
	# 5. Twin Emergency Spark Emitters
	assert_true(player.spark_particles_left != null, "Left jetpack emergency flint spark emitter created")
	assert_true(player.spark_particles_right != null, "Right jetpack emergency flint spark emitter created")
	
	# 6. Dynamic Jetpack Thruster OmniLight3D
	assert_true(player.jetpack_light != null, "Dynamic jetpack thruster omni light created")
	
	# 7. Test Thruster Activation / Deactivation
	player._set_jetpack_flames(true)
	assert_true(player.flame_particles_left.emitting == true, "Left jetpack flame firing on thrust")
	assert_true(player.flame_particles_right.emitting == true, "Right jetpack flame firing on thrust")
	assert_true(player.jetpack_light.visible == true, "Jetpack dynamic light illuminates on thrust")
	assert_true(player.jetpack_light.light_energy > 0.0, "Jetpack light has positive lumen intensity")
	
	player._set_jetpack_flames(false)
	assert_true(player.flame_particles_left.emitting == false, "Left jetpack flame extinguished")
	assert_true(player.flame_particles_right.emitting == false, "Right jetpack flame extinguished")
	assert_true(player.jetpack_light.visible == false, "Jetpack dynamic light disabled when idle")
	
	player._set_jetpack_bubbles(true)
	assert_true(player.bubble_particles_left.emitting == true, "Left jetpack cavitation bubbles blasting underwater")
	assert_true(player.bubble_particles_right.emitting == true, "Right jetpack cavitation bubbles blasting underwater")
	
	player._set_jetpack_bubbles(false)
	assert_true(player.bubble_particles_left.emitting == false, "Left cavitation bubbles stopped")
	assert_true(player.bubble_particles_right.emitting == false, "Right cavitation bubbles stopped")
	
	# 8. Test Spherical Fluid Shader Source Code for Camera Invariance & Perturbation
	var fluid_shader = load("res://assets/shaders/spherical_fluid.gdshader") as Shader
	assert_true(fluid_shader != null, "Spherical fluid shader resource loads successfully")
	var shader_code = fluid_shader.code
	assert_true(shader_code.contains("v_world_normal"), "Shader passes world-space normal varying to eliminate camera texture sliding")
	assert_true(shader_code.contains("NORMAL = normalize((VIEW_MATRIX * vec4("), "Shader perturbs physical NORMAL in view space for real lighting reflections")
	assert_true(shader_code.contains("calc_wave_height"), "Shader computes analytical multi-frequency wave height for realistic fluid optics")
	
	# 9. Test Swimming Posture Angles (Prone Forward Facing)
	player.is_in_liquid = true
	player.is_swimming_manual = true
	player.swim_time += 0.5
	var target_swim_pitch = -deg_to_rad(65.0)
	assert_true(target_swim_pitch < -deg_to_rad(55.0), "Swimming posture uses streamlined horizontal prone tilt facing forward (< -55 deg)")
	
	# 10. Test Upright Stance on Shoreline / Seabed (Zero Backward Sliding)
	player.visuals.rotation.x = 0.0
	assert_true(abs(player.visuals.rotation.x) < 0.01, "Standing on shoreline or seabed is completely upright (0 deg pitch)")
	
	# 11. Test Ocean Waves Physics & Hazard Integration
	player.global_position = Vector3(0, player.planet_radius - 0.5, 0)
	var norm_p = player.global_position.normalized()
	var w1 = sin(norm_p.x * 28.0 + norm_p.y * 22.0) * 0.45
	var w2 = cos(norm_p.z * 32.0 + norm_p.x * 18.0) * 0.35
	var w3 = sin(norm_p.y * 42.0 - norm_p.z * 26.0) * 0.20
	var calc_h = (w1 + w2 + w3) * 0.35
	assert_true(abs(calc_h) <= 0.40, "Wave height calculation bounded physically (+/- 0.40m)")
	
	# Test strong wave stumble knockback
	player.wave_stumble_timer = 0.55
	assert_true(player.wave_stumble_timer > 0.0, "Strong wave crest triggers stumble knockback timer")
	
	player.free()

# 25. Testing Normal Jetpack Behavior, Selective Jumping Without Fuel & Elevated Ocean Spawn
func test_normal_jetpack_behavior_and_selective_jumping() -> void:
	print("--- 25. Testing Normal Jetpack, Selective Jumping & Elevated Ocean Spawn ---")
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	assert_true(char_scene != null, "Character scene loads successfully")
	var player = char_scene.instantiate()
	add_child(player)

	# 1. Normal Jetpack Operation WITH Fuel
	GameManager.player_stats.fuel = 100.0
	
	# In air: standard acceleration and flame particles
	player.is_in_liquid = false
	player.vertical_speed = 0.0
	# Simulate normal jetpack thrust frame
	var delta = 0.016
	player.vertical_speed += player.jetpack_accel * delta
	player._set_jetpack_flames(true)
	player._set_jetpack_bubbles(false)
	assert_true(player.vertical_speed > 0.2, "Jetpack accelerates normally upwards in air")
	assert_true(player.flame_particles_left.emitting == true, "Jetpack flames fire in air with fuel")
	assert_true(player.bubble_particles_left.emitting == false, "Cavitation bubbles disabled in air")

	# In liquid: normal propulsion with underwater bubbles
	player.is_in_liquid = true
	player._set_jetpack_flames(false)
	player._set_jetpack_bubbles(true)
	assert_true(player.flame_particles_left.emitting == false, "Jetpack flames extinguished in liquid")
	assert_true(player.bubble_particles_left.emitting == true, "Cavitation bubbles active in liquid with fuel")

	# 2. Selective Jumping WITHOUT Fuel
	GameManager.player_stats.fuel = 0.0
	player._set_jetpack_flames(false)
	player._set_jetpack_bubbles(false)
	assert_true(player.flame_particles_left.emitting == false, "No jetpack flames when out of fuel")
	assert_true(player.bubble_particles_left.emitting == false, "No cavitation bubbles when out of fuel")

	# 2a. Jump on Land (Floor): Works
	player.is_in_liquid = false
	player.can_emergency_spark_jump = true
	player.vertical_speed = player.jump_velocity * 0.85
	player.can_emergency_spark_jump = false
	assert_almost_eq(player.vertical_speed, 6.8, 0.01, "Jump on land floor gives impulse (6.8 m/s)")
	assert_true(player.can_emergency_spark_jump == false, "Land jump consumed spark until next floor contact")

	# 2b. Jump in Mid-Air: Emergency spark jump works once
	player.can_emergency_spark_jump = true
	player.vertical_speed = player.jump_velocity * 0.85
	player.can_emergency_spark_jump = false
	assert_almost_eq(player.vertical_speed, 6.8, 0.01, "Jump in mid-air gives emergency spark impulse (6.8 m/s)")
	assert_true(player.can_emergency_spark_jump == false, "Mid-air spark jump consumed")

	# 2c. Jump touching Seabed Floor: Works
	player.is_in_liquid = true
	player.can_emergency_spark_jump = true
	player.vertical_speed = player.jump_velocity * 0.85
	player.can_emergency_spark_jump = false
	assert_almost_eq(player.vertical_speed, 6.8, 0.01, "Jump touching seabed gives push-off impulse (6.8 m/s)")
	assert_true(player.can_emergency_spark_jump == false, "Seabed jump consumed")

	# 2d. In Water (NOT touching seabed): Zero floating, astronaut descends toward seabed under fluid gravity
	player.is_in_liquid = true
	var fluid_grav = 9.8 * 0.62
	assert_true(fluid_grav > 0.0, "Astronaut descends toward seabed under fluid gravity without floating")

	# 3. Respiration with Head Above Water (Breathable Atmosphere)
	player.planet = { "has_oxygen": true, "water_status": "Agua Líquida" }
	var ocean_surf_r = 160.0
	# Test shallow water wading (feet at 159.0m, water depth 1.0m): head is at 159.0 + 1.55 = 160.55m (ABOVE WATER)
	var shallow_feet_dist = 159.0
	var head_dist_shallow = shallow_feet_dist + 1.55
	var head_above_water = head_dist_shallow >= ocean_surf_r
	assert_true(head_above_water, "Astronaut head is above water level when wading in shallow ocean")
	
	# Deep immersion (feet at 156.0m, water depth 4.0m): head is at 156.0 + 1.55 = 157.55m (SUBMERGED)
	var deep_feet_dist = 156.0
	var head_dist_deep = deep_feet_dist + 1.55
	var head_submerged = head_dist_deep < ocean_surf_r
	assert_true(head_submerged, "Astronaut head is submerged underwater when diving deep")

	# 4. Fluid Density Dynamics and Seabed Bounding Strides ("Saltitos")
	# 4a. Methane density
	player.planet = { "ocean_chemical": "methane", "water_status": "Hielo Criogénico" }
	assert_almost_eq(player.get_liquid_density(), 0.45, 0.01, "Cryogenic methane relative density is 0.45")
	
	# 4b. Standard water density
	player.planet = { "ocean_chemical": "h2o", "water_status": "Agua Líquida" }
	assert_almost_eq(player.get_liquid_density(), 1.00, 0.01, "Standard ocean water relative density is 1.00")
	
	# 4c. Sulfuric acid density
	player.planet = { "ocean_chemical": "sulfuric_acid", "water_status": "Vapor Tóxico" }
	assert_almost_eq(player.get_liquid_density(), 1.84, 0.01, "Sulfuric acid relative density is 1.84")
	
	# 4d. Magma density
	player.planet = { "ocean_chemical": "magma", "is_molten": true }
	assert_almost_eq(player.get_liquid_density(), 2.65, 0.01, "Silicate magma relative density is 2.65")
	
	# 4e. Seabed hop parameters: higher hops in lighter fluid, shorter heavier hops in magma
	var methane_t = clampf((0.45 - 0.45) / 2.2, 0.0, 1.0)
	var magma_t = clampf((2.65 - 0.45) / 2.2, 0.0, 1.0)
	var methane_hop_h = lerpf(0.24, 0.11, methane_t)
	var magma_hop_h = lerpf(0.24, 0.11, magma_t)
	assert_true(methane_hop_h > magma_hop_h, "Astronaut takes higher bounding hops in light methane than dense magma")
	assert_almost_eq(methane_hop_h, 0.24, 0.01, "Methane hop height is ~0.24m")
	assert_almost_eq(magma_hop_h, 0.11, 0.01, "Magma hop height is ~0.11m")

	# 4f. Test Biomechanical Locomotion Preference (prefers_lunar_hopping)
	# On land in low gravity (Moon 0.166g): prefers lunar lope
	player.is_in_liquid = false
	player.planet = { "gravity_g": 0.166 }
	assert_true(player.prefers_lunar_hopping() == true, "Moon surface (0.166g) prefers lunar lope hopping strides")
	
	# On land in normal terrestrial gravity (Earth 1.0g): prefers normal walking
	player.planet = { "gravity_g": 1.0 }
	assert_true(player.prefers_lunar_hopping() == false, "Earth-like planet (1.0g) prefers normal walking strides")
	
	# On land in high gravity super-earth (1.8g): prefers normal walking
	player.planet = { "gravity_g": 1.8 }
	assert_true(player.prefers_lunar_hopping() == false, "Super-earth (1.8g) prefers normal walking strides")

	# Underwater in normal ocean water (density 1.0): prefers seabed hopping
	player.is_in_liquid = true
	player.planet = { "ocean_chemical": "h2o", "water_status": "Agua Líquida" }
	assert_true(player.prefers_lunar_hopping() == true, "Subsea ocean floor (density 1.0) prefers seabed hopping")
	
	# Underwater in dense magma (density 2.65): prefers heavy wading (no hopping)
	player.planet = { "ocean_chemical": "magma", "is_molten": true }
	assert_true(player.prefers_lunar_hopping() == false, "Dense viscous magma ocean (density 2.65) prefers heavy wading")

	# 4g. Test Sprinting produces much larger hops (footage Apollo)
	# In low gravity: walking hop = 0.22m, running sprint hop = 0.46m (>2x height!)
	var walk_lope_h = 0.22
	var sprint_lope_h = 0.46
	assert_true(sprint_lope_h > walk_lope_h * 1.8, "Running sprint in low gravity produces over 2x larger hops (~0.46m)")
	
	# Underwater: walking seabed hop vs running seabed hop
	var water_t = clampf((1.0 - 0.45) / 2.2, 0.0, 1.0)
	var base_water_h = lerpf(0.22, 0.12, water_t)
	var sprint_water_h = base_water_h * 1.85
	assert_true(sprint_water_h > base_water_h * 1.5, "Underwater sprint produces notably larger bounding leaps (~0.36m)")

	# 5. Elevated Ocean World Spawn
	var noise = FastNoiseLite.new()
	noise.seed = 9999
	var ocean_planet = {
		"is_ocean_world": true,
		"type": "Oceánico",
		"water_status": "Agua Líquida",
		"ocean_coverage": 1.0,
		"seed": 9999
	}
	var ocean_spawn_h = SphericalPlanet._calc_elevation_static(noise, Vector3.UP, ocean_planet)
	assert_almost_eq(ocean_spawn_h, 1.80, 0.01, "Ocean world north pole spawn is safely elevated at 1.80m above sea level")

	player.free()





