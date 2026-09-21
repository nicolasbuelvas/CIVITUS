extends CharacterBody3D

const LandingFXProfile = preload("res://scripts/effects/landing_fx_profile.gd")

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
var was_in_liquid: bool = false
var nearby_interactable: Node3D = null
var current_interactable_type: String = ""
var planet: Dictionary = {}

# Locomotion, Swimming, and Jetpack State
var walk_time: float = 0.0
var vertical_speed: float = 0.0
var can_emergency_spark_jump: bool = true
var is_swimming_manual: bool = false
var is_jetpack_thrusting: bool = false
var swim_time: float = 0.0

# Dynamic Ocean Wave Physics & Staged Water Interactions
var wave_surge_velocity: Vector3 = Vector3.ZERO
var wave_stumble_timer: float = 0.0
var water_impact_timer: float = 0.0
var current_wave_height: float = 0.0
var current_wave_flow: Vector3 = Vector3.ZERO

# Dual Jetpack Thrusters & Twin Particle FX (2 SRC)
var jetpack_left_mesh: Node3D = null
var jetpack_right_mesh: Node3D = null
var flame_particles_left: CPUParticles3D = null
var flame_particles_right: CPUParticles3D = null
var flame_particles: CPUParticles3D = null
var flame_smoke_left: CPUParticles3D = null
var flame_smoke_right: CPUParticles3D = null
var bubble_particles_left: CPUParticles3D = null
var bubble_particles_right: CPUParticles3D = null
var bubble_particles: CPUParticles3D = null
var spark_particles_left: CPUParticles3D = null
var spark_particles_right: CPUParticles3D = null
var spark_particles: CPUParticles3D = null
var splash_particles: CPUParticles3D = null
var jetpack_light: OmniLight3D = null

# Thermal and Fluid Suit Materials & Particle FX
var active_suit_material: StandardMaterial3D = null
var suit_effect_intensity: float = 0.0

var laser_immediate: ImmediateMesh = ImmediateMesh.new()
var is_action_locked: bool = false

# Orbit camera & zoom state
var cam_yaw: float = 0.0
var cam_pitch: float = 0.0
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var target_zoom: float = 0.0
var current_zoom: float = 0.0
var was_cam_underwater: bool = false
var cam_submersion_anim_t: float = 0.0
var cam_base_fwd: Vector3 = Vector3.FORWARD
var current_facing: Vector3 = Vector3.FORWARD
const MIN_ZOOM: float = 0.0
const MAX_ZOOM: float = 16.0
const FPS_THRESHOLD: float = 0.8
const HELMET_HEAD_POS: Vector3 = Vector3(0, 1.6, 0)
const HELMET_HELD_POS: Vector3 = Vector3(0, 0.95, -0.36)
const HELMET_HELD_ROT: Vector3 = Vector3(0.35, 0, 0)
const HELMET_HIP_POS: Vector3 = Vector3(-0.38, 0.78, 0.05)
const HELMET_HIP_ROT: Vector3 = Vector3(0.2, 0.3, 0.45)
const HELMET_HIP_R_POS: Vector3 = Vector3(0.38, 0.78, 0.05)
const HELMET_HIP_R_ROT: Vector3 = Vector3(0.2, -0.3, -0.45)
const LEFT_ARM_HELD_ROT: Vector3 = Vector3(0.72, 0.22, 0.42)
const RIGHT_ARM_HELD_ROT: Vector3 = Vector3(0.72, -0.22, -0.42)

func get_occupied_hands_count() -> int:
	if not is_instance_valid(GameManager) or not GameManager.crafting:
		return 0
	var count = 0
	var b_slots = GameManager.crafting.body_slots
	if b_slots.get("hand_left", {}).get("count", 0) > 0:
		count += 1
	if b_slots.get("hand_right", {}).get("count", 0) > 0:
		count += 1
	return count

# Surface Swimming State
var is_surface_swimming: bool = false

var underwater_screen_overlay: ColorRect = null

func _ready() -> void:
	if laser_mesh:
		laser_mesh.mesh = laser_immediate
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 0.9, 1.0)
		laser_mesh.material_override = mat
	if camera_pivot:
		camera_pivot.top_level = true
	_setup_suit_materials()
	_setup_fluid_and_jetpack_particles()
	_setup_underwater_overlay()
	_setup_body_attachment_props()
	set_suit_mode(true)
	_check_fps_mode()

