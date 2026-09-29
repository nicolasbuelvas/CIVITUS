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
var cloning_bay_pos: Vector3 = Vector3(-1.8, 0.2, 0.3)
var starmap_pos: Vector3 = Vector3(-1.8, 0.2, 1.6)

var module_damage_status: Dictionary = {
	"hyperdrive": "damaged",
	"oxygen_gen": "nominal",
	"gravity_device": "nominal",
	"propulsion": "nominal",
	"cloning_bay": "nominal",
	"starmap": "nominal"
}

var is_player_seated: bool = false
var grav_ring_outer: Node3D = null
var grav_ring_inner: Node3D = null
var grav_core_sphere: Node3D = null
var hyperdrive_plasma_core: Node3D = null
var hyperdrive_light: OmniLight3D = null
var hyperdrive_status_light: OmniLight3D = null
var cabin_modules_initialized: bool = false

# Electrical Power & Exterior Solar Arrays
var max_energy: float = 100.0
var current_energy: float = 100.0
var has_solar_generation: bool = true
var solar_array_l: Node3D = null
var solar_array_r: Node3D = null

# O2 Canister Injectable Dock System (2 slots)
var o2_tube_1_charge: float = 100.0
var o2_tube_2_charge: float = 100.0
var o2_tube_1_docked: bool = true
var o2_tube_2_docked: bool = true
var o2_tank_mesh_1: MeshInstance3D = null
var o2_tank_mesh_2: MeshInstance3D = null
var o2_led_band_1: MeshInstance3D = null
var o2_led_band_2: MeshInstance3D = null

# Space Flight & Orbital Parking Loop (Space Agency 2138 / Juno New Origins)
enum FlightState {
	LANDED,
	LAUNCHING_TO_ORBIT,
	PARKING_ORBIT,
	INTERPLANETARY_TRANSIT,
	LANDING_APPROACH
}
var flight_state: FlightState = FlightState.LANDED
var target_destination_planet: Dictionary = {}
var transit_duration_sec: float = 120.0
var transit_timer: float = 0.0
var orbital_cruise_speed: float = 0.0
var launch_timer: float = 0.0

# Space Agency / KSP Orbital Piloting & SOI Mechanics
const PLANET_SOI_RADIUS: float = 480.0
const ATMOSPHERE_ENTRY_ALT: float = 45.0
var orbital_camera: Camera3D = null
var is_camera_following_ship: bool = false
var is_in_celestial_soi: bool = false
var current_soi_body_name: String = ""
var is_reentry_burn_active: bool = false
var reentry_progress: float = 0.0
var prev_ship_global_pos: Vector3 = Vector3.ZERO
var prev_ship_basis: Basis = Basis.IDENTITY
var is_artificial_gravity_active: bool = true
var is_hyperdrive_transit: bool = false
var transit_energy_cost: float = 0.0
var transit_fuel_cost: float = 0.0
var distant_planets_root: Node3D = null

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
	_setup_exterior_solar_panels()
	
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

func finish_interplanetary_transit() -> void:
	flight_state = FlightState.PARKING_ORBIT
	update_exterior_engine_state("warm")
	var p_name = target_destination_planet.get("name", "Nuevo Planeta")
	GameManager.select_planet(target_destination_planet)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("LLEGADA A %s • Órbita de estacionamiento alcanzada. Aterrizaje listo." % p_name)
	if hud and hud.has_method("update_flight_mode_ui"):
		hud.update_flight_mode_ui()
	
	initiate_automatic_landing(target_destination_planet)

func initiate_automatic_landing(target_planet: Dictionary = {}) -> void:
	if target_planet.is_empty() and is_instance_valid(GameManager) and GameManager.current_planet.size() > 0:
		target_planet = GameManager.current_planet
	initiate_atmospheric_reentry(target_planet)

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

	# Vehicle frame delta sync (astronaut inside cabin never slips or clips through cabin in orbit/transit)
	if prev_ship_global_pos != Vector3.ZERO:
		if is_player_in_cabin and not is_player_seated and is_instance_valid(player_ref):
			# Transform player from previous ship frame into current ship frame (zero slip, zero clipping)
			var local_p = prev_ship_basis.inverse() * (player_ref.global_position - prev_ship_global_pos)
			player_ref.global_position = global_position + global_transform.basis * local_p
			var rot_delta = global_transform.basis * prev_ship_basis.inverse()
			player_ref.global_transform.basis = (rot_delta * player_ref.global_transform.basis).orthonormalized()
		elif is_player_seated and is_instance_valid(player_ref):
			player_ref.global_position = to_global(pilot_seat_pos + Vector3(0.0, 0.20, -0.05))
			player_ref.global_transform.basis = global_transform.basis
			player_ref.velocity = Vector3.ZERO
	prev_ship_global_pos = global_position
	prev_ship_basis = global_transform.basis

func check_celestial_soi(target_planet: Dictionary = {}) -> Dictionary:
	var p_radius = 160.0
	var body_name = "Planeta"
	if target_planet.is_empty() and is_instance_valid(GameManager) and GameManager.current_planet.size() > 0:
		target_planet = GameManager.current_planet
	if not target_planet.is_empty():
		p_radius = float(target_planet.get("radius", 160.0))
		body_name = str(target_planet.get("name", "Planeta"))
		
	var dist = global_position.length()
	var alt = dist - p_radius
	var in_soi = (dist <= PLANET_SOI_RADIUS)
	is_in_celestial_soi = in_soi
	if in_soi:
		current_soi_body_name = body_name
	var atmo_entered = (alt <= ATMOSPHERE_ENTRY_ALT)
	return {
		"in_soi": in_soi,
		"body_name": body_name,
		"radius": p_radius,
		"altitude": alt,
		"distance": dist,
		"atmo_entered": atmo_entered
	}

