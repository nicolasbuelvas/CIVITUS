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
@onready var helmet: Node3D = get_node_or_null("Visuals/Head/Helmet")
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
var nearby_interactable: Node3D = null
var current_interactable_type: String = ""

var walk_time: float = 0.0
var vertical_speed: float = 0.0
var laser_immediate: ImmediateMesh = ImmediateMesh.new()

# Orbit camera & zoom state
var cam_yaw: float = 0.0
var cam_pitch: float = 20.0
var target_yaw: float = 0.0
var target_pitch: float = 20.0
var target_zoom: float = 5.2
var current_zoom: float = 5.2
const MIN_ZOOM: float = 0.0
const MAX_ZOOM: float = 16.0
const FPS_THRESHOLD: float = 0.8

func _ready() -> void:
	if laser_mesh:
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
	if face:
		face.visible = not outside and not is_first_person
	if not outside:
		target_zoom = min(target_zoom, 2.5)

func rotate_camera_by(drag_offset: Vector2) -> void:
	# In 3P, clamp min pitch to -15 deg so camera never dips below horizon / terrain
	var min_pitch = -15.0 if not is_first_person else -75.0
	var max_pitch = 75.0
	target_yaw -= drag_offset.x * 0.005
	target_pitch = clamp(target_pitch + drag_offset.y * 0.005, min_pitch, max_pitch)

