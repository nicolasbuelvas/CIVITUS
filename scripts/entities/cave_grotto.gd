extends StaticBody3D
class_name CaveGrotto

@onready var light: OmniLight3D = get_node_or_null("CaveOmniLight")
@onready var crystal: MeshInstance3D = get_node_or_null("CrystalInterior")
@onready var crystal_sec: MeshInstance3D = get_node_or_null("CrystalSecondary")

var spawned_interior_nodes: Array = []

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("caves")
	add_to_group("interactable")

func setup_theme(planet_params: Dictionary) -> void:
	if not light:
		light = get_node_or_null("CaveOmniLight")
	if not crystal:
		crystal = get_node_or_null("CrystalInterior")
	if not crystal_sec:
		crystal_sec = get_node_or_null("CrystalSecondary")
		
	var lvl = planet_params.get("level", 0)
	var glow_col: Color
	var light_energy: float = 2.8
	
	match lvl:
		0: # Gaia / Habitable: bioluminescent azure cyan
			glow_col = Color(0.18, 0.88, 1.0)
		1: # Arid / Desert: subterranean golden amber quartz
			glow_col = Color(1.0, 0.78, 0.22)
		2: # Toxic / Acid: vibrant alien emerald phosphor
			glow_col = Color(0.25, 0.95, 0.35)
		3: # Cryo / Glacial: deep glacial sapphire blue
			glow_col = Color(0.35, 0.65, 1.0)
		4: # Singularity / Void: eerie quantum violet
			glow_col = Color(0.75, 0.35, 1.0)
		5, _: # Molten / Igneous: incandescent magma orange
			glow_col = Color(1.0, 0.42, 0.08)
			light_energy = 3.5
			
	if light:
		light.light_color = glow_col
		light.light_energy = light_energy
		
	if crystal:
		var mat = crystal.get_active_material(0)
		if mat is StandardMaterial3D:
			var dyn_mat = mat.duplicate()
			dyn_mat.albedo_color = glow_col
			dyn_mat.emission = glow_col
			dyn_mat.emission_energy_multiplier = 3.0
			crystal.material_override = dyn_mat

	if crystal_sec:
		var mat2 = crystal_sec.get_active_material(0)
		if mat2 is StandardMaterial3D:
			var dyn_mat2 = mat2.duplicate()
			dyn_mat2.albedo_color = glow_col.lerp(Color.WHITE, 0.3)
			dyn_mat2.emission = glow_col
			dyn_mat2.emission_energy_multiplier = 2.2
			crystal_sec.material_override = dyn_mat2
			
	populate_cavern_contents(planet_params)

func populate_cavern_contents(planet_params: Dictionary) -> void:
	if not spawned_interior_nodes.is_empty():
		return
		
	var ore_scene = load("res://scenes/entities/resource_chunk.tscn")
	if ore_scene:
		# Interior crystalline resource deposits inside the cave gallery
		var ore_positions = [
			Vector3(-1.8, 0.4, -2.2),
			Vector3(1.9, 0.4, -3.2)
		]
		for idx in range(ore_positions.size()):
			var ore = ore_scene.instantiate()
			ore.ore_type = 2 if idx == 0 else 3 # Silicon and Uranium
			ore.position = ore_positions[idx]
			add_child(ore)
			spawned_interior_nodes.append(ore)

	var creature_scene = load("res://scenes/entities/alien_creature.tscn")
	if creature_scene:
		# Subterranean cave creature dwelling inside the cavern
		var creature = creature_scene.instantiate()
		creature.position = Vector3(0.0, 0.5, -2.8)
		add_child(creature)
		if creature.has_method("setup_creature"):
			# Subterranean dweller: Hexapod Lumen (3) or Burrowing Mole (6)
			creature.setup_creature(planet_params, false, 0)
			creature.configure_subspecies(3, planet_params, false)
		spawned_interior_nodes.append(creature)