func get_pole_landing_position(planet_data: Dictionary = {}) -> Vector3:
	var p_radius = 160.0
	var is_ocean = false
	if planet_data.is_empty() and is_instance_valid(GameManager) and GameManager.current_planet.size() > 0:
		planet_data = GameManager.current_planet
	if not planet_data.is_empty():
		p_radius = float(planet_data.get("radius", 160.0))
		is_ocean = bool(planet_data.get("is_ocean_world", false))
	var pad_h = 1.80 if is_ocean else 3.2
	return Vector3(0.0, p_radius + pad_h, 0.0)

func initiate_atmospheric_reentry(target_planet: Dictionary = {}) -> void:
	if flight_state == FlightState.LANDING_APPROACH or flight_state == FlightState.LANDED:
		return
	if target_planet.is_empty() and is_instance_valid(GameManager) and GameManager.current_planet.size() > 0:
		target_planet = GameManager.current_planet
	target_destination_planet = target_planet
	flight_state = FlightState.LANDING_APPROACH
	is_reentry_burn_active = true
	reentry_progress = 0.0
	update_exterior_engine_state("burn")
	if is_instance_valid(orbital_camera):
		orbital_camera.current = true
		
	var target_pos = get_pole_landing_position(target_planet)
	play_landing_intro(target_pos, Vector3.UP)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("REENTRADA ATMOSFÉRICA INICIADA • Encendido de frenado y guiado a polo...")
	if hud and hud.has_method("update_flight_mode_ui"):
		hud.update_flight_mode_ui()

func reach_surface_landing(target_pos: Vector3 = Vector3.ZERO) -> void:
	if target_pos != Vector3.ZERO:
		global_position = target_pos
	flight_state = FlightState.LANDED
	is_reentry_burn_active = false
	orbital_cruise_speed = 0.0
	update_exterior_engine_state("off")
	
	# Restore planet entities (Requirement 2)
	var planet_node = get_parent()
	if not (planet_node and planet_node.has_method("set_orbital_lod")):
		planet_node = get_tree().get_first_node_in_group("planet")
	if planet_node and planet_node.has_method("set_orbital_lod"):
		planet_node.set_orbital_lod(false)
		
	if is_instance_valid(distant_planets_root):
		distant_planets_root.visible = false
		
	drop_ramp_with_physics()
	landing_completed.emit()
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("ATERRIZAJE POLAR EXITOSO • Módulo en plataforma de descenso.")
	if hud and hud.has_method("update_flight_mode_ui"):
		hud.update_flight_mode_ui()

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

	# 3. Safe Haven: vitals (O2, Suit Hull, Fuel) regenerate ONLY when hatch door is hermetically CLOSED and ship has power!
	if is_player_in_cabin and not is_hatch_open and not is_operating_hatch:
		if current_energy > 0.0:
			GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 60.0 * delta)
			GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 35.0 * delta)
			GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 45.0 * delta)

	# 4. Electrical Grid & Solar Generation
	if current_energy > 0.0:
		if has_solar_generation:
			current_energy = minf(max_energy, current_energy + 1.25 * delta)
		current_energy = maxf(0.0, current_energy - 0.20 * delta) # Base cabin draw
		
		# 5. O2 Canister Injectable Dock Recharging (1% per second = 100 seconds per tube, 200 seconds both)
		if o2_tube_1_docked and o2_tube_1_charge < 100.0:
			o2_tube_1_charge = minf(100.0, o2_tube_1_charge + 1.0 * delta)
			current_energy = maxf(0.0, current_energy - 0.12 * delta)
		if o2_tube_2_docked and o2_tube_2_charge < 100.0:
			o2_tube_2_charge = minf(100.0, o2_tube_2_charge + 1.0 * delta)
			current_energy = maxf(0.0, current_energy - 0.12 * delta)
	else:
		current_energy = 0.0
		if interior_light:
			interior_light.light_color = Color(1.0, 0.2, 0.1)
			interior_light.light_energy = 0.15

	# 6. Space Flight State Machine
	if flight_state == FlightState.LAUNCHING_TO_ORBIT:
		launch_timer += delta
		var up_launch = global_position.normalized()
		if up_launch.length_squared() < 0.001:
			up_launch = Vector3.UP
		global_position += up_launch * (24.0 * delta)
		if is_instance_valid(orbital_camera):
			orbital_camera.current = true
		if is_player_seated and is_instance_valid(player_ref):
			player_ref.global_position = to_global(pilot_seat_pos + Vector3(0.0, 0.20, -0.05))
			player_ref.global_transform.basis = global_transform.basis
			player_ref.velocity = Vector3.ZERO
		if launch_timer >= 5.5:
			reach_parking_orbit()
	elif flight_state == FlightState.PARKING_ORBIT:
		var planet_node = get_tree().get_first_node_in_group("planet")
		var p_center = planet_node.global_position if is_instance_valid(planet_node) else Vector3.ZERO
		var p_radius = planet_node.get("radius") if is_instance_valid(planet_node) and planet_node.get("radius") != null else 160.0
		var to_ship = global_position - p_center
		var current_r = to_ship.length()
		var norm_to_ship = to_ship.normalized()
		
		# Prograde orbit motion around planet
		var orbit_normal = Vector3.UP
		var prograde = norm_to_ship.cross(orbit_normal).normalized()
		if prograde.length_squared() < 0.1:
			orbit_normal = Vector3.RIGHT
			prograde = norm_to_ship.cross(orbit_normal).normalized()
			
		# Inertial orbital movement
		global_position += prograde * (orbital_cruise_speed * delta)
		
		# Synchronize astronaut
		if is_player_seated and is_instance_valid(player_ref):
			if is_instance_valid(orbital_camera):
				orbital_camera.current = true
			player_ref.global_position = to_global(pilot_seat_pos + Vector3(0.0, 0.20, -0.05))
			player_ref.global_transform.basis = global_transform.basis
			player_ref.velocity = Vector3.ZERO
			
			var t_thrust = Input.get_axis("move_backward", "move_forward")
			var t_yaw = Input.get_axis("move_right", "move_left")
			var t_pitch = 0.0
			var t_roll = 0.0
			if Input.is_key_pressed(KEY_UP): t_pitch += 1.0
			if Input.is_key_pressed(KEY_DOWN): t_pitch -= 1.0
			if Input.is_key_pressed(KEY_Q): t_roll -= 1.0
			if Input.is_key_pressed(KEY_E): t_roll += 1.0
			if absf(t_thrust) > 0.05 or absf(t_yaw) > 0.05 or absf(t_pitch) > 0.05 or absf(t_roll) > 0.05:
				apply_space_flight_controls(t_thrust, t_pitch, t_yaw, t_roll, delta)
		elif not is_player_seated and is_instance_valid(player_ref) and is_player_in_cabin:
			# Player is standing/walking inside cabin in orbit!
			# Ensure orbital camera does not override astronaut FPS camera
			if is_instance_valid(orbital_camera) and orbital_camera.current:
				orbital_camera.current = false
		else:
			var target_basis = Basis.looking_at(-prograde, norm_to_ship).orthonormalized()
			global_transform.basis = global_transform.basis.slerp(target_basis, 1.2 * delta).orthonormalized()
			
		# Automatic polar landing trigger when approaching planet:
		if current_r <= (p_radius + ATMOSPHERE_ENTRY_ALT):
			initiate_atmospheric_reentry(GameManager.current_planet if is_instance_valid(GameManager) else {})
	elif flight_state == FlightState.INTERPLANETARY_TRANSIT:
		transit_timer += delta
		if is_player_seated:
			if is_instance_valid(orbital_camera):
				orbital_camera.current = true
			if is_instance_valid(player_ref):
				player_ref.global_position = to_global(pilot_seat_pos + Vector3(0.0, 0.20, -0.05))
				player_ref.global_transform.basis = global_transform.basis
				player_ref.velocity = Vector3.ZERO
		elif not is_player_seated and is_instance_valid(player_ref) and is_player_in_cabin:
			if is_instance_valid(orbital_camera) and orbital_camera.current:
				orbital_camera.current = false
				
		# Forward transit motion in deep space
		var fwd_dir = -global_transform.basis.z
		var transit_speed = 140.0 if is_hyperdrive_transit else 48.0
		global_position += fwd_dir * (transit_speed * delta)
		
		# Continuous draw
		if current_energy > 0.0:
			var draw_rate = 0.50 if is_hyperdrive_transit else 0.18
			current_energy = maxf(0.0, current_energy - draw_rate * delta)
			
		if transit_timer >= transit_duration_sec:
			finish_interplanetary_transit()
	elif flight_state == FlightState.LANDING_APPROACH:
		reentry_progress += delta
		if is_instance_valid(orbital_camera):
			orbital_camera.current = true
		if is_player_seated and is_instance_valid(player_ref):
			player_ref.global_position = to_global(pilot_seat_pos + Vector3(0.0, 0.20, -0.05))
			player_ref.global_transform.basis = global_transform.basis
			player_ref.velocity = Vector3.ZERO
			
		var p_radius = 160.0
		var is_ocean = false
		if not target_destination_planet.is_empty():
			p_radius = float(target_destination_planet.get("radius", 160.0))
			is_ocean = bool(target_destination_planet.get("is_ocean_world", false))
		elif is_instance_valid(GameManager) and GameManager.current_planet.size() > 0:
			p_radius = float(GameManager.current_planet.get("radius", 160.0))
			is_ocean = bool(GameManager.current_planet.get("is_ocean_world", false))
		var pad_h = 1.80 if is_ocean else 3.2
		var target_pos = Vector3(0.0, p_radius + pad_h, 0.0)
		
		# Align ship upright with normal
		global_transform.basis = global_transform.basis.slerp(Basis.IDENTITY, 2.5 * delta).orthonormalized()
		# Descend smoothly toward pole
		global_position = global_position.lerp(target_pos, 2.0 * delta)
		
		if (global_position - target_pos).length() < 0.35 or reentry_progress >= 4.5:
			reach_surface_landing(target_pos)

