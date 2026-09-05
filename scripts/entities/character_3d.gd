extends CharacterBody3D

signal stats_changed(oxygen: float, fuel: float, hull: float)
signal interaction_available(type: String, target_node: Node3D)
signal interaction_lost()

@export var walk_speed: float = 6.0
@export var jump_velocity: float = 6.5
@export var jetpack_accel: float = 12.0
@export var world_wrap_size: float = 40.0 # Bounded round world

# Node references
@onready var head: MeshInstance3D = $Visuals/Head
@onready var helmet: Node3D = $Visuals/Head/Helmet
@onready var hair: MeshInstance3D = $Visuals/Head/Hair
@onready var left_arm: Node3D = $Visuals/LeftArm
@onready var right_arm: Node3D = $Visuals/RightArm
@onready var left_leg: Node3D = $Visuals/LeftLeg
@onready var right_leg: Node3D = $Visuals/RightLeg
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var laser_mesh: MeshInstance3D = $Visuals/LaserMesh

var is_in_space_suit: bool = true
var is_mining: bool = false
var nearby_interactable: Node3D = null
var current_interactable_type: String = ""

var walk_time: float = 0.0
var laser_immediate: ImmediateMesh = ImmediateMesh.new()

# Touch camera rotation state
var cam_yaw: float = 0.0
var cam_pitch: float = -30.0

func _ready() -> void:
	laser_mesh.mesh = laser_immediate
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 0.9, 1.0)
	laser_mesh.material_override = mat
	set_suit_mode(true) # Starts outside

func set_suit_mode(outside: bool) -> void:
	is_in_space_suit = outside
	if helmet:
		helmet.visible = outside
	if hair:
		hair.visible = not outside

func rotate_camera_by(drag_offset: Vector2) -> void:
	cam_yaw -= drag_offset.x * 0.006
	cam_pitch = clamp(cam_pitch - drag_offset.y * 0.006, -70.0, -10.0)
	camera_pivot.rotation.y = cam_yaw
	camera_pivot.rotation.x = deg_to_rad(cam_pitch)

func _physics_process(delta: float) -> void:
	var planet = GameManager.current_planet
	var gravity_val: float = planet.get("gravity", 9.8)

	# 1. Toroidal seamless world wrapping
	var half_w = world_wrap_size
	if position.x > half_w:
		position.x -= half_w * 2.0
	elif position.x < -half_w:
		position.x += half_w * 2.0
		
	if position.z > half_w:
		position.z -= half_w * 2.0
	elif position.z < -half_w:
		position.z += half_w * 2.0

	# 2. Survival vitals (only drain when outside in space suit)
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

	# 3. Movement input relative to camera
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	input_dir = input_dir.normalized()

	var cam_basis = camera_pivot.global_transform.basis
	var cam_fwd = -cam_basis.z
	var cam_rt = cam_basis.x
	cam_fwd.y = 0.0
	cam_rt.y = 0.0
	cam_fwd = cam_fwd.normalized()
	cam_rt = cam_rt.normalized()

	var move_vec = (cam_rt * input_dir.x + cam_fwd * input_dir.y).normalized()

	if move_vec.length() > 0.1:
		velocity.x = move_vec.x * walk_speed
		velocity.z = move_vec.z * walk_speed
		
		# Rotate character body to face movement direction
		var target_angle = atan2(-move_vec.x, -move_vec.z)
		$Visuals.rotation.y = lerp_angle($Visuals.rotation.y, target_angle, delta * 12.0)
		
		# 3D Walk cycle animation
		walk_time += delta * 10.0
		left_leg.rotation.x = sin(walk_time) * 0.6
		right_leg.rotation.x = -sin(walk_time) * 0.6
		left_arm.rotation.x = -sin(walk_time) * 0.5
		right_arm.rotation.x = sin(walk_time) * 0.5
		head.position.y = 1.35 + abs(sin(walk_time)) * 0.08
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0, walk_speed * delta * 8.0)
		left_leg.rotation.x = move_toward(left_leg.rotation.x, 0.0, delta * 4.0)
		right_leg.rotation.x = move_toward(right_leg.rotation.x, 0.0, delta * 4.0)
		left_arm.rotation.x = move_toward(left_arm.rotation.x, 0.0, delta * 4.0)
		right_arm.rotation.x = move_toward(right_arm.rotation.x, 0.0, delta * 4.0)
		head.position.y = move_toward(head.position.y, 1.35, delta * 2.0)

	# 4. Jump & Jetpack
	if Input.is_action_just_pressed("jump_thrust"):
		if is_on_floor():
			velocity.y = jump_velocity
			AudioManager.play("hop", 1.1)
	elif Input.is_action_pressed("jump_thrust"):
		if not is_on_floor() and GameManager.player_stats.fuel > 0.0:
			velocity.y += jetpack_accel * delta
			velocity.y = min(velocity.y, 8.0)
			GameManager.player_stats.fuel = max(0.0, GameManager.player_stats.fuel - 20.0 * delta)
			AudioManager.play("thruster", 1.0, -8.0)

	if not is_on_floor():
		velocity.y -= gravity_val * delta

	move_and_slide()

	# 5. Nearby Interactables Scan (Context-sensitive UX)
	check_nearby_interactables()

	# 6. Mining
	if is_mining and nearby_interactable and current_interactable_type == "mine":
		nearby_interactable.mine_tick(delta)
		_draw_laser(nearby_interactable.global_position + Vector3(0, 0.6, 0))
		AudioManager.start_laser_loop()
	else:
		laser_mesh.visible = false
		AudioManager.stop_laser_loop()

	stats_changed.emit(GameManager.player_stats.oxygen, GameManager.player_stats.fuel, GameManager.player_stats.hull)

func check_nearby_interactables() -> void:
	var space = get_world_3d().direct_space_state
	var q = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 3.2
	q.shape = sphere
	q.transform = global_transform
	q.collision_mask = 2 # Minerals layer
	
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

func _draw_laser(target_world_pos: Vector3) -> void:
	laser_mesh.visible = true
	laser_immediate.clear_surfaces()
	laser_immediate.surface_begin(Mesh.PRIMITIVE_LINES)
	var local_start = to_local(head.global_position + Vector3(0, -0.2, 0))
	var local_end = to_local(target_world_pos)
	laser_immediate.surface_add_vertex(local_start)
	laser_immediate.surface_add_vertex(local_end)
	laser_immediate.surface_end()
