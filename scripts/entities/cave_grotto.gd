extends StaticBody3D
class_name CaveGrotto

# =============================================================================
# CAVE GROTTO & MINING SHAFT (ORGANIC SUBTERRANEAN CAVERN - MINECRAFT STYLE)
# =============================================================================

@onready var light: OmniLight3D = get_node_or_null("CaveOmniLight")
@onready var crystal: MeshInstance3D = get_node_or_null("CrystalInterior")
@onready var crystal_sec: MeshInstance3D = get_node_or_null("CrystalSecondary")
@onready var tunnel_root: Node3D = get_node_or_null("TunnelRoot")

var spawned_interior_nodes: Array = []
var submerged_bodies: Array = []
var cave_theme: int = 0
var cave_type: int = 0 # 0: Dry, 1: Submerged, 2: Mixed
var fluid_area: Area3D = null

func _physics_process(delta: float) -> void:
	if submerged_bodies.is_empty():
		return
	for b in submerged_bodies:
		if is_instance_valid(b) and ("vertical_speed" in b):
			# Natural fluid buoyancy: gentle upward lift with swimming controls
			var is_crouching = bool(b.get("is_crouch_pressed")) if "is_crouch_pressed" in b else false
			var is_jumping = bool(b.get("is_jump_pressed")) if "is_jump_pressed" in b else false
			if is_jumping:
				b.vertical_speed = lerpf(b.vertical_speed, 2.6, delta * 5.0)
			elif is_crouching:
				b.vertical_speed = lerpf(b.vertical_speed, -2.4, delta * 5.0)
			else:
				b.vertical_speed = lerpf(b.vertical_speed, 0.4, delta * 3.5)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("caves")
	add_to_group("structures")
	add_to_group("interactable")
	
	_ensure_arch_roof_and_boulders()
	if not tunnel_root:
		tunnel_root = get_node_or_null("TunnelRoot")
	_build_organic_cave_architecture()

func _ensure_arch_roof_and_boulders() -> void:
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.24, 0.22, 0.20)
	rock_mat.roughness = 0.94
	rock_mat.metallic = 0.05

	if not has_node("ArchRoof"):
		var roof = MeshInstance3D.new()
		roof.name = "ArchRoof"
		var box = BoxMesh.new()
		box.size = Vector3(7.4, 1.8, 8.5)
		box.material = rock_mat
		roof.mesh = box
		roof.position = Vector3(0.0, 4.2, -6.0)
		add_child(roof)

	if not has_node("EntranceBoulderL"):
		var b_l = MeshInstance3D.new()
		b_l.name = "EntranceBoulderL"
		var bm = BoxMesh.new()
		bm.size = Vector3(2.2, 1.6, 2.2)
		bm.material = rock_mat
		b_l.mesh = bm
		b_l.position = Vector3(-2.6, 0.7, 2.4)
		add_child(b_l)

	if not has_node("EntranceBoulderR"):
		var b_r = MeshInstance3D.new()
		b_r.name = "EntranceBoulderR"
		var bm2 = BoxMesh.new()
		bm2.size = Vector3(2.2, 1.6, 2.2)
		bm2.material = rock_mat
		b_r.mesh = bm2
		b_r.position = Vector3(2.6, 0.7, 2.4)
		add_child(b_r)

	if not has_node("ExitBoulderL"):
		var ex_l = MeshInstance3D.new()
		ex_l.name = "ExitBoulderL"
		var bm3 = BoxMesh.new()
		bm3.size = Vector3(2.2, 1.6, 2.2)
		bm3.material = rock_mat
		ex_l.mesh = bm3
		ex_l.position = Vector3(-2.5, 0.7, -4.8)
		add_child(ex_l)

	if not has_node("ExitBoulderR"):
		var ex_r = MeshInstance3D.new()
		ex_r.name = "ExitBoulderR"
		var bm4 = BoxMesh.new()
		bm4.size = Vector3(2.2, 1.6, 2.2)
		bm4.material = rock_mat
		ex_r.mesh = bm4
		ex_r.position = Vector3(2.5, 0.7, -4.8)
		add_child(ex_r)

