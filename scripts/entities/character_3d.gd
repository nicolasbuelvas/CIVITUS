extends CharacterBody3D

signal stats_changed(oxygen: float, fuel: float, hull: float)
signal interaction_available(type: String, target_node: Node3D)
signal interaction_lost()
signal first_person_toggled(is_fps: bool)

@export var walk_speed: float = 7.5
@export var jump_velocity: float = 8.0
@export var jetpack_accel: float = 15.0
@export var planet_radius: float = 160.0

# Node references
@onready var visuals: Node3D = get_node_or_null("Visuals")
@onready var head: Node3D = get_node_or_null("Visuals/Head")
@onready var helmet: Node3D = get_node_or_null("Visuals/Helmet")
@onready var face: Node3D = get_node_or_null("Visuals/Head/Face")
@onready var left_arm: Node3D = get_node_or_null("Visuals/LeftArm")
@onready var right_arm: Node3D = get_node_or_null("Visuals/RightArm")
@onready var left_leg: Node3D = get_node_or_null("Visuals/LeftLeg")
@onready var right_leg: Node3D = get_node_or_null("Visuals/RightLeg")
@onready var camera_pivot: Node3D = get_node_or_null("CameraPivot")
@onready var camera: Camera3D = get_node_or_null("CameraPivot/Camera3D")
@onready var laser_mesh: MeshInstance3D = get_node_or_null("Visuals/LaserMesh")

var is_in_space_suit: bool = true
var is_mining: bool = false
var is_first_person: bool = false
var is_sprinting: bool = false
var is_dead: bool = false
var is_in_liquid: bool = false
var nearby_interactable: Node3D = null
var current_interactable_type: String = ""

var walk_time: float = 0.0
var vertical_speed: float = 0.0
var laser_immediate: ImmediateMesh = ImmediateMesh.new()
var is_action_locked: bool = false

# Orbit camera & zoom state
var cam_yaw: float = 0.0
var cam_pitch: float = 0.0
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var target_zoom: float = 0.0
var current_zoom: float = 0.0
var cam_base_fwd: Vector3 = Vector3.FORWARD
var current_facing: Vector3 = Vector3.FORWARD
const MIN_ZOOM: float = 0.0
const MAX_ZOOM: float = 16.0
const FPS_THRESHOLD: float = 0.8
const HELMET_HEAD_POS: Vector3 = Vector3(0, 1.6, 0)
const HELMET_HELD_POS: Vector3 = Vector3(0, 0.95, -0.36)
const HELMET_HELD_ROT: Vector3 = Vector3(0.35, 0, 0)

func _ready() -> void:
	if laser_mesh:
		laser_mesh.mesh = laser_immediate
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 0.9, 1.0)
		laser_mesh.material_override = mat
	if camera_pivot:
		camera_pivot.top_level = true
	set_suit_mode(true)
	_check_fps_mode()

func setup_spawn(spawn_pos: Vector3, up_dir: Vector3, facing_dir: Vector3) -> void:
	global_position = spawn_pos
	up_direction = up_dir
	
	var tangent_fwd = (facing_dir - up_dir * facing_dir.dot(up_dir)).normalized()
	if tangent_fwd.length_squared() < 0.001:
		tangent_fwd = Vector3.FORWARD
	
	current_facing = tangent_fwd
	cam_base_fwd = tangent_fwd
	
	var tangent_back = -tangent_fwd
	var tangent_rt = up_dir.cross(tangent_back).normalized()
	global_transform.basis = Basis(tangent_rt, up_dir, tangent_back).orthonormalized()
	
	target_yaw = 0.0
	cam_yaw = 0.0
	target_pitch = 0.0
	cam_pitch = 0.0
	target_zoom = 0.0
	current_zoom = 0.0
	is_first_person = true
	
	if visuals:
		visuals.visible = true
		visuals.rotation = Vector3.ZERO
	if head:
		head.visible = false
	if camera_pivot:
		camera_pivot.top_level = true
		camera_pivot.global_position = global_position + up_dir * 1.6
		camera_pivot.rotation = Vector3.ZERO
	if camera:
		camera.position = Vector3(0, 0.15, -0.05)
		camera.fov = 80.0
	
	first_person_toggled.emit(true)

func set_suit_mode(outside: bool) -> void:
	is_in_space_suit = outside
	if is_first_person:
		if helmet: helmet.visible = false
		if face: face.visible = false
	else:
		if helmet:
			helmet.visible = true
			if outside:
				helmet.position = HELMET_HEAD_POS
				helmet.rotation = Vector3.ZERO
			else:
				helmet.position = HELMET_HELD_POS
				helmet.rotation = HELMET_HELD_ROT
		if face:
			face.visible = not outside

