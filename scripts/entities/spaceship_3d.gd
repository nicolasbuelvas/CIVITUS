extends Node3D

const LandingFXProfile = preload("res://scripts/effects/landing_fx_profile.gd")

signal hyperdrive_launched()
signal hull_integrity_changed(health_dict: Dictionary, is_breached: bool)
signal landing_completed()

var is_landing_intro_active: bool = false

@onready var interior_area: Area3D = $CabinInterior/InteriorArea
@onready var outer_cylinder: CSGCylinder3D = $HullStructure/CapsuleHull/OuterCylinder
@onready var interior_light: OmniLight3D = $CabinInterior/InteriorLight
@onready var hatch_node: Node3D = get_node_or_null("HullStructure/ApolloHatch")
@onready var hatch_col: CollisionShape3D = get_node_or_null("HullStructure/ApolloHatch/HatchCollider/CollisionShape3D")
@onready var boarding_ramp: StaticBody3D = get_node_or_null("HullStructure/BoardingRamp")

# Boarding ramp physics constants and state
const RAMP_REST_ANGLE: float = 0.3886 # 22.27 deg (touches ground firmly at Y=-0.94)
const RAMP_RETRACTED_ANGLE: float = -1.15 # ~66 deg (retracted against doorway)

var is_ramp_falling: bool = false
var is_ramp_anchored: bool = true
var ramp_current_angle: float = RAMP_REST_ANGLE
var ramp_angular_velocity: float = 0.0

var is_player_in_cabin: bool = false
var is_hatch_open: bool = false
var is_operating_hatch: bool = false
var is_equalizing_pressure: bool = false
var player_ref: CharacterBody3D = null

# Cabin Modules & Systems (Waste of Space Architecture)
const MODULE_INTERACT_RADIUS: float = 1.6

var pilot_seat_pos: Vector3 = Vector3(0.0, 0.2, -1.8)
var hyperdrive_pos: Vector3 = Vector3(-1.8, 0.2, -1.4)
var oxygen_gen_pos: Vector3 = Vector3(2.0, 0.2, -0.3)
var gravity_device_pos: Vector3 = Vector3(-2.0, 0.2, 0.3)
var storage_bin_pos: Vector3 = Vector3(1.8, 0.2, 1.6)
var fabricator_pos: Vector3 = Vector3(1.8, 0.2, -1.4)

var is_player_seated: bool = false
var grav_ring_outer: Node3D = null
var grav_ring_inner: Node3D = null
var grav_core_sphere: Node3D = null
var hyperdrive_plasma_core: Node3D = null
var hyperdrive_light: OmniLight3D = null
var hyperdrive_status_light: OmniLight3D = null
var cabin_modules_initialized: bool = false

# Crash pod integrity & environmental weathering
var capsule_hull_hp: float = 100.0
var active_hull_material: StandardMaterial3D = null
var landing_tween: Tween = null

func abort_landing() -> void:
	is_landing_intro_active = false
	if landing_tween and landing_tween.is_valid():
		landing_tween.kill()

func _exit_tree() -> void:
	abort_landing()

# Rocket Engine Visual FX & Thermal State
var active_nozzle_material: StandardMaterial3D = null
var active_flame_material: ShaderMaterial = null
var engine_fire_stream: CPUParticles3D = null
var engine_light_ref: OmniLight3D = null

func _ready() -> void:
	add_to_group("spaceship")
	add_to_group("interactable")
	interior_area.body_entered.connect(_on_cabin_entered)
	interior_area.body_exited.connect(_on_cabin_exited)
	_setup_cabin_modules()
	
	if outer_cylinder and outer_cylinder.material:
		active_hull_material = outer_cylinder.material.duplicate()
		outer_cylinder.material = active_hull_material
	
	# Initial state: Hatch closed, solid
	is_hatch_open = false
	is_operating_hatch = false
	is_equalizing_pressure = false
	if hatch_node:
		hatch_node.position = Vector3(-1.04, 1.35, 3.4)
		hatch_node.rotation.y = 0.0
	if hatch_col:
		hatch_col.set_deferred("disabled", false)
	
	# Apply initial planet-specific crash wear & scorch
	var planet = GameManager.current_planet
	_update_hazard_oxidation_visuals(planet, planet.get("temperature", 20.0))
	
	if boarding_ramp:
		boarding_ramp.rotation.x = RAMP_REST_ANGLE
		ramp_current_angle = RAMP_REST_ANGLE
		is_ramp_anchored = true
		is_ramp_falling = false

