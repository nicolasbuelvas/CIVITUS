extends Node3D
class_name SphericalPlanet

const LandingFXProfile = preload("res://scripts/effects/landing_fx_profile.gd")

signal generation_step_changed(step_idx: int, total_steps: int, step_desc: String)
signal planet_ready()

@export var radius: float = 160.0 # 5/10 scale KSP style diorama horizon
@export var face_resolution: int = 32

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D

# Scenes are preloaded asynchronously during Process 1 I/O in LoadingScreen (zero APK cold-start freeze)
var tree_scene: PackedScene = null
var resource_scene: PackedScene = null
var spaceship_scene: PackedScene = null
var character_scene: PackedScene = null
var hud_scene: PackedScene = null
var cave_scene: PackedScene = null
var creature_scene: PackedScene = null
var basalt_scene: PackedScene = null
var flora_scene: PackedScene = null
var shipwreck_scene: PackedScene = null

var planet_params: Dictionary = {}
var active_cam: Camera3D = null
var spaceship_instance: Node3D = null
var ocean_instance: MeshInstance3D = null
var atmosphere_instance: MeshInstance3D = null
var cloud_instance: MeshInstance3D = null
var weather_system: CPUParticles3D = null
var player_instance: CharacterBody3D = null
var hud_instance: Control = null
var noise: FastNoiseLite = FastNoiseLite.new()
var is_generating: bool = false

var spawned_trees: Array = []
var spawned_flora: Array = []
var spawned_ores_tier1: Array = []
var spawned_ores_tier2: Array = []
var spawned_caves: Array = []
var spawned_wrecks: Array = []
var spawned_creatures: Array = []
var is_orbital_lod_active: bool = false

# Meteor streak timer
var meteor_timer: float = 8.0

# Landing sequence and cinematic chase camera state
var landing_target_pos: Vector3 = Vector3.ZERO
var landing_up_dir: Vector3 = Vector3.UP
var is_landing_sequence_running: bool = false
var is_aborted: bool = false
var landing_cinematic_tween: Tween = null
var scorch_crater_mat: ShaderMaterial = null
var scorch_crater_node: MeshInstance3D = null
var ground_plume_fire: CPUParticles3D = null
var ground_plume_smoke: CPUParticles3D = null
var ground_plume_dust: CPUParticles3D = null
var ground_plume_sparks: CPUParticles3D = null

# Dynamic Tidal Oscillations (Rising and falling coastline fluid)
var tide_time: float = 0.0
var tide_amplitude: float = 0.0
var tide_speed: float = 0.065

func abort_generation() -> void:
	is_aborted = true
	is_generating = false
	if landing_cinematic_tween and landing_cinematic_tween.is_valid():
		landing_cinematic_tween.kill()
	if spaceship_instance and spaceship_instance.has_method("abort_landing"):
		spaceship_instance.abort_landing()

func _calc_tide_parameters(p_params: Dictionary) -> void:
	var water_stat = str(p_params.get("water_status", "Seco / Desolado"))
	if water_stat == "Seco / Desolado" or water_stat == "":
		tide_amplitude = 0.0
		return
		
	var grav_g: float = float(p_params.get("gravity_g", 1.0))
	var ocean_cov: float = float(p_params.get("ocean_coverage", 0.68))
	var is_ocean: bool = bool(p_params.get("is_ocean_world", false))
	
	# Low gravity facilitates dynamic tidal swell; expansive ocean coverage enhances liquid surge
	var grav_factor = clampf(1.15 / sqrt(maxf(0.25, grav_g)), 0.6, 2.2)
	var cov_factor = 1.0 if is_ocean else clampf(ocean_cov, 0.4, 1.25)
	
	# Dynamic shore rise and fall between +/-0.35m and +/-1.35m
	tide_amplitude = 0.45 * grav_factor * cov_factor
	tide_speed = 0.065

func get_current_tide() -> float:
	if tide_amplitude <= 0.001:
		return 0.0
	return sin(tide_time * tide_speed) * tide_amplitude + sin(tide_time * tide_speed * 2.2) * (tide_amplitude * 0.25)

func get_ocean_surface_radius() -> float:
	return radius + get_current_tide()

# Global step tracking across 40 fine-grained micro-stages
const TOTAL_SUBSTEPS: int = 40

func _ready() -> void:
	add_to_group("planet")
	_ensure_resource_references()
	_init_planet_world()

func _ensure_resource_references() -> void:
	if not tree_scene: tree_scene = load("res://scenes/entities/paper_tree.tscn")
	if not resource_scene: resource_scene = load("res://scenes/entities/resource_chunk.tscn")
	if not spaceship_scene: spaceship_scene = load("res://scenes/entities/spaceship_3d.tscn")
	if not character_scene: character_scene = load("res://scenes/entities/character_3d.tscn")
	if not hud_scene: hud_scene = load("res://scenes/ui/hud.tscn")
	if not cave_scene: cave_scene = load("res://scenes/entities/cave_grotto.tscn")
	if not creature_scene: creature_scene = load("res://scenes/entities/alien_creature.tscn")
	if not basalt_scene: basalt_scene = load("res://scenes/entities/basalt_column.tscn")
	if not flora_scene: flora_scene = load("res://scenes/entities/procedural_flora.tscn")
	if not shipwreck_scene: shipwreck_scene = load("res://scenes/entities/abandoned_shipwreck.tscn")

func _process(delta: float) -> void:
	# Update dynamic tidal oscillation on planetary fluid
	tide_time += delta
	var current_ocean_r = get_ocean_surface_radius()
	if is_instance_valid(ocean_instance):
		ocean_instance.scale = Vector3.ONE * (current_ocean_r / radius)

	# Update real-time fluid ripple wake around player (ONLY when player is actually in liquid!)
	if is_instance_valid(ocean_instance) and is_instance_valid(player_instance):
		var ocean_mat = ocean_instance.material_override as ShaderMaterial
		if ocean_mat:
			var player_in_water = bool(player_instance.get("is_in_liquid"))
			if player_in_water:
				ocean_mat.set_shader_parameter("character_pos", player_instance.global_position)
				var p_speed = player_instance.velocity.length()
				ocean_mat.set_shader_parameter("character_motion", clampf(p_speed / 4.5, 0.0, 1.5))
			else:
				ocean_mat.set_shader_parameter("character_pos", Vector3.ZERO)
				ocean_mat.set_shader_parameter("character_motion", 0.0)

	# Active chase camera from above tracking spaceship during descent
	if has_node("LandingCinematicCamera3D") and is_instance_valid(spaceship_instance):
		var cam = get_node_or_null("LandingCinematicCamera3D") as Camera3D
		if cam and not cam.get_meta("is_zooming", false):
			var ship_pos = spaceship_instance.global_position
			var ship_fwd = spaceship_instance.global_transform.basis.z.normalized()
			var target_cam_pos = ship_pos + landing_up_dir * 20.0 + ship_fwd * 18.0
			cam.global_position = target_cam_pos
			cam.look_at(ship_pos + landing_up_dir * -1.5, landing_up_dir)

		# Smooth progressive ground scorch and realistic supersonic surface interaction
		if is_instance_valid(spaceship_instance) and not cam.get_meta("is_zooming", false):
			var dist = spaceship_instance.global_position.distance_to(landing_target_pos)
			if scorch_crater_mat:
				var burn_t = clampf(1.0 - (dist / 42.0), 0.0, 1.0)
				var current_opacity = pow(burn_t, 1.4)
				scorch_crater_mat.set_shader_parameter("scorch_opacity", current_opacity)
				scorch_crater_mat.set_shader_parameter("heat_glow", current_opacity * 1.35)
				
			# Supersonic Ground Interaction: Engine exhaust strikes surface when altitude < 30m
			if dist <= 30.0:
				var blast_intensity = clampf(1.0 - (dist / 30.0), 0.0, 1.0)
				if ground_plume_fire:
					ground_plume_fire.emitting = true
					ground_plume_fire.initial_velocity_min = 10.0 + blast_intensity * 14.0
					ground_plume_fire.initial_velocity_max = 18.0 + blast_intensity * 16.0
				if ground_plume_smoke:
					ground_plume_smoke.emitting = true
					ground_plume_smoke.initial_velocity_min = 6.0 + blast_intensity * 10.0
					ground_plume_smoke.initial_velocity_max = 14.0 + blast_intensity * 12.0
				if ground_plume_dust:
					ground_plume_dust.emitting = true
					ground_plume_dust.initial_velocity_min = 8.0 + blast_intensity * 12.0
					ground_plume_dust.initial_velocity_max = 16.0 + blast_intensity * 18.0
				if ground_plume_sparks:
					ground_plume_sparks.emitting = true
			else:
				if ground_plume_fire: ground_plume_fire.emitting = false
				if ground_plume_smoke: ground_plume_smoke.emitting = false
				if ground_plume_dust: ground_plume_dust.emitting = false
				if ground_plume_sparks: ground_plume_sparks.emitting = false

	# Procedural Meteor Streaks & Dynamic Clouds (Fase 5)
	if cloud_instance and is_instance_valid(cloud_instance):
		cloud_instance.rotate_y(delta * 0.006)
		
	if not is_generating:
		meteor_timer -= delta
		if meteor_timer <= 0.0:
			meteor_timer = randf_range(16.0, 32.0)
			var lvl = GameManager.current_planet.get("level", 0)
			if lvl >= 2 and randf() < 0.45:
				_spawn_active_meteorite()
			else:
				_spawn_shooting_star()

	# Dynamic Orbital LOD based on active Camera3D distance
	active_cam = get_viewport().get_camera_3d() if is_inside_tree() and get_viewport() else null
	if is_instance_valid(active_cam):
		var cam_dist = active_cam.global_position.distance_to(global_position)
		if cam_dist > radius + 55.0:
			if not is_orbital_lod_active:
				set_orbital_lod(true)
		elif cam_dist < radius + 42.0:
			if is_orbital_lod_active:
				set_orbital_lod(false)

	# Radial streaming update (culls beyond radius, renders & processes near camera/astronaut)
	if not is_generating and not is_orbital_lod_active:
		radial_streaming_timer -= delta
		if radial_streaming_timer <= 0.0:
			radial_streaming_timer = 0.15
			update_radial_streaming()

const HIGH_DETAIL_LOGIC_DISTANCE: float = 40.0
const MEDIUM_DETAIL_DISTANCE: float = 85.0
const PLANET_HORIZON_DOT_THRESHOLD: float = 0.10
var radial_streaming_timer: float = 0.0

