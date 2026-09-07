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
@onready var visuals: Node3D = $Visuals
@onready var head: MeshInstance3D = $Visuals/Head
@onready var helmet: Node3D = $Visuals/Head/Helmet
@onready var hair: MeshInstance3D = $Visuals/Head/Hair
@onready var left_arm: Node3D = $Visuals/LeftArm
@onready var right_arm: Node3D = $Visuals/RightArm
@onready var left_leg: Node3D = $Visuals/LeftLeg
@onready var right_leg: Node3D = $Visuals/RightLeg
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var laser_mesh: MeshInstance3D = $Visuals/LaserMesh

var is_in_space_suit: bool = true
var is_mining: bool = false
var is_first_person: bool = false
var nearby_interactable: Node3D = null
var current_interactable_type: String = ""

var walk_time: float = 0.0
var vertical_speed: float = 0.0
var laser_immediate: ImmediateMesh = ImmediateMesh.new()

# Touch & Mouse camera rotation & zoom state
var cam_yaw: float = 0.0
var cam_pitch: float = 0.0
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var target_zoom: float = 4.0
var current_zoom: float = 4.0
const MIN_ZOOM: float = 0.0 # 0.0 is true First-Person Jarvis mode
const MAX_ZOOM: float = 20.0 # Orbit overview
const FPS_THRESHOLD: float = 0.8

func _ready() -> void:
	laser_mesh.mesh = laser_immediate
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 0.9, 1.0)
	laser_mesh.material_override = mat
	set_suit_mode(true)
	_check_fps_mode()

func set_suit_mode(outside: bool) -> void:
	is_in_space_suit = outside
	if helmet:
		helmet.visible = outside and not is_first_person
	if hair:
		hair.visible = not outside and not is_first_person

func rotate_camera_by(drag_offset: Vector2) -> void:
	var min_pitch = -75.0 if is_first_person else -30.0
	var max_pitch = 75.0 if is_first_person else 65.0
	target_yaw -= drag_offset.x * 0.005
	target_pitch = clamp(target_pitch + drag_offset.y * 0.005, min_pitch, max_pitch)