func setup_landing_engine_fx(planet_params: Dictionary = {}) -> void:
	if planet_params.is_empty() and is_instance_valid(GameManager) and GameManager.current_planet is Dictionary:
		planet_params = GameManager.current_planet
		
	var profile = LandingFXProfile.get_profile(planet_params)
	
	# 1. MainRocketEngine Nozzle incandescence (heats up during retro-burn)
	var engine_mesh = get_node_or_null("HullStructure/MainRocketEngine") as MeshInstance3D
	if engine_mesh:
		if not active_nozzle_material:
			var base_mat = engine_mesh.material_override
			if not base_mat and engine_mesh.mesh:
				base_mat = engine_mesh.mesh.material
			if base_mat and base_mat is StandardMaterial3D:
				active_nozzle_material = base_mat.duplicate()
			else:
				active_nozzle_material = StandardMaterial3D.new()
			engine_mesh.material_override = active_nozzle_material
			
		active_nozzle_material.emission_enabled = true
		active_nozzle_material.emission = profile.nozzle_heat_color
		active_nozzle_material.emission_energy_multiplier = 3.5
		
	# 2. Supersonic Plume Shader tailored to planet atmospheric backpressure
	var flame_plume = get_node_or_null("HullStructure/MainRocketEngine/FlamePivot/FlamePlume") as MeshInstance3D
	if flame_plume:
		if not active_flame_material:
			var f_mat = flame_plume.get_active_material(0)
			if f_mat and f_mat is ShaderMaterial:
				active_flame_material = f_mat.duplicate()
			else:
				var s = load("res://assets/shaders/rocket_flame.gdshader")
				active_flame_material = ShaderMaterial.new()
				active_flame_material.shader = s
			flame_plume.material_override = active_flame_material
			
		active_flame_material.set_shader_parameter("core_color", profile.engine_core_color)
		active_flame_material.set_shader_parameter("flame_color", profile.engine_flame_color)
		active_flame_material.set_shader_parameter("rim_color", profile.engine_rim_color)
		active_flame_material.set_shader_parameter("shock_diamond_freq", profile.shock_diamond_freq)
		active_flame_material.set_shader_parameter("flame_speed", profile.flame_speed)
		active_flame_material.set_shader_parameter("expansion_power", profile.expansion_power)
		
	# 3. Dynamic Engine Light (localized beneath the heat shield, illuminating only ground and legs)
	engine_light_ref = get_node_or_null("HullStructure/MainRocketEngine/FlamePivot/EngineLight") as OmniLight3D
	if engine_light_ref:
		engine_light_ref.position = Vector3(0, -0.65, 0)
		engine_light_ref.light_color = profile.engine_light_color
		engine_light_ref.light_energy = 6.0
		engine_light_ref.omni_range = 16.0
		engine_light_ref.visible = true
		
	# 4. Engine Sparks (pointing strictly down towards ground)
	var sparks = get_node_or_null("HullStructure/MainRocketEngine/FlamePivot/RocketSparks") as CPUParticles3D
	if sparks:
		sparks.color = profile.engine_sparks_color
		sparks.direction = Vector3(0, -1, 0)
		sparks.gravity = Vector3(0, -14.0, 0)
		
	var flame_pivot = get_node_or_null("HullStructure/MainRocketEngine/FlamePivot")
	
	# 5. Engine Fire Stream (high-velocity supersonic fire tongues jetting straight down)
	if flame_pivot and not engine_fire_stream:
		engine_fire_stream = CPUParticles3D.new()
		engine_fire_stream.name = "EngineFireStream"
		engine_fire_stream.local_coords = false
		engine_fire_stream.direction = Vector3(0, -1, 0)
		engine_fire_stream.spread = 6.0
		engine_fire_stream.gravity = Vector3(0, -14.0, 0) # Pulls strictly downward to ground
		engine_fire_stream.initial_velocity_min = 24.0
		engine_fire_stream.initial_velocity_max = 38.0
		engine_fire_stream.scale_amount_min = 0.5
		engine_fire_stream.scale_amount_max = 1.3
		engine_fire_stream.lifetime = 0.35
		engine_fire_stream.amount = 28
		engine_fire_stream.emitting = false
		var stream_mesh = QuadMesh.new()
		stream_mesh.size = Vector2(1.2, 1.2)
		stream_mesh.material = LandingFXProfile.create_billboard_mat(LandingFXProfile.get_soft_circle_texture(), true)
		engine_fire_stream.mesh = stream_mesh
		flame_pivot.add_child(engine_fire_stream)
		
	if engine_fire_stream:
		engine_fire_stream.color = profile.engine_flame_color

