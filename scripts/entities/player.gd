extends CharacterBody3D

signal stats_changed(oxygen: float, fuel: float, hull: float, minerals: int)
signal mining_progress(progress: float)
signal entered_lander()

@export var walk_speed: float = 6.0
@export var sprint_speed: float = 9.0
@export var jump_strength: float = 7.0
@export var jetpack_acceleration: float = 14.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var target_cam_rotation_y: float = 0.0
var cam_tween: Tween

# Paper squish/wobble animation state
var walk_anim_timer: float = 0.0
var is_facing_right: bool = true

# Mining state
var is_mining: bool = false
var mining_target: Node3D = null
var current_mine_progress: float = 0.0

func _ready() -> void:
	target_cam_rotation_y = camera_pivot.rotation.y
	# Connect to GameManager planet updates
	stats_changed.emit(GameManager.player_stats.oxygen, GameManager.player_stats.fuel, GameManager.player_stats.hull, GameManager.player_stats.minerals_collected)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_cam_left"):
		rotate_camera(-PI / 4.0) # 45 degrees left
	elif event.is_action_pressed("rotate_cam_right"):
		rotate_camera(PI / 4.0)  # 45 degrees right

func rotate_camera(angle_delta: float) -> void:
	target_cam_rotation_y += angle_delta
	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()
	cam_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cam_tween.tween_property(camera_pivot, "rotation:y", target_cam_rotation_y, 0.25)

func _physics_process(delta: float) -> void:
	var planet = GameManager.current_planet
	var gravity_val: float = planet.get("gravity", 9.8)
	
	# Environmental survival drain
	process_survival_vitals(delta, planet)
	
	# Check for game over
	if GameManager.player_stats.oxygen <= 0.0 or GameManager.player_stats.hull <= 0.0:
		GameManager.game_over.emit("Vital systems offline. Survival failed.")
		set_physics_process(false)
		return

	# Handle Camera-relative movement
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	input_dir = input_dir.normalized()
	
	# Transform input relative to camera yaw
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
		
		# Paper Mario paper wobble & facing
		walk_anim_timer += delta * 12.0
		var wobble = sin(walk_anim_timer) * 0.12
		sprite.rotation.z = wobble
		sprite.scale.y = 1.0 + abs(wobble) * 0.5
		
		if is_on_floor() and fmod(walk_anim_timer, PI) < 0.2:
			AudioManager.play("hop", 1.2)
		
		# Determine facing based on screen space right/left
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

	# Vertical / Gravity & Jetpack
	if Input.is_action_pressed("jump_thrust"):
		if GameManager.player_stats.fuel > 0.0:
			velocity.y += jetpack_acceleration * delta
			velocity.y = min(velocity.y, 8.0)
			# Drain fuel
			var fuel_drain_rate = 18.0 * (gravity_val / 9.8)
			GameManager.player_stats.fuel = max(0.0, GameManager.player_stats.fuel - fuel_drain_rate * delta)
			# Paper stretch effect when jetpacking
			sprite.scale.y = 1.25
			sprite.scale.x = 0.85
	else:
		if not is_on_floor():
			velocity.y -= gravity_val * delta
		else:
			if velocity.y < 0:
				velocity.y = 0.0

	move_and_slide()
	
	# Process Mining
	process_mining(delta)
	
	# Emit stats
	stats_changed.emit(
		GameManager.player_stats.oxygen,
		GameManager.player_stats.fuel,
		GameManager.player_stats.hull,
		GameManager.player_stats.minerals_collected
	)

func process_survival_vitals(delta: float, planet: Dictionary) -> void:
	# Oxygen drain
	if not planet.get("has_oxygen", false):
		var o2_drain = 1.2 * (planet.get("atmosphere", 1.0))
		GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - o2_drain * delta)
	
	# Temperature hazard
	var temp = planet.get("temperature", 20.0)
	if temp > 100.0:
		# Extreme heat
		var heat_damage = (temp - 100.0) * 0.03
		GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - heat_damage * delta)
	elif temp < -50.0:
		# Extreme cold drains suit battery / heat
		var cold_damage = abs(temp + 50.0) * 0.025
		GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - cold_damage * delta)

func process_mining(delta: float) -> void:
	# Raycast forward or check nearby area for crystals
	if Input.is_action_pressed("jump_thrust"):
		return
		
	# Find closest mineable crystal in range 3.0 meters
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.8
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 2 # Mineral layer
	
	var results = space_state.intersect_shape(query, 1)
	if results.size() > 0:
		var target = results[0]["collider"]
		if target and target.has_method("mine"):
			current_mine_progress += delta * 1.5
			mining_progress.emit(min(current_mine_progress, 1.0))
			if fmod(current_mine_progress * 4.0, 1.0) < 0.15:
				AudioManager.play("mine", 1.0 + current_mine_progress)
			if current_mine_progress >= 1.0:
				target.mine()
				AudioManager.play("collect")
				GameManager.player_stats.minerals_collected += target.mineral_value
				current_mine_progress = 0.0
				mining_progress.emit(0.0)
				# Small bounce animation
				var tween = create_tween()
				tween.tween_property(sprite, "scale", Vector3(1.3, 0.7, 1.0), 0.08)
				tween.tween_property(sprite, "scale", Vector3.ONE, 0.1)
	else:
		if current_mine_progress > 0.0:
			current_mine_progress = 0.0
			mining_progress.emit(0.0)
