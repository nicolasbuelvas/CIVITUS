extends StaticBody3D
class_name ProceduralFlora

enum FloraDomain { TERRESTRIAL, AQUATIC, EXOTIC }

enum FloraType {
	# 7 Terrestres
	FRACTAL_TREE,        # 0. Árbol con tronco ramificado y follaje poliédrico
	CONICAL_PINE,        # 1. Pino cónico boreal con copas superpuestas
	BERRY_BUSH,          # 2. Arbusto esférico con bayas nutritivas cosechables
	FAN_FERN,            # 3. Helecho abanico con hojas curvadas en espiral
	COLUMNAR_CACTUS,     # 4. Cactus columnar estriado con brazos ramificados
	GIANT_MUSHROOM,      # 5. Seta gigante con sombrero convexo y láminas
	REED_CLUSTERS,       # 6. Grupo de cañas tubulares delgadas con penachos

	# 7 Acuáticos
	GIANT_KELP,          # 7. Algas kelp marinas ondulantes desde el fondo
	SURFACE_LOTUS,       # 8. Loto flotante reposando sobre la superficie del agua
	TUBE_CORAL,          # 9. Arrecife de coral tubular ramificado multicolor
	LUMEN_ANEMONE,       # 10. Anémona luminosa con tentáculos blandos brillantes
	SEAGRASS_BED,        # 11. Pradera de hierba marina verde/turquesa ondulante
	WATER_LILY_PAD,      # 12. Hojas circulares flotantes con flor central
	SPIRAL_HYDROPHYTE,   # 13. Hidrofita helicoidal sumergida que gira con la corriente

	# 7 Exóticos (con propiedades especiales únicas)
	CAVE_GLOW_SHROOM,    # 14. Hongo bioluminiscente de caverna y minas profundas (emite luz)
	DESERT_TUMBLEWEED,   # 15. Planta rodante del desierto que se desprende y rueda con el viento
	CARNIVOROUS_SNAPPER, # 16. Planta carnívora con mandíbulas que se cierran al acercarse
	VESICLE_FLOATER,     # 17. Planta con sacos de gas que flota suspendida a baja altura
	PRISMATIC_CRYSTAL_TREE, # 18. Estructura vegetal cristalina refractiva y reflectiva
	SPORE_POD_BULB,      # 19. Bulbo vegetal que pulsa y emite esporas cuando el jugador se aproxima
	BASALT_VINE          # 20. Enredadera trepadora de basalto y roca escarpada
}

@export var flora_type: FloraType = FloraType.FRACTAL_TREE
@export var flora_domain: FloraDomain = FloraDomain.TERRESTRIAL

var planet_radius: float = 160.0
var sway_time: float = 2.5
var sway_mag: float = 0.05
var anim_phase: float = 0.0

# Special behavior variables
var is_snapper_shut: bool = false
var snap_cooldown: float = 0.0
var tumble_dir: Vector3 = Vector3.FORWARD
var tumble_speed: float = 0.0
var is_tumbling: bool = false
var spore_cooldown: float = 0.0

# Node references
@onready var col_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var visuals: Node3D = get_node_or_null("Visuals")
@onready var omni_light: OmniLight3D = get_node_or_null("CaveOmniLight")

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	anim_phase = randf_range(0.0, TAU)
	sway_time = randf_range(2.0, 4.0)
	sway_mag = randf_range(0.03, 0.07)
	
	if flora_type == FloraType.DESERT_TUMBLEWEED:
		is_tumbling = true
		tumble_speed = randf_range(2.5, 4.8)
		if col_shape: col_shape.disabled = true

func setup_flora(type_id: int, planet_params: Dictionary, up_direction: Vector3 = Vector3.UP) -> void:
	flora_type = type_id as FloraType
	
	# Group into domains
	if flora_type <= FloraType.REED_CLUSTERS:
		flora_domain = FloraDomain.TERRESTRIAL
	elif flora_type <= FloraType.SPIRAL_HYDROPHYTE:
		flora_domain = FloraDomain.AQUATIC
	else:
		flora_domain = FloraDomain.EXOTIC

	if flora_type == FloraType.DESERT_TUMBLEWEED:
		is_tumbling = true
		tumble_speed = randf_range(2.5, 4.8)
		if col_shape: col_shape.disabled = true

	_build_procedural_mesh(planet_params, up_direction)

