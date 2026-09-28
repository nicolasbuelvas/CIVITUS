extends StaticBody3D
class_name ResourceChunk

enum OreType { IRON, COPPER, SILICON, URANIUM }

@export var ore_type: OreType = OreType.IRON
@export var yield_amount: int = 3
@export var max_health: float = 1.2

@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var label_3d: Label3D = get_node_or_null("Label3D")

var current_health: float = 1.2
var ore_color: Color = Color(0.85, 0.55, 0.25)
var ore_label_text: String = "HIERRO"
var initial_scale: Vector3 = Vector3.ONE
var is_being_scanned: bool = false
var spark_particles: CPUParticles3D = null
var lod_check_timer: float = 0.0

func _ready() -> void:
	collision_layer = 2 # Mining layer
	collision_mask = 0
	current_health = max_health
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		var b = BoxMesh.new()
		b.size = Vector3(0.5, 0.5, 0.5)
		mesh_instance.mesh = b
		add_child(mesh_instance)
	if not label_3d:
		label_3d = Label3D.new()
		add_child(label_3d)
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
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.55
	mat.metallic = 0.65
	
	match ore_type:
		OreType.IRON:
			ore_label_text = "HIERRO" if GameManager.current_language == "es" else "IRON"
			ore_color = Color(0.82, 0.85, 0.92)
			mat.metallic = 0.85
			mat.roughness = 0.4
		OreType.COPPER:
			ore_label_text = "COBRE" if GameManager.current_language == "es" else "COPPER"
			ore_color = Color(0.95, 0.52, 0.22)
			mat.metallic = 0.80
			mat.roughness = 0.35
		OreType.SILICON:
			ore_label_text = "SILICIO" if GameManager.current_language == "es" else "SILICON"
			ore_color = Color(0.35, 0.85, 1.0)
			mat.metallic = 0.3
			mat.roughness = 0.2
			mat.emission_enabled = true
			mat.emission = ore_color * 0.4
		OreType.URANIUM:
			ore_label_text = "URANIO" if GameManager.current_language == "es" else "URANIUM"
			ore_color = Color(0.25, 0.95, 0.40)
			mat.emission_enabled = true
			mat.emission = ore_color * 0.8
			mat.roughness = 0.3
			
	mat.albedo_color = ore_color
	if mesh_instance:
		mesh_instance.material_override = mat
		for child in mesh_instance.get_children():
			if child is MeshInstance3D:
				child.material_override = mat
		
	if label_3d:
		label_3d.text = "[ %s ]" % ore_label_text
		label_3d.modulate = ore_color

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
	if label_3d:
		label_3d.visible = scanned
		if scanned:
			var data = get_scanner_data()
			var pct = int(clampf(current_health / max_health, 0.0, 1.0) * 100.0)
			label_3d.text = "[ %s • %s • %d%% ]" % [data.get("name", ore_label_text), data.get("purity", ""), pct]
			label_3d.modulate = ore_color

func mine_tick(delta: float) -> bool:
	current_health -= delta
	
	if spark_particles and not spark_particles.emitting:
		spark_particles.emitting = true
		
	# Responsive fracture scaling & shake
	if mesh_instance:
		var health_pct = clampf(current_health / max_health, 0.0, 1.0)
		var factor = 0.35 + 0.65 * health_pct
		mesh_instance.scale = initial_scale * factor
		mesh_instance.position.x = randf_range(-0.06, 0.06)
		mesh_instance.position.z = randf_range(-0.06, 0.06)
		
	if label_3d and label_3d.visible:
		var pct = int(clampf(current_health / max_health, 0.0, 1.0) * 100.0)
		label_3d.text = "[ %s %d%% ]" % [ore_label_text, pct]
	
	if current_health <= 0.0:
		break_and_harvest()
		return true
	return false

func break_and_harvest() -> void:
	collision_layer = 0
	if spark_particles:
		spark_particles.emitting = false
		
	var res_key = "iron"
	match ore_type:
		OreType.IRON: res_key = "iron"
		OreType.COPPER: res_key = "copper"
		OreType.SILICON: res_key = "silicon"
		OreType.URANIUM: res_key = "uranium"
		
	GameManager.crafting.add_resource(res_key, yield_amount)
	AudioManager.play("collect", 1.2, 2.0)
	
	if label_3d:
		label_3d.visible = true
		label_3d.text = "+%d %s!" % [yield_amount, ore_label_text]
		label_3d.modulate = Color(1.0, 1.0, 0.4)
		var tw_l = create_tween()
		tw_l.tween_property(label_3d, "position:y", 2.2, 0.6)
		tw_l.parallel().tween_property(label_3d, "modulate:a", 0.0, 0.6)
	
	# Spawn detached physical resource orb before clearing
	_spawn_harvest_sphere()
	
	if mesh_instance:
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.2)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _spawn_harvest_sphere() -> void:
	var sphere = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.18
	s_mesh.height = 0.36
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = ore_color
	s_mat.metallic = 0.8
	s_mat.roughness = 0.25
	s_mesh.material = s_mat
	sphere.mesh = s_mesh
	sphere.global_position = global_position + Vector3.UP * 0.4
	
	get_parent().add_child(sphere)
	var tw = sphere.create_tween().set_parallel(true)
	tw.tween_property(sphere, "scale", Vector3.ZERO, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(sphere, "position:y", sphere.position.y + 0.6, 0.85)
	tw.chain().tween_callback(sphere.queue_free)