func play_landing_intro(target_pos: Vector3, up_dir: Vector3) -> void:
	is_landing_intro_active = true
	var start_pos = target_pos + up_dir * 88.0
	global_position = start_pos
	
	# Keep boarding ramp retracted against doorway during flight
	if boarding_ramp:
		boarding_ramp.rotation.x = RAMP_RETRACTED_ANGLE
		ramp_current_angle = RAMP_RETRACTED_ANGLE
		is_ramp_falling = false
		is_ramp_anchored = false
		
	# Setup planet-specific propulsion flame, nozzle thermal glow, and exhaust particles
	setup_landing_engine_fx()
	
	var flame_pivot = get_node_or_null("HullStructure/MainRocketEngine/FlamePivot")
	var sparks = get_node_or_null("HullStructure/MainRocketEngine/FlamePivot/RocketSparks")
	if flame_pivot:
		flame_pivot.visible = true
		flame_pivot.scale = Vector3(1.0, 1.0, 1.0)
	if sparks:
		sparks.emitting = true
	if engine_fire_stream:
		engine_fire_stream.emitting = true
	
	AudioManager.play("reentry", 0.80, 4.5)
	AudioManager.play("thruster", 0.90, 4.0)
	
	# Smooth continuous atmospheric retro-burn descent without intermediate slowdowns
	abort_landing()
	landing_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var tw = landing_tween
	
	# Continuous descent: high speed in upper atmosphere decelerating smoothly into touchdown
	tw.tween_property(self, "global_position", target_pos, 5.4)
	if flame_pivot:
		# Flame plume expands steadily as ground approaches
		tw.parallel().tween_property(flame_pivot, "scale:y", 2.2, 5.0)
		
	# Touchdown impact, leg suspension compression & firm parking freeze
	tw.tween_callback(func():
		is_landing_intro_active = false
		if flame_pivot:
			flame_pivot.visible = false
		if sparks:
			sparks.emitting = false
		if engine_fire_stream:
			engine_fire_stream.emitting = false
		if engine_light_ref:
			engine_light_ref.light_energy = 0.0
			engine_light_ref.visible = false
			
		# Smooth nozzle thermal cooldown: hot glowing metal cools down over 3.2s
		if active_nozzle_material:
			var tw_nozzle_cool = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_nozzle_cool.tween_property(active_nozzle_material, "emission_energy_multiplier", 0.05, 3.2)
			tw_nozzle_cool.tween_callback(func():
				if active_nozzle_material:
					active_nozzle_material.emission_enabled = false
			)
			
		AudioManager.play("docking", 1.0, 5.0)
		
		# KSP landing leg suspension compression bounce
		var tw_bounce = create_tween().set_trans(Tween.TRANS_SINE)
		tw_bounce.tween_property(self, "global_position", target_pos - up_dir * 0.14, 0.10)
		tw_bounce.tween_property(self, "global_position", target_pos, 0.18)
		tw_bounce.tween_callback(func():
			# Firmly frozen and parked on the ground
			global_position = target_pos
			# Release ramp with gravity physics so it drops to ground and anchors
			drop_ramp_with_physics()
			landing_completed.emit()
		)
	)

func drop_ramp_with_physics() -> void:
	is_ramp_falling = true
	is_ramp_anchored = false
	ramp_angular_velocity = 0.0

func _physics_process(delta: float) -> void:
	if is_ramp_falling and not is_ramp_anchored and boarding_ramp:
		# Angular gravity acceleration
		ramp_angular_velocity += 18.5 * delta
		ramp_current_angle += ramp_angular_velocity * delta
		if ramp_current_angle >= RAMP_REST_ANGLE:
			ramp_current_angle = RAMP_REST_ANGLE
			if absf(ramp_angular_velocity) > 0.8:
				# Bounce off ground with mechanical damping
				ramp_angular_velocity = -ramp_angular_velocity * 0.20
				AudioManager.play("click", 0.90, -1.0)
			else:
				# Firmly anchored to ground
				ramp_angular_velocity = 0.0
				is_ramp_falling = false
				is_ramp_anchored = true
				AudioManager.play("docking", 0.95, -5.0)
		boarding_ramp.rotation.x = ramp_current_angle

func _process(delta: float) -> void:
	# Dynamic cabin module animations (Waste of Space systems)
	if is_instance_valid(grav_ring_outer):
		grav_ring_outer.rotate_x(1.2 * delta)
	if is_instance_valid(grav_ring_inner):
		grav_ring_inner.rotate_z(-1.6 * delta)
	if is_instance_valid(grav_core_sphere):
		grav_core_sphere.position.y = 0.65 + sin(Time.get_ticks_msec() * 0.003) * 0.04
	if is_instance_valid(hyperdrive_light):
		var pulse = 0.75 + sin(Time.get_ticks_msec() * 0.005) * 0.25
		hyperdrive_light.light_energy = 1.6 * pulse

	# Supersonic combustion pulsation on the engine light during descent
	if is_landing_intro_active and is_instance_valid(engine_light_ref):
		var t_sec = Time.get_ticks_msec() / 1000.0
		engine_light_ref.light_energy = 7.5 + sin(t_sec * 38.0) * 1.4 + cos(t_sec * 52.0) * 0.9

	var planet = GameManager.current_planet
	var temp = planet.get("temperature", 20.0)
	var is_hostile_temp = (temp > 65.0 or temp < -35.0)
	var lvl = planet.get("level", 0)

	# 1. Environmental weathering to the outer hull
	if is_hostile_temp or lvl >= 2:
		var dmg_rate = 0.5
		if temp > 90.0:
			dmg_rate += (temp - 90.0) * 0.04
		elif temp < -50.0:
			dmg_rate += abs(temp + 50.0) * 0.03
		capsule_hull_hp = max(10.0, capsule_hull_hp - dmg_rate * delta)
		_update_hazard_oxidation_visuals(planet, temp)

	# 2. Dynamic tidal fluid contact: affected by rising tides but NEVER destroyed
	var ship_dist = global_position.length()
	var planet_ref = get_parent()
	var ocean_r = 160.0
	if planet_ref and planet_ref.has_method("get_ocean_surface_radius"):
		ocean_r = planet_ref.get_ocean_surface_radius()
	elif GameManager.current_planet.has("radius"):
		ocean_r = float(GameManager.current_planet.get("radius", 160.0))
		
	var has_fluid = str(planet.get("water_status", "Seco / Desolado")) != "Seco / Desolado" and str(planet.get("water_status", "")) != ""
	if has_fluid and ship_dist < (ocean_r + 1.25):
		var water_stat = str(planet.get("water_status", ""))
		var is_molten = planet.get("is_molten", false) or water_stat == "Lava Fundida"
		var fluid_corrosion = 2.0 if is_molten else 0.45
		# Ship is affected by fluid contact, but strictly safe from destruction (minimum 25.0 HP threshold)
		capsule_hull_hp = max(25.0, capsule_hull_hp - fluid_corrosion * delta)
		_update_hazard_oxidation_visuals(planet, temp)

	# 3. Safe Haven: vitals (O2, Suit Hull, Fuel) regenerate ONLY when hatch door is hermetically CLOSED!
	if is_player_in_cabin and not is_hatch_open and not is_operating_hatch:
		GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 60.0 * delta)
		GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 35.0 * delta)
		GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 45.0 * delta)

