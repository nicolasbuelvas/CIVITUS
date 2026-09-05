extends Node3D

@export var map_size: int = 44
@export var block_size: float = 2.0

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var multimesh_instance: MultiMeshInstance3D = $TerrainMultiMesh
@onready var terrain_collider: StaticBody3D = $TerrainCollider

var resource_chunk_scene = preload("res://scenes/entities/resource_chunk.tscn")
var spaceship_scene = preload("res://scenes/entities/spaceship.tscn")
var tree_scene = preload("res://scenes/entities/paper_tree.tscn")

var spaceship_instance: Node3D = null

func _ready() -> void:
	generate_world()

func generate_world() -> void:
	var planet = GameManager.current_planet
	var p_seed = planet.get("seed", 12345)
	
	# Atmosphere & sun
	var surf_col: Color = planet.get("surface_color", Color(0.3, 0.5, 0.4))
	var sky_col: Color = planet.get("sky_color", Color(0.05, 0.08, 0.15))
	
	sun_light.light_color = Color.WHITE.lerp(surf_col, 0.2)
	sun_light.shadow_enabled = true
	
	# Noise generator
	var noise = FastNoiseLite.new()
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.04
	
	var total_blocks = map_size * map_size
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(block_size * 0.98, block_size * 1.5, block_size * 0.98)
	
	# Material with block texture matching the user images
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.75
	if ResourceLoader.exists("res://assets/textures/block_grass_top.png"):
		mat.albedo_texture = load("res://assets/textures/block_grass_top.png")
	box_mesh.material = mat
	mm.mesh = box_mesh
	mm.instance_count = total_blocks
	
	var half_size = map_size / 2
	var idx = 0
	var center_h = 0.0
	
	for x in range(-half_size, half_size):
		for z in range(-half_size, half_size):
			var dist_center = Vector2(x, z).length()
			var n_val = noise.get_noise_2d(float(x) * 2.2, float(z) * 2.2)
			
			var height_step = 0
			if dist_center > 5.5:
				height_step = int(round(n_val * 4.5))
				
			var world_x = x * block_size
			var world_z = z * block_size
			var world_y = height_step * (block_size * 0.75)
			
			if x == 0 and z == 0:
				center_h = world_y
				
			var t = Transform3D()
			t.origin = Vector3(world_x, world_y, world_z)
			mm.set_instance_transform(idx, t)
			
			# Color coding matching biomes (Grass, Water, Snow from images)
			var block_color = surf_col
			if height_step >= 3:
				# Snowy mountain peak
				block_color = Color(0.92, 0.96, 1.0)
			elif height_step <= -2 and planet.get("has_oxygen", false):
				# Water stream (Azure Cyan from Image 6)
				block_color = Color(0.1, 0.75, 0.95)
			elif height_step > 0:
				block_color = surf_col.lightened(0.18)
			else:
				block_color = surf_col.darkened(0.12)
				
			mm.set_instance_color(idx, block_color)
			
			# Collider
			var c_shape = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(block_size, block_size * 1.5, block_size)
			c_shape.shape = box
			c_shape.transform = t
			terrain_collider.add_child(c_shape)
			
			# Spawn Trees on lush planets
			if dist_center > 7.0 and height_step >= 0 and height_step < 3:
				if planet.get("has_oxygen", false) and randf() < 0.035:
					var tree = tree_scene.instantiate()
					tree.position = Vector3(world_x, world_y + (block_size * 0.75), world_z)
					add_child(tree)
			
			# Spawn Surface Ore Chunks (Waste of Space style)
			if dist_center > 6.0 and randf() < 0.045:
				var ore = resource_chunk_scene.instantiate()
				var roll = randf()
				if roll < 0.40:
					ore.ore_type = 0 # Iron
				elif roll < 0.70:
					ore.ore_type = 1 # Copper
				elif roll < 0.88:
					ore.ore_type = 2 # Silicon
				else:
					ore.ore_type = 3 # Uranium / Energy Crystal
					
				ore.position = Vector3(world_x, world_y + (block_size * 0.75), world_z)
				add_child(ore)
				
			idx += 1
			
	multimesh_instance.multimesh = mm
	
	# Spawn Walk-in Spaceship
	spaceship_instance = spaceship_scene.instantiate()
	spaceship_instance.position = Vector3(0, center_h + (block_size * 0.75) + 0.2, 0)
	spaceship_instance.add_to_group("spaceship")
	add_child(spaceship_instance)
	
	# Connect Player & HUD
	var player = get_node_or_null("Player")
	var hud = get_node_or_null("HUD")
	if player and hud and hud.has_method("init_player"):
		player.position = Vector3(0, center_h + 2.5, 3.0)
		hud.init_player(player)