func _process(delta: float) -> void:
	anim_phase += delta
	
	# 1. Gentle wind sway for terrestrial and aquatic flora
	if visuals and (flora_domain == FloraDomain.TERRESTRIAL or flora_domain == FloraDomain.AQUATIC):
		var sway = sin(anim_phase * (TAU / sway_time)) * sway_mag
		visuals.rotation.z = sway
		visuals.rotation.x = cos(anim_phase * (TAU / (sway_time * 1.3))) * (sway_mag * 0.7)

	# 2. Exotic: Carnivorous Snapper jaw mechanics
	if flora_type == FloraType.CARNIVOROUS_SNAPPER:
		snap_cooldown -= delta
		var player = get_tree().get_first_node_in_group("player")
		if player is Node3D:
			var d = global_position.distance_to(player.global_position)
			if d < 2.4 and not is_snapper_shut and snap_cooldown <= 0.0:
				_snap_jaws(true)
			elif d > 3.2 and is_snapper_shut:
				_snap_jaws(false)

	# 3. Exotic: Desert Tumbleweed rolling across surface
	elif flora_type == FloraType.DESERT_TUMBLEWEED and is_tumbling:
		var pos = global_position
		var up_dir = pos.normalized()
		if tumble_dir.length_squared() < 0.1:
			var rand_v = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized()
			tumble_dir = (rand_v - up_dir * rand_v.dot(up_dir)).normalized()
		
		# Move along tangent
		position += tumble_dir * (tumble_speed * delta)
		# Re-project to sphere surface
		var p_len = position.length()
		if planet_radius > 10.0:
			position = position.normalized() * (planet_radius + 0.45)
		if visuals:
			visuals.rotate(up_dir.cross(tumble_dir).normalized(), tumble_speed * delta * 2.5)

	# 4. Exotic: Vesicle Floater buoyant vertical oscillation
	elif flora_type == FloraType.VESICLE_FLOATER and visuals:
		visuals.position.y = 1.1 + sin(anim_phase * 2.2) * 0.22

	# 5. Exotic: Spore Pod Bulb pulsing & player proximity reaction
	elif flora_type == FloraType.SPORE_POD_BULB and visuals:
		var pulse = 1.0 + sin(anim_phase * 3.5) * 0.08
		visuals.scale = Vector3(pulse, 1.0 + cos(anim_phase * 3.5) * 0.12, pulse)
		spore_cooldown -= delta
		var player = get_tree().get_first_node_in_group("player")
		if player is Node3D and spore_cooldown <= 0.0:
			if global_position.distance_to(player.global_position) < 3.0:
				spore_cooldown = 4.0
				AudioManager.play("plasma_shot", 0.6, 2.0)
				var hud = get_tree().get_first_node_in_group("hud")
				if hud and hud.has_method("show_status_toast"):
					hud.show_status_toast("¡ESPORAS ACTIVAS! Muestra bio-vegetal liberada.")

func _snap_jaws(shut: bool) -> void:
	is_snapper_shut = shut
	snap_cooldown = 0.5
	var jaw_top = get_node_or_null("Visuals/JawTop")
	var jaw_bot = get_node_or_null("Visuals/JawBottom")
	if jaw_top and jaw_bot:
		var tw = create_tween().set_parallel(true)
		if shut:
			tw.tween_property(jaw_top, "rotation:x", deg_to_rad(5.0), 0.12).set_trans(Tween.TRANS_BACK)
			tw.tween_property(jaw_bot, "rotation:x", deg_to_rad(-5.0), 0.12).set_trans(Tween.TRANS_BACK)
			AudioManager.play("mine", 1.5, -2.0)
		else:
			tw.tween_property(jaw_top, "rotation:x", deg_to_rad(38.0), 0.35).set_trans(Tween.TRANS_SINE)
			tw.tween_property(jaw_bot, "rotation:x", deg_to_rad(-38.0), 0.35).set_trans(Tween.TRANS_SINE)