# Interaction prompt calculation based on exact player location
func get_hatch_interaction_state(p: CharacterBody3D) -> String:
	if is_operating_hatch:
		return ""
		
	var local_p = to_local(p.global_position)
	
	if not is_hatch_open:
		# Hatch is closed. Player can open it from inside near the hatch:
		if is_player_in_cabin and local_p.z > 0.2 and local_p.z < 3.2:
			return "open_hatch"
		# Or from OUTSIDE on the boarding ramp / doorstep:
		if not is_player_in_cabin and local_p.z >= 2.6 and local_p.z <= 6.8 and absf(local_p.x) <= 2.0 and local_p.y >= -1.2 and local_p.y <= 2.6:
			return "open_hatch"
		return ""
	else:
		# Hatch is open. Player can close it ONLY from inside near the center:
		# local_p.z <= 1.5 prevents closing while in the doorway threshold or outside!
		if is_player_in_cabin and local_p.z <= 1.5 and local_p.length() < 2.5:
			return "close_hatch"
		return ""

# Hatch Opening Sequence: Atmospheric balancing + helmet donning + smooth swing open
func open_hatch() -> void:
	if is_operating_hatch or is_hatch_open:
		return
	is_operating_hatch = true
	is_equalizing_pressure = true
	if player_ref:
		player_ref.is_action_locked = true
	
	# Decompression hiss
	AudioManager.play("airlock", 0.9, -2.0)
	
	# Character animation: only put on helmet if currently INSIDE cabin preparing for EVA
	if is_player_in_cabin:
		if player_ref and player_ref.has_method("animate_put_on_helmet"):
			player_ref.animate_put_on_helmet()
		elif player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true)
		
		# Equalization duration (1.4s)
		var tween = create_tween()
		tween.tween_interval(1.4)
		tween.tween_callback(func():
			is_equalizing_pressure = false
			_open_hatch_direct()
		)
	else:
		# Fast exterior latch depressurization (0.4s) since player is already wearing suit
		var tween = create_tween()
		tween.tween_interval(0.4)
		tween.tween_callback(func():
			is_equalizing_pressure = false
			_open_hatch_direct()
		)

func _open_hatch_direct() -> void:
	AudioManager.play("click", 1.1)
	if hatch_node:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Swing open on the left hinge! Height stays at 1.35m, never pokes through roof!
		tw.tween_property(hatch_node, "rotation:y", -deg_to_rad(105.0), 0.5)
		tw.tween_callback(func():
			if hatch_col:
				hatch_col.set_deferred("disabled", true)
			is_hatch_open = true
			is_operating_hatch = false
			if player_ref:
				player_ref.is_action_locked = false
		)
	else:
		if hatch_col:
			hatch_col.set_deferred("disabled", true)
		is_hatch_open = true
		is_operating_hatch = false
		if player_ref:
			player_ref.is_action_locked = false

# Hatch Closing Sequence: Fast and smooth seal (0.35s)
func close_hatch() -> void:
	if is_operating_hatch or not is_hatch_open:
		return
	is_operating_hatch = true
	if player_ref:
		player_ref.is_action_locked = true
	AudioManager.play("airlock", 1.2, -4.0)
	
	if hatch_col:
		hatch_col.set_deferred("disabled", false)
	if hatch_node:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# Swing shut flush into frame
		tw.tween_property(hatch_node, "rotation:y", 0.0, 0.35)
		tw.tween_callback(func():
			is_hatch_open = false
			is_operating_hatch = false
			# Cabin is now sealed: take off helmet with hands and reveal face
			if player_ref and player_ref.has_method("animate_take_off_helmet"):
				player_ref.animate_take_off_helmet()
				var tw_unlock = create_tween()
				tw_unlock.tween_interval(1.1)
				tw_unlock.tween_callback(func():
					if player_ref:
						player_ref.is_action_locked = false
				)
			elif player_ref and player_ref.has_method("set_suit_mode"):
				player_ref.set_suit_mode(false)
				if player_ref:
					player_ref.is_action_locked = false
		)
	else:
		is_hatch_open = false
		is_operating_hatch = false
		if player_ref:
			player_ref.is_action_locked = false