# Interaction prompt calculation based on exact player location
func get_hatch_interaction_state(p: CharacterBody3D) -> String:
	if is_operating_hatch:
		return ""
	if flight_state != FlightState.LANDED:
		# Strictly forbidden to open hatch in orbit or space transit
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
	if flight_state != FlightState.LANDED:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("ESCOTILLA SELLADA • Bloqueo de seguridad orbital activo (vacío espacial).")
		return
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
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("trigger_suit_eva_alert"):
			hud.trigger_suit_eva_alert()

# Cabin Module Interaction & Management
func get_cabin_module_interaction(p: CharacterBody3D) -> Dictionary:
	if not is_player_in_cabin:
		return {}
	
	var local_p = to_local(p.global_position)
	# Check hatch threshold first if near door
	if flight_state == FlightState.LANDED:
		if not is_hatch_open and local_p.z > 2.0 and local_p.z < 3.3:
			return {"type": "open_hatch", "label": GameManager.loc("context_open"), "target": self}
		if is_hatch_open and local_p.z > 0.8 and local_p.z <= 2.2 and absf(local_p.x) < 1.2:
			return {"type": "close_hatch", "label": GameManager.loc("context_close"), "target": self}
	elif local_p.z > 2.0 and local_p.z < 3.3:
		return {"type": "hatch_locked", "label": "🔒 ESCOTILLA SELLADA (ÓRBITA/VACÍO)", "target": self}
		
	# Find the closest module within interaction radius
	var p_2d = Vector2(local_p.x, local_p.z)
	var modules = [
		{"type": "pilot_seat", "pos": Vector2(pilot_seat_pos.x, pilot_seat_pos.z)},
		{"type": "hyperdrive", "pos": Vector2(hyperdrive_pos.x, hyperdrive_pos.z)},
		{"type": "oxygen_gen", "pos": Vector2(oxygen_gen_pos.x, oxygen_gen_pos.z)},
		{"type": "gravity_device", "pos": Vector2(gravity_device_pos.x, gravity_device_pos.z)},
		{"type": "fabricator", "pos": Vector2(fabricator_pos.x, fabricator_pos.z)},
		{"type": "storage", "pos": Vector2(storage_bin_pos.x, storage_bin_pos.z)},
		{"type": "cloning_bay", "pos": Vector2(cloning_bay_pos.x, cloning_bay_pos.z)},
		{"type": "starmap", "pos": Vector2(starmap_pos.x, starmap_pos.z)}
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
			var label = ""
			if not is_player_seated:
				label = "💺 ASIENTO DE PILOTO [MANDO]"
			elif flight_state == FlightState.LANDED:
				label = "🚀 DESPEGAR A ÓRBITA SEGURA"
			else:
				label = "💺 LEVANTARSE DEL ASIENTO"
			return {"type": "pilot_seat", "label": label, "target": self}
		"hyperdrive":
			var is_ready = GameManager.crafting.is_hyperdrive_complete()
			var status = " [100%]" if is_ready else " [%d%%]" % int(GameManager.crafting.get_hyperdrive_progress() * 100)
			return {"type": "hyperdrive", "label": "🚀 HYPERDRIVE" + status, "target": self}
		"oxygen_gen":
			var dmg = " [DAÑADO]" if module_damage_status.get("oxygen_gen") == "damaged" else " [100%]"
			return {"type": "oxygen_gen", "label": "🫁 GENERADOR O2" + dmg, "target": self}
		"gravity_device":
			var grav_lbl = " [1.0G ACTIVA]" if is_artificial_gravity_active else " [0.0G MICROGRAVEDAD]"
			return {"type": "gravity_device", "label": "🌀 ESTABILIZADOR GRAVEDAD" + grav_lbl, "target": self}
		"fabricator":
			return {"type": "fabricator", "label": "⚙ FABRICADOR DE PIEZAS", "target": self}
		"storage":
			return {"type": "storage", "label": "📦 ALMACÉN DE NAVE", "target": self}
		"cloning_bay":
			return {"type": "cloning_bay", "label": "🧬 BAHÍA DE CLONACIÓN [LISTA]", "target": self}
		"starmap":
			return {"type": "starmap", "label": "🗺️ MAPA ESTELAR [CARTOGRAFÍA]", "target": self}
		
	return {}

func toggle_pilot_seat(p: CharacterBody3D) -> void:
	if not is_player_in_cabin or not is_instance_valid(p):
		return
	if not is_player_seated:
		sit_in_pilot_seat(p)
	elif flight_state == FlightState.LANDED:
		launch_to_safe_orbit()
	else:
		stand_up_from_pilot_seat(p)

func sit_in_pilot_seat(p: CharacterBody3D) -> void:
	is_player_in_cabin = true
	player_ref = p
	is_player_seated = true
	var seat_world_pos = to_global(pilot_seat_pos + Vector3(0.0, 0.20, -0.05))
	var seat_xf = global_transform
	seat_xf.origin = seat_world_pos
	if p.has_method("set_seated_in_cockpit"):
		p.set_seated_in_cockpit(true, seat_xf)
	else:
		p.global_position = seat_world_pos
		p.velocity = Vector3.ZERO
		p.is_action_locked = true
	AudioManager.play("click", 0.9, -1.0)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("open_cockpit_dialog"):
		hud.open_cockpit_dialog(self)
	elif hud and hud.has_method("show_status_toast"):
		if flight_state == FlightState.LANDED:
			hud.show_status_toast("CABINA DE MANDO: Telemetría lista. Despegue a órbita disponible.")
		elif flight_state == FlightState.PARKING_ORBIT:
			hud.show_status_toast("ÓRBITA ESTABLE: Maniobra manual y StarMap disponibles.")

func stand_up_from_pilot_seat(p: CharacterBody3D) -> void:
	is_player_in_cabin = true
	player_ref = p
	is_player_seated = false
	if p.has_method("set_seated_in_cockpit"):
		p.set_seated_in_cockpit(false)
	else:
		p.is_action_locked = false
	var stand_pos = to_global(pilot_seat_pos + Vector3(0.0, 0.0, 0.85))
	p.global_position = stand_pos
	
	# Switch camera from orbital camera to astronaut camera!
	if is_instance_valid(orbital_camera):
		orbital_camera.current = false
	var fps_cam = p.get_node_or_null("Head/CameraFPS")
	if is_instance_valid(fps_cam):
		fps_cam.current = true
		
	AudioManager.play("click", 1.1, -1.0)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("close_cockpit_dialog"):
		hud.close_cockpit_dialog()

func activate_oxygen_generator(p: CharacterBody3D) -> void:
	if current_energy <= 0.0:
		AudioManager.play("click", 0.6, -2.0)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("SOPORTE VITAL APAGADO: Sin suministro eléctrico en la nave.")
		return
		
	AudioManager.play("airlock", 1.2, -3.0)
	GameManager.player_stats.oxygen = 100.0
	
	var hud = get_tree().get_first_node_in_group("hud")
	# Canister interaction: if player has a canister in inventory and generator has empty slot, dock it!
	var has_canister_in_inv = GameManager.crafting and GameManager.crafting.get_item_count("o2_canister") > 0
	if not o2_tube_1_docked and has_canister_in_inv:
		dock_oxygen_canister(1)
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("SOPORTE VITAL: Tubo de O₂ acoplado en Ranura 1. Recargando...")
	elif not o2_tube_2_docked and has_canister_in_inv:
		dock_oxygen_canister(2)
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("SOPORTE VITAL: Tubo de O₂ acoplado en Ranura 2. Recargando...")
	elif o2_tube_1_docked and o2_tube_1_charge >= 95.0:
		withdraw_oxygen_canister(1)
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("SOPORTE VITAL: Barra de O₂ #1 retirada al inventario (100% carga).")
	elif o2_tube_2_docked and o2_tube_2_charge >= 95.0:
		withdraw_oxygen_canister(2)
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("SOPORTE VITAL: Barra de O₂ #2 retirada al inventario (100% carga).")
	else:
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("SOPORTE VITAL: O₂ 100%% | Barra 1: %d%% | Barra 2: %d%%" % [int(o2_tube_1_charge), int(o2_tube_2_charge)])

func activate_gravity_device(p: CharacterBody3D) -> void:
	is_artificial_gravity_active = not is_artificial_gravity_active
	AudioManager.play("thruster", 1.8, -4.0)
	var hud = get_tree().get_first_node_in_group("hud")
	
	if is_artificial_gravity_active:
		if is_instance_valid(grav_core_sphere):
			var mat = grav_core_sphere.get_active_material(0) as StandardMaterial3D
			if mat:
				mat.albedo_color = Color(0.15, 0.75, 1.0)
				mat.emission = Color(0.2, 0.85, 1.0)
				mat.emission_energy_multiplier = 4.0
				var tw = create_tween()
				tw.tween_property(mat, "emission_energy_multiplier", 2.2, 1.2)
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("ESTABILIZADOR GRAVITACIONAL: Campo 1.0G ACTIVO • Gravedad artificial en cabina nominal.")
	else:
		if is_instance_valid(grav_core_sphere):
			var mat = grav_core_sphere.get_active_material(0) as StandardMaterial3D
			if mat:
				mat.albedo_color = Color(0.85, 0.25, 0.95)
				mat.emission = Color(0.75, 0.20, 1.0)
				mat.emission_energy_multiplier = 1.2
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("ESTABILIZADOR GRAVITACIONAL: DESACTIVADO • Microgravedad 0G activa (Flotación inercial).")

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
	o2_tank_mesh_1 = o2_tank1
	
	var o2_tank2 = MeshInstance3D.new()
	o2_tank2.mesh = t1_mesh
	o2_tank2.position = Vector3(0.0, 0.9, 0.26)
	o2_node.add_child(o2_tank2)
	o2_tank_mesh_2 = o2_tank2
	
	var o2_band = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.205
	b_mesh.bottom_radius = 0.205
	b_mesh.height = 0.15
	b_mesh.material = cyan_glow
	o2_band.mesh = b_mesh
	o2_band.position = Vector3(0.0, 1.15, -0.26)
	o2_node.add_child(o2_band)
	o2_led_band_1 = o2_band
	
	var o2_band2 = MeshInstance3D.new()
	o2_band2.mesh = b_mesh
	o2_band2.position = Vector3(0.0, 1.15, 0.26)
	o2_node.add_child(o2_band2)
	o2_led_band_2 = o2_band2
	
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
	
	# 7. CLONING BAY (Bahía de Clonación Médica)
	var clone_node = Node3D.new()
	clone_node.name = "CloningBay"
	clone_node.position = cloning_bay_pos
	clone_node.add_to_group("cabin_module")
	interior.add_child(clone_node)
	
	var clone_base = MeshInstance3D.new()
	var cb_mesh = CylinderMesh.new()
	cb_mesh.top_radius = 0.45
	cb_mesh.bottom_radius = 0.50
	cb_mesh.height = 0.22
	cb_mesh.material = dark_trim
	clone_base.mesh = cb_mesh
	clone_base.position = Vector3(0.0, 0.11, 0.0)
	clone_node.add_child(clone_base)
	
	var clone_capsule = MeshInstance3D.new()
	var cc_mesh = CylinderMesh.new()
	cc_mesh.top_radius = 0.38
	cc_mesh.bottom_radius = 0.38
	cc_mesh.height = 1.35
	var bio_glass = StandardMaterial3D.new()
	bio_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bio_glass.albedo_color = Color(0.2, 0.9, 0.5, 0.45)
	bio_glass.roughness = 0.15
	bio_glass.emission_enabled = true
	bio_glass.emission = Color(0.15, 0.85, 0.45)
	bio_glass.emission_energy_multiplier = 1.2
	clone_capsule.mesh = cc_mesh
	clone_capsule.material_override = bio_glass
	clone_capsule.position = Vector3(0.0, 0.85, 0.0)
	clone_node.add_child(clone_capsule)
	
	var clone_light = OmniLight3D.new()
	clone_light.light_color = Color(0.25, 0.95, 0.5)
	clone_light.light_energy = 1.2
	clone_light.omni_range = 2.5
	clone_light.position = Vector3(0.0, 0.9, 0.0)
	clone_node.add_child(clone_light)
	
	# 8. STARMAP (Consola de Navegación Cartográfica 3D)
	var starmap_node = Node3D.new()
	starmap_node.name = "StarMap"
	starmap_node.position = starmap_pos
	starmap_node.add_to_group("cabin_module")
	interior.add_child(starmap_node)
	
	var sm_pedestal = MeshInstance3D.new()
	var sm_p_mesh = CylinderMesh.new()
	sm_p_mesh.top_radius = 0.35
	sm_p_mesh.bottom_radius = 0.42
	sm_p_mesh.height = 0.65
	sm_p_mesh.material = dark_trim
	sm_pedestal.mesh = sm_p_mesh
	sm_pedestal.position = Vector3(0.0, 0.325, 0.0)
	starmap_node.add_child(sm_pedestal)
	
	var sm_ring = MeshInstance3D.new()
	var sm_r_mesh = TorusMesh.new()
	sm_r_mesh.inner_radius = 0.28
	sm_r_mesh.outer_radius = 0.32
	sm_r_mesh.material = cyan_glow
	sm_ring.mesh = sm_r_mesh
	sm_ring.position = Vector3(0.0, 0.66, 0.0)
	starmap_node.add_child(sm_ring)
	
	var mini_star = MeshInstance3D.new()
	var ms_mesh = SphereMesh.new()
	ms_mesh.radius = 0.08
	ms_mesh.height = 0.16
	var star_mat = StandardMaterial3D.new()
	star_mat.albedo_color = Color(1.0, 0.9, 0.4)
	star_mat.emission_enabled = true
	star_mat.emission = Color(1.0, 0.85, 0.3)
	star_mat.emission_energy_multiplier = 3.0
	mini_star.mesh = ms_mesh
	mini_star.material_override = star_mat
	mini_star.position = Vector3(0.0, 0.88, 0.0)
	starmap_node.add_child(mini_star)

func get_cloning_bay_position() -> Vector3:
	var interior = get_node_or_null("CabinInterior")
	var cb = interior.get_node_or_null("CloningBay") if interior else null
	if cb:
		return cb.global_position
	return to_global(cloning_bay_pos)

func init_modules_for_difficulty(difficulty: int) -> void:
	module_damage_status = {
		"hyperdrive": "damaged",
		"oxygen_gen": "nominal",
		"gravity_device": "nominal",
		"propulsion": "nominal",
		"cloning_bay": "nominal",
		"starmap": "nominal"
	}
	if difficulty >= 2:
		module_damage_status["oxygen_gen"] = "damaged"
	if difficulty >= 3:
		module_damage_status["propulsion"] = "damaged"
		module_damage_status["gravity_device"] = "damaged"

func get_module_status(module_name: String) -> String:
	return module_damage_status.get(module_name, "nominal")

func repair_module(module_name: String) -> bool:
	if not module_damage_status.has(module_name):
		return false
	if module_damage_status[module_name] == "nominal":
		return true
	module_damage_status[module_name] = "nominal"
	AudioManager.play("craft", 1.0, 1.2)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("MÓDULO REPARADO: %s nominal." % module_name.to_upper())
	return true

func update_exterior_engine_state(engine_state: String) -> void:
	var flame = get_node_or_null("HullStructure/MainRocketEngine/FlamePivot/FlamePlume")
	var sparks = get_node_or_null("HullStructure/MainRocketEngine/RocketSparks")
	var light = get_node_or_null("HullStructure/MainRocketEngine/EngineLight")
	match engine_state:
		"off":
			if flame: flame.visible = false
			if sparks: sparks.emitting = false
			if light: light.light_energy = 0.0
		"warm":
			if flame: flame.visible = true
			if sparks: sparks.emitting = false
			if light:
				light.light_energy = 0.8
				light.light_color = Color(1.0, 0.4, 0.1)
		"burn", "ready":
			if flame: flame.visible = true
			if sparks: sparks.emitting = true
			if light:
				light.light_energy = 3.5
				light.light_color = Color(0.3, 0.85, 1.0)

# ----------------- Exterior Solar Arrays (Power Generation) -----------------
func _setup_exterior_solar_panels() -> void:
	var hull = get_node_or_null("HullStructure")
	if not hull:
		return
		
	var solar_mat = StandardMaterial3D.new()
	solar_mat.albedo_color = Color(0.06, 0.14, 0.35)
	solar_mat.metallic = 0.85
	solar_mat.roughness = 0.18
	solar_mat.emission_enabled = true
	solar_mat.emission = Color(0.08, 0.22, 0.45)
	solar_mat.emission_energy_multiplier = 0.4
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.75, 0.65, 0.25)
	frame_mat.metallic = 0.9
	frame_mat.roughness = 0.3
	
	# Left Wing Solar Array
	var wing_l = Node3D.new()
	wing_l.name = "SolarArrayLeft"
	wing_l.position = Vector3(-3.2, 1.8, 0.0)
	hull.add_child(wing_l)
	solar_array_l = wing_l
	
	var boom_l = MeshInstance3D.new()
	var b_mesh_l = BoxMesh.new()
	b_mesh_l.size = Vector3(1.2, 0.1, 0.15)
	b_mesh_l.material = frame_mat
	boom_l.mesh = b_mesh_l
	boom_l.position = Vector3(-0.6, 0.0, 0.0)
	wing_l.add_child(boom_l)
	
	for seg in range(2):
		var panel = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(1.1, 0.05, 1.8)
		p_mesh.material = solar_mat
		panel.mesh = p_mesh
		panel.position = Vector3(-1.4 - float(seg) * 1.25, 0.0, 0.0)
		wing_l.add_child(panel)
		
	# Right Wing Solar Array
	var wing_r = Node3D.new()
	wing_r.name = "SolarArrayRight"
	wing_r.position = Vector3(3.2, 1.8, 0.0)
	hull.add_child(wing_r)
	solar_array_r = wing_r
	
	var boom_r = MeshInstance3D.new()
	var b_mesh_r = BoxMesh.new()
	b_mesh_r.size = Vector3(1.2, 0.1, 0.15)
	b_mesh_r.material = frame_mat
	boom_r.mesh = b_mesh_r
	boom_r.position = Vector3(0.6, 0.0, 0.0)
	wing_r.add_child(boom_r)
	
	for seg in range(2):
		var panel = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(1.1, 0.05, 1.8)
		p_mesh.material = solar_mat
		panel.mesh = p_mesh
		panel.position = Vector3(1.4 + float(seg) * 1.25, 0.0, 0.0)
		wing_r.add_child(panel)