func _setup_underwater_overlay() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "UnderwaterCanvas"
	canvas.layer = 105
	add_child(canvas)
	
	underwater_screen_overlay = ColorRect.new()
	underwater_screen_overlay.name = "UnderwaterOverlay"
	underwater_screen_overlay.anchors_preset = Control.PRESET_FULL_RECT
	underwater_screen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underwater_screen_overlay.color = Color(0.04, 0.28, 0.65, 0.0)
	underwater_screen_overlay.visible = false
	canvas.add_child(underwater_screen_overlay)

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
		if not outside:
			if left_arm: left_arm.rotation = LEFT_ARM_HELD_ROT
			if right_arm and not is_mining: right_arm.rotation = RIGHT_ARM_HELD_ROT

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
	var hands_occ = get_occupied_hands_count()
	if helmet and not is_first_person:
		helmet.visible = true
		if hands_occ >= 2:
			# Both hands occupied: automated suit collar pops and helmet docks directly to magnetic hip clip
			var tw = create_tween().set_parallel(true)
			tw.tween_property(helmet, "position", Vector3(-0.18, 1.45, 0.15), 0.25)
			tw.chain().tween_property(helmet, "position", HELMET_HIP_POS, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(helmet, "rotation", HELMET_HIP_ROT, 0.35)
			if face: face.visible = true
			AudioManager.play("click", 1.1)
		elif hands_occ == 1:
			# One hand occupied: free hand unlatches helmet and rests it on side hip
			var has_left = GameManager.crafting.body_slots.get("hand_left", {}).get("count", 0) > 0
			var target_pos = HELMET_HIP_R_POS if has_left else HELMET_HIP_POS
			var target_rot = HELMET_HIP_R_ROT if has_left else HELMET_HIP_ROT
			var free_arm = right_arm if has_left else left_arm
			var tw = create_tween().set_parallel(true)
			if free_arm:
				tw.tween_property(free_arm, "rotation:x", 1.7, 0.3)
			tw.chain().tween_property(helmet, "position", target_pos, 0.35)
			tw.tween_property(helmet, "rotation", target_rot, 0.35)
			if free_arm:
				tw.chain().tween_property(free_arm, "rotation", Vector3(0.5, 0.0, 0.1), 0.3)
			if face: face.visible = true
			AudioManager.play("click", 1.1)
		else:
			# Both hands free: normal 2-handed helmet removal to chest
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
	if is_instance_valid(GameManager) and (GameManager.current_planet.size() > 0 or planet.is_empty()):
		planet = GameManager.current_planet
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

	# Synchronize camera orientation and facing with diurnal planetary rotation
	var day_len = float(planet.get("day_length", 1200.0))
	var rot_d_angle = (TAU / maxf(10.0, day_len)) * delta
	cam_base_fwd = cam_base_fwd.rotated(Vector3.UP, rot_d_angle)
	current_facing = current_facing.rotated(Vector3.UP, rot_d_angle)

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
			
		# Mathematical Spherical Ground Floor: Camera stops at SOLID ROCK TERRAIN floor (not water level)
		if camera:
			var cam_pos = camera.global_position
			var cam_dir = cam_pos.normalized()
			var ground_elev = _calc_ground_elevation(cam_dir)
			var min_surface_r = planet_radius + ground_elev + 0.65
			if cam_pos.length() < min_surface_r:
				camera.global_position = cam_dir * min_surface_r
				
		# Anti-clipping: hide head if 3P camera is pushed closer than 1.1m
		if head:
			head.visible = (effective_dist >= 1.1)

	# Dynamic Camera Submersion Transition & Audio Reaction (underwater camera dive/surface)
	if camera:
		var cam_rad = camera.global_position.length()
		var p_parent = get_parent()
		var cur_sea_r = planet_radius
		if p_parent and p_parent.has_method("get_ocean_surface_radius"):
			cur_sea_r = p_parent.get_ocean_surface_radius()
		var has_liq = str(planet.get("water_status", "Seco / Desolado")) != "Seco / Desolado" and str(planet.get("water_status", "")) != ""
		var is_cam_submerged = has_liq and (cam_rad < cur_sea_r)
		
		if is_cam_submerged != was_cam_underwater:
			was_cam_underwater = is_cam_submerged
			cam_submersion_anim_t = 0.50 # 500ms dynamic optical dive reaction
			if is_cam_submerged:
				AudioManager.play("splash", 0.85, -4.0)
				AudioManager.play("bubbles", 1.0, -1.0)
			else:
				AudioManager.play("splash", 0.90, 3.0)
				
		if cam_submersion_anim_t > 0.0:
			cam_submersion_anim_t = maxf(0.0, cam_submersion_anim_t - delta)
			var sub_pulse = sin((cam_submersion_anim_t / 0.50) * PI)
			# Fluid dive optical FOV distortion pulse & vertical refractive displacement
			camera.fov += sub_pulse * 4.5
			camera.position.y -= sub_pulse * 0.08

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
	
	# Liquid Ocean / Hydro Basin Immersion (Dynamic Tides & Hitbox Calibration)
	var ocean_surface_r = planet_radius
	var p_node = get_parent()
	if p_node and p_node.has_method("get_ocean_surface_radius"):
		ocean_surface_r = p_node.get_ocean_surface_radius()
	elif GameManager.current_planet.has("radius"):
		ocean_surface_r = float(GameManager.current_planet.get("radius", 160.0))

	var dist_from_center = global_position.length()
	var has_planetary_liquid = str(planet.get("water_status", "Seco / Desolado")) != "Seco / Desolado" and str(planet.get("water_status", "")) != ""
	# Real fluid immersion: astronaut interacts with fluid whenever submerged
	is_in_liquid = has_planetary_liquid and (dist_from_center < (ocean_surface_r + 0.10))
	
	# Detect surface transition: spawn fluid splash strictly when crossing the liquid threshold
	if is_in_liquid != was_in_liquid:
		var dist_to_surface = absf(dist_from_center - ocean_surface_r)
		if has_planetary_liquid and dist_to_surface < 0.65:
			_trigger_liquid_splash(planet)
			if is_in_liquid and vertical_speed < -3.0:
				water_impact_timer = 0.55
				vertical_speed *= 0.35 # Fluid cushions high impact fall
		was_in_liquid = is_in_liquid
		
	# Physical Ocean Waves: only applies when actively swimming in fluid, NEVER pushing stationary player on solid land
	if is_in_liquid and not is_on_floor():
		var norm_pos = global_position.normalized()
		var wave_t = walk_time * 0.038
		var w1 = sin(norm_pos.x * 28.0 + norm_pos.y * 22.0 + wave_t * 4.0) * 0.45
		var w2 = cos(norm_pos.z * 32.0 + norm_pos.x * 18.0 - wave_t * 3.5) * 0.35
		var w3 = sin(norm_pos.y * 42.0 - norm_pos.z * 26.0 + wave_t * 5.2) * 0.20
		var local_wave_factor = w1 + w2 + w3
		current_wave_height = local_wave_factor * 0.35
		
		var wave_t1 = Vector3(-norm_pos.z, 0.0, norm_pos.x).slide(up_dir).normalized()
		var wave_t2 = Vector3(norm_pos.y, -norm_pos.x, 0.0).slide(up_dir).normalized()
		current_wave_flow = (wave_t1 * w1 + wave_t2 * w2) * 2.2
		wave_surge_velocity = wave_surge_velocity.lerp(current_wave_flow * 0.45, delta * 3.5)
	else:
		current_wave_height = 0.0
		current_wave_flow = Vector3.ZERO
		wave_surge_velocity = wave_surge_velocity.lerp(Vector3.ZERO, delta * 8.0)
		if is_on_floor() or not is_in_liquid:
			wave_surge_velocity = Vector3.ZERO

	water_impact_timer = maxf(0.0, water_impact_timer - delta)
	wave_stumble_timer = maxf(0.0, wave_stumble_timer - delta)
		
	_update_suit_thermal_and_fluid_reactions(delta, planet)
	
	if is_in_liquid:
		var submersion_depth = ocean_surface_r - dist_from_center
		var water_stat = str(planet.get("water_status", ""))
		var chem = str(planet.get("ocean_chemical", ""))
		var is_molten = planet.get("is_molten", false) or water_stat == "Lava Fundida" or chem == "magma"
		var is_acid = water_stat == "Vapor Tóxico" or chem == "sulfuric_acid"
		var is_cryo = water_stat == "Hielo Criogénico" or chem == "methane"
		
		if is_molten:
			# Magma Ocean + Thermal Wave Surge: Severe burning of suit hull
			var wave_burn = 38.0 + maxf(0.0, current_wave_height) * 25.0
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - wave_burn * delta)
		elif is_acid:
			# Sulfuric Acid Ocean + Corrosive Chemical Wave: Acid damage to suit
			var wave_acid = 28.0 + maxf(0.0, current_wave_height) * 20.0
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - wave_acid * delta)
		elif is_cryo:
			# Cryogenic Methane Ocean: Subzero freezing
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 22.0 * delta)
		elif not has_oxygen_atmo and planet_temp > 70.0:
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 18.0 * delta)

	# Oxygen Consumption Calculation
	var head_dist = dist_from_center + 1.55 # Helmet center is ~1.55m above astronaut feet
	var is_head_submerged = has_planetary_liquid and (head_dist < ocean_surface_r)
	var is_head_above_water = not has_planetary_liquid or (head_dist >= ocean_surface_r)

	if is_in_space_suit:
		if has_oxygen_atmo and is_head_above_water:
			# Respires breathable atmosphere whenever head is above the water line!
			GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 45.0 * delta)
		else:
			# Submerged underwater or unbreathable atmosphere: consumes oxygen tank
			var o2_drain = 1.2
			if is_head_submerged:
				o2_drain = 2.5 # Submerged breathing resistance
				if is_swimming_manual:
					o2_drain += 3.8
				if is_sprint_active and input_str > 0.1:
					o2_drain += 3.8
			elif is_sprint_active and input_str > 0.1:
				o2_drain = 3.8
			GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - o2_drain * delta)
	
	if GameManager.player_stats.oxygen <= 0.0:
		GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 12.0 * delta)

	# Physical Death Sequence
	if GameManager.player_stats.hull <= 0.0 and not is_dead:
		var death_reason = GameManager.loc("game_over_reason_hazard") if is_in_liquid and not has_oxygen_atmo else (
			GameManager.loc("game_over_reason_o2") if GameManager.player_stats.oxygen <= 0.0 else GameManager.loc("game_over_reason_hull")
		)
		_die(death_reason)

	# 6. Locomotion, Underwater Walking, Jetpack & Swimming
	var is_jump_pressed = not is_action_locked and (Input.is_action_pressed("jump_thrust") or Input.is_key_pressed(KEY_SPACE))
	var is_jump_just_pressed = not is_action_locked and (Input.is_action_just_pressed("jump_thrust") or Input.is_key_pressed(KEY_SPACE))
	var is_crouch_pressed = not is_action_locked and ((InputMap.has_action("crouch") and Input.is_action_pressed("crouch")) or Input.is_key_pressed(KEY_CTRL))

	var current_speed = walk_speed * (1.85 if is_sprint_active else 1.0)
	var horizontal_vel = move_tangent * (input_str * current_speed)

	# Touching solid floor (either on dry land or on the seabed) primes emergency spark jump
	if is_on_floor():
		can_emergency_spark_jump = true

	# --- JETPACK NORMAL (cuando tiene combustible) ---
	if is_jump_pressed and GameManager.player_stats.fuel > 0.0:
		is_jetpack_thrusting = true
		vertical_speed += jetpack_accel * delta
		vertical_speed = min(vertical_speed, 14.0)
		GameManager.player_stats.fuel = max(0.0, GameManager.player_stats.fuel - 18.0 * delta)
		is_surface_swimming = false

		if is_in_liquid:
			# Cavitación submarina con burbujas y propulsión normal
			_set_jetpack_flames(false)
			_set_jetpack_bubbles(true)
			is_swimming_manual = true
			if fmod(walk_time, 0.35) < delta:
				AudioManager.play("bubbles", 0.9, 0.0)
		else:
			# Propulsión supersónica atmosférica con llamas
			_set_jetpack_bubbles(false)
			_set_jetpack_flames(true)
			is_swimming_manual = false
			if fmod(walk_time, 0.25) < delta:
				AudioManager.play("thruster", 1.0, -8.0)
	else:
		# Jetpack apagado (sin presionar o sin combustible)
		is_jetpack_thrusting = false
		_set_jetpack_flames(false)
		_set_jetpack_bubbles(false)

		# --- SALTO Y LOCOMOCIÓN SIN JETPACK / SIN COMBUSTIBLE ---
		if is_in_liquid:
			floor_snap_length = 0.85
			var fluid_gravity = gravity_val * 0.62

			if is_on_floor():
				# Tocando fondo marino: salto de impulso disponible
				vertical_speed = 0.0
				is_surface_swimming = false
				is_swimming_manual = false
				if is_jump_just_pressed:
					can_emergency_spark_jump = false
					vertical_speed = jump_velocity * 0.85
					_trigger_emergency_sparks()
					AudioManager.play("flint_jump", 1.1, 2.0)
					AudioManager.play("bubbles", 1.0, 1.0)
			else:
				# En medio del agua: sin flotabilidad, desciende por gravedad al fondo marino
				is_surface_swimming = false
				is_swimming_manual = false
				vertical_speed -= fluid_gravity * delta
				if is_crouch_pressed:
					vertical_speed = min(vertical_speed, -4.5)
				vertical_speed = max(vertical_speed, -12.0)

		elif is_on_floor():
			# En tierra firme
			is_surface_swimming = false
			floor_snap_length = 0.85
			vertical_speed = 0.0
			is_swimming_manual = false

			if is_jump_just_pressed:
				if GameManager.player_stats.fuel > 0.0:
					vertical_speed = jump_velocity
					AudioManager.play("jump", 1.0)
				elif can_emergency_spark_jump:
					can_emergency_spark_jump = false
					vertical_speed = jump_velocity * 0.85
					AudioManager.play("flint_jump", 1.1, 2.0)
					_trigger_emergency_sparks()

		else:
			# En el aire (airborne)
			is_surface_swimming = false
			is_swimming_manual = false

			if is_jump_just_pressed and GameManager.player_stats.fuel <= 0.0 and can_emergency_spark_jump:
				# Salto de emergencia en el aire sin combustible
				can_emergency_spark_jump = false
				vertical_speed = jump_velocity * 0.85
				AudioManager.play("flint_jump", 1.1, 2.0)
				_trigger_emergency_sparks()
			else:
				# Caída libre / gravedad
				vertical_speed -= gravity_val * delta
				vertical_speed = max(vertical_speed, -25.0)

	if is_in_liquid:
		var liq_density = get_liquid_density()
		var drag_factor = clampf(1.05 / sqrt(liq_density), 0.50, 1.20)
		var is_hopping = prefers_lunar_hopping()
		# En fluidos donde conviene saltar, al correr los saltos más grandes cubren mayor distancia
		var seabed_speed = current_speed * (0.82 if (is_hopping and is_sprint_active) else (0.70 if is_hopping else 0.45)) * drag_factor
		horizontal_vel = move_tangent * (input_str * seabed_speed)
	else:
		# En tierra firme: en baja gravedad los saltitos ("lunar lope") brindan mayor velocidad y tracción
		if is_on_floor() and prefers_lunar_hopping():
			var lope_speed_mult = 1.25 if is_sprint_active else 1.08
			horizontal_vel = move_tangent * (input_str * current_speed * lope_speed_mult)

	# 7. Procedural Limb & Posture Animations (Air, Land, Underwater, Jetpack)
	if not is_action_locked and visuals:
		if is_in_liquid:
			var submersion_depth: float = maxf(0.0, ocean_surface_r - global_position.length())
			var is_deep_water: bool = submersion_depth >= 1.15 and not is_on_floor()
			var is_swimming_active: bool = (is_deep_water and (input_str > 0.05 or is_crouch_pressed)) or is_swimming_manual
			
			# Natural Upright Posture in Fluid: zero forward/backward tilt when entering or staying in water!
			visuals.rotation.x = lerp_angle(visuals.rotation.x, 0.0, delta * 8.0)
			visuals.rotation.z = lerp_angle(visuals.rotation.z, 0.0, delta * 8.0)
			
			if is_surface_swimming:
				# High-Quality Surface Swimming: Head floating above water, arms & legs tread water rítmicamente
				swim_time += delta * (5.8 if input_str > 0.05 else 3.2)
				visuals.rotation.x = lerp_angle(visuals.rotation.x, 0.0, delta * 8.0)
				visuals.rotation.z = lerp_angle(visuals.rotation.z, -input_vec.x * 0.05, delta * 6.0)
				visuals.position.y = 0.0
				
				# Harmonic surface breaststroke / treading arms
				var arm_phase = swim_time
				var arm_swing = sin(arm_phase)
				var arm_pitch = -deg_to_rad(24.0) + arm_swing * deg_to_rad(18.0)
				var arm_spread = deg_to_rad(28.0) + cos(arm_phase) * deg_to_rad(12.0)
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(arm_pitch, 0, arm_spread), delta * 8.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(arm_pitch, 0, -arm_spread), delta * 8.0)
				
				# Scissor flutter kicks under surface
				var kick_left = sin(arm_phase * 2.2) * deg_to_rad(24.0)
				var kick_right = sin(arm_phase * 2.2 + PI) * deg_to_rad(24.0)
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, kick_left, delta * 8.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, kick_right, delta * 8.0)
			elif wave_stumble_timer > 0.0:
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(deg_to_rad(-15.0), 0, deg_to_rad(25.0)), delta * 8.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(deg_to_rad(-15.0), 0, deg_to_rad(-25.0)), delta * 8.0)
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, deg_to_rad(12.0), delta * 8.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, deg_to_rad(12.0), delta * 8.0)
			elif water_impact_timer > 0.0:
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(deg_to_rad(15.0), 0, deg_to_rad(20.0)), delta * 8.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(deg_to_rad(15.0), 0, deg_to_rad(-20.0)), delta * 8.0)
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, deg_to_rad(14.0), delta * 8.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, deg_to_rad(14.0), delta * 8.0)
			elif is_jetpack_thrusting:
				# Vertical Jetpack Ascent through water
				walk_time += delta * 6.0
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, deg_to_rad(12.0), delta * 8.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, deg_to_rad(12.0), delta * 8.0)
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(-deg_to_rad(15.0), 0, deg_to_rad(15.0)), delta * 8.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(-deg_to_rad(15.0), 0, -deg_to_rad(15.0)), delta * 8.0)
			elif is_swimming_active:
				# Upright swimming treading / propulsion
				swim_time += delta * (4.2 if is_sprint_active else 3.0)
				var stroke_phase = swim_time
				var arm_cycle = sin(stroke_phase)
				var arm_pitch = -deg_to_rad(20.0) - arm_cycle * deg_to_rad(16.0)
				var arm_spread = deg_to_rad(16.0) + cos(stroke_phase) * deg_to_rad(10.0)
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(arm_pitch, 0, arm_spread), delta * 8.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(arm_pitch, 0, -arm_spread), delta * 8.0)
				var kick_left = sin(stroke_phase * 2.0) * deg_to_rad(18.0)
				var kick_right = sin(stroke_phase * 2.0 + PI) * deg_to_rad(18.0)
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, kick_left, delta * 8.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, kick_right, delta * 8.0)
			elif is_deep_water:
				# Upright descent through water
				walk_time += delta * 1.8
				visuals.position.y = 0.0
				var gentle_scull = sin(walk_time * 1.6) * 0.08
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, deg_to_rad(10.0) + gentle_scull, delta * 5.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, deg_to_rad(6.0) - gentle_scull, delta * 5.0)
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(deg_to_rad(14.0) + gentle_scull, 0, deg_to_rad(18.0)), delta * 5.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(deg_to_rad(14.0) + gentle_scull, 0, -deg_to_rad(18.0)), delta * 5.0)
			elif input_str > 0.05:
				var liq_density = get_liquid_density()
				var density_t = clampf((liq_density - 0.45) / 2.2, 0.0, 1.0)
				
				if prefers_lunar_hopping():
					# Saltitos submarinos elásticos ("lunar lope" subacuático)
					# Al correr (sprint), saltos notablemente más grandes y zancada más amplia
					var hop_freq = lerpf(4.4, 2.6, density_t) * (1.15 if is_sprint_active else 1.0)
					var base_hop_h = lerpf(0.22, 0.12, density_t)
					var hop_height = base_hop_h * (1.85 if is_sprint_active else 1.0) # Al correr saltos casi el doble de altos (~0.40m en agua/metano!)
					
					walk_time += delta * hop_freq
					var hop_phase = fmod(walk_time, PI)
					var hop_y = sin(hop_phase) * hop_height
					visuals.position.y = hop_y
					
					var forward_lean = deg_to_rad(6.0 if is_sprint_active else 4.0) + (hop_y / maxf(0.01, hop_height)) * deg_to_rad(6.0 if is_sprint_active else 4.0)
					visuals.rotation.x = lerp_angle(visuals.rotation.x, forward_lean, delta * 6.0)
					visuals.rotation.z = -input_vec.x * 0.04
					
					var stride = sin(walk_time) * (0.54 if is_sprint_active else 0.35)
					if left_leg: left_leg.rotation.x = stride
					if right_leg: right_leg.rotation.x = -stride
					
					var arm_spread = deg_to_rad(14.0) + sin(hop_phase) * deg_to_rad(8.0 if is_sprint_active else 4.0)
					if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(-deg_to_rad(10.0), 0, arm_spread), delta * 8.0)
					if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(-deg_to_rad(10.0), 0, -arm_spread), delta * 8.0)
					
					# Burbujas periódicas levantadas en cada saltito en el fondo
					if hop_phase < delta * hop_freq:
						if fmod(walk_time, TAU) < delta * hop_freq * 1.5:
							AudioManager.play("bubbles", 0.75, -2.0)
				else:
					# Magma hiper-denso: vadeo viscoso pesado sin saltitos
					walk_time += delta * (4.5 if is_sprint_active else 2.8)
					visuals.position.y = 0.0
					visuals.rotation.x = lerp_angle(visuals.rotation.x, deg_to_rad(4.0), delta * 6.0)
					var stride = sin(walk_time) * (0.35 if is_sprint_active else 0.22)
					if left_leg: left_leg.rotation.x = stride
					if right_leg: right_leg.rotation.x = -stride
					if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(0.0, 0, deg_to_rad(10.0)), delta * 6.0)
					if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(0.0, 0, -deg_to_rad(10.0)), delta * 6.0)
			else:
				# Upright standing still in fluid
				walk_time += delta * 1.5
				visuals.position.y = 0.0
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, delta * 6.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, delta * 6.0)
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(0.1, 0, 0.12), delta * 6.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(0.1, 0, -0.12), delta * 6.0)
		else:
			# Land / Air Postures
			if is_jetpack_thrusting:
				# 2) Airborne Jetpack Flight Posture
				visuals.rotation.x = lerp_angle(visuals.rotation.x, deg_to_rad(14.0), delta * 6.0)
				visuals.rotation.z = -input_vec.x * 0.10
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, deg_to_rad(22.0), delta * 6.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, deg_to_rad(26.0), delta * 6.0)
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(deg_to_rad(-18.0), 0, deg_to_rad(18.0)), delta * 6.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(deg_to_rad(-18.0), 0, deg_to_rad(-18.0)), delta * 6.0)
			elif not is_in_space_suit:
				# 3) Holding helmet with both hands in front of torso (Image 6: exact natural pose)
				walk_time += delta * (12.0 if input_str > 0.05 else 1.5)
				var breath = sin(walk_time * 1.5) * 0.015
				var swing = sin(walk_time) * 0.35 if input_str > 0.05 else 0.0
				visuals.position.y = abs(sin(walk_time)) * 0.04 if input_str > 0.05 else sin(walk_time) * 0.012
				visuals.rotation.x = lerp_angle(visuals.rotation.x, 0.0, delta * 8.0)
				visuals.rotation.z = -input_vec.x * 0.06 if input_str > 0.05 else 0.0
				if left_leg: left_leg.rotation.x = swing
				if right_leg: right_leg.rotation.x = -swing
				
				var hands_occ = get_occupied_hands_count()
				if hands_occ >= 2:
					# Both hands occupied: holding items forward, helmet docked to magnetic hip clip
					var arm_l = Vector3(0.52 + breath, 0.05, 0.12)
					var arm_r = Vector3(0.52 + breath, -0.05, -0.12)
					if left_arm: left_arm.rotation = left_arm.rotation.lerp(arm_l, delta * 12.0)
					if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(arm_r, delta * 12.0)
					if helmet and not is_first_person:
						helmet.position = HELMET_HIP_POS + Vector3(0, breath * 0.4, 0)
						helmet.rotation = HELMET_HIP_ROT
						helmet.visible = true
				elif hands_occ == 1:
					# One hand occupied: carrying cargo in one hand, helmet on hip by the free hand
					var has_left = GameManager.crafting.body_slots.get("hand_left", {}).get("count", 0) > 0
					if has_left:
						if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(0.52 + breath, 0.05, 0.12), delta * 12.0)
						if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(0.40, -0.15, -0.25), delta * 12.0)
						if helmet and not is_first_person:
							helmet.position = HELMET_HIP_R_POS + Vector3(0, breath * 0.4, 0)
							helmet.rotation = HELMET_HIP_R_ROT
							helmet.visible = true
					else:
						if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(0.40, 0.15, 0.25), delta * 12.0)
						if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(0.52 + breath, -0.05, -0.12), delta * 12.0)
						if helmet and not is_first_person:
							helmet.position = HELMET_HIP_POS + Vector3(0, breath * 0.4, 0)
							helmet.rotation = HELMET_HIP_ROT
							helmet.visible = true
				else:
					# Both hands free: cradling helmet in front of chest
					var arm_target_l = Vector3(0.72 + breath, 0.22, 0.42)
					var arm_target_r = Vector3(0.72 + breath, -0.22, -0.42)
					if left_arm: left_arm.rotation = left_arm.rotation.lerp(arm_target_l, delta * 12.0)
					if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(arm_target_r, delta * 12.0)
					if helmet and not is_first_person:
						helmet.position = Vector3(HELMET_HELD_POS.x, HELMET_HELD_POS.y + breath * 0.4, HELMET_HELD_POS.z)
						helmet.rotation = HELMET_HELD_ROT
						helmet.visible = true
			elif input_str > 0.05:
				if is_on_floor() and prefers_lunar_hopping():
					# Marcha Apolo ("Lunar Loping Stride" del footage histórico de la NASA)
					# En baja gravedad (Luna, Marte, asteroides, lunas heladas): saltitos elásticos
					# Al correr (sprint): ¡saltos notablemente más grandes (~0.46m en el aire)!
					var lope_freq = 5.2 if is_sprint_active else 4.4
					var lope_hop_h = 0.46 if is_sprint_active else 0.22
					
					walk_time += delta * lope_freq
					var hop_phase = fmod(walk_time, PI)
					var hop_y = sin(hop_phase) * lope_hop_h
					visuals.position.y = hop_y
					
					# Inclinación de avance del footage lunar
					var forward_lean = deg_to_rad(12.0 if is_sprint_active else 6.0)
					visuals.rotation.x = lerp_angle(visuals.rotation.x, forward_lean, delta * 8.0)
					visuals.rotation.z = -input_vec.x * 0.06
					
					# Zancada lunar suspendida en el aire
					var stride = sin(walk_time) * (0.60 if is_sprint_active else 0.40)
					if left_leg: left_leg.rotation.x = stride
					if right_leg: right_leg.rotation.x = -stride
					
					# Brazos en abducción espacial balanceando el salto
					var arm_pitch = -deg_to_rad(8.0) - sin(walk_time) * deg_to_rad(14.0 if is_sprint_active else 8.0)
					var arm_spread = deg_to_rad(20.0 if is_sprint_active else 15.0)
					if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3(arm_pitch, 0, arm_spread), delta * 8.0)
					if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3(-arm_pitch, 0, -arm_spread), delta * 8.0)
				else:
					# Planetas de gravedad normal/alta (Tierra, mundos densos): marcha terrestre tradicional paso a paso
					walk_time += delta * (14.0 if is_sprint_active else 8.5)
					var swing = sin(walk_time) * (0.65 if is_sprint_active else 0.45)
					visuals.rotation.x = lerp_angle(visuals.rotation.x, 0.0, delta * 8.0)
					visuals.rotation.z = -input_vec.x * 0.08
					visuals.position.y = abs(sin(walk_time)) * 0.05
					if left_leg: left_leg.rotation.x = swing
					if right_leg: right_leg.rotation.x = -swing
					if left_arm: left_arm.rotation = Vector3(-swing * 0.8, 0, 0)
					if right_arm and not is_mining: right_arm.rotation = Vector3(swing * 0.8, 0, 0)
			else:
				walk_time += delta * 1.5
				var idle_breath = sin(walk_time) * 0.015
				visuals.position.y = idle_breath
				visuals.rotation.x = lerp_angle(visuals.rotation.x, 0.0, delta * 8.0)
				visuals.rotation.z = lerp_angle(visuals.rotation.z, 0.0, delta * 10.0)
				if left_leg: left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, delta * 10.0)
				if right_leg: right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, delta * 10.0)
				if left_arm: left_arm.rotation = left_arm.rotation.lerp(Vector3.ZERO, delta * 10.0)
				if right_arm and not is_mining: right_arm.rotation = right_arm.rotation.lerp(Vector3.ZERO, delta * 10.0)

	# Dynamic Fullscreen Fluid Submersion Overlay
	if underwater_screen_overlay:
		if was_cam_underwater:
			underwater_screen_overlay.visible = true
			var water_stat = str(planet.get("water_status", ""))
			var is_molten = planet.get("is_molten", false) or water_stat == "Lava Fundida"
			var is_acid = water_stat == "Vapor Tóxico"
			var is_cryo = water_stat == "Hielo Criogénico"
			
			var target_tint = Color(0.04, 0.35, 0.75, 0.32)
			if is_molten:
				target_tint = Color(0.95, 0.25, 0.05, 0.52)
			elif is_acid:
				target_tint = Color(0.40, 0.68, 0.10, 0.40)
			elif is_cryo:
				target_tint = Color(0.12, 0.52, 0.85, 0.35)
				
			underwater_screen_overlay.color = underwater_screen_overlay.color.lerp(target_tint, delta * 8.0)
		else:
			if underwater_screen_overlay.color.a > 0.02:
				underwater_screen_overlay.color.a = lerpf(underwater_screen_overlay.color.a, 0.0, delta * 12.0)
			else:
				underwater_screen_overlay.visible = false

	velocity = horizontal_vel + up_dir * vertical_speed + wave_surge_velocity
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
	var ship = get_tree().get_first_node_in_group("spaceship")
	
	# 1. Inside Spaceship Cabin: Check Cabin Modules (Pilot Seat, Hyperdrive, O2, Gravity, Fabricator, Storage, Hatch)
	if ship and bool(ship.get("is_player_in_cabin")):
		if ship.has_method("get_cabin_module_interaction"):
			var mod_info = ship.get_cabin_module_interaction(self)
			if not mod_info.is_empty():
				var act_type = mod_info.get("type", "")
				if nearby_interactable != ship or current_interactable_type != act_type:
					nearby_interactable = ship
					current_interactable_type = act_type
					interaction_available.emit(act_type, ship)
				return
		elif ship.has_method("get_hatch_interaction_state"):
			var h_state = ship.get_hatch_interaction_state(self)
			if h_state != "":
				if nearby_interactable != ship or current_interactable_type != h_state:
					nearby_interactable = ship
					current_interactable_type = h_state
					interaction_available.emit(h_state, ship)
				return
		# No module currently within interaction range in cabin
		if nearby_interactable != null:
			nearby_interactable = null
			current_interactable_type = ""
			interaction_lost.emit()
		return

	# 2. Outside Spaceship: Check Hatch from ramp/doorstep
	if ship and ship.has_method("get_hatch_interaction_state"):
		var h_state = ship.get_hatch_interaction_state(self)
		if h_state != "":
			if nearby_interactable != ship or current_interactable_type != h_state:
				nearby_interactable = ship
				current_interactable_type = h_state
				interaction_available.emit(h_state, ship)
			return

	# 3. Mineable Resource Chunks & Creatures
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
	var p_node = get_parent()
	if p_node and p_node.has_method("_get_elevation"):
		return p_node._get_elevation(dir)
	var root_w = get_tree().current_scene if is_inside_tree() else null
	if root_w:
		var p_sub = root_w.get_node_or_null("SphericalPlanet")
		if p_sub and p_sub.has_method("_get_elevation"):
			return p_sub._get_elevation(dir)
	return -8.0