func update_radial_streaming(custom_player_pos: Vector3 = Vector3.ZERO) -> void:
	if is_orbital_lod_active:
		return
	var player_pos = custom_player_pos
	if player_pos == Vector3.ZERO:
		if is_instance_valid(player_instance):
			player_pos = player_instance.global_position
		elif is_instance_valid(active_cam):
			player_pos = active_cam.global_position
		else:
			var vp_cam = get_viewport().get_camera_3d() if is_inside_tree() and get_viewport() else null
			if is_instance_valid(vp_cam):
				player_pos = vp_cam.global_position
			else:
				return
	
	var player_dir = player_pos.normalized()
	
	# Progressive Multi-Stage LOD & Smooth Horizon Occlusion Culling
	for c in spawned_creatures:
		if is_instance_valid(c):
			var dot = player_dir.dot(c.global_position.normalized())
			if dot > PLANET_HORIZON_DOT_THRESHOLD:
				var dist = c.global_position.distance_to(player_pos)
				if c.has_method("set_lod_level"):
					if dist <= HIGH_DETAIL_LOGIC_DISTANCE:
						c.set_lod_level(0)
					elif dist <= MEDIUM_DETAIL_DISTANCE:
						c.set_lod_level(1)
					else:
						c.set_lod_level(2)
				else:
					c.visible = true
					var is_near = dist <= HIGH_DETAIL_LOGIC_DISTANCE
					c.process_mode = Node.PROCESS_MODE_INHERIT if is_near else Node.PROCESS_MODE_DISABLED
					c.set_process(is_near)
					c.set_physics_process(is_near)
			else:
				if c.has_method("set_lod_level"):
					c.set_lod_level(3)
				else:
					c.visible = false
					c.process_mode = Node.PROCESS_MODE_DISABLED
			
	for f in spawned_flora:
		if is_instance_valid(f):
			var dot = player_dir.dot(f.global_position.normalized())
			if dot > PLANET_HORIZON_DOT_THRESHOLD:
				var dist = f.global_position.distance_to(player_pos)
				if f.has_method("set_lod_level"):
					if dist <= HIGH_DETAIL_LOGIC_DISTANCE:
						f.set_lod_level(0)
					elif dist <= MEDIUM_DETAIL_DISTANCE:
						f.set_lod_level(1)
					else:
						f.set_lod_level(2)
				else:
					f.visible = true
					var is_near = dist <= HIGH_DETAIL_LOGIC_DISTANCE
					f.process_mode = Node.PROCESS_MODE_INHERIT if is_near else Node.PROCESS_MODE_DISABLED
					f.set_process(is_near)
			else:
				if f.has_method("set_lod_level"):
					f.set_lod_level(3)
				else:
					f.visible = false
					f.process_mode = Node.PROCESS_MODE_DISABLED
			
	for t in spawned_trees:
		if is_instance_valid(t):
			var dot = player_dir.dot(t.global_position.normalized())
			if dot > 0.08:
				var dist = t.global_position.distance_to(player_pos)
				if t.has_method("set_lod_level"):
					if dist <= HIGH_DETAIL_LOGIC_DISTANCE:
						t.set_lod_level(0)
					elif dist <= MEDIUM_DETAIL_DISTANCE:
						t.set_lod_level(1)
					else:
						t.set_lod_level(2)
				else:
					t.visible = true
					var is_near = dist <= HIGH_DETAIL_LOGIC_DISTANCE
					t.process_mode = Node.PROCESS_MODE_INHERIT if is_near else Node.PROCESS_MODE_DISABLED
					t.set_process(is_near)
			else:
				if t.has_method("set_lod_level"):
					t.set_lod_level(3)
				else:
					t.visible = false
					t.process_mode = Node.PROCESS_MODE_DISABLED
			
	for o in spawned_ores_tier1:
		if is_instance_valid(o):
			var dot = player_dir.dot(o.global_position.normalized())
			if dot > PLANET_HORIZON_DOT_THRESHOLD:
				o.visible = true
				var dist = o.global_position.distance_to(player_pos)
				var is_near = dist <= HIGH_DETAIL_LOGIC_DISTANCE
				o.process_mode = Node.PROCESS_MODE_INHERIT if is_near else Node.PROCESS_MODE_DISABLED
				o.set_process(is_near)
			else:
				o.visible = false
				o.process_mode = Node.PROCESS_MODE_DISABLED
			
	for o in spawned_ores_tier2:
		if is_instance_valid(o):
			var dot = player_dir.dot(o.global_position.normalized())
			if dot > PLANET_HORIZON_DOT_THRESHOLD:
				o.visible = true
				var dist = o.global_position.distance_to(player_pos)
				var is_near = dist <= HIGH_DETAIL_LOGIC_DISTANCE
				o.process_mode = Node.PROCESS_MODE_INHERIT if is_near else Node.PROCESS_MODE_DISABLED
				o.set_process(is_near)
			else:
				o.visible = false
				o.process_mode = Node.PROCESS_MODE_DISABLED

	for w in spawned_wrecks:
		if is_instance_valid(w):
			var dot = player_dir.dot(w.global_position.normalized())
			if dot > 0.08:
				w.visible = true
				var dist = w.global_position.distance_to(player_pos)
				var is_near = dist <= 65.0
				w.process_mode = Node.PROCESS_MODE_INHERIT if is_near else Node.PROCESS_MODE_DISABLED
				w.set_process(is_near)
			else:
				w.visible = false
				w.process_mode = Node.PROCESS_MODE_DISABLED

func get_surface_snap(dir: Vector3, fallback_elev: float = 0.0) -> Dictionary:
	var elev = fallback_elev if fallback_elev != 0.0 else _get_elevation(dir)
	var expected_dist = radius + elev
	var ray_start = global_position + dir * (expected_dist + 25.0)
	var ray_end = global_position + dir * (expected_dist - 15.0)
	if is_inside_tree() and get_world_3d():
		var space = get_world_3d().direct_space_state
		if space:
			var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
			query.collide_with_areas = false
			query.collide_with_bodies = true
			var hit = space.intersect_ray(query)
			if hit and not hit.is_empty():
				var dist = hit.position.distance_to(global_position)
				# Anti-subsurface guarantee: hit must be on or above theoretical terrain crust
				if dist >= expected_dist - 0.05 and absf(dist - expected_dist) < 15.0:
					return {
						"position": hit.position,
						"normal": hit.normal,
						"snapped": true
					}
	return {
		"position": global_position + dir * expected_dist,
		"normal": dir,
		"snapped": false
	}

func set_orbital_lod(active: bool) -> void:
	if is_orbital_lod_active == active:
		return
	is_orbital_lod_active = active
	
	if active:
		for c in spawned_creatures:
			if is_instance_valid(c):
				c.visible = false
				c.process_mode = Node.PROCESS_MODE_DISABLED
				c.set_physics_process(false)
				c.set_process(false)
				
		for f in spawned_flora:
			if is_instance_valid(f):
				f.visible = false
				f.process_mode = Node.PROCESS_MODE_DISABLED
				f.set_process(false)
				
		for t in spawned_trees:
			if is_instance_valid(t):
				t.visible = false
				t.process_mode = Node.PROCESS_MODE_DISABLED
				t.set_process(false)
				
		for o in spawned_ores_tier1:
			if is_instance_valid(o):
				o.visible = false
				o.process_mode = Node.PROCESS_MODE_DISABLED
				o.set_process(false)
				
		for o in spawned_ores_tier2:
			if is_instance_valid(o):
				o.visible = false
				o.process_mode = Node.PROCESS_MODE_DISABLED
				o.set_process(false)
				
		for cv in spawned_caves:
			if is_instance_valid(cv):
				cv.visible = false
				cv.process_mode = Node.PROCESS_MODE_DISABLED
		for w in spawned_wrecks:
			if is_instance_valid(w):
				w.visible = false
				w.process_mode = Node.PROCESS_MODE_DISABLED

		# Culling of any active loose resource chunks, collectibles, dropped items
		var tree_root = get_tree()
		if tree_root:
			for grp in ["resource_chunk", "ore", "collectible", "dropped_item"]:
				for node in tree_root.get_nodes_in_group(grp):
					if is_instance_valid(node) and node is Node3D:
						node.visible = false
						node.process_mode = Node.PROCESS_MODE_DISABLED

		# Ensure planet surface sphere mesh, ocean and atmosphere halo remain visible from afar!
		if is_instance_valid(mesh_instance):
			mesh_instance.visible = true
		if is_instance_valid(ocean_instance):
			ocean_instance.visible = true
		if is_instance_valid(atmosphere_instance):
			atmosphere_instance.visible = true
	else:
		if is_instance_valid(atmosphere_instance):
			atmosphere_instance.visible = false
		if is_instance_valid(player_instance):
			update_radial_streaming()
		else:
			for c in spawned_creatures:
				if is_instance_valid(c):
					c.visible = true
					c.process_mode = Node.PROCESS_MODE_INHERIT
					c.set_physics_process(true)
					c.set_process(true)
			for f in spawned_flora:
				if is_instance_valid(f):
					f.visible = true
					f.process_mode = Node.PROCESS_MODE_INHERIT
					f.set_process(true)
			for t in spawned_trees:
				if is_instance_valid(t):
					t.visible = true
					t.process_mode = Node.PROCESS_MODE_INHERIT
					t.set_process(true)
			for o in spawned_ores_tier1:
				if is_instance_valid(o):
					o.visible = true
					o.process_mode = Node.PROCESS_MODE_INHERIT
					o.set_process(true)
			for o in spawned_ores_tier2:
				if is_instance_valid(o):
					o.visible = true
					o.process_mode = Node.PROCESS_MODE_INHERIT
					o.set_process(true)
			for cv in spawned_caves:
				if is_instance_valid(cv):
					cv.visible = true
					cv.process_mode = Node.PROCESS_MODE_INHERIT
			for w in spawned_wrecks:
				if is_instance_valid(w):
					w.visible = true
					w.process_mode = Node.PROCESS_MODE_INHERIT
			var tree_root = get_tree()
			if tree_root:
				for grp in ["resource_chunk", "ore", "collectible", "dropped_item"]:
					for node in tree_root.get_nodes_in_group(grp):
						if is_instance_valid(node) and node is Node3D:
							node.visible = true
							node.process_mode = Node.PROCESS_MODE_INHERIT