# ----------------- Oxygen Injectable Canisters (2 Slots) -----------------
func withdraw_oxygen_canister(slot_idx: int = 1) -> bool:
	if slot_idx == 1:
		if not o2_tube_1_docked:
			return false
		o2_tube_1_docked = false
		if o2_tank_mesh_1: o2_tank_mesh_1.visible = false
		if o2_led_band_1: o2_led_band_1.visible = false
		if GameManager.crafting:
			GameManager.crafting.add_item("o2_canister", 1)
		AudioManager.play("click", 1.0, 0.0)
		return true
	elif slot_idx == 2:
		if not o2_tube_2_docked:
			return false
		o2_tube_2_docked = false
		if o2_tank_mesh_2: o2_tank_mesh_2.visible = false
		if o2_led_band_2: o2_led_band_2.visible = false
		if GameManager.crafting:
			GameManager.crafting.add_item("o2_canister", 1)
		AudioManager.play("click", 1.0, 0.0)
		return true
	return false

func dock_oxygen_canister(slot_idx: int = 1) -> bool:
	if not GameManager.crafting or GameManager.crafting.get_item_count("o2_canister") <= 0:
		return false
	if slot_idx == 1 and not o2_tube_1_docked:
		o2_tube_1_docked = true
		o2_tube_1_charge = 0.0
		if o2_tank_mesh_1: o2_tank_mesh_1.visible = true
		if o2_led_band_1: o2_led_band_1.visible = true
		GameManager.crafting.consume_item("o2_canister", 1)
		AudioManager.play("click", 1.0, 0.0)
		return true
	elif slot_idx == 2 and not o2_tube_2_docked:
		o2_tube_2_docked = true
		o2_tube_2_charge = 0.0
		if o2_tank_mesh_2: o2_tank_mesh_2.visible = true
		if o2_led_band_2: o2_led_band_2.visible = true
		GameManager.crafting.consume_item("o2_canister", 1)
		AudioManager.play("click", 1.0, 0.0)
		return true
	return false