func toggle_first_person() -> void:
	if is_first_person:
		target_zoom = 4.5
		target_pitch = 15.0
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
	if camera_pivot:
		camera_pivot.rotation.y = cam_yaw
		camera_pivot.rotation.x = deg_to_rad(cam_pitch)

	# 2. Camera Distance & Absolute Anti-Clipping (Raycast + Spherical Horizon Floor)
	current_zoom = lerp(current_zoom, target_zoom, delta * 12.0)
	if is_first_person:
		if camera:
			camera.position = Vector3(0, 0.15, -0.05)
			camera.fov = lerp(camera.fov, 80.0, delta * 12.0)
	else:
		var effective_dist = current_zoom
		if camera_pivot:
			var space = get_world_3d().direct_space_state
			var pivot_pos = camera_pivot.global_position
			var cam_back = camera_pivot.global_transform.basis.z.normalized()
			
			# Physical Raycast check
			var ray_query = PhysicsRayQueryParameters3D.create(pivot_pos, pivot_pos + cam_back * (current_zoom + 0.3), 1)
			ray_query.exclude = [self.get_rid()]
			var hit = space.intersect_ray(ray_query)
			if not hit.is_empty():
				var hit_dist = pivot_pos.distance_to(hit.position)
				effective_dist = max(0.6, hit_dist - 0.25)
				
		if camera:
			camera.position.x = 0.0
			camera.position.y = 0.0
			camera.position.z = lerp(camera.position.z, effective_dist, delta * 18.0)
			camera.fov = lerp(camera.fov, 55.0, delta * 12.0)
			
		# Mathematical Spherical Ground Floor: Camera can NEVER penetrate below planet surface
		if camera:
			var cam_pos = camera.global_position
			var player_r = global_position.length()
			var cam_r = cam_pos.length()
			var min_surface_r = player_r + 0.35
			if cam_r < min_surface_r:
				var cam_up = cam_pos.normalized()
				camera.global_position = cam_pos + cam_up * (min_surface_r - cam_r)

	# 3. Deterministic Surface Orientation (Right-Handed Basis: Right = Fwd x Up)
	var cur_fwd = -global_transform.basis.z
	var tangent_fwd = (cur_fwd - up_dir * cur_fwd.dot(up_dir)).normalized()
	if tangent_fwd.length_squared() < 0.001:
		tangent_fwd = Vector3.FORWARD - up_dir * Vector3.FORWARD.dot(up_dir)
		if tangent_fwd.length_squared() < 0.001:
			tangent_fwd = Vector3.RIGHT - up_dir * Vector3.RIGHT.dot(up_dir)
		tangent_fwd = tangent_fwd.normalized()
		
	# Right vector = Forward x Up (gives +X in standard Godot coordinates)
	var tangent_rt = tangent_fwd.cross(up_dir).normalized()
	# Back vector = Up x Right = -Forward
	var tangent_back = up_dir.cross(tangent_rt).normalized()
	global_transform.basis = Basis(tangent_rt, up_dir, tangent_back).orthonormalized()

	# 4. Movement Input Projected onto Spherical Tangent Plane
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var input_fwd = -input_vec.y # W/stick up gives forward (+1.0)
	var input_str = input_vec.length()

	# Camera relative direction on the spherical surface
	var cam_b = camera_pivot.global_transform.basis if camera_pivot else global_transform.basis
	var cam_fwd = -cam_b.z
	cam_fwd = (cam_fwd - up_dir * cam_fwd.dot(up_dir)).normalized()
	var cam_rt = cam_fwd.cross(up_dir).normalized()

	var move_tangent = Vector3.ZERO
	if input_str > 0.05:
		move_tangent = (cam_rt * input_vec.x + cam_fwd * input_fwd).normalized()

	# 5. Survival Vitals & Oxygen
	var is_sprint_active = is_sprinting or Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("sprint")
	if is_in_space_suit:
		if planet.get("has_oxygen", false):
			GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 45.0 * delta)
		else:
			var o2_drain = 3.8 if (is_sprint_active and input_str > 0.1) else 1.2
			GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - o2_drain * delta)
	
	if GameManager.player_stats.oxygen <= 0.0:
		GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 8.0 * delta)

	# 6. Horizontal Velocity & Procedural Character Facing
	var current_speed = walk_speed * (1.85 if is_sprint_active else 1.0)
	var horizontal_vel = move_tangent * (input_str * current_speed)

	if input_str > 0.05 and visuals:
		walk_time += delta * (14.0 if is_sprint_active else 8.5)
		var swing = sin(walk_time) * (0.65 if is_sprint_active else 0.45)
		if left_leg: left_leg.rotation.x = swing
		if right_leg: right_leg.rotation.x = -swing
		if left_arm: left_arm.rotation.x = -swing * 0.8
		if right_arm and not is_mining: right_arm.rotation.x = swing * 0.8

		# Turn the astronaut body to face move_tangent directly in local coordinates
		var local_move = global_transform.basis.inverse() * move_tangent
		var target_angle = atan2(local_move.x, -local_move.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, delta * 15.0)
		visuals.rotation.z = -local_move.x * 0.10
		var double_bounce = abs(sin(walk_time))
		visuals.position.y = double_bounce * 0.05
	elif visuals:
		walk_time += delta * 1.5
		var idle_breath = sin(walk_time) * 0.015
		visuals.position.y = idle_breath
		visuals.rotation.z = lerp_angle(visuals.rotation.z, 0.0, delta * 10.0)
		if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, delta * 10.0)
		if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, delta * 10.0)
		if left_arm: left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 0.0, delta * 10.0)
		if right_arm and not is_mining: right_arm.rotation.x = lerp_angle(right_arm.rotation.x, 0.0, delta * 10.0)

	# 7. Vertical Velocity / Jetpack / Jump
	if is_on_floor():
		vertical_speed = 0.0
		if Input.is_action_just_pressed("jump_thrust"):
			vertical_speed = jump_velocity
			AudioManager.play("jump", 1.0)
	else:
		if Input.is_action_pressed("jump_thrust") and GameManager.player_stats.fuel > 0.0:
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
	var space = get_world_3d().direct_space_state
	var q = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 4.0
	q.shape = sphere
	q.transform = global_transform
	q.collision_mask = 2 | 4
	
	var hits = space.intersect_shape(q, 1)
	if hits.size() > 0:
		var target = hits[0]["collider"]
		if target and target.has_method("mine_tick"):
			if nearby_interactable != target:
				nearby_interactable = target
				current_interactable_type = "mine"
				interaction_available.emit("mine", target)
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