func setup_theme(planet_params: Dictionary) -> void:
	if not light: light = get_node_or_null("CaveOmniLight")
	if not crystal: crystal = get_node_or_null("CrystalInterior")
	if not crystal_sec: crystal_sec = get_node_or_null("CrystalSecondary")
	
	var lvl = planet_params.get("level", 0)
	var p_type = str(planet_params.get("type", ""))
	var water_st = str(planet_params.get("water_status", ""))
	var is_ocean = planet_params.get("is_ocean_world", false)
	
	var is_molten = planet_params.get("is_molten", false) or water_st.contains("Lava") or p_type.contains("Volcán") or p_type.contains("Magma") or lvl == 5
	var is_toxic = water_st.contains("Ácido") or p_type.contains("Tóxico") or lvl == 2
	var is_cryo = water_st.contains("Hielo") or p_type.contains("Criogénico") or lvl == 3
	var has_water = water_st.contains("Líquida") or is_ocean
	
	var glow_col: Color
	var light_energy: float = 3.2
	
	if is_molten:
		cave_theme = 2
		glow_col = Color(1.0, 0.38, 0.08)
		light_energy = 4.2
		cave_type = 0
	elif is_toxic:
		cave_theme = 3
		glow_col = Color(0.12, 0.95, 0.35)
		light_energy = 3.2
		cave_type = 2 if has_water else 0
	elif is_cryo:
		cave_theme = 4
		glow_col = Color(0.15, 0.45, 1.0)
		light_energy = 3.2
		cave_type = 0
	elif is_ocean:
		cave_theme = 1
		glow_col = Color(0.15, 0.85, 1.0)
		light_energy = 3.2
		cave_type = 1
	elif has_water:
		cave_theme = 1
		glow_col = Color(0.15, 0.85, 1.0)
		light_energy = 3.0
		cave_type = 2
	else:
		cave_theme = 0
		glow_col = Color(1.0, 0.72, 0.25)
		light_energy = 2.8
		cave_type = 0
		
	if light:
		light.light_color = glow_col
		light.light_energy = light_energy
		
	if crystal and is_instance_valid(crystal):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = glow_col
		mat.emission_enabled = true
		mat.emission = glow_col
		mat.emission_energy_multiplier = 3.5
		mat.roughness = 0.15
		mat.metallic = 0.3
		crystal.material_override = mat

	if crystal_sec and is_instance_valid(crystal_sec):
		var mat2 = StandardMaterial3D.new()
		mat2.albedo_color = glow_col.lerp(Color.WHITE, 0.25)
		mat2.emission_enabled = true
		mat2.emission = glow_col
		mat2.emission_energy_multiplier = 2.5
		mat2.roughness = 0.2
		crystal_sec.material_override = mat2

	_setup_subterranean_hydrology(glow_col)
	populate_cavern_contents(planet_params)