func animate_put_on_helmet() -> void:
	is_in_space_suit = true
	if helmet and left_arm and right_arm and not is_first_person:
		helmet.visible = true
		helmet.position = HELMET_HELD_POS
		helmet.rotation = HELMET_HELD_ROT
		if face: face.visible = true
		
		var tw = create_tween().set_parallel(true)
		# 1. Hands and helmet lift together from chest to above head in a natural upward arc (positive X rotation!)
		tw.tween_property(helmet, "position", Vector3(0, 1.85, -0.1), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(helmet, "rotation", Vector3.ZERO, 0.6)
		tw.tween_property(left_arm, "rotation:x", 2.1, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(left_arm, "rotation:z", 0.35, 0.6)
		tw.tween_property(right_arm, "rotation:x", 2.1, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(right_arm, "rotation:z", -0.35, 0.6)
		
		# 2. Helmet settles onto neck collar
		var tw2 = create_tween()
		tw2.tween_interval(0.6)
		tw2.tween_property(helmet, "position", HELMET_HEAD_POS, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw2.tween_callback(func():
			if face: face.visible = false
			AudioManager.play("click", 0.95)
		)
		var tw_lock = create_tween().set_parallel(true)
		tw_lock.tween_interval(0.6)
		tw_lock.chain().tween_property(left_arm, "rotation:x", 1.6, 0.25)
		tw_lock.tween_property(right_arm, "rotation:x", 1.6, 0.25)
		
		# 3. Hands release and return to sides
		var tw3 = create_tween().set_parallel(true)
		tw3.tween_interval(0.95)
		tw3.chain().tween_property(left_arm, "rotation", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw3.tween_property(right_arm, "rotation", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		set_suit_mode(true)

func animate_take_off_helmet() -> void:
	is_in_space_suit = false
	if helmet and left_arm and right_arm and not is_first_person:
		helmet.visible = true
		helmet.position = HELMET_HEAD_POS
		helmet.rotation = Vector3.ZERO
		
		# 1. Hands raise from sides to collar ring
		var tw1 = create_tween().set_parallel(true)
		tw1.tween_property(left_arm, "rotation:x", 1.6, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw1.tween_property(left_arm, "rotation:z", 0.35, 0.35)
		tw1.tween_property(right_arm, "rotation:x", 1.6, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw1.tween_property(right_arm, "rotation:z", -0.35, 0.35)
		
		# 2. Hands lift helmet off head & reveal face
		var tw2 = create_tween().set_parallel(true)
		tw2.tween_interval(0.35)
		tw2.chain().tween_callback(func():
			if face: face.visible = true
			AudioManager.play("click", 1.1)
		)
		tw2.chain().tween_property(helmet, "position", Vector3(0, 1.85, -0.1), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw2.tween_property(left_arm, "rotation:x", 2.15, 0.35)
		tw2.tween_property(right_arm, "rotation:x", 2.15, 0.35)
		
		# 3. Lower helmet smoothly down to chest and cradle with both hands
		var tw3 = create_tween().set_parallel(true)
		tw3.tween_interval(0.7)
		tw3.chain().tween_property(helmet, "position", HELMET_HELD_POS, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw3.tween_property(helmet, "rotation", HELMET_HELD_ROT, 0.45)
		tw3.tween_property(left_arm, "rotation", Vector3(0.72, 0.22, 0.42), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw3.tween_property(right_arm, "rotation", Vector3(0.72, -0.22, -0.42), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	else:
		set_suit_mode(false)

func rotate_camera_by(drag_offset: Vector2) -> void:
	if is_dead:
		return
	var min_pitch = -80.0 if is_first_person else -35.0
	var max_pitch = 80.0 if is_first_person else 65.0
	# Exact 1:1 angular speed: 1px drag = 0.2865 degrees in BOTH Yaw (0.005 rad) and Pitch (0.2865 deg)
	target_yaw += drag_offset.x * 0.005
	target_pitch = clamp(target_pitch - drag_offset.y * 0.2865, min_pitch, max_pitch)

func toggle_first_person() -> void:
	if is_first_person:
		target_zoom = 4.5
		target_pitch = 0.0
	else:
		target_zoom = 0.0
		target_pitch = 0.0
	_check_fps_mode()

func zoom_camera(delta_zoom: float) -> void:
	target_zoom = clamp(target_zoom + delta_zoom, MIN_ZOOM, MAX_ZOOM)
	_check_fps_mode()

func set_camera_zoom_normalized(norm_val: float) -> void:
	target_zoom = lerp(MIN_ZOOM, MAX_ZOOM, clamp(norm_val, 0.0, 1.0))
	_check_fps_mode()

func _check_fps_mode() -> void:
	var should_be_fps = target_zoom <= FPS_THRESHOLD
	if should_be_fps != is_first_person:
		is_first_person = should_be_fps
		visuals.visible = true
		if head:
			head.visible = not is_first_person
		set_suit_mode(is_in_space_suit)
		first_person_toggled.emit(is_first_person)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1.0)

func _physics_process(delta: float) -> void:
	var planet = GameManager.current_planet
	var gravity_val: float = planet.get("gravity", 9.8)

	var up_dir = global_position.normalized()
	if up_dir.length_squared() < 0.001:
		up_dir = Vector3.UP
	up_direction = up_dir

	# Keyboard camera rotation
	if Input.is_action_pressed("rotate_cam_left"):
		target_yaw += 2.5 * delta
	if Input.is_action_pressed("rotate_cam_right"):
		target_yaw -= 2.5 * delta

	# 1. Spherical Orbit Camera Rotation
	cam_yaw = lerp_angle(cam_yaw, target_yaw, delta * 20.0)
	cam_pitch = lerp(cam_pitch, target_pitch, delta * 20.0)

	# Calculate camera orientation decoupled from character body
	cam_base_fwd = (cam_base_fwd - up_dir * cam_base_fwd.dot(up_dir)).normalized()
	if cam_base_fwd.length_squared() < 0.001:
		cam_base_fwd = (Vector3.FORWARD - up_dir * Vector3.FORWARD.dot(up_dir)).normalized()
	var cam_base_rt = cam_base_fwd.cross(up_dir).normalized()

	# Horizontal camera forward & right on sphere surface
	var cam_tangent_fwd = (cam_base_fwd * cos(cam_yaw) + cam_base_rt * sin(cam_yaw)).normalized()
	var cam_tangent_rt = cam_tangent_fwd.cross(up_dir).normalized()

	# Pitch rotation around camera right
	var pitch_rot = Basis(cam_tangent_rt, deg_to_rad(cam_pitch))
	var cam_fwd = (pitch_rot * cam_tangent_fwd).normalized()
	var cam_up = (pitch_rot * up_dir).normalized()
	var cam_back = -cam_fwd

	if camera_pivot:
		camera_pivot.global_position = global_position + up_dir * 1.6
		camera_pivot.global_transform.basis = Basis(cam_tangent_rt, cam_up, cam_back).orthonormalized()

	# 2. Camera Distance & Absolute Anti-Clipping (Raycast + Spherical Horizon Floor)
	current_zoom = lerp(current_zoom, target_zoom, delta * 12.0)
	if is_first_person:
		if camera:
			camera.position = Vector3(0, 0.15, -0.05)
			camera.fov = lerp(camera.fov, 80.0, delta * 12.0)
		if head:
			head.visible = false
	else:
		var effective_dist = current_zoom
		if camera_pivot:
			var space = get_world_3d().direct_space_state
			var pivot_pos = camera_pivot.global_position
			
			# Physical Raycast check
			var ray_query = PhysicsRayQueryParameters3D.create(pivot_pos, pivot_pos + cam_back * (current_zoom + 0.3), 1)
			ray_query.exclude = [self.get_rid()]
			var hit = space.intersect_ray(ray_query)
			if not hit.is_empty():
				var hit_dist = pivot_pos.distance_to(hit.position)
				effective_dist = max(0.5, hit_dist - 0.25)
				
		if camera:
			camera.position.x = 0.0
			camera.position.y = 0.0
			camera.position.z = lerp(camera.position.z, effective_dist, delta * 18.0)
			camera.fov = lerp(camera.fov, 55.0, delta * 12.0)
			
		# Mathematical Spherical Ground Floor: Camera can NEVER penetrate below planet surface
		if camera:
			var cam_pos = camera.global_position
			var cam_dir = cam_pos.normalized()
			var min_surface_r = planet_radius + _calc_ground_elevation(cam_dir) + 0.85
			if cam_pos.length() < min_surface_r:
				camera.global_position = cam_dir * min_surface_r
				
		# Anti-clipping: hide head if 3P camera is pushed closer than 1.1m
		if head:
			head.visible = (effective_dist >= 1.1)

	# 3. Camera-Dependent Movement Input Projected onto Spherical Tangent Plane
	var input_vec = Vector2.ZERO
	var input_fwd = 0.0
	var input_str = 0.0
	if not is_action_locked and not is_dead:
		input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		input_fwd = -input_vec.y # W/stick up gives forward (+1.0)
		input_str = input_vec.length()

	var move_tangent = Vector3.ZERO
	if input_str > 0.05:
		move_tangent = (cam_tangent_rt * input_vec.x + cam_tangent_fwd * input_fwd).normalized()

	# 4. Camera-Dependent Character Facing
	if input_str > 0.05:
		if input_fwd > 0.4 and abs(input_vec.x) < 0.4:
			# Moving forward: character looks directly at camera front!
			current_facing = current_facing.slerp(cam_tangent_fwd, delta * 20.0).normalized()
		else:
			current_facing = current_facing.slerp(move_tangent, delta * 15.0).normalized()
	elif is_first_person:
		current_facing = cam_tangent_fwd

	current_facing = (current_facing - up_dir * current_facing.dot(up_dir)).normalized()
	if current_facing.length_squared() < 0.001:
		current_facing = cam_tangent_fwd

	var char_back = -current_facing
	var char_rt = up_dir.cross(char_back).normalized()
	global_transform.basis = Basis(char_rt, up_dir, char_back).orthonormalized()

	# 5. Survival Vitals, Fluid Immersion & Death Condition
	var is_sprint_active = (is_sprinting or Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("sprint")) and not is_dead
	var planet_temp = planet.get("temperature", 22.0)
	var has_oxygen_atmo = planet.get("has_oxygen", false)
	
	# Liquid Ocean / Hydro Basin Immersion
	var ocean_surface_r = planet_radius
	var dist_from_center = global_position.length()
	is_in_liquid = (dist_from_center < ocean_surface_r)
	
	if is_in_liquid:
		var submersion_depth = ocean_surface_r - dist_from_center
		if has_oxygen_atmo:
			# Water Swimming: Submerged oxygen drain
			if submersion_depth > 1.1:
				GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - 2.5 * delta)
		elif planet_temp > 70.0:
			# Magma / Acid: Thermal burning of hull
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 35.0 * delta)
		elif planet_temp < -60.0:
			# Cryogenic Liquid Methane: Severe thermal freezing
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 22.0 * delta)
		else:
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 16.0 * delta)

	if is_in_space_suit:
		if has_oxygen_atmo and not is_in_liquid:
			GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 45.0 * delta)
		elif not is_in_liquid:
			var o2_drain = 3.8 if (is_sprint_active and input_str > 0.1) else 1.2
			GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - o2_drain * delta)
	
	if GameManager.player_stats.oxygen <= 0.0:
		GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 12.0 * delta)

	# Physical Death Sequence
	if GameManager.player_stats.hull <= 0.0 and not is_dead:
		var death_reason = GameManager.loc("game_over_reason_hazard") if is_in_liquid and not has_oxygen_atmo else (
			GameManager.loc("game_over_reason_o2") if GameManager.player_stats.oxygen <= 0.0 else GameManager.loc("game_over_reason_hull")
		)
		_die(death_reason)

	# 6. Horizontal Velocity & Procedural Character Facing
	var current_speed = walk_speed * (1.85 if is_sprint_active else 1.0)
	var horizontal_vel = move_tangent * (input_str * current_speed)

	if input_str > 0.05 and visuals and not is_action_locked:
		walk_time += delta * (14.0 if is_sprint_active else 8.5)
		var swing = sin(walk_time) * (0.65 if is_sprint_active else 0.45)
		if left_leg: left_leg.rotation.x = swing
		if right_leg: right_leg.rotation.x = -swing

		visuals.rotation.y = 0.0
		visuals.rotation.z = -input_vec.x * 0.08
		var double_bounce = abs(sin(walk_time))
		visuals.position.y = double_bounce * 0.05
	elif visuals and not is_action_locked:
		walk_time += delta * 1.5
		var idle_breath = sin(walk_time) * 0.015
		visuals.position.y = idle_breath
		visuals.rotation.y = 0.0
		visuals.rotation.z = lerp_angle(visuals.rotation.z, 0.0, delta * 10.0)
		if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, delta * 10.0)
		if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, delta * 10.0)

	# Upper body arms & helmet holding logic
	if not is_in_space_suit and not is_action_locked:
		var breath = sin(walk_time * 1.5) * 0.015
		var arm_target_l = Vector3(0.72 + breath, 0.22, 0.42)
		var arm_target_r = Vector3(0.72 + breath, -0.22, -0.42)
		if left_arm: left_arm.rotation = left_arm.rotation.lerp(arm_target_l, delta * 12.0)
		if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(arm_target_r, delta * 12.0)
		if helmet and not is_first_person:
			helmet.position = Vector3(HELMET_HELD_POS.x, HELMET_HELD_POS.y + breath * 0.4, HELMET_HELD_POS.z)
			helmet.rotation = HELMET_HELD_ROT
			helmet.visible = true
	elif is_in_space_suit and not is_action_locked:
		if is_in_liquid and input_str > 0.05:
			# Swimming breaststroke / paddle arm animation
			var stroke = sin(walk_time * 1.5)
			if left_arm:
				left_arm.rotation.x = stroke * 0.9
				left_arm.rotation.z = deg_to_rad(25.0) + abs(stroke) * 0.35
			if right_arm and not is_mining:
				right_arm.rotation.x = -stroke * 0.9
				right_arm.rotation.z = -deg_to_rad(25.0) - abs(stroke) * 0.35
		elif input_str > 0.05:
			var swing = sin(walk_time) * (0.65 if is_sprint_active else 0.45)
			if left_arm: left_arm.rotation.x = -swing * 0.8
			if left_arm: left_arm.rotation.z = lerp_angle(left_arm.rotation.z, 0.0, delta * 10.0)
			if right_arm and not is_mining: right_arm.rotation.x = swing * 0.8
			if right_arm: right_arm.rotation.z = lerp_angle(right_arm.rotation.z, 0.0, delta * 10.0)
		else:
			if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3.ZERO, delta * 10.0)
			if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3.ZERO, delta * 10.0)

	# 7. Vertical Velocity / Jetpack / Jump / Swimming
	if is_in_liquid:
		floor_snap_length = 0.0 # Crucial: Disable floor snap so water buoyancy lifts character off ocean bed
		var dist_c = global_position.length()
		var depth = ocean_surface_r - dist_c
		
		# Fluid Buoyancy: floats near surface (depth ~0.3m)
		if depth > 0.35:
			vertical_speed = lerpf(vertical_speed, 2.2, delta * 3.5)
		else:
			vertical_speed = lerpf(vertical_speed, 0.0, delta * 5.0)
			
		# Swimming actions
		if not is_action_locked and (Input.is_action_pressed("jump_thrust") or Input.is_key_pressed(KEY_SPACE)):
			# Swim upwards towards surface / breach shore
			vertical_speed = 4.8
			if fmod(walk_time, 0.45) < delta:
				AudioManager.play("jump", 0.7, -4.0)
		elif not is_action_locked and ((InputMap.has_action("crouch") and Input.is_action_pressed("crouch")) or Input.is_key_pressed(KEY_CTRL)):
			vertical_speed = -3.5 # Dive down
			
		horizontal_vel *= 0.85 # Fluid drag
	elif is_on_floor():
		floor_snap_length = 0.85
		vertical_speed = 0.0
		if not is_action_locked and Input.is_action_just_pressed("jump_thrust"):
			vertical_speed = jump_velocity
			AudioManager.play("jump", 1.0)
	else:
		if not is_action_locked and Input.is_action_pressed("jump_thrust") and GameManager.player_stats.fuel > 0.0:
			vertical_speed += jetpack_accel * delta
			vertical_speed = min(vertical_speed, 12.0)
			GameManager.player_stats.fuel = max(0.0, GameManager.player_stats.fuel - 18.0 * delta)
			if fmod(walk_time, 0.25) < delta:
				AudioManager.play("thruster", 1.0, -8.0)
		else:
			vertical_speed -= gravity_val * delta
			vertical_speed = max(vertical_speed, -25.0)

	velocity = horizontal_vel + up_dir * vertical_speed
	move_and_slide()

	# Ceiling Collision Detection: Stop upward speed immediately if ceiling touched
	if is_on_ceiling() and vertical_speed > 0.0:
		vertical_speed = 0.0
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if col.get_normal().dot(up_dir) < -0.35 and vertical_speed > 0.0:
			vertical_speed = 0.0
			break

	# 8. Nearby Interactables Scan & Mining
	check_nearby_interactables()

	if is_mining and nearby_interactable and current_interactable_type == "mine":
		nearby_interactable.mine_tick(delta)
		_draw_laser(nearby_interactable.global_position)
		AudioManager.start_laser_loop()
	else:
		laser_mesh.visible = false
		AudioManager.stop_laser_loop()

	stats_changed.emit(GameManager.player_stats.oxygen, GameManager.player_stats.fuel, GameManager.player_stats.hull)

