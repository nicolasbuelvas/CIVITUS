extends Node3D

@export var radius: float = 160.0 # 5/10 scale KSP style diorama horizon
@export var face_resolution: int = 36

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D

var tree_scene = preload("res://scenes/entities/paper_tree.tscn")
var resource_scene = preload("res://scenes/entities/resource_chunk.tscn")
var spaceship_scene = preload("res://scenes/entities/spaceship_3d.tscn")

var spaceship_instance: Node3D = null
var noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	generate_planet()

func generate_planet() -> void:
	var planet_params = GameManager.current_planet
	var p_seed = planet_params.get("seed", 1337)
	
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Cube face normal directions
	var face_normals = [
		Vector3.UP, Vector3.DOWN,
		Vector3.LEFT, Vector3.RIGHT,
		Vector3.FORWARD, Vector3.BACK
	]
	
	for normal in face_normals:
		_generate_cubed_sphere_face(st, normal, planet_params)
		
	st.generate_normals()
	var planet_mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mat.metallic_specular = 0.25
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.mesh = planet_mesh
	mesh_instance.material_override = mat
	
	# Create solid 360-degree SphereShape3D for reliable radial physics
	var solid_sphere = SphereShape3D.new()
	solid_sphere.radius = radius - 0.2
	collision_shape.shape = solid_sphere
	
	# Place Spaceship at North Pole landing plateau
	var north_dir = Vector3.UP
	var north_pos = north_dir * (radius + _get_elevation(north_dir) + 0.1)
	spaceship_instance = spaceship_scene.instantiate()
	spaceship_instance.position = north_pos
	_align_node_to_up(spaceship_instance, north_dir)
	add_child(spaceship_instance)
	
	# Spawn features across the spherical surface
	_spawn_spherical_features(planet_params)
	
	# Position Player safely near the Spaceship boarding ramp
	var player = get_parent().get_node_or_null("Character3D")
	var hud = get_parent().get_node_or_null("HUD")
	if player:
		player.floor_snap_length = 0.8
		player.floor_max_angle = deg_to_rad(65.0)
		var start_dir = (Vector3.UP + Vector3.FORWARD * 0.06).normalized()
		var start_pos = start_dir * (radius + _get_elevation(start_dir) + 1.2)
		player.position = start_pos
		player.planet_radius = radius
		if hud and hud.has_method("init_player"):
			hud.init_player(player)

func _get_elevation(norm_dir: Vector3) -> float:
	# Flat landing zone around North Pole for spaceship & player spawn
	if norm_dir.dot(Vector3.UP) > 0.96:
		return 0.5
		
	var n_val = noise.get_noise_3dv(norm_dir * 120.0)
	var mountain = noise.get_noise_3dv(norm_dir * 40.0)
	
	# Stepped elevation layers for stylized low-poly diorama look
	var step = round(n_val * 4.0) * 1.2 + (mountain * 3.5)
	return clamp(step, -4.0, 12.0)