func get_liquid_density() -> float:
	var p_params = planet if planet.size() > 0 else (GameManager.current_planet if is_instance_valid(GameManager) else {})
	var chem = str(p_params.get("ocean_chemical", ""))
	var water_stat = str(p_params.get("water_status", ""))
	var is_molten = p_params.get("is_molten", false) or water_stat == "Lava Fundida" or chem == "magma"
	var is_acid = water_stat == "Vapor Tóxico" or chem == "sulfuric_acid"
	var is_cryo = water_stat == "Hielo Criogénico" or chem == "methane"
	var is_hycean = chem == "hycean"
	
	if is_molten:
		return 2.65 # Magma basáltico denso (~2650 kg/m³)
	elif is_acid:
		return 1.84 # Ácido sulfúrico concentrado (~1840 kg/m³)
	elif is_cryo:
		return 0.45 # Metano/etano líquido superligero (~450 kg/m³)
	elif is_hycean:
		return 0.92 # Amoníaco-agua (~920 kg/m³)
	else:
		return 1.00 # Agua marina estándar (~1025 kg/m³)

func prefers_lunar_hopping() -> bool:
	var p_params = planet if planet.size() > 0 else (GameManager.current_planet if is_instance_valid(GameManager) else {})
	if is_in_liquid:
		# En líquido: la flotabilidad reduce el peso aparente. En fluidos normales o ligeros
		# (metano, agua, amoníaco, ácido) conviene avanzar a saltitos submarinos.
		# En magma hiperdenso y viscoso (>2.2 g/cm³), el fluido bloquea el salto; conviene caminar empujando.
		var liq_density = get_liquid_density()
		return liq_density < 2.2
	else:
		# En tierra firme:
		# En planetas de baja gravedad (< 0.78g como la Luna, Marte, asteroides o lunas heladas),
		# la tracción de caminar plano es ineficiente; conviene el "lunar lope" de saltitos de las misiones Apolo.
		# En mundos terrestres de gravedad normal o alta (>= 0.78g), caminar normal es más eficiente.
		var grav_g = float(p_params.get("gravity_g", p_params.get("gravity", 9.8) / 9.8))
		return grav_g < 0.78

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

