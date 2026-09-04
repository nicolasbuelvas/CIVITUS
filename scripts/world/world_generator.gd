extends Node3D

@export var map_size: int = 40
@export var block_size: float = 2.0

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var multimesh_instance: MultiMeshInstance3D = $TerrainMultiMesh
@onready var terrain_collider: StaticBody3D = $TerrainCollider

var crystal_scene = preload("res://scenes/entities/crystal.tscn")
var lander_scene = preload("res://scenes/entities/lander.tscn")
var lander_instance: Node3D = null

func _ready() -> void:
	generate_world()

func generate_world() -> void:
	var planet = GameManager.current_planet
	var p_seed = planet.get("seed", 12345)
	
	# Configure lighting and atmosphere colors
	var surf_col: Color = planet.get("surface_color", Color(0.3, 0.5, 0.4))
	var sky_col: Color = planet.get("sky_color", Color(0.05, 0.08, 0.15))
	
	sun_light.light_color = Color.WHITE.lerp(surf_col, 0.25)
	sun_light.shadow_enabled = true
	
	# Setup Noise for procedural block heights
	var noise = FastNoiseLite.new()
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.04
	
	var total_blocks = map_size * map_size
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.mesh.size = Vector3(block_size * 0.98, block_size * 1.5, block_size * 0.98) # stylized block gaps
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mat.metallic = 0.05
	mm.mesh.material = mat
	
	mm.instance_count = total_blocks
	
	var half_size = map_size / 2
	var idx = 0
	
	# Spawn Lander near center (0, y, 0)
	var center_h = 0.0
	
	for x in range(-half_size, half_size):
		for z in range(-half_size, half_size):
			var dist_center = Vector2(x, z).length()
			var n_val = noise.get_noise_2d(float(x) * 2.0, float(z) * 2.0)
			
			# Flatten center for landing zone
			var height_step = 0
			if dist_center > 4.0:
				height_step = int(round(n_val * 5.0))
			
			var world_x = x * block_size
			var world_z = z * block_size
			var world_y = height_step * (block_size * 0.75)
			
			if x == 0 and z == 0:
				center_h = world_y
			
			var t = Transform3D()
			t.origin = Vector3(world_x, world_y, world_z)
			mm.set_instance_transform(idx, t)
			
			# Shading variation for papercraft / block look
			var block_color = surf_col
			if height_step > 1:
				block_color = surf_col.lightened(0.15)
			elif height_step < -1:
				block_color = surf_col.darkened(0.2)
			
			# Edge variation
			var edge_factor = sin(float(x * 7 + z * 13)) * 0.05
			block_color = block_color.lightened(edge_factor)
			mm.set_instance_color(idx, block_color)
			
			# Add collision box for each column
			var c_shape = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(block_size, block_size * 1.5, block_size)
			c_shape.shape = box
			c_shape.transform = t
			terrain_collider.add_child(c_shape)
			
			# Procedural crystals spawning (outside center)
			if dist_center > 5.0 and randf() < (0.05 * planet.get("resource_density", 1.0)):
				var cryst = crystal_scene.instantiate()
				cryst.position = Vector3(world_x, world_y + (block_size * 0.75), world_z)
				cryst.is_rare_gold = (randf() < 0.2)
				add_child(cryst)
				
			idx += 1
			
	multimesh_instance.multimesh = mm
	
	# Place Lander at center
	lander_instance = lander_scene.instantiate()
	lander_instance.position = Vector3(0, center_h + (block_size * 0.75), 0)
	lander_instance.add_to_group("lander")
	add_child(lander_instance)
	
	# Connect player and HUD
	var player = get_node_or_null("Player")
	var hud = get_node_or_null("HUD")
	if player and hud and hud.has_method("init_player"):
		player.position = Vector3(2.5, center_h + 2.0, 2.5)
		hud.init_player(player)