func check_nearby_interactables() -> void:
	# 1. Spaceship Hatch Interaction (Open / Close)
	var ship = get_tree().get_first_node_in_group("spaceship")
	if ship and ship.has_method("get_hatch_interaction_state"):
		var h_state = ship.get_hatch_interaction_state(self)
		if h_state != "":
			if nearby_interactable != ship or current_interactable_type != h_state:
				nearby_interactable = ship
				current_interactable_type = h_state
				interaction_available.emit(h_state, ship)
			return

	# 2. Mineable Resource Chunks & Creatures
	var space = get_world_3d().direct_space_state
	var q = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 4.0
	q.shape = sphere
	q.transform = global_transform
	q.collision_mask = 2 | 4
	
	var hits = space.intersect_shape(q, 4)
	if hits.size() > 0:
		for hit in hits:
			var target = hit.get("collider")
			if not target:
				continue
			# Check creatures first
			if target.is_in_group("creatures") and not target.get("is_dead"):
				var act_type = "attack" if target.get("is_aggressive") else "feed"
				if nearby_interactable != target or current_interactable_type != act_type:
					nearby_interactable = target
					current_interactable_type = act_type
					interaction_available.emit(act_type, target)
				return
			# Check mineable ores
			elif target.has_method("mine_tick"):
				if nearby_interactable != target or current_interactable_type != "mine":
					nearby_interactable = target
					current_interactable_type = "mine"
					interaction_available.emit("mine", target)
				return

	if nearby_interactable != null:
		nearby_interactable = null
		current_interactable_type = ""
		interaction_lost.emit()

