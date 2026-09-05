extends Node3D

@export var map_size: int = 40
@export var block_size: float = 2.0

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var multimesh_instance: MultiMeshInstance3D = $TerrainMultiMesh
@onready var terrain_collider: StaticBody3D = $TerrainCollider

var resource_chunk_scene = preload("res://scenes/entities/resource_chunk.tscn")
var spaceship_scene = preload("res://scenes/entities/spaceship_3d.tscn")
var tree_scene = preload("res://scenes/entities/paper_tree.tscn")

var spaceship_instance: Node3D = null

func _ready() -> void:
	generate_world()

func generate_world() -> void:
	var planet = GameManager.current_planet
	var p_seed = planet.get("seed", 12345)
	
	var surf_col: Color = planet.get("surface_color", Color(0.3, 0.5, 0.4))
	var sky_col: Color = planet.get("sky_color", Color(0.05, 0.08, 0.15))
	
	sun_light.light_color = Color.WHITE.lerp(surf_col, 0.2)
	sun_light.shadow_enabled = true
	
	var noise = FastNoiseLite.new()
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.05
	
	var total_blocks = map_size * map_size
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(block_size * 0.99, block_size * 2.0, block_size * 0.99)
	
	var shader = load("res://assets/shaders/block_terrain.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	if ResourceLoader.exists("res://assets/textures/block_grass_top.png"):
		mat.set_shader_parameter("top_texture", load("res://assets/textures/block_grass_top.png"))
	if ResourceLoader.exists("res://assets/textures/block_dirt_side.png"):
		mat.set_shader_parameter("side_texture", load("res://assets/textures/block_dirt_side.png"))
	box_mesh.material = mat
	mm.mesh = box_mesh
	mm.instance_count = total_blocks
	
	var half_size = map_size / 2
	var idx = 0
	var center_h = 0.0
	
	# Periodic Toroidal Heightmap: Heights at +half_size match -half_size seamlessly!
	for x in range(-half_size, half_size):
		for z in range(-half_size, half_size):
			var dist_center = Vector2(x, z).length()
			
			# Periodic trigonometric wrapping factors
			var norm_x = (float(x) / float(half_size)) * PI
			var norm_z = (float(z) / float(half_size)) * PI
			
			# Smooth toroidal wave + noise
			var periodic_factor = sin(norm_x) * cos(norm_z)
			var n_val = noise.get_noise_2d(cos(norm_x) * 40.0, sin(norm_z) * 40.0)
			
			# Flatten area for spaceship landing pad
			var height_step = 0
			if abs(x) <= 3 and abs(z) <= 5:
				height_step = 0
			elif dist_center > 6.5:
				height_step = int(round(periodic_factor * 2.0 + n_val * 2.2))
				
			var world_x = x * block_size
			var world_z = z * block_size
			var world_y = height_step * 1.2
			
			if x == 0 and z == 0:
				center_h = world_y
				
			var t = Transform3D()
			t.origin = Vector3(world_x, world_y, world_z)
			mm.set_instance_transform(idx, t)
			
			# Color coding matching biomes
			var block_color = Color.WHITE
			if height_step >= 2:
				block_color = Color(1.3, 1.3, 1.4) # Snowy mountain bright
			elif height_step <= -2 and planet.get("has_oxygen", false):
				block_color = Color(0.3, 0.9, 1.2) # Cyan water stream
			elif height_step > 0:
				block_color = Color(1.05, 1.05, 0.95)
			else:
				block_color = Color(0.9, 0.88, 0.85)
				
			mm.set_instance_color(idx, block_color)
			
			# Solid continuous collider column
			var c_shape = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(block_size, block_size * 2.0, block_size)
			c_shape.shape = box
			c_shape.transform = t
			terrain_collider.add_child(c_shape)
			
			# Spawn Trees on grassy biomes
			if dist_center > 7.5 and height_step >= 0 and height_step < 2:
				if planet.get("has_oxygen", false) and randf() < 0.04:
					var tree = tree_scene.instantiate()
					tree.position = Vector3(world_x, world_y + 1.0, world_z)
					add_child(tree)
			
			# Spawn Ore Chunks (Waste of Space style)
			if dist_center > 7.0 and randf() < 0.05:
				var ore = resource_chunk_scene.instantiate()
				var roll = randf()
				if roll < 0.38: ore.ore_type = 0 # Iron
				elif roll < 0.68: ore.ore_type = 1 # Copper
				elif roll < 0.88: ore.ore_type = 2 # Silicon
				else: ore.ore_type = 3 # Uranium
				
				ore.position = Vector3(world_x, world_y + 1.0, world_z)
				add_child(ore)
				
			idx += 1
			
	multimesh_instance.multimesh = mm
	
	# Spawn Real 3D Walk-in Spaceship
	spaceship_instance = spaceship_scene.instantiate()
	spaceship_instance.position = Vector3(0, center_h + 0.1, 0)
	add_child(spaceship_instance)
	
	# Connect Character3D & HUD
	var player = get_node_or_null("Character3D")
	var hud = get_node_or_null("HUD")
	if player and hud:
		player.world_wrap_size = half_size * block_size # Exactly matches terrain bounds!
		player.position = Vector3(0, center_h + 1.2, 7.5) # In front of ramp!
		if hud.has_method("init_player"):
			hud.init_player(player)