func _build_procedural_mesh(planet_params: Dictionary, up_direction: Vector3) -> void:
	if not visuals:
		visuals = Node3D.new()
		visuals.name = "Visuals"
		add_child(visuals)
		
	# Clear any previous meshes
	for child in visuals.get_children():
		child.queue_free()
		
	var p_type = planet_params.get("type", "Habitable")
	var lvl = planet_params.get("level", 0)
	
	# Determine base color theme based on planet
	var primary_col = Color(0.25, 0.72, 0.35)
	var secondary_col = Color(0.42, 0.28, 0.18)
	var is_emissive = false
	
	if p_type.contains("Cryo") or p_type.contains("Hielo"):
		primary_col = Color(0.40, 0.85, 0.95)
		secondary_col = Color(0.25, 0.38, 0.50)
	elif p_type.contains("Volcan") or p_type.contains("Lava"):
		primary_col = Color(0.95, 0.42, 0.12)
		secondary_col = Color(0.20, 0.15, 0.14)
		is_emissive = true
	elif p_type.contains("Toxic") or p_type.contains("Acido"):
		primary_col = Color(0.55, 0.92, 0.22)
		secondary_col = Color(0.32, 0.20, 0.38)
		is_emissive = true
	elif p_type.contains("Desert") or p_type.contains("Arido"):
		primary_col = Color(0.85, 0.68, 0.25)
		secondary_col = Color(0.55, 0.38, 0.22)

	var mat_main = StandardMaterial3D.new()
	mat_main.albedo_color = primary_col
	mat_main.roughness = 0.65
	if is_emissive or flora_domain == FloraDomain.AQUATIC or flora_type == FloraType.CAVE_GLOW_SHROOM:
		mat_main.emission_enabled = true
		mat_main.emission = primary_col * 0.6
		mat_main.emission_energy_multiplier = 1.8
		
	var mat_bark = StandardMaterial3D.new()
	mat_bark.albedo_color = secondary_col
	mat_bark.roughness = 0.85

	# Construct 3D geometry based on the exact 21 Flora Types
	match flora_type:
		# --- TERRESTRIAL (7) ---
		FloraType.FRACTAL_TREE:
			_build_tree_mesh(mat_bark, mat_main, false)
		FloraType.CONICAL_PINE:
			_build_pine_mesh(mat_bark, mat_main)
		FloraType.BERRY_BUSH:
			_build_bush_mesh(mat_main)
		FloraType.FAN_FERN:
			_build_fern_mesh(mat_main)
		FloraType.COLUMNAR_CACTUS:
			_build_cactus_mesh(mat_main)
		FloraType.GIANT_MUSHROOM:
			_build_mushroom_mesh(mat_bark, mat_main, false)
		FloraType.REED_CLUSTERS:
			_build_reeds_mesh(mat_main)

		# --- AQUATIC (7) ---
		FloraType.GIANT_KELP:
			_build_kelp_mesh(mat_main)
		FloraType.SURFACE_LOTUS:
			_build_lotus_mesh(mat_main)
		FloraType.TUBE_CORAL:
			_build_coral_mesh(mat_main)
		FloraType.LUMEN_ANEMONE:
			_build_anemone_mesh(mat_main)
		FloraType.SEAGRASS_BED:
			_build_seagrass_mesh(mat_main)
		FloraType.WATER_LILY_PAD:
			_build_lilypad_mesh(mat_main)
		FloraType.SPIRAL_HYDROPHYTE:
			_build_spiral_hydro_mesh(mat_main)

		# --- EXOTIC (7) ---
		FloraType.CAVE_GLOW_SHROOM:
			mat_main.emission = Color(0.2, 0.95, 1.0)
			mat_main.albedo_color = Color(0.1, 0.85, 0.95)
			mat_main.emission_energy_multiplier = 2.8
			_build_mushroom_mesh(mat_bark, mat_main, true)
		FloraType.DESERT_TUMBLEWEED:
			_build_tumbleweed_mesh(mat_bark)
		FloraType.CARNIVOROUS_SNAPPER:
			_build_carnivorous_mesh(mat_bark, mat_main)
		FloraType.VESICLE_FLOATER:
			_build_floater_mesh(mat_main)
		FloraType.PRISMATIC_CRYSTAL_TREE:
			mat_main.metallic = 0.85
			mat_main.roughness = 0.12
			mat_main.albedo_color = Color(0.85, 0.95, 1.0, 0.85)
			_build_tree_mesh(mat_main, mat_main, true)
		FloraType.SPORE_POD_BULB:
			_build_spore_pod_mesh(mat_main)
		FloraType.BASALT_VINE:
			_build_vine_mesh(mat_main)