func _setup_suit_materials() -> void:
	active_suit_material = StandardMaterial3D.new()
	active_suit_material.albedo_color = Color(0.92, 0.94, 0.97)
	active_suit_material.roughness = 0.40
	active_suit_material.metallic = 0.10
	
	var mesh_paths = [
		"Visuals/Torso",
		"Visuals/Helmet/HelmetSphere",
		"Visuals/LeftArm/Mesh",
		"Visuals/RightArm/Mesh",
		"Visuals/LeftLeg/Mesh",
		"Visuals/RightLeg/Mesh"
	]
	for path in mesh_paths:
		var m = get_node_or_null(path) as MeshInstance3D
		if m:
			m.material_override = active_suit_material

func _create_jetpack_mesh_unit(is_left: bool) -> Node3D:
	var root = Node3D.new()
	root.name = "JetpackLeft" if is_left else "JetpackRight"
	root.position = Vector3(-0.28 if is_left else 0.28, -0.06, 0.06)
	
	# Titanium Jetpack Body
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.065
	body_mesh.bottom_radius = 0.065
	body_mesh.height = 0.32
	body_mesh.radial_segments = 16
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.22, 0.26, 0.34, 1.0)
	body_mat.metallic = 0.92
	body_mat.roughness = 0.24
	body_mesh.material = body_mat
	
	var body_inst = MeshInstance3D.new()
	body_inst.name = "Body"
	body_inst.mesh = body_mesh
	root.add_child(body_inst)
	
	# Conical Titanium Nozzle
	var nozzle_mesh = CylinderMesh.new()
	nozzle_mesh.top_radius = 0.055
	nozzle_mesh.bottom_radius = 0.082
	nozzle_mesh.height = 0.14
	nozzle_mesh.radial_segments = 16
	var nozzle_mat = StandardMaterial3D.new()
	nozzle_mat.albedo_color = Color(0.12, 0.13, 0.16, 1.0)
	nozzle_mat.metallic = 0.95
	nozzle_mat.roughness = 0.18
	nozzle_mat.emission_enabled = true
	nozzle_mat.emission = Color(0.25, 0.12, 0.03, 1.0)
	nozzle_mat.emission_energy_multiplier = 0.6
	nozzle_mesh.material = nozzle_mat
	
	var nozzle_inst = MeshInstance3D.new()
	nozzle_inst.name = "NozzleL" if is_left else "NozzleR"
	nozzle_inst.mesh = nozzle_mesh
	nozzle_inst.position = Vector3(0, -0.21, 0)
	root.add_child(nozzle_inst)
	
	return root