func _setup_subterranean_hydrology(water_tint: Color) -> void:
	if cave_type == 0 or fluid_area != null:
		return
		
	fluid_area = Area3D.new()
	fluid_area.name = "SubterraneanFluidVolume"
	fluid_area.collision_layer = 0
	fluid_area.collision_mask = 2 # Detect player
	add_child(fluid_area)
	
	var col = CollisionShape3D.new()
	var bshape = BoxShape3D.new()
	
	if cave_type == 1:
		bshape.size = Vector3(18.0, 16.0, 36.0)
		col.position = Vector3(0.0, -2.5, -12.0)
	else:
		bshape.size = Vector3(15.0, 7.5, 18.0)
		col.position = Vector3(0.0, -6.5, -18.0)
		
	col.shape = bshape
	fluid_area.add_child(col)
	
	# Fluid surface reflection & refraction sheet
	var surface_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(bshape.size.x, bshape.size.z)
	var water_mat = StandardMaterial3D.new()
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.albedo_color = Color(water_tint.r * 0.4, water_tint.g * 0.6, water_tint.b * 0.9, 0.65)
	water_mat.roughness = 0.08
	water_mat.metallic = 0.15
	water_mat.emission_enabled = true
	water_mat.emission = water_tint * 0.25
	surface_mesh.mesh = plane
	surface_mesh.position = col.position + Vector3(0.0, bshape.size.y * 0.5 - 0.05, 0.0)
	add_child(surface_mesh)
	
	# Subterranean underwater volumetric lighting
	var under_light = OmniLight3D.new()
	under_light.name = "UnderwaterAmbience"
	under_light.light_color = water_tint
	under_light.light_energy = 2.4
	under_light.omni_range = 24.0
	under_light.omni_attenuation = 1.3
	under_light.position = col.position + Vector3(0.0, -1.0, 0.0)
	add_child(under_light)
	
	fluid_area.body_entered.connect(_on_fluid_body_entered)
	fluid_area.body_exited.connect(_on_fluid_body_exited)

func _on_fluid_body_entered(body: Node) -> void:
	if body and "is_in_liquid" in body:
		body.is_in_liquid = true
		if "is_in_subterranean_fluid" in body:
			body.is_in_subterranean_fluid = true
		if not submerged_bodies.has(body):
			submerged_bodies.append(body)

func _on_fluid_body_exited(body: Node) -> void:
	if body and "is_in_liquid" in body:
		if "is_in_subterranean_fluid" in body:
			body.is_in_subterranean_fluid = false
		submerged_bodies.erase(body)
		if not ("is_in_subterranean_fluid" in body and body.is_in_subterranean_fluid):
			body.is_in_liquid = false

func _build_organic_cave_architecture() -> void:
	if not tunnel_root:
		tunnel_root = Node3D.new()
		tunnel_root.name = "TunnelRoot"
		add_child(tunnel_root)
		
	if tunnel_root.get_child_count() > 0:
		return
		
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.24, 0.22, 0.20)
	rock_mat.roughness = 0.94
	rock_mat.metallic = 0.05
	
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.38, 0.25, 0.15)
	wood_mat.roughness = 0.88
	
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.45, 0.45, 0.48)
	iron_mat.metallic = 0.85
	iron_mat.roughness = 0.3
	
	var tunnel_depth_steps = 7
	for step in range(tunnel_depth_steps):
		var z_pos = -float(step) * 2.4 - 1.2
		var y_pos = -float(step) * 0.85 - 0.4
		
		for side in [-1.0, 1.0]:
			var rock_pillar = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = randf_range(0.65, 0.95)
			cyl.bottom_radius = randf_range(0.85, 1.25)
			cyl.height = 3.6 + step * 0.4
			cyl.radial_segments = 6
			cyl.material = rock_mat
			rock_pillar.mesh = cyl
			rock_pillar.position = Vector3(side * (2.4 + step * 0.2), y_pos + 1.2, z_pos)
			rock_pillar.rotation = Vector3(randf_range(-0.1, 0.1), randf_range(-0.3, 0.3), side * randf_range(-0.15, -0.05))
			tunnel_root.add_child(rock_pillar)
			
		var arch_stone = MeshInstance3D.new()
		var pr = PrismMesh.new()
		pr.size = Vector3(4.8 + step * 0.4, 1.4, 2.2)
		pr.material = rock_mat
		arch_stone.mesh = pr
		arch_stone.position = Vector3(0.0, y_pos + 3.2 + step * 0.2, z_pos)
		arch_stone.rotation = Vector3(deg_to_rad(180.0), 0.0, 0.0)
		tunnel_root.add_child(arch_stone)
		
		if step % 2 == 1:
			_create_timber_support(tunnel_root, Vector3(0.0, y_pos, z_pos), wood_mat, iron_mat, 4.2 + step * 0.3, 3.2)
			
		_create_mine_rails(tunnel_root, Vector3(0.0, y_pos + 0.05, z_pos), iron_mat, wood_mat)

	var chamber_center = Vector3(0.0, -6.5, -19.5)
	for i in range(5):
		var stalactite = MeshInstance3D.new()
		var st_cyl = CylinderMesh.new()
		st_cyl.top_radius = 0.02
		st_cyl.bottom_radius = randf_range(0.35, 0.6)
		st_cyl.height = randf_range(2.0, 3.5)
		st_cyl.radial_segments = 5
		st_cyl.material = rock_mat
		stalactite.mesh = st_cyl
		stalactite.position = chamber_center + Vector3(randf_range(-3.5, 3.5), 3.8, randf_range(-3.5, 3.5))
		tunnel_root.add_child(stalactite)
		
	for i in range(5):
		var stalagmite = MeshInstance3D.new()
		var sm_cyl = CylinderMesh.new()
		sm_cyl.top_radius = randf_range(0.3, 0.5)
		sm_cyl.bottom_radius = 0.04
		sm_cyl.height = randf_range(1.5, 2.8)
		sm_cyl.radial_segments = 5
		sm_cyl.material = rock_mat
		stalagmite.mesh = sm_cyl
		stalagmite.position = chamber_center + Vector3(randf_range(-3.8, 3.8), 0.8, randf_range(-3.8, 3.8))
		tunnel_root.add_child(stalagmite)