func _update_hazard_oxidation_visuals(planet: Dictionary, temp: float) -> void:
	if not active_hull_material:
		return
		
	var dmg_ratio = clamp(1.0 - (capsule_hull_hp / 100.0), 0.0, 1.0)
	var clean_col = Color(0.88, 0.90, 0.94)
	var p_type = planet.get("type", "")

	if temp < -35.0 or p_type.contains("Cryo") or p_type.contains("Hielo"):
		var ice_cyan = Color(0.42, 0.70, 0.92)
		active_hull_material.albedo_color = clean_col.lerp(ice_cyan, 0.35 + dmg_ratio * 0.65)
		active_hull_material.roughness = 0.85
	elif temp > 75.0 or p_type.contains("Volcan") or p_type.contains("Lava"):
		var scorch_black = Color(0.14, 0.10, 0.08)
		active_hull_material.albedo_color = clean_col.lerp(scorch_black, 0.45 + dmg_ratio * 0.55)
		active_hull_material.roughness = 0.9
		if dmg_ratio > 0.3:
			active_hull_material.emission_enabled = true
			active_hull_material.emission = Color(0.9, 0.25, 0.05) * (dmg_ratio - 0.3) * 1.5
	elif p_type.contains("Toxic") or p_type.contains("Acido"):
		var acid_col = Color(0.46, 0.66, 0.24)
		active_hull_material.albedo_color = clean_col.lerp(acid_col, 0.4 + dmg_ratio * 0.6)
		active_hull_material.roughness = 0.8
	else:
		var dust_col = Color(0.68, 0.52, 0.22)
		active_hull_material.albedo_color = clean_col.lerp(dust_col, 0.35 + dmg_ratio * 0.65)
		active_hull_material.roughness = 0.75

func _on_cabin_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = true
		player_ref = body as CharacterBody3D
		if not is_hatch_open:
			if player_ref and player_ref.has_method("set_suit_mode"):
				player_ref.set_suit_mode(false)

func _on_cabin_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = false
		if is_player_seated and player_ref:
			stand_up_from_pilot_seat(player_ref)
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true)

# Cabin Module Interaction & Management
func get_cabin_module_interaction(p: CharacterBody3D) -> Dictionary:
	if not is_player_in_cabin:
		return {}
	
	var local_p = to_local(p.global_position)
	# Check hatch threshold first if near door
	if not is_hatch_open and local_p.z > 2.0 and local_p.z < 3.3:
		return {"type": "open_hatch", "label": "🚪 " + GameManager.loc("context_open"), "target": self}
	if is_hatch_open and local_p.z > 0.8 and local_p.z <= 2.2 and absf(local_p.x) < 1.2:
		return {"type": "close_hatch", "label": "🚪 " + GameManager.loc("context_close"), "target": self}
		
	# Find the closest module within interaction radius
	var p_2d = Vector2(local_p.x, local_p.z)
	var modules = [
		{"type": "pilot_seat", "pos": Vector2(pilot_seat_pos.x, pilot_seat_pos.z)},
		{"type": "hyperdrive", "pos": Vector2(hyperdrive_pos.x, hyperdrive_pos.z)},
		{"type": "oxygen_gen", "pos": Vector2(oxygen_gen_pos.x, oxygen_gen_pos.z)},
		{"type": "gravity_device", "pos": Vector2(gravity_device_pos.x, gravity_device_pos.z)},
		{"type": "fabricator", "pos": Vector2(fabricator_pos.x, fabricator_pos.z)},
		{"type": "storage", "pos": Vector2(storage_bin_pos.x, storage_bin_pos.z)}
	]
	
	var closest_mod: String = ""
	var min_dist: float = MODULE_INTERACT_RADIUS
	for m in modules:
		var d = p_2d.distance_to(m["pos"])
		if d < min_dist:
			min_dist = d
			closest_mod = m["type"]
			
	match closest_mod:
		"pilot_seat":
			var label = "💺 " + ("LEVANTARSE" if is_player_seated else "PILOTAR NAVE")
			return {"type": "pilot_seat", "label": label, "target": self}
		"hyperdrive":
			var is_ready = GameManager.crafting.is_hyperdrive_complete()
			var status = " [LISTO]" if is_ready else " [REPARAR]"
			return {"type": "hyperdrive", "label": "🚀 HIPERDRIVE" + status, "target": self}
		"oxygen_gen":
			return {"type": "oxygen_gen", "label": "🫁 GENERADOR O2 [100%]", "target": self}
		"gravity_device":
			return {"type": "gravity_device", "label": "🌀 ESTABILIZADOR GRAVEDAD [1.0G]", "target": self}
		"fabricator":
			return {"type": "fabricator", "label": "⚙ FABRICADOR DE PIEZAS", "target": self}
		"storage":
			return {"type": "storage", "label": "📦 ALMACÉN DE NAVE", "target": self}
		
	return {}

