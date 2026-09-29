extends StaticBody3D
class_name ResourceChunk

enum OreType { IRON, COPPER, SILICON, URANIUM }

@export var ore_type: OreType = OreType.IRON:
	set(val):
		ore_type = val
		if is_node_ready():
			_setup_material()
@export var yield_amount: int = 1
@export var total_extractions: int = 4
@export var max_health: float = 4.0

@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var label_3d: Label3D = get_node_or_null("Label3D")

var current_health: float = 4.0
var remaining_extractions: int = 4
var extraction_timer: float = 0.0
const EXTRACTION_STEP_TIME: float = 0.95

var ore_color: Color = Color(0.85, 0.55, 0.25)
var ore_label_text: String = "HIERRO"
var initial_scale: Vector3 = Vector3.ONE
var is_being_scanned: bool = false
var is_depleted: bool = false
var spark_particles: CPUParticles3D = null
var lod_check_timer: float = 0.0
var vein_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	collision_layer = 2 # Mining layer
	collision_mask = 0
	add_to_group("resource_nodes")
	current_health = max_health
	remaining_extractions = total_extractions
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
	_build_large_boulder_mesh()
	initial_scale = mesh_instance.scale
	_setup_material()
	_setup_particles()
	
	# Anti-clutter: label hidden by default until visor scanner focuses it
	if label_3d:
		label_3d.visible = false

func _process(delta: float) -> void:
	lod_check_timer += delta
	if lod_check_timer >= 0.35:
		lod_check_timer = 0.0
		_update_lod()

func _update_lod() -> void:
	var cam = get_viewport().get_camera_3d()
	if cam:
		var dist_sq = global_position.distance_squared_to(cam.global_position)
		# LOD threshold: beyond 48 meters, hide scanner label and detail to save mobile draw calls
		if dist_sq > 2304.0: # 48m * 48m
			if label_3d and label_3d.visible:
				label_3d.visible = false
		elif is_being_scanned and label_3d:
			label_3d.visible = true

func _setup_particles() -> void:
	spark_particles = CPUParticles3D.new()
	spark_particles.emitting = false
	spark_particles.one_shot = false
	spark_particles.amount = 8
	spark_particles.lifetime = 0.35
	spark_particles.explosiveness = 0.1
	spark_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	spark_particles.emission_sphere_radius = 0.25
	spark_particles.direction = Vector3.UP
	spark_particles.spread = 70.0
	spark_particles.initial_velocity_min = 1.5
	spark_particles.initial_velocity_max = 3.5
	spark_particles.color = Color(1.0, 0.85, 0.3)
	
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.04, 0.04, 0.04)
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(1.0, 0.9, 0.4)
	p_mat.emission_enabled = true
	p_mat.emission = Color(1.0, 0.8, 0.2)
	p_mesh.material = p_mat
	spark_particles.mesh = p_mesh
	
	add_child(spark_particles)