func _setup_fluid_and_jetpack_particles() -> void:
	var backpack = get_node_or_null("Visuals/Torso/BackpackPLSS")
	if backpack:
		# 0. Ensure Twin Jetpacks exist on Backpack
		jetpack_left_mesh = backpack.get_node_or_null("JetpackLeft")
		jetpack_right_mesh = backpack.get_node_or_null("JetpackRight")
		if not jetpack_left_mesh:
			jetpack_left_mesh = _create_jetpack_mesh_unit(true)
			backpack.add_child(jetpack_left_mesh)
		if not jetpack_right_mesh:
			jetpack_right_mesh = _create_jetpack_mesh_unit(false)
			backpack.add_child(jetpack_right_mesh)
		
		# Shared particle materials & textures
		var circle_tex = LandingFXProfile.get_soft_circle_texture()
		var smoke_tex = LandingFXProfile.get_soft_smoke_texture()
		var flame_mat = LandingFXProfile.create_billboard_mat(circle_tex, true) # Additive blend
		var smoke_mat = LandingFXProfile.create_billboard_mat(smoke_tex, false) # Alpha blend
		var bubble_mat = LandingFXProfile.create_billboard_mat(circle_tex, false) # Alpha blend
		
		var flame_qmesh = QuadMesh.new()
		flame_qmesh.size = Vector2(0.28, 0.28)
		flame_qmesh.material = flame_mat
		
		var smoke_qmesh = QuadMesh.new()
		smoke_qmesh.size = Vector2(0.35, 0.35)
		smoke_qmesh.material = smoke_mat
		
		var bubble_qmesh = QuadMesh.new()
		bubble_qmesh.size = Vector2(0.32, 0.32)
		bubble_qmesh.material = bubble_mat
		
		var spark_qmesh = QuadMesh.new()
		spark_qmesh.size = Vector2(0.22, 0.22)
		spark_qmesh.material = flame_mat
		
		var nozzle_l_pos = Vector3(-0.28, -0.36, 0.06)
		var nozzle_r_pos = Vector3(0.28, -0.36, 0.06)
		
		# 1. Twin Supersonic Jetpack Flame Emitters (Left & Right)
		flame_particles_left = _create_flame_emitter("FlameLeft", flame_qmesh, nozzle_l_pos)
		flame_particles_right = _create_flame_emitter("FlameRight", flame_qmesh, nozzle_r_pos)
		backpack.add_child(flame_particles_left)
		backpack.add_child(flame_particles_right)
		flame_particles = flame_particles_left
		
		# 2. Twin Wispy Flame Smoke Emitters (Left & Right)
		flame_smoke_left = _create_smoke_emitter("SmokeLeft", smoke_qmesh, nozzle_l_pos)
		flame_smoke_right = _create_smoke_emitter("SmokeRight", smoke_qmesh, nozzle_r_pos)
		backpack.add_child(flame_smoke_left)
		backpack.add_child(flame_smoke_right)
		
		# 3. Twin Underwater Cavitation Bubble Emitters (Left & Right)
		bubble_particles_left = _create_bubble_emitter("BubblesLeft", bubble_qmesh, nozzle_l_pos)
		bubble_particles_right = _create_bubble_emitter("BubblesRight", bubble_qmesh, nozzle_r_pos)
		backpack.add_child(bubble_particles_left)
		backpack.add_child(bubble_particles_right)
		bubble_particles = bubble_particles_left # Preserves compatibility
		
		# 4. Twin Emergency Flint Spark Emitters (Left & Right)
		spark_particles_left = _create_spark_emitter("SparksLeft", spark_qmesh, nozzle_l_pos)
		spark_particles_right = _create_spark_emitter("SparksRight", spark_qmesh, nozzle_r_pos)
		backpack.add_child(spark_particles_left)
		backpack.add_child(spark_particles_right)
		spark_particles = spark_particles_left # Preserves compatibility
		
		# 5. Dynamic Jetpack Thruster OmniLight3D
		jetpack_light = OmniLight3D.new()
		jetpack_light.name = "JetpackLight"
		jetpack_light.light_color = Color(1.0, 0.65, 0.22)
		jetpack_light.omni_range = 3.8
		jetpack_light.light_energy = 0.0
		jetpack_light.visible = false
		jetpack_light.position = Vector3(0, -0.38, 0.08)
		backpack.add_child(jetpack_light)

	# 6. Liquid Entry / Breach Splash
	if visuals:
		splash_particles = CPUParticles3D.new()
		splash_particles.name = "LiquidSplash"
		splash_particles.emitting = false
		splash_particles.one_shot = true
		splash_particles.explosiveness = 0.88
		splash_particles.amount = 26
		splash_particles.lifetime = 0.55
		splash_particles.direction = Vector3(0, 1, 0)
		splash_particles.spread = 75.0
		splash_particles.gravity = Vector3(0, -12.0, 0)
		splash_particles.initial_velocity_min = 4.0
		splash_particles.initial_velocity_max = 8.5
		splash_particles.scale_amount_min = 0.3
		splash_particles.scale_amount_max = 0.8
		var sp_mesh = QuadMesh.new()
		sp_mesh.size = Vector2(0.45, 0.45)
		var sp_mat = StandardMaterial3D.new()
		sp_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sp_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sp_mat.vertex_color_use_as_albedo = true
		sp_mat.albedo_texture = LandingFXProfile.get_soft_circle_texture()
		splash_particles.mesh = sp_mesh
		splash_particles.position = Vector3(0, 0.2, 0)
		visuals.add_child(splash_particles)