func toggle_first_person() -> void:
	if is_first_person:
		target_zoom = 4.0
	else:
		target_zoom = 0.0
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

	# Smooth camera damping
	cam_yaw = lerp_angle(cam_yaw, target_yaw, delta * 24.0)
	cam_pitch = lerp(cam_pitch, target_pitch, delta * 24.0)
	camera_pivot.rotation.y = cam_yaw
	camera_pivot.rotation.x = deg_to_rad(cam_pitch)

	# Smooth zoom interpolation
	current_zoom = lerp(current_zoom, target_zoom, delta * 12.0)
	if is_first_person:
		camera.position = Vector3(0, 0.15, 0.05)
		camera.rotation = Vector3.ZERO
		camera.fov = lerp(camera.fov, 80.0, delta * 12.0)
	else:
		camera.position = Vector3(0, 0.6, current_zoom)
		camera.rotation = Vector3(deg_to_rad(15.0), 0, 0)
		camera.fov = lerp(camera.fov, 55.0, delta * 12.0)

	# Align character's local Y basis to point radially outwards from planet center
	var cur_up = global_transform.basis.y
	if cur_up.cross(up_dir).length() > 0.001:
		var rot_axis = cur_up.cross(up_dir).normalized()
		var rot_angle = cur_up.angle_to(up_dir)
		global_rotate(rot_axis, rot_angle)

	# 2. Survival vitals
	if is_in_space_suit:
		if not planet.get("has_oxygen", false):
			GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - 1.2 * delta)
		var temp = planet.get("temperature", 20.0)
		if temp > 90.0:
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - (temp - 90.0) * 0.03 * delta)
		elif temp < -40.0:
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - abs(temp + 40.0) * 0.02 * delta)

	if GameManager.player_stats.oxygen <= 0.0 or GameManager.player_stats.hull <= 0.0:
		GameManager.game_over.emit("Sistemas vitales agotados.")
		set_physics_process(false)
		return

	# 3. Movement input projected onto the spherical tangent plane
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var input_fwd = -input_vec.y # W/stick up gives +1.0 forward
	var input_str = input_vec.length()

	var cam_basis = camera_pivot.global_transform.basis
	var cam_fwd = -cam_basis.z
	# Project forward onto spherical tangent plane
	cam_fwd = (cam_fwd - up_dir * cam_fwd.dot(up_dir)).normalized()
	var cam_rt = cam_fwd.cross(up_dir).normalized()

	var move_tangent = Vector3.ZERO
	if input_str > 0.05:
		move_tangent = (cam_rt * input_vec.x + cam_fwd * input_fwd).normalized()

	# Horizontal speed along planet surface
	var horizontal_vel = Vector3.ZERO
	if move_tangent.length() > 0.1:
		horizontal_vel = move_tangent * (walk_speed * min(1.0, input_str))
		
		# Rotate visuals locally to face move direction
		var local_move = to_local(global_position + move_tangent).normalized()
		var target_yaw = atan2(-local_move.x, -local_move.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, delta * 14.0)
		
		# Walk animation
		walk_time += delta * 11.0
		left_leg.rotation.x = sin(walk_time) * 0.6
		right_leg.rotation.x = -sin(walk_time) * 0.6
		left_arm.rotation.x = -sin(walk_time) * 0.5
		right_arm.rotation.x = sin(walk_time) * 0.5
		head.position.y = 1.5 + abs(sin(walk_time)) * 0.08
	else:
		if is_first_person:
			visuals.rotation.y = lerp_angle(visuals.rotation.y, cam_yaw + PI, delta * 14.0)
		left_leg.rotation.x = move_toward(left_leg.rotation.x, 0.0, delta * 5.0)
		right_leg.rotation.x = move_toward(right_leg.rotation.x, 0.0, delta * 5.0)
		left_arm.rotation.x = move_toward(left_arm.rotation.x, 0.0, delta * 5.0)
		right_arm.rotation.x = move_toward(right_arm.rotation.x, 0.0, delta * 5.0)
		head.position.y = move_toward(head.position.y, 1.5, delta * 3.0)

	# 4. Vertical Velocity / Radial Jump & Jetpack
	var on_ground = is_on_floor()
	if not on_ground:
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			if col.get_normal().dot(up_dir) > 0.35:
				on_ground = true
				break

	if on_ground:
		if vertical_speed < 0.0:
			vertical_speed = 0.0
		if Input.is_action_just_pressed("jump_thrust"):
			vertical_speed = jump_velocity
			AudioManager.play("hop", 1.1)
	else:
		if Input.is_action_pressed("jump_thrust") and GameManager.player_stats.fuel > 0.0:
			vertical_speed += jetpack_accel * delta
			vertical_speed = min(vertical_speed, 9.5)
			GameManager.player_stats.fuel = max(0.0, GameManager.player_stats.fuel - 20.0 * delta)
			if fmod(Time.get_ticks_msec(), 220) < 40:
				AudioManager.play("thruster", 1.0, -8.0)
		else:
			vertical_speed -= gravity_val * delta
			vertical_speed = max(vertical_speed, -25.0)

	# Combine spherical tangent velocity + radial vertical velocity
	velocity = horizontal_vel + up_dir * vertical_speed
	move_and_slide()

	# 5. Nearby Interactables Scan (Context UX)
	check_nearby_interactables()

	# 6. Mining
	if is_mining and nearby_interactable and current_interactable_type == "mine":
		nearby_interactable.mine_tick(delta)
		_draw_laser(nearby_interactable.global_position)
		AudioManager.start_laser_loop()
	else:
		laser_mesh.visible = false
		AudioManager.stop_laser_loop()

	stats_changed.emit(GameManager.player_stats.oxygen, GameManager.player_stats.fuel, GameManager.player_stats.hull)

func check_nearby_interactables() -> void:
	var space = get_world_3d().direct_space_state
	var q = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 4.0
	q.shape = sphere
	q.transform = global_transform
	q.collision_mask = 2 | 4 # Minerals & Ship interactables
	
	var hits = space.intersect_shape(q, 1)
	if hits.size() > 0:
		var target = hits[0]["collider"]
		if target and target.has_method("mine_tick"):
			if nearby_interactable != target:
				nearby_interactable = target
				current_interactable_type = "mine"
				interaction_available.emit("mine", target)
			return
		elif target and target.is_in_group("interactable_fabricator"):
			if nearby_interactable != target:
				nearby_interactable = target
				current_interactable_type = "fabricator"
				interaction_available.emit("fabricator", target)
			return
		elif target and target.is_in_group("interactable_hyperdrive"):
			if nearby_interactable != target:
				nearby_interactable = target
				current_interactable_type = "hyperdrive"
				interaction_available.emit("hyperdrive", target)
			return
		elif target and target.is_in_group("interactable_starmap"):
			if nearby_interactable != target:
				nearby_interactable = target
				current_interactable_type = "starmap"
				interaction_available.emit("starmap", target)
			return
		elif target and target.is_in_group("interactable_airlock"):
			if nearby_interactable != target:
				nearby_interactable = target
				current_interactable_type = "airlock"
				interaction_available.emit("airlock", target)
			return

	if nearby_interactable != null:
		nearby_interactable = null
		current_interactable_type = ""
		interaction_lost.emit()

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