# Procedural Geometry Builders for all 21 Types
func _build_tree_mesh(bark_mat: Material, leaf_mat: Material, is_crystal: bool) -> void:
	var trunk = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.22
	cy.bottom_radius = 0.42
	cy.height = 2.8
	cy.material = bark_mat
	trunk.mesh = cy
	trunk.position.y = 1.3
	visuals.add_child(trunk)
	
	# Root Anchor
	var roots = MeshInstance3D.new()
	var root_cy = CylinderMesh.new()
	root_cy.top_radius = 0.65
	root_cy.bottom_radius = 0.85
	root_cy.height = 0.6
	root_cy.material = bark_mat
	roots.mesh = root_cy
	roots.position.y = -0.15
	visuals.add_child(roots)
	
	# Foliage Layers
	for i in range(3):
		var fol = MeshInstance3D.new()
		if is_crystal:
			var pr = PrismMesh.new()
			pr.size = Vector3(1.8 - i * 0.4, 1.5 - i * 0.3, 1.8 - i * 0.4)
			pr.material = leaf_mat
			fol.mesh = pr
		else:
			var sp = SphereMesh.new()
			sp.radius = 1.1 - i * 0.22
			sp.height = 1.4 - i * 0.25
			sp.material = leaf_mat
			fol.mesh = sp
		fol.position.y = 2.2 + i * 0.95
		visuals.add_child(fol)

func _build_pine_mesh(bark_mat: Material, leaf_mat: Material) -> void:
	var trunk = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.15
	cy.bottom_radius = 0.35
	cy.height = 3.2
	cy.material = bark_mat
	trunk.mesh = cy
	trunk.position.y = 1.5
	visuals.add_child(trunk)
	
	for i in range(4):
		var tier = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 1.4 - i * 0.28
		cone.height = 1.1
		cone.material = leaf_mat
		tier.mesh = cone
		tier.position.y = 1.2 + i * 0.85
		visuals.add_child(tier)

func _build_bush_mesh(leaf_mat: Material) -> void:
	var bush = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.85
	sp.height = 1.1
	sp.material = leaf_mat
	bush.mesh = sp
	bush.position.y = 0.45
	visuals.add_child(bush)
	
	# Berries
	var berry_mat = StandardMaterial3D.new()
	berry_mat.albedo_color = Color(0.95, 0.22, 0.35)
	berry_mat.emission_enabled = true
	berry_mat.emission = Color(0.95, 0.22, 0.35)
	for i in range(6):
		var b = MeshInstance3D.new()
		var b_sp = SphereMesh.new()
		b_sp.radius = 0.1
		b_sp.height = 0.18
		b_sp.material = berry_mat
		b.mesh = b_sp
		var angle = (i / 6.0) * TAU
		b.position = Vector3(cos(angle) * 0.72, 0.5 + sin(angle) * 0.25, sin(angle) * 0.72)
		visuals.add_child(b)

func _build_fern_mesh(leaf_mat: Material) -> void:
	for i in range(6):
		var blade = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.25, 0.05, 1.4)
		box.material = leaf_mat
		blade.mesh = box
		var angle = (i / 6.0) * TAU
		blade.rotation.y = angle
		blade.rotation.x = deg_to_rad(25.0)
		blade.position = Vector3(cos(angle) * 0.45, 0.4, sin(angle) * 0.45)
		visuals.add_child(blade)