func _setup_material() -> void:
	var ore_mat = StandardMaterial3D.new()
	ore_mat.roughness = 0.35
	ore_mat.metallic = 0.80
	
	match ore_type:
		OreType.IRON:
			ore_label_text = "HIERRO" if GameManager.current_language == "es" else "IRON"
			ore_color = Color(0.88, 0.90, 0.98)
			ore_mat.metallic = 0.95
			ore_mat.roughness = 0.22
			ore_mat.emission_enabled = true
			ore_mat.emission = Color(0.55, 0.70, 0.95) * 0.65
		OreType.COPPER:
			ore_label_text = "COBRE" if GameManager.current_language == "es" else "COPPER"
			ore_color = Color(1.0, 0.55, 0.20)
			ore_mat.metallic = 0.90
			ore_mat.roughness = 0.25
			ore_mat.emission_enabled = true
			ore_mat.emission = Color(1.0, 0.50, 0.15) * 0.75
		OreType.SILICON:
			ore_label_text = "SILICIO" if GameManager.current_language == "es" else "SILICON"
			ore_color = Color(0.25, 0.88, 1.0)
			ore_mat.metallic = 0.25
			ore_mat.roughness = 0.15
			ore_mat.emission_enabled = true
			ore_mat.emission = Color(0.25, 0.88, 1.0) * 1.4
		OreType.URANIUM:
			ore_label_text = "URANIO" if GameManager.current_language == "es" else "URANIUM"
			ore_color = Color(0.30, 1.0, 0.45)
			ore_mat.metallic = 0.20
			ore_mat.roughness = 0.20
			ore_mat.emission_enabled = true
			ore_mat.emission = Color(0.30, 1.0, 0.45) * 2.2
			
	ore_mat.albedo_color = ore_color
	
	# Boulder Base Rock is ALWAYS realistic natural granite / dark crust stone!
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.22, 0.20, 0.19)
	rock_mat.roughness = 0.96
	rock_mat.metallic = 0.04

	if mesh_instance:
		mesh_instance.material_override = rock_mat
		for child in mesh_instance.get_children():
			if child is MeshInstance3D:
				if child.name.begins_with("MineralVein"):
					child.material_override = ore_mat
				else:
					child.material_override = rock_mat
		
	if label_3d:
		label_3d.text = "[ %s ]" % ore_label_text
		label_3d.modulate = ore_color
		
	scale = Vector3(1.35, 1.35, 1.35)

func _build_large_boulder_mesh() -> void:
	if not mesh_instance:
		return
	for child in mesh_instance.get_children():
		child.queue_free()
	vein_meshes.clear()
		
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.22, 0.20, 0.19)
	rock_mat.roughness = 0.96
	rock_mat.metallic = 0.04
	
	# 1. Deep-Rooted Subterranean Anchor (Extends deep into ground: y = -1.5m to 0.4m)
	# This ensures the boulder is completely grounded in the planet crust with zero floating bottoms!
	var anchor_mesh = CylinderMesh.new()
	anchor_mesh.top_radius = 1.35
	anchor_mesh.bottom_radius = 0.65
	anchor_mesh.height = 1.6
	anchor_mesh.radial_segments = 8
	var anchor_inst = MeshInstance3D.new()
	anchor_inst.name = "SubterraneanAnchor"
	anchor_inst.mesh = anchor_mesh
	anchor_inst.position = Vector3(0.0, -0.65, 0.0)
	anchor_inst.material_override = rock_mat
	mesh_instance.add_child(anchor_inst)
	
	# 2. Craggy Exposed Surface Boulder Core
	var rock_mesh = BoxMesh.new()
	rock_mesh.size = Vector3(2.2, 1.4, 2.2)
	mesh_instance.mesh = rock_mesh
	mesh_instance.material_override = rock_mat
	mesh_instance.position = Vector3(0.0, 0.45, 0.0)
	
	# 3. Angular Flanking Stone Slabs (Natural crag contours)
	for side_i in range(6):
		var ang = float(side_i) * (TAU / 6.0) + 0.20
		var slab = MeshInstance3D.new()
		var pr = PrismMesh.new()
		pr.size = Vector3(1.1, 1.5, 1.1)
		pr.material = rock_mat
		slab.mesh = pr
		slab.position = Vector3(cos(ang) * 0.95, 0.1, sin(ang) * 0.95)
		slab.rotation = Vector3(randf_range(-0.25, 0.25), ang, randf_range(-0.25, 0.25))
		mesh_instance.add_child(slab)
		
	# 4. Embedded Mineral Veins protruding from geological fractures
	for c_i in range(total_extractions):
		var c_ang = float(c_i) * (TAU / float(total_extractions)) + 0.35
		var crystal_cluster = MeshInstance3D.new()
		crystal_cluster.name = "MineralVein_%d" % c_i
		var c_prism = PrismMesh.new()
		c_prism.size = Vector3(0.65, 1.05, 0.65)
		crystal_cluster.mesh = c_prism
		crystal_cluster.position = Vector3(cos(c_ang) * 0.92, 0.45 + (c_i % 2) * 0.25, sin(c_ang) * 0.92)
		crystal_cluster.rotation = Vector3(sin(c_ang) * 0.4, c_ang, cos(c_ang) * 0.4)
		mesh_instance.add_child(crystal_cluster)
		vein_meshes.append(crystal_cluster)
		
	# 5. Collision Shape firmly enveloping surface & subterranean foot
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		var box_col = BoxShape3D.new()
		box_col.size = Vector3(2.5, 2.2, 2.5)
		col.shape = box_col
		col.position = Vector3(0.0, 0.35, 0.0)

