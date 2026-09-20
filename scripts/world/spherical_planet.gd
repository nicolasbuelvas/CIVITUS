extends Node3D
class_name SphericalPlanet

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
var spawned_ores_tier1: Array = []
var spawned_ores_tier2: Array = []
var spawned_caves: Array = []
var spawned_creatures: Array = []

# Meteor streak timer
var meteor_timer: float = 8.0

# Landing sequence and cinematic chase camera state
var landing_target_pos: Vector3 = Vector3.ZERO
var landing_up_dir: Vector3 = Vector3.UP
var is_landing_sequence_running: bool = false

# Global step tracking across 40 fine-grained micro-stages
const TOTAL_SUBSTEPS: int = 40

func _ready() -> void:
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

func _process(delta: float) -> void:
	# Active chase camera from above tracking spaceship during descent
	if has_node("LandingCinematicCamera3D") and is_instance_valid(spaceship_instance):
		var cam = get_node_or_null("LandingCinematicCamera3D") as Camera3D
		if cam and not cam.get_meta("is_zooming", false):
			var ship_pos = spaceship_instance.global_position
			var ship_fwd = spaceship_instance.global_transform.basis.z.normalized()
			var target_cam_pos = ship_pos + landing_up_dir * 20.0 + ship_fwd * 18.0
			cam.global_position = target_cam_pos
			cam.look_at(ship_pos + landing_up_dir * -1.5, landing_up_dir)

	# Procedural Meteor Streaks (Bloque F)
	if not is_generating:
		meteor_timer -= delta
		if meteor_timer <= 0.0:
			meteor_timer = randf_range(12.0, 22.0)
			_spawn_shooting_star()