func _init_planet_world() -> void:
	if is_generating:
		return
	is_generating = true
	
	spawned_trees.clear()
	spawned_flora.clear()
	spawned_ores_tier1.clear()
	spawned_ores_tier2.clear()
	spawned_caves.clear()
	spawned_wrecks.clear()
	spawned_creatures.clear()
	
	var planet_params = GameManager.current_planet
	var p_seed = planet_params.get("seed", 1337)
	
	_calc_tide_parameters(planet_params)
	
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012

	# ================================================================
	# PROCESO 2: [Thread 2/7 CPU] Topología y relieve (6 subprocesos por cara)
	# ================================================================
	var faces = [
		{ "normal": Vector3.UP, "msg": "cpu_sub_1" },
		{ "normal": Vector3.DOWN, "msg": "cpu_sub_2" },
		{ "normal": Vector3.LEFT, "msg": "cpu_sub_3" },
		{ "normal": Vector3.RIGHT, "msg": "cpu_sub_4" },
		{ "normal": Vector3.FORWARD, "msg": "cpu_sub_5" },
		{ "normal": Vector3.BACK, "msg": "cpu_sub_6" }
	]
	
	var accumulated_vertices = PackedVector3Array()
	var accumulated_normals = PackedVector3Array()
	var accumulated_colors = PackedColorArray()
	var accumulated_uvs = PackedVector2Array()

	var face_idx = 0
	for f in faces:
		face_idx += 1
		var current_sub = 6 + face_idx # Sub-steps 7..12
		generation_step_changed.emit(current_sub, TOTAL_SUBSTEPS, GameManager.loc(f.msg))
		if is_inside_tree():
			await get_tree().process_frame
			
		var face_data = _generate_single_face_data(f.normal, planet_params)
		accumulated_vertices.append_array(face_data.vertices)
		accumulated_normals.append_array(face_data.normals)
		accumulated_colors.append_array(face_data.colors)
		accumulated_uvs.append_array(face_data.uvs)
		
		if is_inside_tree():
			await get_tree().process_frame

	# ================================================================
	# PROCESO 3: [Thread 3/7 Malla] Geometría, Océanos y Atmósfera (3 subprocesos)
	# ================================================================
	generation_step_changed.emit(13, TOTAL_SUBSTEPS, GameManager.loc("mesh_sub_1"))
	if is_inside_tree():
		await get_tree().process_frame
		
	var mesh_arrays: Array = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = accumulated_vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = accumulated_normals
	mesh_arrays[Mesh.ARRAY_COLOR] = accumulated_colors
	mesh_arrays[Mesh.ARRAY_TEX_UV] = accumulated_uvs

	generation_step_changed.emit(14, TOTAL_SUBSTEPS, GameManager.loc("mesh_sub_2"))
	if is_inside_tree():
		await get_tree().process_frame

	generation_step_changed.emit(15, TOTAL_SUBSTEPS, GameManager.loc("mesh_sub_3"))
	var planet_mesh = ArrayMesh.new()
	planet_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	var terrain_shader = load("res://assets/shaders/planetary_biome_terrain.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = terrain_shader
	mat.set_shader_parameter("sea_level_radius", radius)
	mat.set_shader_parameter("column_scale", 1.35)
	mat.set_shader_parameter("micro_grain_scale", 28.0)
	mat.set_shader_parameter("roughness", 0.84)
	mat.set_shader_parameter("metallic", 0.12)
	mesh_instance.mesh = planet_mesh
	mesh_instance.material_override = mat
	mesh_instance.visible = false
	
	# Liquid Ocean Sphere at sea level (R = radius)
	var water_stat = planet_params.get("water_status", "Seco / Desolado")
	if water_stat != "Seco / Desolado" and water_stat != "":
		var ocean_mesh = SphereMesh.new()
		ocean_mesh.radius = radius
		ocean_mesh.height = radius * 2.0
		ocean_mesh.radial_segments = 40
		ocean_mesh.rings = 20
		
		var fluid_shader = load("res://assets/shaders/spherical_fluid.gdshader")
		var ocean_mat = ShaderMaterial.new()
		ocean_mat.shader = fluid_shader
		var p_ocean_col: Color = planet_params.get("ocean_color", Color(0.12, 0.52, 0.90))
		ocean_mat.set_shader_parameter("fluid_color", Color(p_ocean_col.r, p_ocean_col.g, p_ocean_col.b, 0.88))
		var deep_col = p_ocean_col.lerp(Color(0.06, 0.28, 0.62), 0.35)
		ocean_mat.set_shader_parameter("deep_color", Color(deep_col.r, deep_col.g, deep_col.b, 0.96))
		ocean_mat.set_shader_parameter("wave_speed", 0.035)
		ocean_mat.set_shader_parameter("wave_amplitude", 0.15)
		ocean_mat.set_shader_parameter("roughness", 0.08)
		ocean_mat.set_shader_parameter("metallic", 0.22)
		
		var is_lava = planet_params.get("is_molten", false) or water_stat == "Lava Fundida"
		ocean_mat.set_shader_parameter("is_emissive", is_lava)
		if is_lava:
			ocean_mat.set_shader_parameter("emission_color", p_ocean_col)
			ocean_mat.set_shader_parameter("emission_energy", 2.6)
			
		ocean_instance = MeshInstance3D.new()
		ocean_instance.name = "OceanInstance"
		ocean_instance.mesh = ocean_mesh
		ocean_instance.material_override = ocean_mat
		ocean_instance.visible = false
		add_child(ocean_instance)

	# Dynamic Spherical Cloud Layer (Fase 5.1)
	if planet_params.get("has_atmosphere", true):
		var c_mesh = SphereMesh.new()
		c_mesh.radius = radius + 6.8
		c_mesh.height = (radius + 6.8) * 2.0
		c_mesh.radial_segments = 40
		c_mesh.rings = 20
		
		var c_mat = StandardMaterial3D.new()
		c_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		c_mat.cull_mode = BaseMaterial3D.CULL_BACK
		c_mat.roughness = 0.95
		
		var ocean_cov = planet_params.get("ocean_coverage", 0.0)
		var is_oc_world = planet_params.get("is_ocean_world", false)
		var cloud_alpha = 0.24
		if is_oc_world:
			cloud_alpha = 0.60
		elif ocean_cov > 0.4:
			cloud_alpha = 0.40
		elif water_stat == "Seco / Desolado":
			cloud_alpha = 0.12
		
		var cloud_tint = Color(0.96, 0.97, 1.0, cloud_alpha)
		var p_type = planet_params.get("type", "")
		if p_type.contains("Toxic") or p_type.contains("Acido"):
			cloud_tint = Color(0.85, 0.95, 0.40, cloud_alpha * 1.1)
		elif p_type.contains("Desert") or p_type.contains("Desierto"):
			cloud_tint = Color(0.92, 0.78, 0.62, cloud_alpha)
			
		c_mat.albedo_color = cloud_tint
		
		cloud_instance = MeshInstance3D.new()
		cloud_instance.name = "CloudLayer3D"
		cloud_instance.mesh = c_mesh
		cloud_instance.material_override = c_mat
		cloud_instance.visible = false
		add_child(cloud_instance)
	else:
		cloud_instance = null
		
	if planet_params.get("has_atmosphere", true):
		var atmo_mesh = SphereMesh.new()
		atmo_mesh.radius = radius * 1.055
		atmo_mesh.height = radius * 2.11
		atmo_mesh.radial_segments = 48
		atmo_mesh.rings = 24
		
		var atmo_mat = StandardMaterial3D.new()
		atmo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		atmo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		atmo_mat.cull_mode = BaseMaterial3D.CULL_BACK
		var atmo_col: Color = planet_params.get("atmosphere_color", Color(0.30, 0.70, 1.0))
		atmo_mat.albedo_color = Color(atmo_col.r, atmo_col.g, atmo_col.b, 0.35)
		atmo_mat.rim_enabled = true
		atmo_mat.rim = 1.0
		atmo_mat.rim_tint = 0.85
		
		atmosphere_instance = MeshInstance3D.new()
		atmosphere_instance.name = "AtmosphericHalo3D"
		atmosphere_instance.mesh = atmo_mesh
		atmosphere_instance.material_override = atmo_mat
		atmosphere_instance.visible = false # Surface uses sky shader Rayleigh scattering; halo is strictly for distant orbit
		add_child(atmosphere_instance)
	else:
		atmosphere_instance = null
		
	if is_inside_tree():
		await get_tree().process_frame

	# ================================================================
	# PROCESO 4: [Thread 4/7 Física] Matriz de colisión trimesh (2 subprocesos)
	# ================================================================
	generation_step_changed.emit(16, TOTAL_SUBSTEPS, GameManager.loc("phys_sub_1"))
	if is_inside_tree():
		await get_tree().process_frame
		
	var trimesh_shape = planet_mesh.create_trimesh_shape()
	
	generation_step_changed.emit(17, TOTAL_SUBSTEPS, GameManager.loc("phys_sub_2"))
	collision_shape.shape = trimesh_shape
	if is_inside_tree():
		await get_tree().process_frame

	# ================================================================
	# PROCESO 5: [Thread 5/7 Sector] Módulo espacial y meseta (3 subprocesos)
	# ================================================================
	generation_step_changed.emit(18, TOTAL_SUBSTEPS, GameManager.loc("sect_sub_1"))
	var north_dir = Vector3.UP
	var north_pos = north_dir * (radius + _get_elevation(north_dir) + 0.94)
	if is_inside_tree():
		await get_tree().process_frame

	generation_step_changed.emit(19, TOTAL_SUBSTEPS, GameManager.loc("sect_sub_2"))
	if spaceship_scene:
		spaceship_instance = spaceship_scene.instantiate()
		spaceship_instance.position = north_pos
		spaceship_instance.visible = false
	if is_inside_tree():
		await get_tree().process_frame

	generation_step_changed.emit(20, TOTAL_SUBSTEPS, GameManager.loc("sect_sub_3"))
	landing_target_pos = north_pos
	landing_up_dir = north_dir
	if spaceship_instance:
		_align_node_to_up(spaceship_instance, north_dir)
		add_child(spaceship_instance)
		spaceship_instance.global_position = north_pos + north_dir * 88.0
		spaceship_instance.visible = false
	if is_inside_tree():
		await get_tree().process_frame

	# ================================================================
	# PROCESO 6: [Thread 6/7 Biosfera] Siembra en 6 micro-lotes
	# ================================================================
	await _stream_features_in_batches(planet_params)

	# Dynamic Weather Particles Setup (Bloque F)
	_setup_weather_particles(planet_params, north_pos)

	# ================================================================
	# PROCESO 7: [Pipeline GPU 7/7] Precalentamiento Progresivo de Shaders (13 subprocesos)
	# ================================================================
	# Sub 27: Precompilar atmósfera y cielo procedural
	generation_step_changed.emit(27, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_1"))
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 28: Precalentar sombreador de relieve planetario, océanos y atmósfera
	generation_step_changed.emit(28, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_2"))
	mesh_instance.visible = true
	if ocean_instance:
		ocean_instance.visible = true
	if atmosphere_instance:
		atmosphere_instance.visible = false # Surface uses sky shader Rayleigh scattering; halo is strictly for distant orbit
	if cloud_instance:
		cloud_instance.visible = false # Keep hidden on surface to prevent geometric camera clipping; clouds rendered via sky shader
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 29: Precalentar sombras dinámicas de luz solar
	generation_step_changed.emit(29, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_3"))
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 30: Precalentar materiales metálicos PBR de nave Apolo
	generation_step_changed.emit(30, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_4"))
	if spaceship_instance:
		spaceship_instance.visible = true
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 31: Precalentar yacimientos de hierro y cobre
	generation_step_changed.emit(31, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_5"))
	for ore in spawned_ores_tier1:
		ore.visible = true
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 32: Precalentar yacimientos de silicio, uranio y grutas de cuevas
	generation_step_changed.emit(32, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_6"))
	for ore in spawned_ores_tier2:
		ore.visible = true
	for cave in spawned_caves:
		cave.visible = true
	for creature in spawned_creatures:
		creature.visible = true
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 33: Precalentar biosfera vegetal de forma diferida en sub-lotes atómicos (Bloque H: Cero freeze)
	generation_step_changed.emit(33, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_7"))
	var tree_batch_size = 6
	for start_idx in range(0, spawned_trees.size(), tree_batch_size):
		var end_idx = min(start_idx + tree_batch_size, spawned_trees.size())
		for idx in range(start_idx, end_idx):
			if is_instance_valid(spawned_trees[idx]):
				spawned_trees[idx].visible = true
		if is_inside_tree():
			await get_tree().process_frame

	# Sub 34: Precalentar cinemática y traje de astronauta
	generation_step_changed.emit(34, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_8"))
	_deploy_astronaut_node(north_dir)
	update_radial_streaming()
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 35: Activar cámara orbital 3D en segundo plano
	generation_step_changed.emit(35, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_9"))
	var is_spectator_mode = (get_parent() and get_parent().has_node("SpectatorCamera3D"))
	if not is_spectator_mode:
		var landing_cam = get_node_or_null("LandingCinematicCamera3D") as Camera3D
		if landing_cam:
			landing_cam.current = true
		elif player_instance:
			var cam: Camera3D = player_instance.get_node_or_null("CameraPivot/Camera3D")
			if cam:
				cam.current = true
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 36: Pre-activar matriz de física y colisión
	generation_step_changed.emit(36, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_10"))
	if player_instance:
		player_instance.velocity = Vector3.ZERO
		player_instance.move_and_slide()
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 37: Ensamblar telemetría táctica de soporte vital
	generation_step_changed.emit(37, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_11"))
	_deploy_hud_node()
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 38: Pre-renderizar sombreadores de visor y HUD
	generation_step_changed.emit(38, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_12"))
	if hud_instance:
		hud_instance.visible = false # Hidden until landing cinematic finishes
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 39: Sincronizar búferes finales a 60 FPS
	generation_step_changed.emit(39, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_13"))
	if is_inside_tree():
		await get_tree().process_frame

	# ================================================================
	# FINAL: Despliegue 100% precalentado -> planet_ready
	# ================================================================
	generation_step_changed.emit(40, TOTAL_SUBSTEPS, GameManager.loc("thread_step_ready"))
	if is_inside_tree():
		await get_tree().process_frame
		await get_tree().process_frame
		
	is_generating = false
	planet_ready.emit()
	
	# Standalone autostart (when running world directly without loading screen)
	var has_loader = get_tree().root.find_child("LoadingScreen", true, false) != null
	if not has_loader and not is_landing_sequence_running:
		if is_spectator_mode:
			start_landing_cinematic(true)
		else:
			start_landing_cinematic(false)

func _generate_single_face_data(normal: Vector3, params: Dictionary) -> Dictionary:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var uvs = PackedVector2Array()
	
	var axis_a = Vector3(normal.y, normal.z, normal.x)
	var axis_b = normal.cross(axis_a)
	
	var res = face_resolution
	var r = radius
	
	# Scientific and geological color palettes
	var p_ocean_col: Color = params.get("ocean_color", Color(0.06, 0.35, 0.75))
	var p_beach_col: Color = params.get("beach_color", Color(0.82, 0.75, 0.52))
	var p_land_col: Color = params.get("land_color", params.get("surface_color", Color(0.35, 0.65, 0.25)))
	var p_mount_col: Color = params.get("mountain_color", Color(0.48, 0.42, 0.36))
	var p_peak_col: Color = params.get("peak_color", Color(0.94, 0.97, 1.0))

	for y in range(res):
		var fy0 = (float(y) / float(res) - 0.5) * 2.0
		var fy1 = (float(y + 1) / float(res) - 0.5) * 2.0
		
		for x in range(res):
			var fx0 = (float(x) / float(res) - 0.5) * 2.0
			var fx1 = (float(x + 1) / float(res) - 0.5) * 2.0
			
			var v00 = (normal + axis_a * fx0 + axis_b * fy0).normalized()
			var v10 = (normal + axis_a * fx1 + axis_b * fy0).normalized()
			var v01 = (normal + axis_a * fx0 + axis_b * fy1).normalized()
			var v11 = (normal + axis_a * fx1 + axis_b * fy1).normalized()
			
			var h00 = _calc_elevation_static(noise, v00, params)
			var h10 = _calc_elevation_static(noise, v10, params)
			var h01 = _calc_elevation_static(noise, v01, params)
			var h11 = _calc_elevation_static(noise, v11, params)
			
			var p00 = v00 * (r + h00)
			var p10 = v10 * (r + h10)
			var p01 = v01 * (r + h01)
			var p11 = v11 * (r + h11)
			
			var c00 = _determine_surface_color_smooth(h00, p_ocean_col, p_beach_col, p_land_col, p_mount_col, p_peak_col, v00, params)
			var c10 = _determine_surface_color_smooth(h10, p_ocean_col, p_beach_col, p_land_col, p_mount_col, p_peak_col, v10, params)
			var c01 = _determine_surface_color_smooth(h01, p_ocean_col, p_beach_col, p_land_col, p_mount_col, p_peak_col, v01, params)
			var c11 = _determine_surface_color_smooth(h11, p_ocean_col, p_beach_col, p_land_col, p_mount_col, p_peak_col, v11, params)
			
			# Physical terrain normal calculation with zero extra noise samples
			var tri1_cross = (p01 - p00).cross(p10 - p00).normalized()
			if tri1_cross.dot(v00) < 0.0:
				tri1_cross = -tri1_cross
			var tri2_cross = (p01 - p10).cross(p11 - p10).normalized()
			if tri2_cross.dot(v11) < 0.0:
				tri2_cross = -tri2_cross
				
			# Blend 65% geometric terrain slope + 35% spherical radial for smooth mobile shading
			var n00 = (tri1_cross * 0.65 + p00.normalized() * 0.35).normalized()
			var n10 = (tri1_cross * 0.65 + p10.normalized() * 0.35).normalized()
			var n01 = (tri1_cross * 0.65 + p01.normalized() * 0.35).normalized()
			var n11 = (tri2_cross * 0.65 + p11.normalized() * 0.35).normalized()
			
			# Tri 1
			vertices.push_back(p00)
			vertices.push_back(p01)
			vertices.push_back(p10)
			normals.push_back(n00)
			normals.push_back(n01)
			normals.push_back(n10)
			colors.push_back(c00)
			colors.push_back(c01)
			colors.push_back(c10)
			uvs.push_back(Vector2(0, 0))
			uvs.push_back(Vector2(0, 1))
			uvs.push_back(Vector2(1, 0))
			
			# Tri 2
			vertices.push_back(p10)
			vertices.push_back(p01)
			vertices.push_back(p11)
			normals.push_back(n10)
			normals.push_back(n01)
			normals.push_back(n11)
			colors.push_back(c10)
			colors.push_back(c01)
			colors.push_back(c11)
			uvs.push_back(Vector2(1, 0))
			uvs.push_back(Vector2(0, 1))
			uvs.push_back(Vector2(1, 1))
			
	return {
		"vertices": vertices,
		"normals": normals,
		"colors": colors,
		"uvs": uvs
	}

func _determine_surface_color_smooth(h: float, p_ocean: Color, p_beach: Color, p_land: Color, p_mount: Color, p_peak: Color, norm_dir: Vector3 = Vector3.UP, planet_params: Dictionary = {}) -> Color:
	var base_col: Color
	if h < -3.5:
		# Deep oceanic seabed - rich luminous azure tone instead of dark shadowy black
		base_col = p_ocean.lerp(Color(0.12, 0.45, 0.82), 0.50)
	elif h < 0.2:
		# Shallow coastal shelf & riverbanks
		var t = smoothstep(-3.5, 0.2, h)
		base_col = p_ocean.lerp(p_beach, t)
	elif h < 2.0:
		# Coastal beach sand & shoreline
		var t = smoothstep(0.2, 2.0, h)
		base_col = p_beach.lerp(p_land, t)
	elif h < 8.5:
		# Fertile lowland plains, meadows & valleys
		var t = smoothstep(2.0, 8.5, h)
		base_col = p_land.lerp(p_mount, t * 0.45)
	elif h < 16.5:
		# Craggy mountain slopes, canyon walls & volcanic basalt
		var t = smoothstep(8.5, 16.5, h)
		base_col = p_mount.lerp(p_peak, t * 0.70)
	else:
		# High snowy peaks, ice caps or volcanic obsidian caldera rims
		return p_peak

	# Polar Ice Cap effect at high latitudes for cold/temperate worlds (excluding default test vector)
	if norm_dir != Vector3.UP and planet_params.size() > 0:
		var lat = absf(norm_dir.y)
		var lvl = planet_params.get("level", 0)
		var has_ice = (lvl == 0 or lvl == 3 or str(planet_params.get("water_status", "")).contains("Hielo"))
		if has_ice and lat > 0.80 and h > -2.0:
			var polar_t = smoothstep(0.80, 0.95, lat)
			base_col = base_col.lerp(p_peak, polar_t * 0.88)

	return base_col

func _stream_features_in_batches(planet_params: Dictionary) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = planet_params.get("seed", 1337) + 101
	
	var batch_messages = ["bio_sub_1", "bio_sub_2", "bio_sub_3", "bio_sub_4", "bio_sub_5", "bio_sub_6"]
	var total_items = 300
	var items_per_batch = 50
	var p_beach: Color = planet_params.get("beach_color", Color(0.82, 0.75, 0.52))
	var p_land: Color = planet_params.get("land_color", Color(0.28, 0.55, 0.22))
	var p_mount: Color = planet_params.get("mountain_color", Color(0.48, 0.42, 0.38))
	
	for b in range(6):
		var current_sub = 21 + b # Sub-steps 21..26
		generation_step_changed.emit(current_sub, TOTAL_SUBSTEPS, GameManager.loc(batch_messages[b]))
		if is_inside_tree():
			await get_tree().process_frame
			
		# Dedicated Starter Grove & Mines around Landing Site (Bloque Obbe Vermeij: Ecosistema Vivo Inmediato)
		if b == 0:
			for s_i in range(8):
				var s_ang = float(s_i) * (TAU / 8.0) + 0.35
				var s_dist_factor = 0.12 + (s_i % 2) * 0.04 # ~18 - 25 meters from ship
				var s_dir = Vector3(sin(s_ang) * s_dist_factor, 0.975, cos(s_ang) * s_dist_factor).normalized()
				var s_elev = _get_elevation(s_dir)
				var s_snap = get_surface_snap(s_dir, s_elev)
				var s_pos = s_snap.position
				var s_normal = s_snap.normal
				
				if resource_scene:
					var ore = resource_scene.instantiate()
					ore.ore_type = s_i % 4 # Iron, Copper, Silicon, Uranium starter nodes
					ore.position = s_pos - s_normal * 0.20 # Deep subterranean anchor firmly rooted into the planet crust
					ore.visible = true
					_align_node_to_up(ore, s_normal)
					add_child(ore)
					if ore.ore_type <= 1:
						spawned_ores_tier1.append(ore)
					else:
						spawned_ores_tier2.append(ore)
					
			for t_i in range(12):
				var t_ang = float(t_i) * (TAU / 12.0) + 0.15
				var t_dist_factor = 0.16 + (t_i % 3) * 0.04 # 25-35 meters from ship
				var t_dir = Vector3(sin(t_ang) * t_dist_factor, 0.965, cos(t_ang) * t_dist_factor).normalized()
				var t_elev = _get_elevation(t_dir)
				var t_snap = get_surface_snap(t_dir, t_elev)
				var p_type_start = planet_params.get("type", "Habitable")
				var is_start_tree_viable = not planet_params.get("is_molten", false) and not p_type_start.contains("Vacío") and not p_type_start.contains("Gaseoso") and not planet_params.get("is_ocean_world", false)
				if is_start_tree_viable and t_elev >= -0.5 and tree_scene:
					var tree = tree_scene.instantiate()
					tree.position = t_snap.position - t_snap.normal * 0.25 # Roots buried in crust
					tree.visible = false
					_align_node_to_up(tree, t_snap.normal)
					if tree.has_method("setup_theme"):
						tree.setup_theme(planet_params)
					add_child(tree)
					spawned_trees.append(tree)
					
			if creature_scene and spawned_creatures.is_empty():
				# Starter terrestrial herd
				for c_idx in range(2):
					var c_dir = Vector3(0.10 + c_idx * 0.08, 0.975, -0.12 - c_idx * 0.05).normalized()
					var c_elev = _get_elevation(c_dir)
					var c_snap = get_surface_snap(c_dir, c_elev)
					var creature = creature_scene.instantiate()
					creature.position = c_snap.position + c_snap.normal * 0.5
					creature.visible = false
					_align_node_to_up(creature, c_snap.normal)
					add_child(creature)
					if creature.has_method("setup_creature"):
						creature.setup_creature(planet_params, false, 0) # Peaceful starter terrestrial
					spawned_creatures.append(creature)
				
				# Starter aerial bird/flyer if atmosphere present
				if planet_params.get("has_atmosphere", true):
					var a_dir = Vector3(-0.14, 0.965, 0.18).normalized()
					var a_elev = _get_elevation(a_dir)
					var flyer = creature_scene.instantiate()
					flyer.position = a_dir * (radius + a_elev + 6.0)
					flyer.visible = false
					_align_node_to_up(flyer, a_dir)
					add_child(flyer)
					if flyer.has_method("setup_creature"):
						flyer.setup_creature(planet_params, false, 3) # AERIAL_FLOAT
					spawned_creatures.append(flyer)
				
			if basalt_scene:
				var b_dir = Vector3(-0.16, 0.972, 0.14).normalized()
				var b_elev = _get_elevation(b_dir)
				var basalt = basalt_scene.instantiate()
				basalt.position = b_dir * (radius + b_elev)
				basalt.visible = false
				_align_node_to_up(basalt, b_dir)
				if basalt.has_method("setup_formation"):
					basalt.setup_formation(p_beach if rng.randf() > 0.5 else p_land)
				add_child(basalt)
			
		var start_i = b * items_per_batch
		var end_i = min(start_i + items_per_batch, total_items)
		
		for i in range(start_i, end_i):
			var u = rng.randf()
			var v = rng.randf()
			var theta = u * TAU
			var phi = acos(2.0 * v - 1.0)
			var dir = Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
			
			if dir.dot(Vector3.UP) > 0.92:
				continue
				
			var elev = _get_elevation(dir)
			var surf_snap = get_surface_snap(dir, elev)
			var surf_pos = surf_snap.position
			var surf_normal = surf_snap.normal
			
			# Multi-Domain Procedural Flora (21 Types: 7 Terrestrial, 7 Aquatic, 7 Exotic)
			var p_type = planet_params.get("type", "Habitable")
			var is_flora_viable = not planet_params.get("is_molten", false) and not p_type.contains("Vacío") and not p_type.contains("Gaseoso")
			var has_liquid = str(planet_params.get("water_status", "")) != "Seco / Desolado" and str(planet_params.get("water_status", "")) != ""
			
			if is_flora_viable and flora_scene and rng.randf() < 0.65:
				var flora = flora_scene.instantiate()
				var chosen_type: int = 0
				
				if has_liquid and elev < -0.3:
					# 7 Aquatic Flora types (7 to 13)
					chosen_type = 7 + (rng.randi() % 7)
					flora.position = surf_pos
				elif rng.randf() < 0.28:
					# 7 Exotic Flora types (14 to 20: Snappers, Tumbleweeds, Floaters, Spores, etc.)
					chosen_type = 14 + (rng.randi() % 7)
					flora.position = surf_pos - surf_normal * 0.1
				elif elev >= -0.2 and elev <= 6.5:
					# 7 Terrestrial Flora types (0 to 6: Fractal Trees, Pines, Bushes, Ferns, Cacti, Shrooms, Reeds)
					chosen_type = rng.randi() % 7
					flora.position = surf_pos - surf_normal * 0.2
				else:
					chosen_type = 0
					flora.position = surf_pos - surf_normal * 0.2
					
				flora.visible = false
				_align_node_to_up(flora, surf_normal)
				flora.planet_radius = radius
				if flora.has_method("setup_flora"):
					flora.setup_flora(chosen_type, planet_params, surf_normal)
				add_child(flora)
				spawned_flora.append(flora)
				
			# Standard Fractal Paper Trees for high-density forest clusters
			elif is_flora_viable and elev >= -0.2 and elev <= 6.5 and tree_scene and rng.randf() < 0.55:
				var tree = tree_scene.instantiate()
				tree.position = surf_pos - surf_normal * 0.25 # Roots solidly anchored in ground
				tree.visible = false
				_align_node_to_up(tree, surf_normal)
				if tree.has_method("setup_theme"):
					tree.setup_theme(planet_params)
				add_child(tree)
				spawned_trees.append(tree)
			
			# Procedural Mineral Veins Across All Terrains (Plains, Dunes, Hills & Craters)
			# High geological concentration emerging from bedrock in Mountain/Rock biomes (elev > 0.9)
			var is_mountain_rock = (elev > 0.9)
			var ore_chance = 0.88 if is_mountain_rock else 0.45
			if resource_scene and (is_mountain_rock or i % 5 == 0 or elev < -0.8) and rng.randf() < ore_chance:
				var ore = resource_scene.instantiate()
				var spawnable = GameManager.get_planet_spawnable_ores(planet_params)
				var chosen_ore = spawnable[rng.randi() % spawnable.size()]
				match chosen_ore:
					"iron": ore.ore_type = 0
					"copper": ore.ore_type = 1
					"silicon": ore.ore_type = 2
					"uranium": ore.ore_type = 3
					_: ore.ore_type = 0
				
				# Root subterranean anchor deep into the crust so it physically emerges from the planet
				ore.position = surf_pos - surf_normal * 0.22
				ore.visible = false
				_align_node_to_up(ore, surf_normal)
				add_child(ore)
				
				if ore.ore_type <= 1:
					spawned_ores_tier1.append(ore)
				else:
					spawned_ores_tier2.append(ore)
					
			elif (elev < 1.2 and elev > -2.5) or elev > 5.0:
				# Hexagonal Basalt Column Stepped Terraces (Giant's Causeway coastal/volcanic formations)
				if basalt_scene and rng.randf() < 0.35:
					var basalt = basalt_scene.instantiate()
					basalt.position = surf_pos
					basalt.visible = false
					_align_node_to_up(basalt, surf_normal)
					if basalt.has_method("setup_formation"):
						basalt.setup_formation(p_mount if elev > 3.0 else p_beach)
					add_child(basalt)

			# Multi-Domain Procedural Fauna (21 Types: 7 Terrestrial, 7 Aquatic & 7 Aerial)
			if creature_scene and spawned_creatures.size() < 42 and rng.randf() < 0.55:
				var is_aggro = (elev > 3.0 or planet_params.get("level", 0) >= 2) and (rng.randf() < 0.35)
				var has_atmo = planet_params.get("has_atmosphere", true)
				
				var creature = creature_scene.instantiate()
				creature.planet_radius = radius
				if has_liquid and elev < -0.4:
					# Aquatic creature cruising inside ocean liquid volume (7 Marine species)
					creature.position = dir * (radius - 1.2)
					creature.visible = false
					_align_node_to_up(creature, dir)
					add_child(creature)
					if creature.has_method("setup_creature"):
						creature.setup_creature(planet_params, is_aggro, 2) # AQUATIC_SWIMMER
					spawned_creatures.append(creature)
				elif has_atmo and rng.randf() < 0.35:
					# Aerial creature gliding in planetary sky (7 Flying species)
					creature.position = surf_pos + surf_normal * 5.5
					creature.visible = false
					_align_node_to_up(creature, surf_normal)
					add_child(creature)
					if creature.has_method("setup_creature"):
						creature.setup_creature(planet_params, is_aggro, 3) # AERIAL_FLOAT
					spawned_creatures.append(creature)
				elif elev >= -0.2:
					# Terrestrial quadruped/biped walking on ground (7 Land species)
					creature.position = surf_pos + surf_normal * 0.65
					creature.visible = false
					_align_node_to_up(creature, surf_normal)
					add_child(creature)
					if creature.has_method("setup_creature"):
						creature.setup_creature(planet_params, is_aggro, 0 if rng.randf() > 0.3 else 1)
					spawned_creatures.append(creature)
						
		# Procedural Subterranean Caverns & Mining Shaft Structures
		if b == 4 and cave_scene and spawned_caves.is_empty():
			var p_seed = planet_params.get("seed", 1337)
			for c_idx in range(3):
				var c_dir = get_cenote_direction(p_seed, c_idx)
				var c_elev = _get_elevation(c_dir)
				var c_pos = c_dir * (radius + c_elev)
				var cave = cave_scene.instantiate()
				cave.position = c_pos
				cave.visible = false
				_align_node_to_up(cave, c_dir)
				if cave.has_method("setup_theme"):
					cave.setup_theme(planet_params)
				add_child(cave)
				spawned_caves.append(cave)
				
				# Geologically logical placement: Rich mineral boulders around cave mouths
				if resource_scene:
					for cv_ore in range(2):
						var ore_offset = Vector3(cos(float(cv_ore) * 3.14) * 4.5, 0.0, sin(float(cv_ore) * 3.14) * 4.5)
						var ore_dir = (c_pos + ore_offset).normalized()
						var ore_snap = get_surface_snap(ore_dir, _get_elevation(ore_dir))
						var ore = resource_scene.instantiate()
						ore.ore_type = 2 if cv_ore == 0 else 3 # Silicon crystals or Uranium deposits inside caverns
						ore.position = ore_snap.position - ore_snap.normal * 0.20
						ore.visible = false
						_align_node_to_up(ore, ore_snap.normal)
						add_child(ore)
						spawned_ores_tier2.append(ore)
				
		# Procedural Surface Infrastructures: Abandoned Spaceships / Crashed Wrecks
		if b == 4 and shipwreck_scene and spawned_wrecks.is_empty():
			var p_seed = planet_params.get("seed", 1337)
			for w_idx in range(3):
				var w_th = float((p_seed * 431 + w_idx * 179) % 1000) / 1000.0 * TAU
				var w_ph = 0.85 + float((p_seed * 719 + w_idx * 283) % 1000) / 1000.0 * 1.3
				var w_dir = Vector3(sin(w_ph) * cos(w_th), cos(w_ph), sin(w_ph) * sin(w_th)).normalized()
				var w_elev = _get_elevation(w_dir)
				var w_snap = get_surface_snap(w_dir, w_elev)
				var w_pos = w_snap.position
				var w_norm = w_snap.normal
				var wreck = shipwreck_scene.instantiate()
				wreck.wreck_type = w_idx % 3
				wreck.position = w_pos + w_norm * 0.15 # Rest firmly on surface
				wreck.visible = false
				_align_node_to_up(wreck, w_norm)
				wreck.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(15.0 + w_idx * 4.0))
				add_child(wreck)
				spawned_wrecks.append(wreck)
					
		if is_inside_tree():
			await get_tree().process_frame

func _setup_weather_particles(planet_params: Dictionary, center_pos: Vector3) -> void:
	if not planet_params.get("has_atmosphere", true):
		GameManager.current_weather = "clear"
		GameManager.current_weather_intensity = 0.0
		return
		
	var lvl = planet_params.get("level", 0)
	var ocean_cov = planet_params.get("ocean_coverage", 0.0)
	var p_type = planet_params.get("type", "")
	
	weather_system = CPUParticles3D.new()
	weather_system.name = "WeatherParticles"
	weather_system.position = center_pos + Vector3.UP * 8.0
	weather_system.amount = 54
	weather_system.lifetime = 3.5
	weather_system.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	weather_system.emission_sphere_radius = 28.0
	
	if p_type.contains("Toxic") or p_type.contains("Acido") or lvl == 2:
		# Acid rain
		GameManager.current_weather = "acid_rain"
		GameManager.current_weather_intensity = 0.85
		weather_system.color = Color(0.75, 0.88, 0.20, 0.65)
		weather_system.gravity = Vector3(0, -6.5, 0)
		weather_system.initial_velocity_min = 2.0
		weather_system.initial_velocity_max = 5.0
	elif p_type.contains("Cryo") or p_type.contains("Hielo") or lvl == 3:
		# Cryogenic blizzard / methane flurries
		GameManager.current_weather = "blizzard"
		GameManager.current_weather_intensity = 0.9
		weather_system.color = Color(0.85, 0.95, 1.0, 0.75)
		weather_system.gravity = Vector3(2.0, -3.0, 0)
		weather_system.initial_velocity_min = 2.0
		weather_system.initial_velocity_max = 5.5
	elif p_type.contains("Volcan") or p_type.contains("Lava") or lvl >= 4:
		# Magma embers & ash
		GameManager.current_weather = "ash_embers"
		GameManager.current_weather_intensity = 1.0
		weather_system.color = Color(1.0, 0.45, 0.10, 0.85)
		weather_system.gravity = Vector3(0, 2.5, 0)
		weather_system.initial_velocity_min = 1.0
		weather_system.initial_velocity_max = 3.5
	elif p_type.contains("Desert") or p_type.contains("Desierto") or lvl == 1:
		# Sandstorm / dust storm
		GameManager.current_weather = "sandstorm"
		GameManager.current_weather_intensity = 0.8
		weather_system.color = Color(0.85, 0.50, 0.25, 0.65)
		weather_system.gravity = Vector3(6.0, -0.8, 0)
		weather_system.initial_velocity_min = 5.0
		weather_system.initial_velocity_max = 9.0
	elif ocean_cov > 0.2 or planet_params.get("is_ocean_world", false):
		# Maritime rain
		GameManager.current_weather = "rain"
		GameManager.current_weather_intensity = 0.75
		weather_system.color = Color(0.70, 0.85, 1.0, 0.60)
		weather_system.gravity = Vector3(0.5, -8.0, 0)
		weather_system.initial_velocity_min = 3.0
		weather_system.initial_velocity_max = 6.5
	else:
		GameManager.current_weather = "clear"
		GameManager.current_weather_intensity = 0.0
		weather_system.queue_free()
		weather_system = null
		return
		
	add_child(weather_system)

func _spawn_active_meteorite() -> void:
	if is_generating or not is_inside_tree():
		return
		
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var target_dir = Vector3.UP
	if player_instance and is_instance_valid(player_instance):
		target_dir = player_instance.global_position.normalized()
	else:
		target_dir = landing_up_dir
		
	var rand_offset = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.5, 0.5), rng.randf_range(-1.0, 1.0)).normalized()
	var strike_dir = (target_dir + rand_offset * 0.28).normalized()
	var strike_elev = _get_elevation(strike_dir)
	var strike_pos = strike_dir * (radius + strike_elev)
	var entry_start = strike_pos + strike_dir * 85.0 + Vector3(rng.randf_range(-25.0, 25.0), 0, rng.randf_range(-25.0, 25.0))
	
	var meteor = Node3D.new()
	meteor.name = "ActiveMeteorite"
	add_child(meteor)
	meteor.global_position = entry_start
	
	var m_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.65
	sphere.height = 1.3
	m_mesh.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.08, 0.06)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.1)
	mat.emission_energy_multiplier = 3.5
	m_mesh.material_override = mat
	meteor.add_child(m_mesh)
	
	var trail = CPUParticles3D.new()
	trail.amount = 32
	trail.lifetime = 0.6
	trail.color = Color(1.0, 0.6, 0.15, 0.8)
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 0.4
	trail.gravity = -strike_dir * 12.0
	meteor.add_child(trail)
	
	AudioManager.play("reentry", 1.4, -2.0)
	
	var fall_time = 1.6
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(meteor, "global_position", strike_pos, fall_time)
	tw.tween_callback(func():
		_on_meteorite_impact(strike_pos, strike_dir)
		meteor.queue_free()
	)

func _on_meteorite_impact(pos: Vector3, up_dir: Vector3) -> void:
	AudioManager.play("thruster", 0.6, 4.0)
	AudioManager.play("mine", 0.8, 3.0)
	
	var local_pos = to_local(pos) if is_inside_tree() else pos
	var local_up = (global_transform.basis.inverse() * up_dir).normalized() if is_inside_tree() else up_dir
	
	_init_ground_scorch(local_pos, local_up)
	_spawn_ground_impact_effects(pos, up_dir)
	
	if resource_scene:
		var ore = resource_scene.instantiate()
		var rng = randf()
		if rng < 0.35:
			ore.ore_type = 3 # Uranium
		elif rng < 0.70:
			ore.ore_type = 2 # Silicon
		else:
			ore.ore_type = 0 # Iron
		ore.position = local_pos - local_up * 0.15
		_align_node_to_up(ore, local_up)
		add_child(ore)
		spawned_ores_tier2.append(ore)

func _spawn_shooting_star() -> void:
	# Small ephemeral shooting star streak across upper horizon
	var star = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.4, 0.4, 6.5)
	star.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.7, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.7)
	mat.emission_energy = 3.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star.material_override = mat
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var ang = rng.randf() * TAU
	var start_pos = Vector3(cos(ang) * 190.0, 205.0 + rng.randf_range(-15.0, 15.0), sin(ang) * 190.0)
	var end_pos = start_pos + Vector3(-sin(ang), -0.3, cos(ang)) * 60.0
	
	add_child(star)
	star.look_at_from_position(start_pos, end_pos, Vector3.UP)
	
	var tw = create_tween()
	tw.tween_property(star, "position", end_pos, 1.2)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 1.2)
	tw.tween_callback(star.queue_free)

func start_landing_cinematic(is_spectator: bool = false) -> void:
	if is_landing_sequence_running:
		return
	is_landing_sequence_running = true
	
	# Initialize progressive ground scorch (starts invisible, darkens as thrusters approach ground)
	_init_ground_scorch(landing_target_pos - landing_up_dir * 0.94, landing_up_dir)
	
	if hud_instance:
		hud_instance.visible = false
		
	if player_instance:
		player_instance.visible = false
		player_instance.is_action_locked = true
		player_instance.set_physics_process(false)
		player_instance.set_process(false)
		
	if spaceship_instance:
		spaceship_instance.visible = true
		if spaceship_instance.has_method("play_landing_intro"):
			spaceship_instance.play_landing_intro(landing_target_pos, landing_up_dir)
			
	if not is_spectator:
		var cam = get_node_or_null("LandingCinematicCamera3D") as Camera3D
		if cam:
			cam.current = true
			if spaceship_instance:
				var s_pos = spaceship_instance.global_position
				var s_fwd = spaceship_instance.global_transform.basis.z.normalized()
				cam.global_position = s_pos + landing_up_dir * 20.0 + s_fwd * 18.0
				cam.look_at(s_pos + landing_up_dir * -1.5, landing_up_dir)
	else:
		if spaceship_instance and spaceship_instance.has_signal("landing_completed"):
			if not spaceship_instance.landing_completed.is_connected(_on_spectator_landing_completed):
				spaceship_instance.landing_completed.connect(_on_spectator_landing_completed)

func _on_spectator_landing_completed() -> void:
	if not is_instance_valid(self) or is_aborted:
		return
	var north_elev = _get_elevation(landing_up_dir)
	var true_ground_pos = landing_up_dir * (radius + north_elev)
	_spawn_ground_impact_effects(true_ground_pos, landing_up_dir)

func _deploy_astronaut_node(north_dir: Vector3) -> void:
	var parent_node = get_parent()
	if parent_node and parent_node.has_node("SpectatorCamera3D"):
		return
		
	if not is_instance_valid(player_instance) and character_scene:
		player_instance = character_scene.instantiate()
		player_instance.name = "Character3D"
		# Parent astronaut to SphericalPlanet so diurnal planetary rotation carries player realistically
		add_child(player_instance)
		
	if player_instance:
		player_instance.floor_snap_length = 0.8
		player_instance.floor_max_angle = deg_to_rad(65.0)
		player_instance.planet_radius = radius
		
		# Ground-anchored resting position for spaceship on terrain
		var north_elev = _get_elevation(north_dir)
		var true_ground_pos = north_dir * (radius + north_elev)
		var ground_ship_pos = north_dir * (radius + north_elev + 0.94)
		
		if spaceship_instance:
			var exit_dir = spaceship_instance.global_transform.basis.z.normalized()
			var spawn_pos = ground_ship_pos + north_dir * 0.35 + exit_dir * 0.2
			if player_instance.has_method("setup_spawn"):
				player_instance.setup_spawn(spawn_pos, north_dir, exit_dir)
			else:
				player_instance.global_position = spawn_pos
				player_instance.up_direction = north_dir
				
			# Keep player hidden inside cabin during atmospheric descent intro
			player_instance.visible = false
			player_instance.is_action_locked = true
			
			_deploy_landing_camera(ground_ship_pos, north_dir)
		else:
			player_instance.global_position = ground_ship_pos + north_dir * 0.35
			player_instance.visible = true
			player_instance.is_action_locked = false
			_spawn_ground_impact_effects(true_ground_pos, north_dir)
				
		player_instance.set_physics_process(false)
		player_instance.set_process(false)

func _deploy_landing_camera(ground_ship_pos: Vector3, north_dir: Vector3) -> void:
	if has_node("LandingCinematicCamera3D"):
		return
		
	var cam = Camera3D.new()
	cam.name = "LandingCinematicCamera3D"
	add_child(cam)
	
	# Initial position: Above and behind the spaceship looking down
	var start_cam_pos = ground_ship_pos + north_dir * 108.0 + Vector3(0.0, 0.0, 18.0)
	cam.global_position = start_cam_pos
	cam.look_at(ground_ship_pos + north_dir * 88.0, north_dir)
	cam.current = true
	
	if spaceship_instance and spaceship_instance.has_signal("landing_completed"):
		spaceship_instance.landing_completed.connect(func():
			if not is_instance_valid(cam):
				return
				
			var north_elev = _get_elevation(north_dir)
			var true_ground_pos = north_dir * (radius + north_elev)
			_spawn_ground_impact_effects(true_ground_pos, north_dir)
			
			# 1. Stay in the wide exterior landed shot for 2.0 seconds (HUD hidden, astronaut loaded inside)
			cam.set_meta("is_zooming", true)
			var tw_wait = create_tween()
			tw_wait.tween_interval(2.0)
			tw_wait.tween_callback(func():
				if not is_instance_valid(cam):
					return
					
				var cur_exit = Vector3.FORWARD
				var cur_rt = Vector3.RIGHT
				if is_instance_valid(spaceship_instance):
					cur_exit = spaceship_instance.global_transform.basis.z.normalized()
					cur_rt = spaceship_instance.global_transform.basis.x.normalized()
					
				if is_instance_valid(player_instance):
					var p_pos = spaceship_instance.global_position + north_dir * 0.35 + cur_exit * 0.2
					player_instance.global_position = p_pos
					player_instance.visible = true
					player_instance.is_action_locked = true
					player_instance.is_first_person = false
					player_instance.set_suit_mode(false)
					if player_instance.head: player_instance.head.visible = true
					if player_instance.face: player_instance.face.visible = true
					if player_instance.helmet:
						player_instance.helmet.visible = true
						player_instance.helmet.position = player_instance.HELMET_HELD_POS
						player_instance.helmet.rotation = player_instance.HELMET_HELD_ROT
					if player_instance.left_arm:
						player_instance.left_arm.rotation = player_instance.LEFT_ARM_HELD_ROT
					if player_instance.right_arm:
						player_instance.right_arm.rotation = player_instance.RIGHT_ARM_HELD_ROT

				# 2. Smooth zoom in from exterior into spaceship cabin continuously tracking astronaut
				var p_head = player_instance.global_position + north_dir * 1.45 if is_instance_valid(player_instance) else spaceship_instance.global_position + north_dir * 1.6
				var cabin_cam_pos = p_head + cur_exit * 1.60 + cur_rt * 0.45 + north_dir * 0.12
				var zoom_start_cam_pos = cam.global_position
				
				var tw_enter = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
				tw_enter.tween_method(func(pos: Vector3):
					if is_instance_valid(cam):
						cam.global_position = pos
						cam.look_at(p_head, north_dir)
				, zoom_start_cam_pos, cabin_cam_pos, 1.3)
				tw_enter.parallel().tween_property(cam, "fov", 62.0, 1.3)
				
				tw_enter.tween_callback(func():
					if not is_instance_valid(cam):
						return
						
					AudioManager.play("click", 0.90, -4.0)
					
					# 3. Apenas se entra a la nave, solo se ve por 1 segundo el astronauta (sin zoom dentro de la cabeza)
					var tw_show = create_tween()
					tw_show.tween_interval(1.0)
					
					# Astronaut subtle gesture during the 1-second showcase
					if is_instance_valid(player_instance) and player_instance.head:
						var tw_h = create_tween().set_trans(Tween.TRANS_SINE)
						tw_h.tween_property(player_instance.head, "rotation:y", deg_to_rad(6.0), 0.4)
						tw_h.tween_property(player_instance.head, "rotation:y", deg_to_rad(-4.0), 0.35)
						tw_h.tween_property(player_instance.head, "rotation:y", 0.0, 0.25)
						
					tw_show.tween_callback(func():
						# 4. Cambia directamente a primera persona (sin entrar en la cabeza) + interfaz aparece
						AudioManager.play("click", 1.25, -1.0)
						if is_instance_valid(player_instance):
							var p_cam: Camera3D = player_instance.get_node_or_null("CameraPivot/Camera3D")
							if player_instance.has_method("zoom_camera"):
								player_instance.zoom_camera(-16.0) # Switches to 1st person
							if p_cam:
								p_cam.current = true
							player_instance.set_physics_process(true)
							player_instance.set_process(true)
							player_instance.is_action_locked = false
							
						if is_instance_valid(hud_instance):
							hud_instance.visible = true
							if hud_instance.has_method("activate_hud"):
								hud_instance.activate_hud()
								
						if is_instance_valid(cam):
							cam.queue_free()
					)
				)
			)
		)

func _init_ground_scorch(pos: Vector3, up_dir: Vector3) -> void:
	if has_node("GroundImpactCrater"):
		return
	var crater_mesh = PlaneMesh.new()
	crater_mesh.size = Vector2(16.0, 16.0)
	var crater_inst = MeshInstance3D.new()
	crater_inst.name = "GroundImpactCrater"
	crater_inst.mesh = crater_mesh
	
	var shader = load("res://assets/shaders/scorch_crater.gdshader")
	if shader:
		scorch_crater_mat = ShaderMaterial.new()
		scorch_crater_mat.shader = shader
		scorch_crater_mat.set_shader_parameter("scorch_opacity", 0.0)
		scorch_crater_mat.set_shader_parameter("heat_glow", 0.0)
		crater_inst.material_override = scorch_crater_mat
	
	# Exactly 2cm above the ground surface so it decals onto the terrain
	crater_inst.position = pos + up_dir * 0.02
	_align_node_to_up(crater_inst, up_dir)
	add_child(crater_inst)
	scorch_crater_node = crater_inst
	
	# Kerbal Space Program style Ground Plume Blast & Supersonic Surface Interaction
	var planet_params = GameManager.current_planet if is_instance_valid(GameManager) else {}
	var profile = LandingFXProfile.get_profile(planet_params)
	
	if scorch_crater_mat:
		scorch_crater_mat.set_shader_parameter("crater_center_color", profile.crater_center_color)
		scorch_crater_mat.set_shader_parameter("scorch_edge_color", profile.crater_edge_color)
		scorch_crater_mat.set_shader_parameter("ember_color", profile.crater_ember_color)
		var surf_col = planet_params.get("surface_color", Color(0.45, 0.40, 0.35))
		scorch_crater_mat.set_shader_parameter("planet_regolith_color", surf_col)

	var soft_circle_tex = LandingFXProfile.get_soft_circle_texture()
	var soft_smoke_tex = LandingFXProfile.get_soft_smoke_texture()

	# 1. Radial Ground Surface Fire Splash (hot supersonic gas deflecting horizontally FLAT along the ground)
	ground_plume_fire = CPUParticles3D.new()
	ground_plume_fire.name = "GroundPlumeFire"
	ground_plume_fire.emitting = false
	ground_plume_fire.amount = 50
	ground_plume_fire.lifetime = 0.40
	ground_plume_fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	ground_plume_fire.emission_ring_axis = Vector3(0, 1, 0)
	ground_plume_fire.emission_ring_radius = 1.4
	ground_plume_fire.emission_ring_inner_radius = 0.2
	ground_plume_fire.direction = Vector3(0, 0, 0)
	ground_plume_fire.flatness = 1.0 # 100% horizontal flat deflection along the ground surface, never rises into cabin
	ground_plume_fire.gravity = Vector3(0, -1.5, 0) # Hugs the ground tightly beneath landing legs
	ground_plume_fire.radial_accel_min = 28.0
	ground_plume_fire.radial_accel_max = 48.0
	ground_plume_fire.initial_velocity_min = 14.0
	ground_plume_fire.initial_velocity_max = 26.0
	ground_plume_fire.damping_min = 12.0
	ground_plume_fire.damping_max = 18.0
	ground_plume_fire.color = profile.ground_fire_color
	ground_plume_fire.scale_amount_min = 0.5
	ground_plume_fire.scale_amount_max = 1.4
	var fire_mesh = QuadMesh.new()
	fire_mesh.size = Vector2(1.2, 1.2)
	fire_mesh.material = LandingFXProfile.create_billboard_mat(soft_circle_tex, true)
	ground_plume_fire.mesh = fire_mesh
	crater_inst.add_child(ground_plume_fire)

	# 2. Dense Billowing Ground Smoke (spawns STRICTLY outside the spaceship perimeter > 5.2m)
	ground_plume_smoke = CPUParticles3D.new()
	ground_plume_smoke.name = "GroundPlumeSmoke"
	ground_plume_smoke.emitting = false
	ground_plume_smoke.amount = 65
	ground_plume_smoke.lifetime = profile.ground_smoke_lifetime
	ground_plume_smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	ground_plume_smoke.emission_ring_axis = Vector3(0, 1, 0)
	ground_plume_smoke.emission_ring_radius = 8.5
	ground_plume_smoke.emission_ring_inner_radius = 5.2 # Beyond 3.6m hull and 4.6m legs, NEVER inside ship!
	ground_plume_smoke.direction = Vector3(0, 0.9, 0)
	ground_plume_smoke.spread = 35.0
	ground_plume_smoke.radial_accel_min = 8.0
	ground_plume_smoke.radial_accel_max = 16.0 # Pushes smoke outwards into the terrain
	ground_plume_smoke.gravity = profile.ground_smoke_buoyancy
	ground_plume_smoke.initial_velocity_min = 4.0
	ground_plume_smoke.initial_velocity_max = 10.0
	ground_plume_smoke.damping_min = 4.0
	ground_plume_smoke.damping_max = 8.0
	ground_plume_smoke.color = profile.ground_smoke_color
	ground_plume_smoke.scale_amount_min = 1.6
	ground_plume_smoke.scale_amount_max = profile.ground_smoke_scale_max
	var smoke_mesh = QuadMesh.new()
	smoke_mesh.size = Vector2(2.2, 2.2)
	smoke_mesh.material = LandingFXProfile.create_billboard_mat(soft_smoke_tex, false)
	ground_plume_smoke.mesh = smoke_mesh
	crater_inst.add_child(ground_plume_smoke)

	# 3. Radial Ground Surface Plume (expanding outward along the surface outside ship)
	ground_plume_dust = CPUParticles3D.new()
	ground_plume_dust.name = "GroundPlumeDust"
	ground_plume_dust.emitting = false
	ground_plume_dust.amount = 50
	ground_plume_dust.lifetime = 1.4
	ground_plume_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	ground_plume_dust.emission_ring_axis = Vector3(0, 1, 0)
	ground_plume_dust.emission_ring_radius = 8.0
	ground_plume_dust.emission_ring_inner_radius = 4.8
	ground_plume_dust.direction = Vector3(0, 0.12, 0)
	ground_plume_dust.flatness = 0.85
	ground_plume_dust.radial_accel_min = 16.0
	ground_plume_dust.radial_accel_max = 30.0
	ground_plume_dust.gravity = profile.ground_smoke_buoyancy * 0.4 - Vector3(0, 1.2, 0)
	ground_plume_dust.initial_velocity_min = 8.0
	ground_plume_dust.initial_velocity_max = 18.0
	ground_plume_dust.color = profile.ground_dust_color
	ground_plume_dust.scale_amount_min = 0.8
	ground_plume_dust.scale_amount_max = 2.4
	var dust_mesh = QuadMesh.new()
	dust_mesh.size = Vector2(1.2, 1.2)
	dust_mesh.material = LandingFXProfile.create_billboard_mat(soft_smoke_tex, false)
	ground_plume_dust.mesh = dust_mesh
	crater_inst.add_child(ground_plume_dust)
	
	# 4. Impingement Thermal Sparks (skimming low to the ground)
	ground_plume_sparks = CPUParticles3D.new()
	ground_plume_sparks.name = "GroundPlumeSparks"
	ground_plume_sparks.emitting = false
	ground_plume_sparks.amount = 35
	ground_plume_sparks.lifetime = 0.65
	ground_plume_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	ground_plume_sparks.emission_ring_axis = Vector3(0, 1, 0)
	ground_plume_sparks.emission_ring_radius = 2.2
	ground_plume_sparks.emission_ring_inner_radius = 0.4
	ground_plume_sparks.direction = Vector3(0, 0.15, 0)
	ground_plume_sparks.flatness = 0.85
	ground_plume_sparks.radial_accel_min = 18.0
	ground_plume_sparks.radial_accel_max = 32.0
	ground_plume_sparks.gravity = Vector3(0, -12.0, 0)
	ground_plume_sparks.initial_velocity_min = 10.0
	ground_plume_sparks.initial_velocity_max = 22.0
	ground_plume_sparks.color = profile.ground_spark_color
	crater_inst.add_child(ground_plume_sparks)

func _spawn_ground_impact_effects(pos: Vector3, up_dir: Vector3) -> void:
	if not has_node("GroundImpactCrater"):
		_init_ground_scorch(pos, up_dir)
		
	if scorch_crater_mat:
		scorch_crater_mat.set_shader_parameter("scorch_opacity", 1.0)
		scorch_crater_mat.set_shader_parameter("heat_glow", 1.35)
		# Smooth cooling of ground heat glow after landing over 10 seconds
		var tw_crater_cool = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_crater_cool.tween_method(func(val: float):
			if scorch_crater_mat:
				scorch_crater_mat.set_shader_parameter("heat_glow", val)
		, 1.35, 0.15, 10.0)
		
	if ground_plume_fire:
		ground_plume_fire.emitting = false
	if ground_plume_smoke:
		ground_plume_smoke.emitting = false
	if ground_plume_dust:
		ground_plume_dust.emitting = false
	if ground_plume_sparks:
		ground_plume_sparks.emitting = false
		
	var crater_inst = get_node_or_null("GroundImpactCrater")
	if crater_inst:
		var planet_params = GameManager.current_planet if is_instance_valid(GameManager) else {}
		var profile = LandingFXProfile.get_profile(planet_params)
		var soft_smoke_tex = LandingFXProfile.get_soft_smoke_texture()
		
		# Residual smoke gently drifts up from the perimeter scorched ground (OUTSIDE ship!)
		if not crater_inst.has_node("ResidualSmoke"):
			var smoke = CPUParticles3D.new()
			smoke.name = "ResidualSmoke"
			smoke.emitting = true
			smoke.amount = 30
			smoke.lifetime = 4.0
			smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
			smoke.emission_ring_axis = Vector3(0, 1, 0)
			smoke.emission_ring_radius = 7.5
			smoke.emission_ring_inner_radius = 4.8 # Strictly outside cabin, zero smoke inside!
			smoke.direction = Vector3(0, 1, 0)
			smoke.spread = 26.0
			smoke.radial_accel_min = 1.0
			smoke.radial_accel_max = 3.0
			smoke.gravity = profile.ground_smoke_buoyancy * 0.6
			smoke.initial_velocity_min = 0.4
			smoke.initial_velocity_max = 1.0
			var smoke_col = profile.ground_smoke_color
			smoke_col.a = minf(smoke_col.a, 0.30)
			smoke.color = smoke_col
			smoke.scale_amount_min = 1.6
			smoke.scale_amount_max = 3.6
			var res_smoke_mesh = QuadMesh.new()
			res_smoke_mesh.size = Vector2(1.8, 1.8)
			res_smoke_mesh.material = LandingFXProfile.create_billboard_mat(soft_smoke_tex, false)
			smoke.mesh = res_smoke_mesh
			crater_inst.add_child(smoke)
			
			# Stop residual smoke after 12 seconds
			var tw_smoke = create_tween()
			tw_smoke.tween_interval(12.0)
			tw_smoke.tween_callback(func():
				if is_instance_valid(smoke):
					smoke.emitting = false
			)
			
		# Residual glowing embers crackling in the perimeter cracks
		if not crater_inst.has_node("ResidualEmbers"):
			var embers = CPUParticles3D.new()
			embers.name = "ResidualEmbers"
			embers.emitting = true
			embers.amount = 16
			embers.lifetime = 1.8
			embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
			embers.emission_ring_axis = Vector3(0, 1, 0)
			embers.emission_ring_radius = 7.0
			embers.emission_ring_inner_radius = 4.8
			embers.direction = Vector3(0, 1, 0)
			embers.spread = 45.0
			embers.gravity = Vector3(0, 0.3, 0)
			embers.initial_velocity_min = 0.6
			embers.initial_velocity_max = 1.8
			embers.color = profile.crater_ember_color
			embers.scale_amount_min = 0.3
			embers.scale_amount_max = 0.8
			crater_inst.add_child(embers)
			
			var tw_embers = create_tween()
			tw_embers.tween_interval(8.0)
			tw_embers.tween_callback(func():
				if is_instance_valid(embers):
					embers.emitting = false
			)

func _deploy_hud_node() -> void:
	var parent_node = get_parent()
	if not parent_node or parent_node.has_node("SpectatorCamera3D"):
		return
		
	hud_instance = parent_node.get_node_or_null("HUD")
	if not hud_instance and hud_scene:
		hud_instance = hud_scene.instantiate()
		hud_instance.name = "HUD"
		parent_node.add_child(hud_instance)
		
	if hud_instance and player_instance and hud_instance.has_method("init_player"):
		hud_instance.init_player(player_instance)

static func _calc_elevation_static(noise_obj: FastNoiseLite, norm_dir: Vector3, planet_params: Dictionary = {}) -> float:
	var pole_dot = norm_dir.dot(Vector3.UP)
	var is_ocean = bool(planet_params.get("is_ocean_world", false))
	var p_type = str(planet_params.get("type", ""))
	var is_marine = is_ocean or p_type.contains("Oceán") or p_type.contains("Ocean")
	
	# 1. North Pole Landing Plateau (flattened strictly in immediate ~12m pad under spaceship)
	if pole_dot > 0.982:
		var blend = smoothstep(0.982, 0.995, pole_dot)
		var base_h = _calc_raw_terrain(noise_obj, norm_dir, planet_params)
		var target_pad_h = 1.80 if is_marine else 3.20
		return lerp(base_h, target_pad_h, blend)
		
	# 2. Scenic Landing Bay / Swimming Lake (25m behind spaceship at -Z)
	var water_stat = planet_params.get("water_status", "Seco / Desolado")
	if not is_ocean and water_stat != "Seco / Desolado" and water_stat != "":
		if pole_dot > 0.935 and pole_dot <= 0.980 and norm_dir.z < -0.10:
			var lake_factor = smoothstep(0.935, 0.960, pole_dot) * smoothstep(0.980, 0.965, pole_dot)
			var base_elev = _calc_raw_terrain(noise_obj, norm_dir, planet_params)
			return lerp(base_elev, -1.8, lake_factor * 0.85)
		
	return _calc_raw_terrain(noise_obj, norm_dir, planet_params)

static func _calc_raw_terrain(noise_obj: FastNoiseLite, norm_dir: Vector3, planet_params: Dictionary = {}) -> float:
	var seed_i: int = planet_params.get("seed", noise_obj.seed)
	var lvl: int = planet_params.get("level", 0)
	var has_atmo: bool = planet_params.get("has_atmosphere", true)
	var water_stat: String = str(planet_params.get("water_status", "Seco / Desolado"))
	var has_liquid: bool = (water_stat != "Seco / Desolado" and water_stat != "")
	var is_ocean: bool = bool(planet_params.get("is_ocean_world", false))
	var ocean_cov: float = float(planet_params.get("ocean_coverage", 1.0 if is_ocean else (0.68 if has_liquid else 0.0)))
	
	# 1. Domain Warping: tectonic shear and crustal folding
	var warp_scale = 22.0
	var wx = noise_obj.get_noise_3dv(norm_dir * warp_scale + Vector3(12.3, 45.6, 78.9))
	var wy = noise_obj.get_noise_3dv(norm_dir * warp_scale + Vector3(98.7, 65.4, 32.1))
	var wz = noise_obj.get_noise_3dv(norm_dir * warp_scale + Vector3(54.1, 87.2, 19.4))
	var warped_dir = (norm_dir + Vector3(wx, wy, wz) * 0.36).normalized()

	# 2. Continental Macro-Crust & Oceanic Trenches (-14m to +10m)
	var continent = noise_obj.get_noise_3dv(warped_dir * 30.0) * 11.5

	# 3. Ridged Multifractal Orogeny (Acute razor mountain arêtes and ridges)
	var r_sample = 1.0 - absf(noise_obj.get_noise_3dv(warped_dir * 68.0 + Vector3(24.3, 67.8, 12.5)))
	var mountains = 0.0
	if r_sample > 0.28:
		var norm_r = (r_sample - 0.28) / 0.72
		mountains = pow(norm_r, 2.2) * 18.5

	# 4. Planetary Landmark: Great Shield Volcano ("Mons" like Olympus Mons / Mauna Kea)
	var m_hash = (seed_i * 92837111) ^ 0x291A3B5D
	var m_theta = (float(m_hash & 0xFFFF) / 65535.0) * TAU
	var m_phi = 0.65 + (float((m_hash >> 16) & 0x7FFF) / 32767.0) * 1.7 # Mid-latitudes
	var mons_dir = Vector3(sin(m_phi) * cos(m_theta), cos(m_phi), sin(m_phi) * sin(m_theta)).normalized()
	var d_mons = norm_dir.distance_to(mons_dir)
	var mons_relief = 0.0
	if d_mons < 0.40:
		var flank = smoothstep(0.40, 0.05, d_mons) * 19.0
		if d_mons < 0.10:
			var caldera = smoothstep(0.10, 0.02, d_mons) * 7.5
			flank -= caldera
		mons_relief = flank

	# 5. Planetary Landmark: Great Tectonic Rift Chasm ("Valles Marineris" Graben)
	var rift_axis = Vector3(sin(m_theta * 1.3), cos(m_theta * 0.8), sin(m_theta + 1.5)).normalized()
	var rift_dist = absf(norm_dir.dot(rift_axis))
	var rift_sector = smoothstep(0.75, 0.20, absf(norm_dir.cross(rift_axis).y))
	var canyon_relief = 0.0
	if rift_dist < 0.14 and rift_sector > 0.05:
		var chasm = smoothstep(0.14, 0.015, rift_dist) * 12.5 * rift_sector
		var strata = sin(norm_dir.dot(Vector3.UP) * 38.0) * 1.1
		canyon_relief = -(chasm + strata * smoothstep(0.10, 0.02, rift_dist))
	else:
		var river_noise = absf(noise_obj.get_noise_3dv(warped_dir * 125.0 + Vector3(72.1, 31.8, 49.6)))
		if river_noise < 0.08:
			canyon_relief = -smoothstep(0.08, 0.0, river_noise) * 5.5

	# 6. Karst Sinkholes / Cenote Depressions (Natural cavern entrances)
	var cenote_sink = 0.0
	for c_idx in range(3):
		var c_dir = get_cenote_direction(seed_i, c_idx)
		var d_cen = norm_dir.distance_to(c_dir)
		if d_cen < 0.12:
			# Organic smooth karst depression, avoids sharp pitch-black shadow circles
			var max_depth = 4.2 if has_liquid else 7.0
			var sink = smoothstep(0.12, 0.02, d_cen) * max_depth
			cenote_sink = maxf(cenote_sink, sink)

	# 7. Impact Craters on barren / thin-atmosphere worlds (Moon/Mercury/Mars analogues)
	var crater_relief = 0.0
	if not has_atmo or lvl == 1 or lvl == 3 or lvl == 5:
		for cr_idx in range(4):
			var cr_hash = (seed_i * 49979687 + cr_idx * 7919) ^ 0x27220A95
			var cr_th = (float(cr_hash & 0xFFFF) / 65535.0) * TAU
			var cr_ph = 0.40 + (float((cr_hash >> 16) & 0x7FFF) / 32767.0) * 2.2
			var cr_dir = Vector3(sin(cr_ph) * cos(cr_th), cos(cr_ph), sin(cr_ph) * sin(cr_th)).normalized()
			var d_cr = norm_dir.distance_to(cr_dir)
			var cr_radius = 0.14 + (float((cr_hash >> 8) & 0xFF) / 255.0) * 0.08
			if d_cr < cr_radius:
				var rel = d_cr / cr_radius
				if rel < 0.85:
					var bowl = (1.0 - pow(rel / 0.85, 2.0)) * -5.0
					if rel < 0.20:
						bowl += (1.0 - rel / 0.20) * 2.4
					crater_relief += bowl
				else:
					var rim = sin((rel - 0.85) / 0.15 * PI) * 2.0
					crater_relief += rim

	# 8. Micro-detail and Regolith Roughness
	var detail = noise_obj.get_noise_3dv(norm_dir * 240.0) * 0.95

	# 9. Ocean World and Sea-level Elevation Resolution
	if is_ocean:
		# 100% Oceanic / Aquatic World:
		# Entire planetary crust is submerged below sea level (elevation < 0.0 everywhere!).
		# Submarine features: abyssal plains (-8m to -14m), submarine oceanic ridges (-2m to -5m),
		# hydrothermal seamounts (-1.5m to -4m), and oceanic trenches (-16m). Zero emerged land!
		var abyssal_floor = continent * 0.45 - 9.5
		var sub_ridges = (mountains * 0.35) if mountains > 0.0 else 0.0
		var sub_mons = mons_relief * 0.25
		var trench = canyon_relief * 0.6
		var total_submerged = abyssal_floor + sub_ridges + sub_mons + trench + detail * 0.5
		return clampf(total_submerged, -16.0, -0.6)

	var total_h = continent + mountains + mons_relief + canyon_relief - cenote_sink + crater_relief + detail

	if has_liquid and ocean_cov > 0.10:
		# Procedural liquid shift: calibrates dry land vs submerged ratio
		var sea_shift = lerpf(-1.0, -13.5, clampf((ocean_cov - 0.30) / 0.65, 0.0, 1.0))
		total_h += sea_shift

	return clampf(total_h, -16.0, 26.0)

static func get_cenote_direction(seed_val: int, idx: int) -> Vector3:
	var c_hash = (seed_val * 15485863 + idx * 32452843) ^ 0x5DEECE66D
	var c_th = (float(c_hash & 0xFFFF) / 65535.0) * TAU
	var c_ph = 0.70 + (float((c_hash >> 16) & 0x7FFF) / 32767.0) * 1.5
	return Vector3(sin(c_ph) * cos(c_th), cos(c_ph), sin(c_ph) * sin(c_th)).normalized()

func get_elevation_at_direction(norm_dir: Vector3) -> float:
	return _get_elevation(norm_dir)

func _get_elevation(norm_dir: Vector3) -> float:
	var p_params = planet_params if not planet_params.is_empty() else (GameManager.current_planet if is_instance_valid(GameManager) else {})
	return _calc_elevation_static(noise, norm_dir, p_params)

func _align_node_to_up(node: Node3D, target_up: Vector3) -> void:
	var current_up = Vector3.UP
	if current_up.cross(target_up).length() > 0.001:
		var axis = current_up.cross(target_up).normalized()
		var angle = current_up.angle_to(target_up)
		node.transform.basis = Basis(axis, angle)