func _create_flame_emitter(p_name: String, p_mesh: Mesh, p_pos: Vector3) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.name = p_name
	p.emitting = false
	p.amount = 32
	p.lifetime = 0.16
	p.direction = Vector3(0, -1, 0.04)
	p.spread = 9.0
	p.gravity = Vector3(0, -2.5, 0)
	p.initial_velocity_min = 4.8
	p.initial_velocity_max = 8.8
	p.color = Color(1.0, 0.65, 0.15, 0.95)
	p.scale_amount_min = 0.18
	p.scale_amount_max = 0.42
	p.mesh = p_mesh
	p.position = p_pos
	return p

func _create_smoke_emitter(p_name: String, p_mesh: Mesh, p_pos: Vector3) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.name = p_name
	p.emitting = false
	p.amount = 14
	p.lifetime = 0.32
	p.direction = Vector3(0, -1, 0.15)
	p.spread = 22.0
	p.gravity = Vector3(0, 0.6, 0)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.4
	p.color = Color(0.70, 0.70, 0.75, 0.22)
	p.scale_amount_min = 0.15
	p.scale_amount_max = 0.38
	p.mesh = p_mesh
	p.position = p_pos
	return p

func _create_bubble_emitter(p_name: String, p_mesh: Mesh, p_pos: Vector3) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.name = p_name
	p.emitting = false
	p.amount = 24
	p.lifetime = 0.72
	p.direction = Vector3(0, -1, 0.1)
	p.spread = 28.0
	p.gravity = Vector3(0, 4.5, 0) # Upward buoyancy
	p.initial_velocity_min = 1.6
	p.initial_velocity_max = 3.6
	p.color = Color(0.85, 0.95, 1.0, 0.85)
	p.scale_amount_min = 0.16
	p.scale_amount_max = 0.46
	p.mesh = p_mesh
	p.position = p_pos
	return p

