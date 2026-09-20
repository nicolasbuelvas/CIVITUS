extends StaticBody3D

@onready var trunk: MeshInstance3D = $Trunk
@onready var foliage_1: MeshInstance3D = $Foliage1
@onready var foliage_2: MeshInstance3D = get_node_or_null("Foliage2")
@onready var foliage_3: MeshInstance3D = get_node_or_null("Foliage3")

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	
	# Gentle procedural wind sway
	var sway_time = randf_range(2.0, 3.5)
	var sway_mag = randf_range(0.04, 0.08)
	var tw = create_tween().set_loops()
	tw.tween_property(self, "rotation:z", sway_mag, sway_time).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "rotation:z", -sway_mag, sway_time).set_trans(Tween.TRANS_SINE)

func setup_theme(planet_params: Dictionary) -> void:
	var p_type = planet_params.get("type", "Habitable")
	var leaf_color = Color(0.25, 0.72, 0.35)
	var wood_color = Color(0.42, 0.28, 0.18)
	var is_emissive = false
	
	if p_type.contains("Cryo") or p_type.contains("Hielo"):
		leaf_color = Color(0.45, 0.85, 0.95)
		wood_color = Color(0.25, 0.35, 0.45)
	elif p_type.contains("Volcan") or p_type.contains("Lava"):
		leaf_color = Color(0.95, 0.40, 0.12)
		wood_color = Color(0.18, 0.15, 0.14)
		is_emissive = true
	elif p_type.contains("Toxic") or p_type.contains("Acido"):
		leaf_color = Color(0.65, 0.32, 0.88)
		wood_color = Color(0.28, 0.22, 0.32)
		is_emissive = true
	elif p_type.contains("Desert") or p_type.contains("Arido"):
		leaf_color = Color(0.85, 0.65, 0.22)
		wood_color = Color(0.50, 0.35, 0.20)
		
	var mat_leaf = StandardMaterial3D.new()
	mat_leaf.albedo_color = leaf_color
	mat_leaf.roughness = 0.75
	if is_emissive:
		mat_leaf.emission_enabled = true
		mat_leaf.emission = leaf_color * 0.5
		
	if foliage_1: foliage_1.material_override = mat_leaf
	if foliage_2: foliage_2.material_override = mat_leaf
	if foliage_3: foliage_3.material_override = mat_leaf
	
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = wood_color
	mat_wood.roughness = 0.85
	if trunk: trunk.material_override = mat_wood