func _generate_cubed_sphere_face(st: SurfaceTool, normal: Vector3, planet_params: Dictionary) -> void:
	var axis_a = Vector3(normal.y, normal.z, normal.x)
	var axis_b = normal.cross(axis_a)
	
	var res = face_resolution
	
	for y in range(res):
		for x in range(res):
			# Generate quad vertices on cube face, projected onto sphere
			var v00 = _cube_to_sphere(x, y, res, normal, axis_a, axis_b)
			var v10 = _cube_to_sphere(x + 1, y, res, normal, axis_a, axis_b)
			var v01 = _cube_to_sphere(x, y + 1, res, normal, axis_a, axis_b)
			var v11 = _cube_to_sphere(x + 1, y + 1, res, normal, axis_a, axis_b)
			
			var h00 = _get_elevation(v00)
			var h10 = _get_elevation(v10)
			var h01 = _get_elevation(v01)
			var h11 = _get_elevation(v11)
			
			var p00 = v00 * (radius + h00)
			var p10 = v10 * (radius + h10)
			var p01 = v01 * (radius + h01)
			var p11 = v11 * (radius + h11)
			
			# Biome Color based on elevation & planet parameters
			var avg_h = (h00 + h10 + h01 + h11) * 0.25
			var c_light = Color(0.65, 0.88, 0.22) # Grass Light
			var c_dark = Color(0.48, 0.72, 0.15)  # Grass Dark
			
			if avg_h >= 5.0:
				c_light = Color(0.96, 0.98, 1.0) # Snow / Glaciers
				c_dark = Color(0.82, 0.90, 0.98)
			elif avg_h <= -1.5 and planet_params.get("has_oxygen", false):
				c_light = Color(0.12, 0.78, 0.95) # Ocean Cyan
				c_dark = Color(0.06, 0.58, 0.82)
			elif not planet_params.get("has_oxygen", false):
				c_light = planet_params.get("surface_color", Color(0.72, 0.35, 0.20))
				c_dark = c_light.darkened(0.22)
			elif avg_h >= 2.5:
				c_light = Color(0.55, 0.52, 0.48) # Mountain Rock
				c_dark = Color(0.40, 0.38, 0.35)
				
			# Triangle 1 (Counter-Clockwise outward facing)
			st.set_color(c_light)
			st.set_uv(Vector2(0, 0))
			st.add_vertex(p00)
			
			st.set_color(c_light)
			st.set_uv(Vector2(0, 1))
			st.add_vertex(p01)
			
			st.set_color(c_light)
			st.set_uv(Vector2(1, 0))
			st.add_vertex(p10)
			
			# Triangle 2 (Counter-Clockwise outward facing)
			st.set_color(c_dark)
			st.set_uv(Vector2(1, 0))
			st.add_vertex(p10)
			
			st.set_color(c_dark)
			st.set_uv(Vector2(0, 1))
			st.add_vertex(p01)
			
			st.set_color(c_dark)
			st.set_uv(Vector2(1, 1))
			st.add_vertex(p11)

func _cube_to_sphere(x: int, y: int, res: int, normal: Vector3, axis_a: Vector3, axis_b: Vector3) -> Vector3:
	var fx = (float(x) / float(res) - 0.5) * 2.0
	var fy = (float(y) / float(res) - 0.5) * 2.0
	var p = normal + axis_a * fx + axis_b * fy
	return p.normalized()

func _spawn_spherical_features(planet_params: Dictionary) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = planet_params.get("seed", 1337) + 101
	
	# Spawn 75-100 items distributed around the sphere
	var num_features = 80
	for i in range(num_features):
		var u = rng.randf()
		var v = rng.randf()
		var theta = u * TAU
		var phi = acos(2.0 * v - 1.0)
		var dir = Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
		
		# Avoid North Pole landing zone
		if dir.dot(Vector3.UP) > 0.92:
			continue
			
		var elev = _get_elevation(dir)
		var surf_pos = dir * (radius + elev)
		
		if elev >= 0.0 and elev < 4.0 and planet_params.get("has_oxygen", false) and rng.randf() < 0.45:
			var tree = tree_scene.instantiate()
			tree.position = surf_pos
			_align_node_to_up(tree, dir)
			add_child(tree)
		else:
			var ore = resource_scene.instantiate()
			var roll = rng.randf()
			if roll < 0.38: ore.ore_type = 0 # Iron
			elif roll < 0.68: ore.ore_type = 1 # Copper
			elif roll < 0.88: ore.ore_type = 2 # Silicon
			else: ore.ore_type = 3 # Uranium
			
			ore.position = surf_pos
			_align_node_to_up(ore, dir)
			add_child(ore)

func _align_node_to_up(node: Node3D, target_up: Vector3) -> void:
	var current_up = Vector3.UP
	if current_up.cross(target_up).length() > 0.001:
		var axis = current_up.cross(target_up).normalized()
		var angle = current_up.angle_to(target_up)
		node.transform.basis = Basis(axis, angle)