func _create_spark_emitter(p_name: String, p_mesh: Mesh, p_pos: Vector3) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.name = p_name
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 14
	p.lifetime = 0.28
	p.direction = Vector3(0, -1, 0)
	p.spread = 45.0
	p.gravity = Vector3(0, -8.0, 0)
	p.initial_velocity_min = 3.2
	p.initial_velocity_max = 7.2
	p.color = Color(1.0, 0.72, 0.25, 1.0)
	p.scale_amount_min = 0.14
	p.scale_amount_max = 0.32
	p.mesh = p_mesh
	p.position = p_pos
	return p

func _set_jetpack_flames(active: bool) -> void:
	if flame_particles_left: flame_particles_left.emitting = active
	if flame_particles_right: flame_particles_right.emitting = active
	if flame_smoke_left: flame_smoke_left.emitting = active
	if flame_smoke_right: flame_smoke_right.emitting = active
	if jetpack_light:
		jetpack_light.visible = active
		jetpack_light.light_energy = 2.4 if active else 0.0

func _set_jetpack_bubbles(active: bool) -> void:
	if bubble_particles_left: bubble_particles_left.emitting = active
	if bubble_particles_right: bubble_particles_right.emitting = active
	if bubble_particles and bubble_particles != bubble_particles_left:
		bubble_particles.emitting = active

func _trigger_emergency_sparks() -> void:
	if spark_particles_left: spark_particles_left.restart()
	if spark_particles_right: spark_particles_right.restart()
	if spark_particles and spark_particles != spark_particles_left:
		spark_particles.restart()

func _trigger_liquid_splash(planet_params: Dictionary) -> void:
	AudioManager.play("splash", 1.0, 1.5)
	if splash_particles:
		var water_stat = str(planet_params.get("water_status", ""))
		var chem = str(planet_params.get("ocean_chemical", ""))
		var splash_col = Color(0.80, 0.95, 1.0, 0.85) # default water
		if water_stat == "Lava Fundida" or chem == "magma" or planet_params.get("is_molten", false):
			splash_col = Color(1.0, 0.40, 0.08, 0.95) # molten lava splash
		elif water_stat == "Vapor Tóxico" or chem == "sulfuric_acid":
			splash_col = Color(0.60, 0.85, 0.15, 0.90) # acid splash
		elif water_stat == "Hielo Criogénico" or chem == "methane":
			splash_col = Color(0.40, 0.85, 1.0, 0.85) # liquid methane splash
		elif chem == "hycean":
			splash_col = Color(0.20, 0.55, 0.90, 0.85)
		splash_particles.color = splash_col
		splash_particles.restart()

func _update_suit_thermal_and_fluid_reactions(delta: float, planet_params: Dictionary) -> void:
	if not active_suit_material:
		return
		
	var water_stat = str(planet_params.get("water_status", ""))
	var chem = str(planet_params.get("ocean_chemical", ""))
	var is_molten = planet_params.get("is_molten", false) or water_stat == "Lava Fundida" or chem == "magma"
	var is_acid = water_stat == "Vapor Tóxico" or chem == "sulfuric_acid"
	var is_cryo = water_stat == "Hielo Criogénico" or chem == "methane"
	
	var target_albedo = Color(0.92, 0.94, 0.97)
	var target_roughness = 0.40
	var target_metallic = 0.10
	var target_emission = Color.BLACK
	var target_emission_energy = 0.0
	
	if is_in_liquid:
		suit_effect_intensity = minf(suit_effect_intensity + delta * 1.6, 1.0)
		if is_molten:
			# Lava: Charred black suit with glowing orange thermal fissures
			target_albedo = Color(0.16, 0.12, 0.10)
			target_roughness = 0.95
			target_metallic = 0.05
			target_emission = Color(1.0, 0.35, 0.05)
			target_emission_energy = 2.2 * suit_effect_intensity
		elif is_acid:
			# Sulfuric acid: Corrosive yellow-green etching
			target_albedo = Color(0.62, 0.72, 0.22)
			target_roughness = 0.98
			target_metallic = 0.08
			target_emission = Color(0.45, 0.65, 0.10)
			target_emission_energy = 0.5 * suit_effect_intensity
		elif is_cryo:
			# Cryogenic methane: Frost glaze & icy crystalline reflection
			target_albedo = Color(0.85, 0.95, 1.0)
			target_roughness = 0.12
			target_metallic = 0.65
		else:
			# Water / Hycean: Glossy wet look with darker fabric
			target_albedo = Color(0.68, 0.74, 0.82)
			target_roughness = 0.14
			target_metallic = 0.25
	else:
		# Gradually dry off and cool down after leaving the fluid
		suit_effect_intensity = maxf(suit_effect_intensity - delta * 0.20, 0.0)
		if suit_effect_intensity > 0.01:
			if is_molten:
				# Residual charred soot and cooling embers
				target_albedo = Color(0.92, 0.94, 0.97).lerp(Color(0.25, 0.20, 0.18), suit_effect_intensity * 0.7)
				target_roughness = lerpf(0.40, 0.85, suit_effect_intensity)
				target_emission = Color(1.0, 0.30, 0.05)
				target_emission_energy = 0.8 * suit_effect_intensity
			elif is_acid:
				target_albedo = Color(0.92, 0.94, 0.97).lerp(Color(0.72, 0.78, 0.35), suit_effect_intensity * 0.6)
				target_roughness = lerpf(0.40, 0.85, suit_effect_intensity)
			elif is_cryo:
				target_albedo = Color(0.92, 0.94, 0.97).lerp(Color(0.88, 0.96, 1.0), suit_effect_intensity * 0.5)
				target_roughness = lerpf(0.40, 0.20, suit_effect_intensity)
			else:
				# Drying water
				target_albedo = Color(0.92, 0.94, 0.97).lerp(Color(0.72, 0.78, 0.86), suit_effect_intensity * 0.5)
				target_roughness = lerpf(0.40, 0.22, suit_effect_intensity)
				
	active_suit_material.albedo_color = active_suit_material.albedo_color.lerp(target_albedo, delta * 5.0)
	active_suit_material.roughness = lerpf(active_suit_material.roughness, target_roughness, delta * 5.0)
	active_suit_material.metallic = lerpf(active_suit_material.metallic, target_metallic, delta * 5.0)
	if target_emission_energy > 0.01:
		active_suit_material.emission_enabled = true
		active_suit_material.emission = target_emission
		active_suit_material.emission_energy_multiplier = target_emission_energy
	elif active_suit_material.emission_enabled:
		active_suit_material.emission_energy_multiplier = lerpf(active_suit_material.emission_energy_multiplier, 0.0, delta * 3.0)
		if active_suit_material.emission_energy_multiplier < 0.02:
			active_suit_material.emission_enabled = false