func _create_timber_support(parent: Node3D, pos: Vector3, wood_mat: Material, iron_mat: Material, span_w: float, height_h: float) -> void:
	var timber_group = Node3D.new()
	timber_group.position = pos
	parent.add_child(timber_group)
	
	for side in [-1.0, 1.0]:
		var post = MeshInstance3D.new()
		var b = BoxMesh.new()
		b.size = Vector3(0.28, height_h, 0.28)
		b.material = wood_mat
		post.mesh = b
		post.position = Vector3(side * (span_w * 0.5 - 0.2), height_h * 0.5, 0.0)
		timber_group.add_child(post)
		
		var bracket = MeshInstance3D.new()
		var bb = BoxMesh.new()
		bb.size = Vector3(0.34, 0.34, 0.34)
		bb.material = iron_mat
		bracket.mesh = bb
		bracket.position = Vector3(side * (span_w * 0.5 - 0.2), height_h - 0.17, 0.0)
		timber_group.add_child(bracket)
		
	var beam = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(span_w, 0.28, 0.28)
	bm.material = wood_mat
	beam.mesh = bm
	beam.position = Vector3(0.0, height_h - 0.14, 0.0)
	timber_group.add_child(beam)

func _create_mine_rails(parent: Node3D, pos: Vector3, iron_mat: Material, wood_mat: Material) -> void:
	var rail_node = Node3D.new()
	rail_node.position = pos
	parent.add_child(rail_node)
	
	for i in range(3):
		var tie = MeshInstance3D.new()
		var tb = BoxMesh.new()
		tb.size = Vector3(1.3, 0.06, 0.22)
		tb.material = wood_mat
		tie.mesh = tb
		tie.position = Vector3(0.0, 0.03, -float(i) * 0.8 + 0.8)
		rail_node.add_child(tie)
		
	for side in [-1.0, 1.0]:
		var rail = MeshInstance3D.new()
		var rb = BoxMesh.new()
		rb.size = Vector3(0.06, 0.08, 2.4)
		rb.material = iron_mat
		rail.mesh = rb
		rail.position = Vector3(side * 0.45, 0.08, 0.0)
		rail_node.add_child(rail)