func _build_cactus_mesh(mat: Material) -> void:
	var stem = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.35
	cy.bottom_radius = 0.35
	cy.height = 2.4
	cy.material = mat
	stem.mesh = cy
	stem.position.y = 1.2
	visuals.add_child(stem)
	
	# Arm 1
	var arm1 = MeshInstance3D.new()
	var cy_a = CylinderMesh.new()
	cy_a.top_radius = 0.2
	cy_a.bottom_radius = 0.2
	cy_a.height = 1.1
	cy_a.material = mat
	arm1.mesh = cy_a
	arm1.position = Vector3(0.55, 1.3, 0)
	arm1.rotation.z = deg_to_rad(30.0)
	visuals.add_child(arm1)

func _build_mushroom_mesh(stalk_mat: Material, cap_mat: Material, is_glow: bool) -> void:
	var stalk = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.25
	cy.bottom_radius = 0.4
	cy.height = 1.6
	cy.material = stalk_mat
	stalk.mesh = cy
	stalk.position.y = 0.8
	visuals.add_child(stalk)
	
	var cap = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.95
	sp.height = 0.75
	sp.material = cap_mat
	cap.mesh = sp
	cap.position.y = 1.65
	visuals.add_child(cap)
	
	if is_glow:
		var light = OmniLight3D.new()
		light.light_color = cap_mat.emission if cap_mat is StandardMaterial3D else Color(0.2, 0.9, 1.0)
		light.light_energy = 2.4
		light.omni_range = 7.5
		light.position.y = 1.8
		add_child(light)

func _build_reeds_mesh(mat: Material) -> void:
	for i in range(7):
		var reed = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = 0.04
		cy.bottom_radius = 0.08
		cy.height = 1.8
		cy.material = mat
		reed.mesh = cy
		var ox = (i % 3 - 1) * 0.28
		var oz = (int(i / 3) - 1) * 0.28
		reed.position = Vector3(ox, 0.9, oz)
		reed.rotation.z = deg_to_rad(randf_range(-6.0, 6.0))
		visuals.add_child(reed)

func _build_kelp_mesh(mat: Material) -> void:
	for i in range(5):
		var blade = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.35, 0.9, 0.06)
		box.material = mat
		blade.mesh = box
		blade.position.y = 0.5 + i * 0.8
		blade.rotation.y = i * 0.65
		visuals.add_child(blade)

func _build_lotus_mesh(mat: Material) -> void:
	var pad = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.85
	cy.bottom_radius = 0.85
	cy.height = 0.05
	cy.material = mat
	pad.mesh = cy
	pad.position.y = 0.02
	visuals.add_child(pad)
	
	var flower = MeshInstance3D.new()
	var fl_sp = SphereMesh.new()
	fl_sp.radius = 0.22
	fl_sp.height = 0.35
	var fl_mat = StandardMaterial3D.new()
	fl_mat.albedo_color = Color(1.0, 0.4, 0.7)
	fl_mat.emission_enabled = true
	fl_mat.emission = Color(1.0, 0.4, 0.7) * 0.8
	flower.mesh = fl_sp
	flower.material_override = fl_mat
	flower.position.y = 0.2
	visuals.add_child(flower)

func _build_coral_mesh(mat: Material) -> void:
	for i in range(5):
		var tube = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = 0.14
		cy.bottom_radius = 0.18
		cy.height = 1.1 + i * 0.15
		cy.material = mat
		tube.mesh = cy
		var a = (i / 5.0) * TAU
		tube.position = Vector3(cos(a) * 0.35, cy.height * 0.5, sin(a) * 0.35)
		tube.rotation.x = deg_to_rad(randf_range(8.0, 18.0))
		visuals.add_child(tube)

func _build_anemone_mesh(mat: Material) -> void:
	var bulb = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.4
	sp.height = 0.5
	sp.material = mat
	bulb.mesh = sp
	bulb.position.y = 0.25
	visuals.add_child(bulb)
	for i in range(8):
		var tent = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = 0.03
		cy.bottom_radius = 0.06
		cy.height = 0.65
		cy.material = mat
		tent.mesh = cy
		var a = (i / 8.0) * TAU
		tent.position = Vector3(cos(a) * 0.25, 0.55, sin(a) * 0.25)
		tent.rotation.z = deg_to_rad(20.0)
		visuals.add_child(tent)