# ==============================================================================
# PHYSICAL 3D BODY ATTACHMENT PROPS (HANDS & BACKPACK)
# ==============================================================================
var slot_prop_nodes: Dictionary = {
	"hand_left": null,
	"hand_right": null,
	"back_1": null,
	"back_2": null
}

func _setup_body_attachment_props() -> void:
	# Hand Left mount - positioned firmly in the left hand forward
	var l_arm = get_node_or_null("Visuals/LeftArm")
	if l_arm and not slot_prop_nodes["hand_left"]:
		var n = Node3D.new()
		n.name = "SlotProp_HandL"
		n.position = Vector3(0.0, -0.42, -0.22)
		l_arm.add_child(n)
		slot_prop_nodes["hand_left"] = n
		
	# Hand Right mount - positioned firmly in the right hand forward
	var r_arm = get_node_or_null("Visuals/RightArm")
	if r_arm and not slot_prop_nodes["hand_right"]:
		var n = Node3D.new()
		n.name = "SlotProp_HandR"
		n.position = Vector3(0.0, -0.42, -0.22)
		r_arm.add_child(n)
		slot_prop_nodes["hand_right"] = n
		
	# Backpack (PLSS) mounts - prominently mounted on the life support backpack
	var backpack = get_node_or_null("Visuals/Torso/BackpackPLSS")
	if backpack:
		if not slot_prop_nodes["back_1"]:
			var n1 = Node3D.new()
			n1.name = "SlotProp_Back1"
			# Mounted high on rear cargo rack, clearly visible over and between O2 tanks
			n1.position = Vector3(0.0, 0.28, 0.32)
			backpack.add_child(n1)
			slot_prop_nodes["back_1"] = n1
			
		if not slot_prop_nodes["back_2"]:
			var n2 = Node3D.new()
			n2.name = "SlotProp_Back2"
			# Mounted low on rear cargo rack, clearly visible beneath O2 tanks
			n2.position = Vector3(0.0, -0.22, 0.32)
			backpack.add_child(n2)
			slot_prop_nodes["back_2"] = n2
			
	if is_instance_valid(GameManager) and GameManager.crafting:
		if not GameManager.crafting.body_slots_changed.is_connected(_update_body_attachment_props):
			GameManager.crafting.body_slots_changed.connect(_update_body_attachment_props)
	_update_body_attachment_props()

func _update_body_attachment_props() -> void:
	if not is_instance_valid(GameManager) or not GameManager.crafting:
		return
	var b_slots = GameManager.crafting.body_slots
	for s_key in ["hand_left", "hand_right", "back_1", "back_2"]:
		var p_node: Node3D = slot_prop_nodes.get(s_key, null)
		if not is_instance_valid(p_node):
			continue
		var data = b_slots.get(s_key, {})
		var item_name = data.get("item", "")
		var count = data.get("count", 0)
		
		# Clear existing prop meshes
		for c in p_node.get_children():
			p_node.remove_child(c)
			c.queue_free()
			
		if count <= 0 or item_name == "":
			continue
			
		# Build and attach new 3D prop
		var prop_inst = _create_resource_3d_prop(item_name)
		if prop_inst:
			p_node.add_child(prop_inst)

func _create_resource_3d_prop(item_name: String) -> Node3D:
	var root = Node3D.new()
	root.name = "Prop_" + item_name
	
	match item_name:
		"iron":
			var m = BoxMesh.new()
			m.size = Vector3(0.20, 0.20, 0.20)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.68, 0.72, 0.80)
			mat.metallic = 0.95
			mat.roughness = 0.30
			var inst = MeshInstance3D.new()
			inst.mesh = m
			inst.material_override = mat
			root.add_child(inst)
			
		"copper":
			var m = CylinderMesh.new()
			m.top_radius = 0.08
			m.bottom_radius = 0.08
			m.height = 0.22
			m.radial_segments = 14
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.92, 0.54, 0.30)
			mat.metallic = 0.92
			mat.roughness = 0.25
			var inst = MeshInstance3D.new()
			inst.mesh = m
			inst.material_override = mat
			root.add_child(inst)
			
		"silicon":
			var m = PrismMesh.new()
			m.size = Vector3(0.18, 0.24, 0.18)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.25, 0.90, 1.0, 0.95)
			mat.roughness = 0.06
			mat.metallic = 0.25
			mat.emission_enabled = true
			mat.emission = Color(0.15, 0.75, 1.0)
			mat.emission_energy_multiplier = 1.4
			var inst = MeshInstance3D.new()
			inst.mesh = m
			inst.material_override = mat
			root.add_child(inst)
			
		"uranium":
			var m = CylinderMesh.new()
			m.top_radius = 0.08
			m.bottom_radius = 0.08
			m.height = 0.24
			m.radial_segments = 14
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.15, 0.85, 0.30)
			mat.emission_enabled = true
			mat.emission = Color(0.25, 1.0, 0.40)
			mat.emission_energy_multiplier = 2.8
			var inst = MeshInstance3D.new()
			inst.mesh = m
			inst.material_override = mat
			root.add_child(inst)
			
		"wrench":
			var shaft_mesh = BoxMesh.new()
			shaft_mesh.size = Vector3(0.04, 0.30, 0.03)
			var head_mesh = CylinderMesh.new()
			head_mesh.top_radius = 0.05
			head_mesh.bottom_radius = 0.05
			head_mesh.height = 0.03
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.80, 0.82, 0.90)
			mat.metallic = 0.98
			mat.roughness = 0.15
			var inst_shaft = MeshInstance3D.new()
			inst_shaft.mesh = shaft_mesh
			inst_shaft.material_override = mat
			root.add_child(inst_shaft)
			var inst_head = MeshInstance3D.new()
			inst_head.mesh = head_mesh
			inst_head.material_override = mat
			inst_head.position = Vector3(0, 0.14, 0)
			root.add_child(inst_head)
			
		"wire":
			var m = TorusMesh.new()
			m.inner_radius = 0.05
			m.outer_radius = 0.11
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.98, 0.70, 0.22)
			mat.metallic = 0.95
			mat.roughness = 0.25
			var inst = MeshInstance3D.new()
			inst.mesh = m
			inst.material_override = mat
			root.add_child(inst)
			
		"microchip":
			var m = BoxMesh.new()
			m.size = Vector3(0.18, 0.02, 0.22)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.10, 0.50, 0.25)
			mat.metallic = 0.50
			mat.roughness = 0.20
			var inst = MeshInstance3D.new()
			inst.mesh = m
			inst.material_override = mat
			root.add_child(inst)
			
		"reactor_cell":
			var m = CylinderMesh.new()
			m.top_radius = 0.085
			m.bottom_radius = 0.085
			m.height = 0.22
			m.radial_segments = 16
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.25, 0.70, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.35, 0.85, 1.0)
			mat.emission_energy_multiplier = 3.5
			var inst = MeshInstance3D.new()
			inst.mesh = m
			inst.material_override = mat
			root.add_child(inst)
			
		_:
			var m = SphereMesh.new()
			m.radius = 0.10
			m.height = 0.20
			var inst = MeshInstance3D.new()
			inst.mesh = m
			root.add_child(inst)
			
	return root