func toggle_pilot_seat(p: CharacterBody3D) -> void:
	if not is_player_in_cabin or not is_instance_valid(p):
		return
	if not is_player_seated:
		sit_in_pilot_seat(p)
	else:
		stand_up_from_pilot_seat(p)

func sit_in_pilot_seat(p: CharacterBody3D) -> void:
	is_player_seated = true
	var seat_world_pos = to_global(pilot_seat_pos + Vector3(0.0, 0.25, 0.0))
	p.global_position = seat_world_pos
	p.velocity = Vector3.ZERO
	p.is_action_locked = true
	AudioManager.play("click", 0.9, -1.0)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("CABINA DE MANDO: Telemetría orbital y propulsores sincronizados.")

func stand_up_from_pilot_seat(p: CharacterBody3D) -> void:
	is_player_seated = false
	p.is_action_locked = false
	var stand_pos = to_global(pilot_seat_pos + Vector3(0.0, 0.0, 0.8))
	p.global_position = stand_pos
	AudioManager.play("click", 1.1, -1.0)

func activate_oxygen_generator(p: CharacterBody3D) -> void:
	AudioManager.play("airlock", 1.2, -3.0)
	GameManager.player_stats.oxygen = 100.0
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("SOPORTE VITAL: Generador de O₂ activo. Cabina presurizada al 100%.")

func activate_gravity_device(p: CharacterBody3D) -> void:
	AudioManager.play("thruster", 1.8, -4.0)
	if is_instance_valid(grav_core_sphere):
		var mat = grav_core_sphere.get_active_material(0) as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 4.0
			var tw = create_tween()
			tw.tween_property(mat, "emission_energy_multiplier", 2.2, 1.2)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("ESTABILIZADOR GRAVITACIONAL: Campo 1.0G Nominal. Inercia estabilizada.")

func trigger_hyperjump() -> void:
	if not GameManager.crafting.is_hyperdrive_complete():
		return
	AudioManager.play("hyperdrive", 1.0)
	hyperdrive_launched.emit()
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("HIPERDRIVE INICIADO: Realizando salto estelar hacia el Nexo Sagital...")
	var tw = create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func():
		GameManager.complete_expedition()
	)