func get_scanner_data() -> Dictionary:
	match ore_type:
		OreType.IRON:
			return {
				"name": "HIERRO [Fe]",
				"purity": "99.2%",
				"density": "7.87 g/cm³",
				"desc": "Estructura austenítica densa para blindajes."
			}
		OreType.COPPER:
			return {
				"name": "COBRE [Cu]",
				"purity": "94.8%",
				"density": "8.96 g/cm³",
				"desc": "Alta conductividad térmica y eléctrica."
			}
		OreType.SILICON:
			return {
				"name": "SILICIO [Si]",
				"purity": "98.1%",
				"density": "2.33 g/cm³",
				"desc": "Red semiconductora para microcircuitos."
			}
		OreType.URANIUM:
			return {
				"name": "URANIO [U-235]",
				"purity": "88.4%",
				"density": "19.1 g/cm³",
				"desc": "Isótopo fisionable de alta energía para hiperimpulso."
			}
	return {}

func set_scanned(scanned: bool) -> void:
	is_being_scanned = scanned
	if label_3d and not is_depleted:
		label_3d.visible = scanned
		if scanned:
			var data = get_scanner_data()
			var pct = int(clampf(float(remaining_extractions) / float(total_extractions), 0.0, 1.0) * 100.0)
			label_3d.text = "[ %s • %s • %d%% (%d/%d) ]" % [data.get("name", ore_label_text), data.get("purity", ""), pct, remaining_extractions, total_extractions]
			label_3d.modulate = ore_color

func mine_tick(delta: float) -> bool:
	if is_depleted:
		return false
		
	current_health = maxf(0.0, current_health - delta)
	extraction_timer += delta
	
	if spark_particles and not spark_particles.emitting:
		spark_particles.emitting = true
		
	# High-frequency geological micro-vibration during plasma beam fracture
	if mesh_instance:
		mesh_instance.position.x = randf_range(-0.04, 0.04)
		mesh_instance.position.z = randf_range(-0.04, 0.04)
		
	if label_3d and label_3d.visible:
		var pct = int(clampf(float(remaining_extractions) / float(total_extractions), 0.0, 1.0) * 100.0)
		label_3d.text = "[ %s • %d%% ]" % [ore_label_text, pct]
		
	# Balanced extraction tick reached: Harvest 1 resource batch!
	if extraction_timer >= EXTRACTION_STEP_TIME:
		extraction_timer = 0.0
		var depleted = _extract_single_vein()
		if depleted:
			return true
			
	if current_health <= 0.0 and not is_depleted:
		_deplete_and_leave_barren_rock()
		return true
		
	return false