func populate_cavern_contents(planet_params: Dictionary) -> void:
	if not spawned_interior_nodes.is_empty():
		return
		
	var ore_scene = load("res://scenes/entities/resource_chunk.tscn")
	if ore_scene:
		# Mineral veins embedded along tunnel walls & gallery chambers:
		# Iron (0), Copper (1), Silicon (2), Uranium (3)
		var mineral_veins = [
			{"pos": Vector3(-2.2, -1.2, -3.8), "type": 0}, # Upper Tunnel Iron Vein
			{"pos": Vector3(2.4, -2.1, -6.5), "type": 1},  # Descent Copper Vein
			{"pos": Vector3(-2.6, -3.6, -11.0), "type": 0}, # Mid Gallery Iron Vein
			{"pos": Vector3(2.8, -4.5, -14.5), "type": 1},  # Mid Gallery Copper Vein
			{"pos": Vector3(-3.4, -6.2, -18.2), "type": 2}, # Deep Chamber Silicon Vein
			{"pos": Vector3(3.2, -6.2, -20.5), "type": 3},  # Deep Chamber Uranium Vein
			{"pos": Vector3(-1.8, -6.4, -22.5), "type": 2}, # Cavern Floor Silicon Prism
			{"pos": Vector3(1.5, -6.4, -23.0), "type": 3}   # Cavern Floor Uranium Crystal
		]
		for vein in mineral_veins:
			var ore = ore_scene.instantiate()
			ore.ore_type = vein["type"]
			ore.position = vein["pos"]
			add_child(ore)
			spawned_interior_nodes.append(ore)

	# Minecraft-style Crystal Formations in subterranean chamber
	_build_crystal_formations(planet_params)

	var creature_scene = load("res://scenes/entities/alien_creature.tscn")
	if creature_scene:
		var creature = creature_scene.instantiate()
		creature.position = Vector3(0.0, -6.0, -19.0)
		add_child(creature)
		if creature.has_method("setup_creature"):
			creature.setup_creature(planet_params, false, 0)
			if creature.has_method("configure_subspecies"):
				creature.configure_subspecies(3, planet_params, false)
		spawned_interior_nodes.append(creature)

func _build_crystal_formations(planet_params: Dictionary) -> void:
	var crystal_root = Node3D.new()
	crystal_root.name = "CrystalFormations"
	add_child(crystal_root)
	spawned_interior_nodes.append(crystal_root)
	
	var crystal_mat = StandardMaterial3D.new()
	var glow_col = Color(0.2, 0.85, 1.0)
	if cave_theme == 2: glow_col = Color(1.0, 0.4, 0.1) # Molten
	elif cave_theme == 3: glow_col = Color(0.2, 1.0, 0.4) # Toxic
	elif cave_theme == 4: glow_col = Color(0.3, 0.6, 1.0) # Cryo
	elif cave_theme == 0: glow_col = Color(1.0, 0.75, 0.25) # Amber
	
	crystal_mat.albedo_color = glow_col
	crystal_mat.emission_enabled = true
	crystal_mat.emission = glow_col
	crystal_mat.emission_energy_multiplier = 3.2
	crystal_mat.roughness = 0.15
	crystal_mat.metallic = 0.25
	
	var cluster_positions = [
		Vector3(-3.2, -6.3, -16.5),
		Vector3(3.5, -6.3, -17.5),
		Vector3(0.0, -6.3, -23.5)
	]
	
	for c_pos in cluster_positions:
		var cluster = Node3D.new()
		cluster.position = c_pos
		crystal_root.add_child(cluster)
		
		for sp in range(4):
			var spike = MeshInstance3D.new()
			var prism = CylinderMesh.new()
			prism.top_radius = 0.02
			prism.bottom_radius = randf_range(0.12, 0.25)
			prism.height = randf_range(1.4, 2.8)
			prism.radial_segments = 5
			prism.material = crystal_mat
			spike.mesh = prism
			spike.position = Vector3(cos(float(sp) * 1.57) * 0.45, prism.height * 0.45, sin(float(sp) * 1.57) * 0.45)
			spike.rotation = Vector3(randf_range(-0.35, 0.35), randf_range(-1.0, 1.0), randf_range(-0.35, 0.35))
			cluster.add_child(spike)