func attack_nearest_target() -> void:
	if is_action_locked:
		return
	AudioManager.play("thruster", 1.8, -2.0)
	var forward = -global_transform.basis.z
	var attack_origin = global_position + up_direction * 0.8
	_draw_laser(attack_origin + forward * 3.0)
	
	var space = get_world_3d().direct_space_state
	var q = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 3.6
	q.shape = sphere
	q.transform = Transform3D(Basis.IDENTITY, attack_origin + forward * 1.5)
	q.collision_mask = 4 # Creature collision layer
	
	var hits = space.intersect_shape(q, 4)
	for hit in hits:
		var col = hit.get("collider")
		if col and col.has_method("take_damage"):
			col.take_damage(35.0)
			break

func _draw_laser(target_pos: Vector3) -> void:
	laser_mesh.visible = true
	var right_hand_pos = right_arm.global_position + global_transform.basis.z * 0.4
	var local_start = to_local(right_hand_pos)
	var local_end = to_local(target_pos)
	
	laser_immediate.clear_surfaces()
	laser_immediate.surface_begin(Mesh.PRIMITIVE_LINES)
	laser_immediate.surface_set_color(Color(0.2, 0.9, 1.0, 1.0))
	laser_immediate.surface_add_vertex(local_start)
	laser_immediate.surface_add_vertex(local_end)
	laser_immediate.surface_end()

func _calc_ground_elevation(dir: Vector3) -> float:
	var planet_node = get_parent().get_node_or_null("SphericalPlanet") if get_parent() else null
	if planet_node and planet_node.has_method("_get_elevation"):
		return planet_node._get_elevation(dir)
	return 0.5

func _die(reason: String) -> void:
	is_dead = true
	is_action_locked = true
	velocity = Vector3.ZERO
	AudioManager.play("click", 0.5, 4.0)
	
	# Ragdoll fall animation
	if visuals:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(visuals, "rotation:z", deg_to_rad(85.0), 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(visuals, "position:y", -0.75, 0.7)
		if left_arm: tw.tween_property(left_arm, "rotation:x", -1.2, 0.5)
		if right_arm: tw.tween_property(right_arm, "rotation:x", 1.4, 0.5)
		if left_leg: tw.tween_property(left_leg, "rotation:x", 0.5, 0.5)
		if right_leg: tw.tween_property(right_leg, "rotation:x", -0.4, 0.5)
		
	var timer = get_tree().create_timer(0.9)
	timer.timeout.connect(func():
		GameManager.game_over.emit(reason)
	)