# ----------------- Space Agency 2138 / Juno New Origins Flight Loop -----------------
func setup_orbital_camera() -> Camera3D:
	if not is_instance_valid(orbital_camera):
		orbital_camera = Camera3D.new()
		orbital_camera.name = "OrbitalFlightCamera3D"
		add_child(orbital_camera)
	orbital_camera.position = Vector3(0.0, 3.8, 12.5)
	orbital_camera.look_at(to_global(Vector3(0.0, 1.2, 0.0)), Vector3.UP)
	orbital_camera.current = true
	is_camera_following_ship = true
	return orbital_camera

func launch_to_safe_orbit() -> void:
	if flight_state != FlightState.LANDED:
		return
	if is_hatch_open:
		is_hatch_open = false
		if hatch_node: hatch_node.rotation.x = 0.0
		if boarding_ramp: boarding_ramp.rotation.x = 0.0
	flight_state = FlightState.LAUNCHING_TO_ORBIT
	launch_timer = 0.0
	setup_orbital_camera()
	update_exterior_engine_state("burn")
	AudioManager.play("thruster", 1.0, 0.0)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("DESPEGUE A ÓRBITA • Ascenso a través de la atmósfera a órbita de estacionamiento...")

func reach_parking_orbit() -> void:
	flight_state = FlightState.PARKING_ORBIT
	if global_position.length() < 220.0:
		global_position = Vector3(0.0, 280.0, 0.0)
	orbital_cruise_speed = 18.0
	update_exterior_engine_state("warm")
	if is_instance_valid(orbital_camera):
		orbital_camera.current = true
		
	# Complete LOD / culling of planet entities in orbit (Requirement 2)
	var planet_node = get_tree().get_first_node_in_group("planet")
	if planet_node and planet_node.has_method("set_orbital_lod"):
		planet_node.set_orbital_lod(true)
		
	# Show distant solar system planets in the background (Requirement 3)
	setup_distant_planets()
	
	AudioManager.play("docking", 1.0, 0.0)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("ÓRBITA SEGURA ESTABLECIDA (220 km) • Controles de vuelo orbital listos.")
	if hud and hud.has_method("update_flight_mode_ui"):
		hud.update_flight_mode_ui()

