extends StaticBody3D
class_name CaveGrotto

@onready var light: OmniLight3D = $CaveOmniLight
@onready var crystal: MeshInstance3D = $CrystalInterior

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

func setup_theme(planet_params: Dictionary) -> void:
	if not light:
		light = get_node_or_null("CaveOmniLight")
	if not crystal:
		crystal = get_node_or_null("CrystalInterior")
		
	var lvl = planet_params.get("level", 0)
	var glow_col: Color
	var light_energy: float = 2.4
	
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
			light_energy = 3.0
			
	if light:
		light.light_color = glow_col
		light.light_energy = light_energy
		
	if crystal:
		var mat = crystal.get_active_material(0)
		if mat is StandardMaterial3D:
			var dyn_mat = mat.duplicate()
			dyn_mat.albedo_color = glow_col
			dyn_mat.emission = glow_col
			dyn_mat.emission_energy_multiplier = 2.8
			crystal.material_override = dyn_mat
