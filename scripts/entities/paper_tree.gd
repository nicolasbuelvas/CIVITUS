extends StaticBody3D

@onready var trunk: MeshInstance3D = $Trunk
@onready var foliage_1: MeshInstance3D = $Foliage1
@onready var foliage_2: MeshInstance3D = get_node_or_null("Foliage2")
@onready var foliage_3: MeshInstance3D = get_node_or_null("Foliage3")

var current_health: float = 1.0
var max_health: float = 1.0
var is_sapling: bool = false
var growth_t: float = 1.0
var expansion_timer: float = 45.0
var planet_radius: float = 160.0
var current_planet_params: Dictionary = {}

func _ready() -> void:
	collision_layer = 2 # Mining layer
	collision_mask = 0
	add_to_group("resource_nodes")
	expansion_timer = randf_range(40.0, 80.0)
	
	# Gentle procedural wind sway
	var sway_time = randf_range(2.0, 3.5)
	var sway_mag = randf_range(0.04, 0.08)
	var tw = create_tween().set_loops()
	tw.tween_property(self, "rotation:z", sway_mag, sway_time).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "rotation:z", -sway_mag, sway_time).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	if is_sapling:
		growth_t = minf(1.0, growth_t + delta / 24.0)
		scale = Vector3.ONE * lerpf(0.35, 1.0, growth_t)
		if growth_t >= 1.0:
			is_sapling = false
			
	expansion_timer -= delta
	if expansion_timer <= 0.0:
		expansion_timer = randf_range(45.0, 85.0)
		_attempt_tree_expansion()

func _attempt_tree_expansion() -> void:
	expansion_timer = randf_range(45.0, 85.0)
	var parent_planet = get_parent()
	if not parent_planet:
		return
		
	# A. Drop harvestable wood or fibers chunk
	var drop_scene = load("res://scenes/entities/dropped_item.tscn")
	if drop_scene:
		var drop = drop_scene.instantiate()
		drop.setup_drop("wood", 1, planet_radius)
		parent_planet.add_child(drop)
		var up = global_position.normalized()
		var tangent = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).cross(up).normalized()
		drop.global_position = global_position + (tangent * randf_range(1.6, 3.4)) + (up * 0.8)
		drop.apply_central_impulse(tangent * 2.0 + up * 1.5)
		
	# B. Propagate tree sapling if density permits
	var local_tree_count = 0
	for t in get_tree().get_nodes_in_group("resource_nodes"):
		if t is StaticBody3D and t != self and is_instance_valid(t):
			if global_position.distance_to(t.global_position) < 9.0:
				local_tree_count += 1
				
	if local_tree_count < 4 and parent_planet:
		var tree_scene = load("res://scenes/entities/paper_tree.tscn")
		if tree_scene:
			var sapling = tree_scene.instantiate()
			var up_dir = global_position.normalized()
			var rand_t = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).cross(up_dir).normalized()
			var sapling_pos = global_position + rand_t * randf_range(3.5, 6.5)
			var sapling_dir = sapling_pos.normalized()
			
			var surf_elev = 0.0
			if parent_planet.has_method("_get_elevation"):
				surf_elev = parent_planet._get_elevation(sapling_dir)
			sapling.position = sapling_dir * (planet_radius + surf_elev)
			sapling.set("is_sapling", true)
			sapling.set("growth_t", 0.25)
			sapling.scale = Vector3.ONE * 0.25
			parent_planet.add_child(sapling)
			if sapling.has_method("setup_theme"):
				sapling.setup_theme(current_planet_params)
			if parent_planet.get("spawned_trees") is Array:
				parent_planet.spawned_trees.append(sapling)

func set_lod_level(level: int) -> void:
	if level >= 3:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	visible = true
	match level:
		0:
			process_mode = Node.PROCESS_MODE_INHERIT
			set_process(true)
			_set_tree_shadows(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
			if foliage_2: foliage_2.visible = true
			if foliage_3: foliage_3.visible = true
		1:
			process_mode = Node.PROCESS_MODE_INHERIT
			set_process(true)
			_set_tree_shadows(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			if foliage_2: foliage_2.visible = true
			if foliage_3: foliage_3.visible = true
		2:
			process_mode = Node.PROCESS_MODE_DISABLED
			set_process(false)
			_set_tree_shadows(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			if foliage_2: foliage_2.visible = false
			if foliage_3: foliage_3.visible = false

func _set_tree_shadows(setting: GeometryInstance3D.ShadowCastingSetting) -> void:
	if trunk: trunk.cast_shadow = setting
	if foliage_1: foliage_1.cast_shadow = setting
	if foliage_2: foliage_2.cast_shadow = setting
	if foliage_3: foliage_3.cast_shadow = setting

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
	var roots = get_node_or_null("Roots")
	if roots: roots.material_override = mat_wood

func mine_tick(delta: float) -> bool:
	current_health -= delta
	if current_health <= 0.0:
		break_and_harvest()
		return true
	return false

func break_and_harvest() -> void:
	collision_layer = 0
	if GameManager and GameManager.crafting:
		GameManager.crafting.add_resource("plant_fibers", 2)
	AudioManager.play("collect", 1.2, 2.0)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.25)
	tw.tween_callback(queue_free)