func apply_space_flight_controls(thrust: float, pitch: float, yaw: float, roll: float, delta: float) -> void:
	if flight_state != FlightState.PARKING_ORBIT:
		return
	# Attitude thrusters (pitch, yaw, roll)
	if absf(yaw) > 0.001:
		rotate_object_local(Vector3.UP, yaw * 1.5 * delta)
	if absf(pitch) > 0.001:
		rotate_object_local(Vector3.RIGHT, pitch * 1.5 * delta)
	if absf(roll) > 0.001:
		rotate_object_local(Vector3.FORWARD, roll * 1.5 * delta)
	
	# Prograde / Retrograde impulse
	orbital_cruise_speed = clampf(orbital_cruise_speed + thrust * 30.0 * delta, -45.0, 160.0)
	var prograde_dir = -global_transform.basis.z
	global_position += prograde_dir * (orbital_cruise_speed * delta)
	
	if absf(thrust) > 0.1:
		update_exterior_engine_state("burn" if thrust > 0.0 else "warm")
		# Consumes fuel and ship energy on thruster firing
		current_energy = maxf(0.0, current_energy - 0.45 * delta)
		GameManager.player_stats.fuel = maxf(0.0, GameManager.player_stats.fuel - 0.30 * delta)
	else:
		update_exterior_engine_state("warm")
		
	# Check SOI and atmospheric penetration
	var soi_info = check_celestial_soi()
	if soi_info.get("atmo_entered", false):
		initiate_atmospheric_reentry(GameManager.current_planet if is_instance_valid(GameManager) else {})