func _extract_single_vein() -> bool:
	if remaining_extractions <= 0 or is_depleted:
		return true
		
	remaining_extractions -= 1
	var res_key = "iron"
	match ore_type:
		OreType.IRON: res_key = "iron"
		OreType.COPPER: res_key = "copper"
		OreType.SILICON: res_key = "silicon"
		OreType.URANIUM: res_key = "uranium"
		
	# 1. Harvest resource into astronaut cargo
	if is_instance_valid(GameManager) and GameManager.crafting:
		GameManager.crafting.add_resource(res_key, yield_amount)
	AudioManager.play("collect", 1.2, 2.0)
	
	# 2. Physically drop a mineral chunk that pops cleanly out of the rock and lands nearby
	var drop_scene = load("res://scenes/entities/dropped_item.tscn")
	if drop_scene and get_parent():
		var drop = drop_scene.instantiate()
		drop.setup_drop(res_key, 1, 160.0)
		get_parent().add_child(drop)
		var up_n = global_transform.basis.y.normalized()
		var rand_ang = randf() * TAU
		var radial_out = (global_transform.basis.x * cos(rand_ang) + global_transform.basis.z * sin(rand_ang)).normalized()
		# Clear the 2.5m boulder collision envelope: spawn on outward rim and launch arc
		drop.global_position = global_position + radial_out * 2.2 + up_n * 1.2
		var pop_impulse = radial_out * 4.8 + up_n * 4.2
		drop.apply_central_impulse(pop_impulse)
		
	# 3. Collapse/fracture one of the visible mineral veins
	if not vein_meshes.is_empty():
		var v_idx = remaining_extractions
		if v_idx >= 0 and v_idx < vein_meshes.size():
			var vein = vein_meshes[v_idx]
			if is_instance_valid(vein):
				var tw = vein.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.tween_property(vein, "scale", Vector3.ZERO, 0.25)
				tw.tween_callback(func(): vein.visible = false)
				
	# 4. Feedback toast & floating counter
	if label_3d:
		label_3d.visible = true
		label_3d.text = "+%d %s! [%d/%d]" % [yield_amount, ore_label_text, remaining_extractions, total_extractions]
		label_3d.modulate = Color(1.0, 0.95, 0.3)
		var tw_l = create_tween()
		tw_l.tween_property(label_3d, "position:y", 2.2, 0.4)
		tw_l.tween_property(label_3d, "position:y", 1.25, 0.2)
		
	_spawn_harvest_sphere()
	
	# If all veins extracted: BARREN ROCK REMAINS!
	if remaining_extractions <= 0:
		_deplete_and_leave_barren_rock()
		return true
		
	return false

func _deplete_and_leave_barren_rock() -> void:
	if is_depleted:
		return
	is_depleted = true
	collision_layer = 1 # Drops out of mining interaction layer (layer 2), stays as solid terrain (layer 1)
	remove_from_group("resource_nodes")
	
	if spark_particles:
		spark_particles.emitting = false
		
	# Hide all remaining vein crystals
	for v in vein_meshes:
		if is_instance_valid(v):
			v.visible = false
			
	# Quenched rock feedback: Rock stays permanently in the scene!
	if label_3d:
		label_3d.visible = true
		label_3d.text = "[ VETA AGOTADA • ROCA INERTE ]"
		label_3d.modulate = Color(0.65, 0.65, 0.65, 0.8)
		var tw_f = create_tween()
		tw_f.tween_property(label_3d, "modulate:a", 0.0, 1.8)
		tw_f.tween_callback(func(): label_3d.visible = false)

func break_and_harvest() -> void:
	# Fallback / unit test compatibility: Completes remaining extractions and depletes rock
	while remaining_extractions > 0:
		_extract_single_vein()
	_deplete_and_leave_barren_rock()

func _spawn_harvest_sphere() -> void:
	var sphere = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.16
	s_mesh.height = 0.32
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = ore_color
	s_mat.metallic = 0.85
	s_mat.roughness = 0.25
	s_mat.emission_enabled = true
	s_mat.emission = ore_color * 1.5
	sphere.mesh = s_mesh
	sphere.material_override = s_mat
	if get_parent():
		get_parent().add_child(sphere)
		sphere.global_position = global_position + Vector3.UP * 0.6
		var tw = sphere.create_tween().set_parallel(true)
		tw.tween_property(sphere, "scale", Vector3.ZERO, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(sphere, "position:y", sphere.position.y + 0.8, 0.75)
		tw.chain().tween_callback(sphere.queue_free)
