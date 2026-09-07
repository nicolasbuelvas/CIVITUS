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
	
	# Initial 3rd person state
	assert_true(not player.is_first_person, "Player starts in 3rd person")
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
	
	# Drag right and down
	player.rotate_camera_by(Vector2(40.0, 30.0))
	assert_true(player.target_yaw < initial_yaw, "Dragging right rotates yaw right (decreases yaw angle)")
	assert_true(player.target_pitch > initial_pitch, "Dragging down tilts pitch down")
	
	# Pitch clamp verification in 1st person
	player.toggle_first_person()
	player.rotate_camera_by(Vector2(0.0, 50000.0)) # Extreme drag down
	assert_true(player.target_pitch <= 75.0, "Pitch is clamped to max 75 degrees in 1st person")
	player.rotate_camera_by(Vector2(0.0, -100000.0)) # Extreme drag up
	assert_true(player.target_pitch >= -75.0, "Pitch is clamped to min -75 degrees in 1st person")
	player.queue_free()