# ----------------- Distant Solar System Planetary Rendering (Requirement 3) -----------------
func setup_distant_planets() -> void:
	if not is_instance_valid(distant_planets_root):
		distant_planets_root = Node3D.new()
		distant_planets_root.name = "DistantPlanetsRoot"
		add_child(distant_planets_root)
	else:
		for c in distant_planets_root.get_children():
			c.queue_free()

	distant_planets_root.visible = (flight_state == FlightState.PARKING_ORBIT or flight_state == FlightState.INTERPLANETARY_TRANSIT)
	
	var sys = GameManager.current_solar_system
	var planets = sys.get("planets", [])
	var cur_p = GameManager.current_planet
	var cur_name = cur_p.get("name", "")
	
	for i in range(planets.size()):
		var p = planets[i]
		var p_name = p.get("name", "Planeta %d" % i)
		if p_name == cur_name:
			continue
			
		var marker = Node3D.new()
		marker.name = "DistantPlanet_%d" % i
		
		# Place on celestial background sphere (~420m away)
		var angle = float(p.get("orbit_angle", float(i) * 1.05 + 0.45))
		var dir = Vector3(cos(angle), sin(angle * 0.4) * 0.15, sin(angle)).normalized()
		marker.position = dir * 420.0
		
		# Miniature celestial body mesh
		var sphere = MeshInstance3D.new()
		sphere.name = "SphereMesh"
		var s_mesh = SphereMesh.new()
		s_mesh.radius = 4.8
		s_mesh.height = 9.6
		s_mesh.radial_segments = 24
		s_mesh.rings = 12
		sphere.mesh = s_mesh
		
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var p_col: Color = p.get("ocean_color", Color(0.2, 0.6, 1.0))
		if p.get("is_desert", false) or p.get("type", "").contains("Desert"):
			p_col = p.get("land_color", Color(0.85, 0.65, 0.4))
		elif p.get("is_molten", false) or p.get("type", "").contains("Lava"):
			p_col = Color(1.0, 0.35, 0.1)
		mat.albedo_color = p_col
		sphere.material_override = mat
		marker.add_child(sphere)
		
		# Miniature planetary rings if present
		if p.get("has_rings", false):
			var ring = MeshInstance3D.new()
			var r_mesh = TorusMesh.new()
			r_mesh.inner_radius = 6.2
			r_mesh.outer_radius = 11.0
			ring.mesh = r_mesh
			var r_mat = StandardMaterial3D.new()
			r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			r_mat.albedo_color = Color(0.85, 0.85, 0.95, 0.7)
			r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ring.material_override = r_mat
			ring.rotation.x = deg_to_rad(25.0)
			marker.add_child(ring)
			
		# Luminous Billboard Label with distance in AU
		var lbl = Label3D.new()
		lbl.name = "InfoLabel"
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.font_size = 28
		lbl.outline_size = 6
		lbl.modulate = Color(0.4, 0.9, 1.0)
		var dist_au = GameManager.calc_transit_distance_au(cur_p, p)
		lbl.text = "🪐 %s\n%.2f AU [%s]" % [p_name, dist_au, p.get("type", "Planeta")]
		lbl.position = Vector3(0.0, 8.0, 0.0)
		marker.add_child(lbl)
		
		distant_planets_root.add_child(marker)