func _build_seagrass_mesh(mat: Material) -> void:
	for i in range(6):
		var blade = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.08, 1.2, 0.02)
		box.material = mat
		blade.mesh = box
		blade.position = Vector3(randf_range(-0.3, 0.3), 0.6, randf_range(-0.3, 0.3))
		blade.rotation.y = randf_range(0.0, PI)
		visuals.add_child(blade)

func _build_lilypad_mesh(mat: Material) -> void:
	var pad = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 1.1
	cy.bottom_radius = 1.1
	cy.height = 0.04
	cy.material = mat
	pad.mesh = cy
	pad.position.y = 0.02
	visuals.add_child(pad)

func _build_spiral_hydro_mesh(mat: Material) -> void:
	for i in range(8):
		var knot = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 0.12
		sp.height = 0.2
		sp.material = mat
		knot.mesh = sp
		var a = i * 0.8
		knot.position = Vector3(cos(a) * 0.3, 0.2 + i * 0.25, sin(a) * 0.3)
		visuals.add_child(knot)

func _build_tumbleweed_mesh(mat: Material) -> void:
	var ball = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.45
	sp.height = 0.9
	sp.material = mat
	ball.mesh = sp
	ball.position.y = 0.45
	visuals.add_child(ball)

func _build_carnivorous_mesh(stalk_mat: Material, jaw_mat: Material) -> void:
	var stalk = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.12
	cy.bottom_radius = 0.2
	cy.height = 1.1
	cy.material = stalk_mat
	stalk.mesh = cy
	stalk.position.y = 0.55
	visuals.add_child(stalk)
	
	var jaw_top = MeshInstance3D.new()
	jaw_top.name = "JawTop"
	var pr_t = PrismMesh.new()
	pr_t.size = Vector3(0.5, 0.35, 0.6)
	pr_t.material = jaw_mat
	jaw_top.mesh = pr_t
	jaw_top.position = Vector3(0, 1.25, 0.15)
	jaw_top.rotation.x = deg_to_rad(38.0)
	visuals.add_child(jaw_top)
	
	var jaw_bot = MeshInstance3D.new()
	jaw_bot.name = "JawBottom"
	var pr_b = PrismMesh.new()
	pr_b.size = Vector3(0.5, 0.35, 0.6)
	pr_b.material = jaw_mat
	jaw_bot.mesh = pr_b
	jaw_bot.position = Vector3(0, 1.05, 0.15)
	jaw_bot.rotation.x = deg_to_rad(-38.0)
	visuals.add_child(jaw_bot)

func _build_floater_mesh(mat: Material) -> void:
	var sac = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.45
	sp.height = 0.7
	sp.material = mat
	sac.mesh = sp
	sac.position.y = 1.1
	visuals.add_child(sac)
	
	for i in range(4):
		var tendril = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = 0.03
		cy.bottom_radius = 0.01
		cy.height = 0.8
		cy.material = mat
		tendril.mesh = cy
		tendril.position = Vector3((i % 2 - 0.5) * 0.3, 0.5, (int(i / 2) - 0.5) * 0.3)
		visuals.add_child(tendril)

func _build_spore_pod_mesh(mat: Material) -> void:
	var pod = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.55
	sp.height = 0.85
	sp.material = mat
	pod.mesh = sp
	pod.position.y = 0.45
	visuals.add_child(pod)

func _build_vine_mesh(mat: Material) -> void:
	for i in range(5):
		var segment = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = 0.05
		cy.bottom_radius = 0.07
		cy.height = 0.5
		cy.material = mat
		segment.mesh = cy
		segment.position = Vector3(sin(i) * 0.1, 0.25 + i * 0.42, cos(i) * 0.1)
		segment.rotation.z = deg_to_rad(sin(i) * 20.0)
		visuals.add_child(segment)