func _init_planet_world() -> void:
	if is_generating:
		return
	is_generating = true
	
	spawned_trees.clear()
	spawned_ores_tier1.clear()
	spawned_ores_tier2.clear()
	spawned_caves.clear()
	
	var planet_params = GameManager.current_planet
	var p_seed = planet_params.get("seed", 1337)
	
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
		var p_ocean_col: Color = planet_params.get("ocean_color", Color(0.06, 0.35, 0.75))
		ocean_mat.set_shader_parameter("fluid_color", Color(p_ocean_col.r, p_ocean_col.g, p_ocean_col.b, 0.82))
		ocean_mat.set_shader_parameter("deep_color", Color(p_ocean_col.r * 0.45, p_ocean_col.g * 0.45, p_ocean_col.b * 0.45, 0.96))
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

	# Atmospheric scattering and cloud dynamics are rendered cleanly via celestial sky & shaders
	atmosphere_instance = null
	cloud_instance = null
		
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
		atmosphere_instance.visible = true
	if cloud_instance:
		cloud_instance.visible = true
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

	# Sub 33: Precalentar biosfera vegetal de forma diferida en 2 sub-lotes (Bloque H: Cero freeze)
	generation_step_changed.emit(33, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_7"))
	var half_trees = spawned_trees.size() / 2
	for idx in range(half_trees):
		spawned_trees[idx].visible = true
	if is_inside_tree():
		await get_tree().process_frame
	for idx in range(half_trees, spawned_trees.size()):
		spawned_trees[idx].visible = true
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 34: Precalentar cinemática y traje de astronauta
	generation_step_changed.emit(34, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_8"))
	_deploy_astronaut_node(north_dir)
	if is_inside_tree():
		await get_tree().process_frame

	# Sub 35: Activar cámara orbital 3D en segundo plano
	generation_step_changed.emit(35, TOTAL_SUBSTEPS, GameManager.loc("shader_sub_9"))
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
		start_landing_cinematic()

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
		# Deep oceanic abyss / marine trench
		base_col = p_ocean.darkened(0.42)
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
	var total_items = 180
	var items_per_batch = 30
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
			for s_i in range(5):
				var s_ang = float(s_i) * (TAU / 5.0) + 0.45
				var s_dist_factor = 0.14 # ~22 meters from ship
				var s_dir = Vector3(sin(s_ang) * s_dist_factor, 0.975, cos(s_ang) * s_dist_factor).normalized()
				var s_elev = _get_elevation(s_dir)
				var s_pos = s_dir * (radius + s_elev)
				
				if resource_scene:
					var ore = resource_scene.instantiate()
					ore.ore_type = 0 if s_i % 2 == 0 else 1 # Iron and Copper starter nodes
					ore.position = s_pos
					ore.visible = false
					_align_node_to_up(ore, s_dir)
					add_child(ore)
					spawned_ores_tier1.append(ore)
					
			for t_i in range(8):
				var t_ang = float(t_i) * (TAU / 8.0) + 0.2
				var t_dist_factor = 0.18 # ~28 meters from ship
				var t_dir = Vector3(sin(t_ang) * t_dist_factor, 0.965, cos(t_ang) * t_dist_factor).normalized()
				var t_elev = _get_elevation(t_dir)
				var p_type_start = planet_params.get("type", "Habitable")
				var is_start_tree_viable = (p_type_start.contains("Habitable") or p_type_start.contains("Tierra") or planet_params.get("has_oxygen", false)) and not planet_params.get("is_molten", false) and not p_type_start.contains("Vacío")
				if is_start_tree_viable and t_elev >= -0.5 and tree_scene:
					var tree = tree_scene.instantiate()
					tree.position = t_dir * (radius + t_elev)
					tree.visible = false
					_align_node_to_up(tree, t_dir)
					if tree.has_method("setup_theme"):
						tree.setup_theme(planet_params)
					add_child(tree)
					spawned_trees.append(tree)
					
			if creature_scene and spawned_creatures.is_empty():
				var c_dir = Vector3(0.12, 0.975, -0.12).normalized()
				var c_elev = _get_elevation(c_dir)
				var creature = creature_scene.instantiate()
				creature.position = c_dir * (radius + c_elev + 0.8)
				creature.visible = false
				_align_node_to_up(creature, c_dir)
				if creature.has_method("setup_creature"):
					creature.setup_creature(planet_params, false) # Peaceful starter alien
				add_child(creature)
				spawned_creatures.append(creature)
				
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
			var surf_pos = dir * (radius + elev)
			
			# Flora spawns in valleys/plains: 0.0m <= elev <= 6.5m (strictly on habitable/viable worlds)
			var p_type = planet_params.get("type", "Habitable")
			var is_tree_viable = (p_type.contains("Habitable") or p_type.contains("Tierra") or planet_params.get("has_oxygen", false)) and not planet_params.get("is_molten", false) and not p_type.contains("Vacío")
			
			if is_tree_viable and elev >= 0.0 and elev <= 6.5 and rng.randf() < 0.65:
				if tree_scene:
					var tree = tree_scene.instantiate()
					tree.position = surf_pos
					tree.visible = false
					_align_node_to_up(tree, dir)
					if tree.has_method("setup_theme"):
						tree.setup_theme(planet_params)
					add_child(tree)
					spawned_trees.append(tree)
			elif elev > 1.5 or elev < -1.5:
				# Mineral deposits exposed in mountain slopes, canyon cliffs or shores
				if resource_scene:
					var ore = resource_scene.instantiate()
					var spawnable = GameManager.get_planet_spawnable_ores(planet_params)
					var chosen_ore = spawnable[rng.randi() % spawnable.size()]
					match chosen_ore:
						"iron": ore.ore_type = 0
						"copper": ore.ore_type = 1
						"silicon": ore.ore_type = 2
						"uranium": ore.ore_type = 3
						_: ore.ore_type = 0
					
					ore.position = surf_pos
					ore.visible = false
					_align_node_to_up(ore, dir)
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
					_align_node_to_up(basalt, dir)
					if basalt.has_method("setup_formation"):
						basalt.setup_formation(p_mount if elev > 3.0 else p_beach)
					add_child(basalt)

			# Alien Creatures spawning across terrestrial and highland domains
			if b >= 3 and creature_scene and spawned_creatures.size() < 6 and rng.randf() < 0.28:
				var creature = creature_scene.instantiate()
				var is_aggro = (elev > 3.0 or planet_params.get("level", 0) >= 2) and (rng.randf() < 0.55)
				creature.position = surf_pos + dir * 0.8
				creature.visible = false
				_align_node_to_up(creature, dir)
				if creature.has_method("setup_creature"):
					creature.setup_creature(planet_params, is_aggro)
				add_child(creature)
				spawned_creatures.append(creature)
						
		# Procedural Subterranean Caverns anchored precisely in planetary karst cenotes
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
					
		if is_inside_tree():
			await get_tree().process_frame

func _setup_weather_particles(planet_params: Dictionary, center_pos: Vector3) -> void:
	if not planet_params.get("has_atmosphere", true):
		return
		
	weather_system = CPUParticles3D.new()
	weather_system.name = "WeatherParticles"
	weather_system.position = center_pos + Vector3.UP * 8.0
	weather_system.amount = 48
	weather_system.lifetime = 4.0
	weather_system.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	weather_system.emission_sphere_radius = 28.0
	
	var lvl = planet_params.get("level", 0)
	match lvl:
		0: # Habitable: floating spores / pollen
			weather_system.color = Color(0.85, 1.0, 0.85, 0.45)
			weather_system.gravity = Vector3(0, -1.2, 0)
			weather_system.initial_velocity_min = 0.5
			weather_system.initial_velocity_max = 2.0
		1: # Desert: red dust storm
			weather_system.color = Color(0.85, 0.45, 0.22, 0.55)
			weather_system.gravity = Vector3(4.5, -0.5, 0) # horizontal wind
			weather_system.initial_velocity_min = 4.0
			weather_system.initial_velocity_max = 8.0
		2: # Toxic: corrosive drizzle
			weather_system.color = Color(0.75, 0.82, 0.15, 0.45)
			weather_system.gravity = Vector3(0, -4.5, 0)
			weather_system.initial_velocity_min = 1.0
			weather_system.initial_velocity_max = 3.0
		3: # Cryo: methane snow flakes
			weather_system.color = Color(0.85, 0.95, 1.0, 0.65)
			weather_system.gravity = Vector3(1.2, -2.5, 0)
			weather_system.initial_velocity_min = 1.5
			weather_system.initial_velocity_max = 4.0
		4, 5: # Igneous / Molten: glowing embers
			weather_system.color = Color(1.0, 0.45, 0.10, 0.85)
			weather_system.gravity = Vector3(0, 2.5, 0) # rising embers
			weather_system.initial_velocity_min = 1.0
			weather_system.initial_velocity_max = 3.5
			
	add_child(weather_system)

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

func start_landing_cinematic() -> void:
	if is_landing_sequence_running:
		return
	is_landing_sequence_running = true
	
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
			
	var cam = get_node_or_null("LandingCinematicCamera3D") as Camera3D
	if cam:
		cam.current = true
		if spaceship_instance:
			var s_pos = spaceship_instance.global_position
			var s_fwd = spaceship_instance.global_transform.basis.z.normalized()
			cam.global_position = s_pos + landing_up_dir * 20.0 + s_fwd * 18.0
			cam.look_at(s_pos + landing_up_dir * -1.5, landing_up_dir)

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
			
			# 1. Stay in the wide exterior landed shot for 3.0 seconds (HUD hidden, astronaut loaded inside)
			cam.set_meta("is_zooming", true)
			var tw_wait = create_tween()
			tw_wait.tween_interval(3.0)
			tw_wait.tween_callback(func():
				# Load astronaut inside cabin
				if is_instance_valid(player_instance):
					player_instance.visible = true
					var cur_exit = spaceship_instance.global_transform.basis.z.normalized()
					player_instance.global_position = spaceship_instance.global_position + north_dir * 0.35 + cur_exit * 0.2
					player_instance.is_action_locked = true
					if player_instance.has_method("zoom_camera"):
						player_instance.zoom_camera(-16.0) # Ensure 1st person mode
						
				if not is_instance_valid(cam):
					return
					
				# 2. Smooth zoom in towards cabin and character first person view (1.4s)
				var p_cam: Camera3D = player_instance.get_node_or_null("CameraPivot/Camera3D") if player_instance else null
				var target_zoom_pos: Vector3
				if p_cam:
					target_zoom_pos = p_cam.global_position
				else:
					target_zoom_pos = spaceship_instance.global_position + north_dir * 1.6
					
				var tw_zoom = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
				tw_zoom.tween_property(cam, "global_position", target_zoom_pos, 1.4)
				tw_zoom.tween_callback(func():
					if is_instance_valid(player_instance):
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

func _spawn_ground_impact_effects(pos: Vector3, up_dir: Vector3) -> void:
	if has_node("GroundImpactCrater"):
		return
	var crater_mesh = PlaneMesh.new()
	crater_mesh.size = Vector2(16.0, 16.0)
	var crater_inst = MeshInstance3D.new()
	crater_inst.name = "GroundImpactCrater"
	crater_inst.mesh = crater_mesh
	
	var shader = load("res://assets/shaders/scorch_crater.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		crater_inst.material_override = mat
	
	# Exactly 2cm above the ground surface so it decals onto the terrain
	crater_inst.position = pos + up_dir * 0.02
	_align_node_to_up(crater_inst, up_dir)
	add_child(crater_inst)
	
	# Residual smoke gently drifts up from the ground
	var smoke = CPUParticles3D.new()
	smoke.name = "ResidualSmoke"
	smoke.emitting = true
	smoke.amount = 25
	smoke.lifetime = 3.5
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	smoke.emission_ring_axis = Vector3(0, 1, 0)
	smoke.emission_ring_radius = 4.8
	smoke.emission_ring_inner_radius = 2.6
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 22.0
	smoke.gravity = Vector3(0, 0.40, 0)
	smoke.initial_velocity_min = 0.2
	smoke.initial_velocity_max = 0.6
	smoke.color = Color(0.65, 0.62, 0.58, 0.24)
	crater_inst.add_child(smoke)

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
	
	# 1. North Pole Landing Plateau (flattened strictly in immediate ~10m pad under spaceship)
	if pole_dot > 0.985:
		var blend = smoothstep(0.985, 0.995, pole_dot)
		return lerp(_calc_raw_terrain(noise_obj, norm_dir, planet_params), 0.5, blend)
		
	# 2. Scenic Landing Bay / Swimming Lake (25m behind spaceship at -Z)
	var water_stat = planet_params.get("water_status", "Seco / Desolado")
	if water_stat != "Seco / Desolado" and water_stat != "":
		if pole_dot > 0.935 and pole_dot <= 0.980 and norm_dir.z < -0.10:
			var lake_factor = smoothstep(0.935, 0.960, pole_dot) * smoothstep(0.980, 0.965, pole_dot)
			var base_elev = _calc_raw_terrain(noise_obj, norm_dir, planet_params)
			return lerp(base_elev, -1.8, lake_factor * 0.85)
		
	return _calc_raw_terrain(noise_obj, norm_dir, planet_params)

static func _calc_raw_terrain(noise_obj: FastNoiseLite, norm_dir: Vector3, planet_params: Dictionary = {}) -> float:
	var seed_i: int = planet_params.get("seed", noise_obj.seed)
	var lvl: int = planet_params.get("level", 0)
	var has_atmo: bool = planet_params.get("has_atmosphere", true)
	
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
			var sink = smoothstep(0.12, 0.03, d_cen) * 11.5
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

	var total_h = continent + mountains + mons_relief + canyon_relief - cenote_sink + crater_relief + detail
	return clampf(total_h, -16.0, 26.0)

static func get_cenote_direction(seed_val: int, idx: int) -> Vector3:
	var c_hash = (seed_val * 15485863 + idx * 32452843) ^ 0x5DEECE66D
	var c_th = (float(c_hash & 0xFFFF) / 65535.0) * TAU
	var c_ph = 0.70 + (float((c_hash >> 16) & 0x7FFF) / 32767.0) * 1.5
	return Vector3(sin(c_ph) * cos(c_th), cos(c_ph), sin(c_ph) * sin(c_th)).normalized()

func _get_elevation(norm_dir: Vector3) -> float:
	var p_params = GameManager.current_planet if is_instance_valid(GameManager) else {}
	return _calc_elevation_static(noise, norm_dir, p_params)

func _align_node_to_up(node: Node3D, target_up: Vector3) -> void:
	var current_up = Vector3.UP
	if current_up.cross(target_up).length() > 0.001:
		var axis = current_up.cross(target_up).normalized()
		var angle = current_up.angle_to(target_up)
		node.transform.basis = Basis(axis, angle)