# ----------------- Interplanetary Transit & Hyperdrive (Requirement 3) -----------------
func start_interplanetary_transfer(target_planet: Dictionary, use_hyperdrive: bool = false) -> void:
	target_destination_planet = target_planet
	flight_state = FlightState.INTERPLANETARY_TRANSIT
	transit_timer = 0.0
	is_hyperdrive_transit = use_hyperdrive
	
	var cur_p = GameManager.current_planet
	var dist_au = GameManager.calc_transit_distance_au(cur_p, target_planet)
	
	# Scale: 1 AU = 1 minute (60 seconds) at maximum manual speed
	if dist_au <= 0.0:
		dist_au = 1.0
	var base_dur = maxf(60.0, dist_au * 60.0)
	if use_hyperdrive:
		transit_duration_sec = maxf(4.0, base_dur / 3.5) # 3.5x faster
		# Hyperdrive consumes 2x energy compared to manual transit
		transit_energy_cost = clampf(dist_au * 40.0, 20.0, 90.0)
		transit_fuel_cost = clampf(dist_au * 12.0, 8.0, 30.0)
	else:
		transit_duration_sec = base_dur
		transit_energy_cost = clampf(dist_au * 20.0, 10.0, 45.0)
		transit_fuel_cost = clampf(dist_au * 25.0, 15.0, 60.0)
		
	# Deduct fuel & energy
	current_energy = maxf(0.0, current_energy - transit_energy_cost)
	GameManager.player_stats.fuel = maxf(0.0, GameManager.player_stats.fuel - transit_fuel_cost)
	
	update_exterior_engine_state("burn")
	if use_hyperdrive:
		AudioManager.play("hyperdrive", 1.0, 2.0)
		if is_instance_valid(hyperdrive_light):
			hyperdrive_light.light_energy = 5.0
	else:
		AudioManager.play("thruster", 1.0, 2.0)
		
	var p_name = target_planet.get("name", "Destino Estelar")
	var mode_str = "HIPERDRIVE (2x Consumo Eléctrico, 3.5x Vel)" if use_hyperdrive else "CRUCERO MANUAL (1 AU = 60s)"
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("TRÁNSITO INICIADO • %s • Destino: %s (ETA: %.0fs)" % [mode_str, p_name, transit_duration_sec])
	if hud and hud.has_method("update_flight_mode_ui"):
		hud.update_flight_mode_ui()

# ----------------- Inventory Refueling & Energy Conversion -----------------
func convert_item_to_ship_energy(item_name: String) -> bool:
	var crafting = GameManager.crafting
	if not crafting:
		return false
	if crafting.get_item_count(item_name) <= 0:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("SIN MATERIALES • No tienes %s en inventario o bodega." % item_name)
		return false
		
	var energy_gain = 35.0
	if item_name == "reactor_cell":
		energy_gain = 80.0
	elif item_name == "energy_cell":
		energy_gain = 35.0
		
	crafting.consume_item(item_name, 1)
	current_energy = minf(max_energy, current_energy + energy_gain)
	AudioManager.play("docking", 1.2, 0.0)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("⚡ ENERGÍA RECARGADA: +%.0f%% (Total: %.0f%%)" % [energy_gain, current_energy])
	return true

func convert_item_to_fuel(item_name: String) -> bool:
	var crafting = GameManager.crafting
	if not crafting:
		return false
	if crafting.get_item_count(item_name) <= 0:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("SIN MATERIALES • No tienes %s en inventario o bodega." % item_name)
		return false
		
	var fuel_gain = 50.0
	crafting.consume_item(item_name, 1)
	GameManager.player_stats.fuel = minf(100.0, GameManager.player_stats.fuel + fuel_gain)
	AudioManager.play("collect", 1.0, 0.0)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("⛽ PROPELENTE REPOSTADO: +%.0f%% (Total: %.0f%%)" % [fuel_gain, GameManager.player_stats.fuel])
	return true