func _setup_cabin_modules() -> void:
	if cabin_modules_initialized:
		return
	var interior = get_node_or_null("CabinInterior")
	if not interior:
		return
	cabin_modules_initialized = true
	
	# Common Materials
	var dark_trim = StandardMaterial3D.new()
	dark_trim.albedo_color = Color(0.12, 0.14, 0.18)
	dark_trim.metallic = 0.8
	dark_trim.roughness = 0.4
	
	var accent_orange = StandardMaterial3D.new()
	accent_orange.albedo_color = Color(0.95, 0.45, 0.1)
	accent_orange.metallic = 0.5
	accent_orange.roughness = 0.35
	
	var cyan_glow = StandardMaterial3D.new()
	cyan_glow.albedo_color = Color(0.1, 0.8, 1.0)
	cyan_glow.emission_enabled = true
	cyan_glow.emission = Color(0.15, 0.85, 1.0)
	cyan_glow.emission_energy_multiplier = 2.0
	
	var magenta_glow = StandardMaterial3D.new()
	magenta_glow.albedo_color = Color(0.85, 0.15, 0.95)
	magenta_glow.emission_enabled = true
	magenta_glow.emission = Color(0.9, 0.2, 1.0)
	magenta_glow.emission_energy_multiplier = 2.5
	
	# 1. PILOT SEAT & CONSOLE
	var pilot_seat_node = Node3D.new()
	pilot_seat_node.name = "PilotSeat"
	pilot_seat_node.position = pilot_seat_pos
	pilot_seat_node.add_to_group("cabin_module")
	interior.add_child(pilot_seat_node)
	
	var seat_base = MeshInstance3D.new()
	var seat_base_mesh = BoxMesh.new()
	seat_base_mesh.size = Vector3(0.7, 0.35, 0.7)
	seat_base_mesh.material = dark_trim
	seat_base.mesh = seat_base_mesh
	seat_base.position = Vector3(0.0, 0.175, 0.0)
	pilot_seat_node.add_child(seat_base)
	
	var seat_back = MeshInstance3D.new()
	var seat_back_mesh = BoxMesh.new()
	seat_back_mesh.size = Vector3(0.65, 0.85, 0.18)
	seat_back_mesh.material = accent_orange
	seat_back.mesh = seat_back_mesh
	seat_back.position = Vector3(0.0, 0.7, 0.28)
	seat_back.rotation.x = deg_to_rad(-8.0)
	pilot_seat_node.add_child(seat_back)
	
	var seat_headrest = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.4, 0.22, 0.15)
	head_mesh.material = dark_trim
	seat_headrest.mesh = head_mesh
	seat_headrest.position = Vector3(0.0, 1.2, 0.35)
	pilot_seat_node.add_child(seat_headrest)
	
	var console = MeshInstance3D.new()
	var console_mesh = BoxMesh.new()
	console_mesh.size = Vector3(1.3, 0.65, 0.45)
	console_mesh.material = dark_trim
	console.mesh = console_mesh
	console.position = Vector3(0.0, 0.35, -0.65)
	pilot_seat_node.add_child(console)
	
	var screen = MeshInstance3D.new()
	var screen_mesh = BoxMesh.new()
	screen_mesh.size = Vector3(1.1, 0.32, 0.04)
	screen_mesh.material = cyan_glow
	screen.mesh = screen_mesh
	screen.position = Vector3(0.0, 0.75, -0.55)
	screen.rotation.x = deg_to_rad(-25.0)
	pilot_seat_node.add_child(screen)
	
	# 2. HYPERDRIVE CORE
	var hyper_node = Node3D.new()
	hyper_node.name = "HyperdriveCore"
	hyper_node.position = hyperdrive_pos
	hyper_node.add_to_group("cabin_module")
	interior.add_child(hyper_node)
	
	var hyper_base = MeshInstance3D.new()
	var h_base_mesh = CylinderMesh.new()
	h_base_mesh.top_radius = 0.55
	h_base_mesh.bottom_radius = 0.65
	h_base_mesh.height = 0.35
	h_base_mesh.material = dark_trim
	hyper_base.mesh = h_base_mesh
	hyper_base.position = Vector3(0.0, 0.175, 0.0)
	hyper_node.add_child(hyper_base)
	
	var hyper_top = MeshInstance3D.new()
	var h_top_mesh = CylinderMesh.new()
	h_top_mesh.top_radius = 0.6
	h_top_mesh.bottom_radius = 0.5
	h_top_mesh.height = 0.3
	h_top_mesh.material = dark_trim
	hyper_top.mesh = h_top_mesh
	hyper_top.position = Vector3(0.0, 1.8, 0.0)
	hyper_node.add_child(hyper_top)
	
	var plasma_rod = MeshInstance3D.new()
	var rod_mesh = CylinderMesh.new()
	rod_mesh.top_radius = 0.18
	rod_mesh.bottom_radius = 0.18
	rod_mesh.height = 1.35
	rod_mesh.material = magenta_glow
	plasma_rod.mesh = rod_mesh
	plasma_rod.position = Vector3(0.0, 0.95, 0.0)
	hyper_node.add_child(plasma_rod)
	hyperdrive_plasma_core = plasma_rod
	
	hyperdrive_light = OmniLight3D.new()
	hyperdrive_light.light_color = Color(0.9, 0.2, 1.0)
	hyperdrive_light.light_energy = 1.6
	hyperdrive_light.omni_range = 3.5
	hyperdrive_light.position = Vector3(0.0, 1.0, 0.0)
	hyper_node.add_child(hyperdrive_light)
	
	# 3. OXYGEN GENERATOR
	var o2_node = Node3D.new()
	o2_node.name = "OxygenGenerator"
	o2_node.position = oxygen_gen_pos
	o2_node.add_to_group("cabin_module")
	interior.add_child(o2_node)
	
	var o2_base = MeshInstance3D.new()
	var o2_base_mesh = BoxMesh.new()
	o2_base_mesh.size = Vector3(0.75, 0.25, 1.1)
	o2_base_mesh.material = dark_trim
	o2_base.mesh = o2_base_mesh
	o2_base.position = Vector3(0.0, 0.125, 0.0)
	o2_node.add_child(o2_base)
	
	var o2_tank1 = MeshInstance3D.new()
	var t1_mesh = CylinderMesh.new()
	t1_mesh.top_radius = 0.20
	t1_mesh.bottom_radius = 0.20
	t1_mesh.height = 1.4
	var tank_mat = StandardMaterial3D.new()
	tank_mat.albedo_color = Color(0.9, 0.94, 0.96)
	tank_mat.metallic = 0.6
	tank_mat.roughness = 0.3
	t1_mesh.material = tank_mat
	o2_tank1.mesh = t1_mesh
	o2_tank1.position = Vector3(0.0, 0.9, -0.26)
	o2_node.add_child(o2_tank1)
	
	var o2_tank2 = MeshInstance3D.new()
	o2_tank2.mesh = t1_mesh
	o2_tank2.position = Vector3(0.0, 0.9, 0.26)
	o2_node.add_child(o2_tank2)
	
	var o2_band = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.205
	b_mesh.bottom_radius = 0.205
	b_mesh.height = 0.15
	b_mesh.material = cyan_glow
	o2_band.mesh = b_mesh
	o2_band.position = Vector3(0.0, 1.15, -0.26)
	o2_node.add_child(o2_band)
	
	var o2_band2 = MeshInstance3D.new()
	o2_band2.mesh = b_mesh
	o2_band2.position = Vector3(0.0, 1.15, 0.26)
	o2_node.add_child(o2_band2)
	
	var o2_light = OmniLight3D.new()
	o2_light.light_color = Color(0.2, 0.9, 1.0)
	o2_light.light_energy = 0.9
	o2_light.omni_range = 2.4
	o2_light.position = Vector3(0.0, 1.1, 0.0)
	o2_node.add_child(o2_light)
	
	# 4. GRAVITY DEVICE
	var grav_node = Node3D.new()
	grav_node.name = "GravityDevice"
	grav_node.position = gravity_device_pos
	grav_node.add_to_group("cabin_module")
	interior.add_child(grav_node)
	
	var grav_base = MeshInstance3D.new()
	var g_base_mesh = CylinderMesh.new()
	g_base_mesh.top_radius = 0.52
	g_base_mesh.bottom_radius = 0.58
	g_base_mesh.height = 0.25
	g_base_mesh.radial_segments = 8
	g_base_mesh.material = dark_trim
	grav_base.mesh = g_base_mesh
	grav_base.position = Vector3(0.0, 0.125, 0.0)
	grav_node.add_child(grav_base)
	
	var outer_ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.38
	ring_mesh.outer_radius = 0.46
	ring_mesh.material = dark_trim
	outer_ring.mesh = ring_mesh
	outer_ring.position = Vector3(0.0, 0.65, 0.0)
	grav_node.add_child(outer_ring)
	grav_ring_outer = outer_ring
	
	var inner_ring = MeshInstance3D.new()
	var inner_ring_mesh = TorusMesh.new()
	inner_ring_mesh.inner_radius = 0.24
	inner_ring_mesh.outer_radius = 0.32
	inner_ring_mesh.material = accent_orange
	inner_ring.mesh = inner_ring_mesh
	inner_ring.position = Vector3(0.0, 0.65, 0.0)
	grav_node.add_child(inner_ring)
	grav_ring_inner = inner_ring
	
	var core_sphere = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.14
	s_mesh.height = 0.28
	var sphere_mat = StandardMaterial3D.new()
	sphere_mat.albedo_color = Color(0.65, 0.2, 1.0)
	sphere_mat.emission_enabled = true
	sphere_mat.emission = Color(0.7, 0.25, 1.0)
	sphere_mat.emission_energy_multiplier = 2.2
	s_mesh.material = sphere_mat
	core_sphere.mesh = s_mesh
	core_sphere.position = Vector3(0.0, 0.65, 0.0)
	grav_node.add_child(core_sphere)
	grav_core_sphere = core_sphere
	
	var grav_light = OmniLight3D.new()
	grav_light.light_color = Color(0.7, 0.3, 1.0)
	grav_light.light_energy = 1.3
	grav_light.omni_range = 2.8
	grav_light.position = Vector3(0.0, 0.7, 0.0)
	grav_node.add_child(grav_light)
	
	# 5. STORAGE BIN
	var bin_node = Node3D.new()
	bin_node.name = "StorageBin"
	bin_node.position = storage_bin_pos
	bin_node.add_to_group("cabin_module")
	interior.add_child(bin_node)
	
	var bin_mesh_inst = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.8, 0.65, 1.0)
	var bin_mat = StandardMaterial3D.new()
	bin_mat.albedo_color = Color(0.22, 0.25, 0.30)
	bin_mat.metallic = 0.7
	bin_mat.roughness = 0.4
	b_box.material = bin_mat
	bin_mesh_inst.mesh = b_box
	bin_mesh_inst.position = Vector3(0.0, 0.325, 0.0)
	bin_node.add_child(bin_mesh_inst)
	
	var bin_latch = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.82, 0.12, 0.25)
	l_box.material = accent_orange
	bin_latch.mesh = l_box
	bin_latch.position = Vector3(0.0, 0.66, 0.0)
	bin_node.add_child(bin_latch)
	
	# 6. FABRICATOR WORKBENCH
	var fab_node = Node3D.new()
	fab_node.name = "FabricatorWorkbench"
	fab_node.position = fabricator_pos
	fab_node.add_to_group("cabin_module")
	interior.add_child(fab_node)
	
	var fab_table = MeshInstance3D.new()
	var ft_mesh = BoxMesh.new()
	ft_mesh.size = Vector3(0.8, 0.7, 1.1)
	ft_mesh.material = dark_trim
	fab_table.mesh = ft_mesh
	fab_table.position = Vector3(0.0, 0.35, 0.0)
	fab_node.add_child(fab_table)
	
	var holo_pad = MeshInstance3D.new()
	var hp_mesh = CylinderMesh.new()
	hp_mesh.top_radius = 0.26
	hp_mesh.bottom_radius = 0.26
	hp_mesh.height = 0.04
	hp_mesh.material = cyan_glow
	holo_pad.mesh = hp_mesh
	holo_pad.position = Vector3(0.0, 0.72, 0.0)
	fab_node.add_child(holo_pad)
