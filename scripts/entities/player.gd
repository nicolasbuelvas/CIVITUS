extends CharacterBody3D

signal stats_changed(oxygen: float, fuel: float, hull: float)
signal mining_state(is_active: bool, progress: float)

@export var walk_speed: float = 6.5
@export var jump_strength: float = 7.0
@export var jetpack_acceleration: float = 14.0
@export var world_wrap_extent: float = 48.0 # Circumnavigation boundary

@onready var sprite: Sprite3D = $Sprite3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var laser_beam: ImmediateMesh = ImmediateMesh.new()
@onready var laser_mesh_instance: MeshInstance3D = $LaserBeamMesh

var target_cam_rotation_y: float = 0.0
var cam_tween: Tween

# Paper squish/wobble animation state
var walk_anim_timer: float = 0.0
var is_mining_input: bool = false
var current_mined_target: Node3D = null

func _ready() -> void:
	target_cam_rotation_y = camera_pivot.rotation.y
	# Setup laser material
	var laser_mat = StandardMaterial3D.new()
	laser_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser_mat.albedo_color = Color(0.2, 0.9, 1.0, 0.9)
	laser_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	laser_mesh_instance.mesh = laser_beam
	laser_mesh_instance.material_override = laser_mat
	laser_mesh_instance.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# PC Controls
	if event.is_action_pressed("rotate_cam_left"):
		rotate_camera(-PI / 4.0)
	elif event.is_action_pressed("rotate_cam_right"):
		rotate_camera(PI / 4.0)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_mining_input = event.pressed
	elif event.is_action("ui_select") and not Input.is_action_pressed("jump_thrust"):
		pass

func rotate_camera(angle_delta: float) -> void:
	target_cam_rotation_y += angle_delta
	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()
	cam_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cam_tween.tween_property(camera_pivot, "rotation:y", target_cam_rotation_y, 0.25)

func _physics_process(delta: float) -> void:
	var planet = GameManager.current_planet
	var gravity_val: float = planet.get("gravity", 9.8)
	
	# Round-World Circumnavigation (Toroidal Wrapping)
	# Walking straight ahead wraps around the planet's circumference
	if position.x > world_wrap_extent:
		position.x -= world_wrap_extent * 2.0
	elif position.x < -world_wrap_extent:
		position.x += world_wrap_extent * 2.0
		
	if position.z > world_wrap_extent:
		position.z -= world_wrap_extent * 2.0
	elif position.z < -world_wrap_extent:
		position.z += world_wrap_extent * 2.0

	# Survival vitals
	process_survival_vitals(delta, planet)
	
	if GameManager.player_stats.oxygen <= 0.0 or GameManager.player_stats.hull <= 0.0:
		GameManager.game_over.emit("Soporte vital agotado en espacio profundo.")
		set_physics_process(false)
		return

	# Movement direction relative to camera yaw
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	input_dir = input_dir.normalized()
	
	var cam_forward = -camera_pivot.global_transform.basis.z
	var cam_right = camera_pivot.global_transform.basis.x
	cam_forward.y = 0.0
	cam_right.y = 0.0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()
	
	var move_vector = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
	
	# Horizontal Velocity
	var speed = walk_speed
	if move_vector.length() > 0.05:
		velocity.x = move_vector.x * speed
		velocity.z = move_vector.z * speed
		
		# Paper Mario paper wobble animation
		walk_anim_timer += delta * 12.0
		var wobble = sin(walk_anim_timer) * 0.12
		sprite.rotation.z = wobble
		sprite.scale.y = 1.0 + abs(wobble) * 0.4
		
		if is_on_floor() and fmod(walk_anim_timer, PI) < 0.2:
			AudioManager.play("hop", 1.2, -6.0)
		
		# Direction facing
		var screen_dot = move_vector.dot(cam_right)
		if screen_dot > 0.1:
			sprite.flip_h = false
		elif screen_dot < -0.1:
			sprite.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 8.0)
		sprite.rotation.z = move_toward(sprite.rotation.z, 0.0, delta * 4.0)
		sprite.scale = sprite.scale.move_toward(Vector3.ONE, delta * 4.0)

	# Vertical / Jetpack & Gravity
	if Input.is_action_pressed("jump_thrust"):
		if GameManager.player_stats.fuel > 0.0:
			velocity.y += jetpack_acceleration * delta
			velocity.y = min(velocity.y, 8.5)
			var fuel_drain = 18.0 * (gravity_val / 9.8)
			GameManager.player_stats.fuel = max(0.0, GameManager.player_stats.fuel - fuel_drain * delta)
			sprite.scale.y = 1.25
			sprite.scale.x = 0.85
			if fmod(Time.get_ticks_msec(), 250) < 50:
				AudioManager.play("thruster", 1.0, -8.0)
	else:
		if not is_on_floor():
			velocity.y -= gravity_val * delta
		else:
			if velocity.y < 0:
				velocity.y = 0.0

	move_and_slide()
	
	# Process Mining Beam
	process_mining(delta)
	
	stats_changed.emit(
		GameManager.player_stats.oxygen,
		GameManager.player_stats.fuel,
		GameManager.player_stats.hull
	)

func process_survival_vitals(delta: float, planet: Dictionary) -> void:
	if not planet.get("has_oxygen", false):
		var o2_drain = 1.2 * (planet.get("atmosphere", 1.0))
		GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - o2_drain * delta)
	
	var temp = planet.get("temperature", 20.0)
	if temp > 100.0:
		var heat_damage = (temp - 100.0) * 0.03
		GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - heat_damage * delta)
	elif temp < -50.0:
		var cold_damage = abs(temp + 50.0) * 0.025
		GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - cold_damage * delta)

func set_mining_active(active: bool) -> void:
	is_mining_input = active

func process_mining(delta: float) -> void:
	var wants_mine = is_mining_input or Input.is_key_pressed(KEY_F)
	
	if wants_mine:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsShapeQueryParameters3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = 4.0
		query.shape = sphere
		query.transform = global_transform
		query.collision_mask = 2 # Mining layer (Ore chunks & crystals)
		
		var results = space_state.intersect_shape(query, 1)
		if results.size() > 0:
			var target = results[0]["collider"]
			if target and target.has_method("mine_tick"):
				current_mined_target = target
				AudioManager.start_laser_loop()
				_render_laser_beam(target.global_position + Vector3(0, 0.6, 0))
				target.mine_tick(delta)
				return
			elif target and target.has_method("mine"):
				# Crystal classic
				current_mined_target = target
				AudioManager.start_laser_loop()
				_render_laser_beam(target.global_position)
				target.mine()
				AudioManager.play("collect")
				GameManager.crafting.add_resource("uranium", 2)
				return
				
	# If no target or not mining
	AudioManager.stop_laser_loop()
	laser_mesh_instance.visible = false
	current_mined_target = null

func _render_laser_beam(target_pos: Vector3) -> void:
	laser_mesh_instance.visible = true
	laser_beam.clear_surfaces()
	laser_beam.surface_begin(Mesh.PRIMITIVE_LINES)
	# Local origin to target
	var start_local = Vector3(0, 0.9, 0)
	var end_local = to_local(target_pos)
	laser_beam.surface_add_vertex(start_local)
	laser_beam.surface_add_vertex(end_local)
	laser_beam.surface_end()
