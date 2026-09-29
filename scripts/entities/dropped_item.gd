extends RigidBody3D
class_name DroppedItem

const LaserPistolBuilder = preload("res://scripts/entities/laser_pistol_builder.gd")

# =============================================================================
# DROPPED ITEM PROP (PHYSICAL 3D WORLD ITEM)
# Spawned when player drops any item from suit body slots or ship storage.
# Settles on ground, displays clean 3D mesh, and can be retrieved via interact.
# =============================================================================

signal picked_up(item_name: String, count: int)

@export var item_name: String = "iron"
@export var item_count: int = 1

@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var col_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var aura_light: OmniLight3D = get_node_or_null("AuraLight")

var planet_radius: float = 160.0
var idle_time: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	gravity_scale = 0.8
	linear_damp = 2.5
	angular_damp = 3.0
	add_to_group("dropped_items")
	add_to_group("interactable")
	_setup_visual_prop()

func setup_drop(p_item: String, p_count: int = 1, p_planet_radius: float = 160.0) -> void:
	item_name = p_item
	item_count = p_count
	planet_radius = p_planet_radius
	_setup_visual_prop()

func _physics_process(_delta: float) -> void:
	# Radial gravity pull towards planet core
	var pos = global_position
	var r = pos.length()
	if r > 1.0:
		var down_dir = -pos.normalized()
		apply_central_force(down_dir * 9.8 * mass)
		
		# Anti-subsurface guarantee: prevent falling through planetary crust
		if r < planet_radius:
			global_position = -down_dir * (planet_radius + 0.15)
			var inward_v = linear_velocity.dot(down_dir)
			if inward_v > 0.0:
				linear_velocity -= down_dir * inward_v

func _setup_visual_prop() -> void:
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
		
	if not col_shape:
		col_shape = CollisionShape3D.new()
		col_shape.name = "CollisionShape3D"
		var box_col = BoxShape3D.new()
		box_col.size = Vector3(0.45, 0.45, 0.45)
		col_shape.shape = box_col
		add_child(col_shape)
		
	# Clear any previous procedural models
	for child in mesh_instance.get_children():
		child.queue_free()
	mesh_instance.mesh = null
	mesh_instance.material_override = null
		
	var item_mat = StandardMaterial3D.new()
	var mesh: Mesh = null
	var light_col: Color = Color(0.8, 0.9, 1.0)
	var display_name: String = item_name.replace("_", " ").capitalize()
	
	match item_name:
		"laser_pistol":
			display_name = "Pistola Láser" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Laser Pistol"
			var p_mesh = LaserPistolBuilder.create_laser_pistol()
			p_mesh.scale = Vector3(1.35, 1.35, 1.35)
			mesh_instance.add_child(p_mesh)
			light_col = Color(0.2, 0.9, 1.0)
		"iron":
			display_name = "Hierro" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Iron"
			var b = BoxMesh.new()
			b.size = Vector3(0.35, 0.22, 0.3)
			mesh = b
			item_mat.albedo_color = Color(0.72, 0.76, 0.84)
			item_mat.metallic = 0.90
			item_mat.roughness = 0.30
			light_col = Color(0.75, 0.85, 1.0)
		"copper":
			display_name = "Cobre" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Copper"
			var c = CylinderMesh.new()
			c.top_radius = 0.12
			c.bottom_radius = 0.12
			c.height = 0.35
			mesh = c
			item_mat.albedo_color = Color(0.92, 0.52, 0.22)
			item_mat.metallic = 0.85
			item_mat.roughness = 0.35
			light_col = Color(1.0, 0.6, 0.2)
		"silicon":
			display_name = "Silicio" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Silicon"
			var pr = PrismMesh.new()
			pr.size = Vector3(0.3, 0.38, 0.3)
			mesh = pr
			item_mat.albedo_color = Color(0.18, 0.78, 0.95)
			item_mat.emission_enabled = true
			item_mat.emission = Color(0.18, 0.78, 0.95)
			item_mat.emission_energy_multiplier = 2.2
			light_col = Color(0.2, 0.85, 1.0)
		"uranium":
			display_name = "Uranio" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Uranium"
			var c = CylinderMesh.new()
			c.top_radius = 0.14
			c.bottom_radius = 0.14
			c.height = 0.40
			mesh = c
			item_mat.albedo_color = Color(0.25, 0.95, 0.35)
			item_mat.emission_enabled = true
			item_mat.emission = Color(0.25, 0.95, 0.35)
			item_mat.emission_energy_multiplier = 2.8
			light_col = Color(0.3, 1.0, 0.4)
		"wrench":
			display_name = "Llave Inglesa" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Wrench"
			var b = BoxMesh.new()
			b.size = Vector3(0.08, 0.38, 0.05)
			mesh = b
			item_mat.albedo_color = Color(0.65, 0.70, 0.78)
			item_mat.metallic = 0.90
			light_col = Color(0.8, 0.85, 0.95)
		"wire":
			display_name = "Cable de Cobre" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Copper Wire"
			var tor = TorusMesh.new()
			tor.inner_radius = 0.08
			tor.outer_radius = 0.18
			mesh = tor
			item_mat.albedo_color = Color(0.95, 0.55, 0.20)
			item_mat.metallic = 0.85
			light_col = Color(1.0, 0.65, 0.2)
		"microchip":
			display_name = "Microchip" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Microchip"
			var b = BoxMesh.new()
			b.size = Vector3(0.28, 0.04, 0.28)
			mesh = b
			item_mat.albedo_color = Color(0.08, 0.50, 0.25)
			item_mat.metallic = 0.5
			light_col = Color(0.2, 0.9, 0.4)
		"reactor_cell":
			display_name = "Celda de Reactor" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Reactor Cell"
			var c = CylinderMesh.new()
			c.top_radius = 0.15
			c.bottom_radius = 0.15
			c.height = 0.42
			mesh = c
			item_mat.albedo_color = Color(0.20, 0.95, 0.30)
			item_mat.emission_enabled = true
			item_mat.emission = Color(0.20, 0.95, 0.30)
			light_col = Color(0.3, 1.0, 0.4)
		"hull_plate":
			display_name = "Placa de Casco" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Hull Plate"
			var b = BoxMesh.new()
			b.size = Vector3(0.38, 0.05, 0.38)
			mesh = b
			item_mat.albedo_color = Color(0.45, 0.50, 0.60)
			item_mat.metallic = 0.92
			light_col = Color(0.6, 0.7, 0.9)
		"nozzle_core":
			display_name = "Núcleo Tobera" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Nozzle Core"
			var c = CylinderMesh.new()
			c.top_radius = 0.12
			c.bottom_radius = 0.22
			c.height = 0.38
			mesh = c
			item_mat.albedo_color = Color(0.85, 0.45, 0.15)
			item_mat.metallic = 0.88
			light_col = Color(1.0, 0.5, 0.2)
		"hyperdrive_coil":
			display_name = "Bobina Hiperimpulso" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Hyperdrive Coil"
			var tor = TorusMesh.new()
			tor.inner_radius = 0.12
			tor.outer_radius = 0.24
			mesh = tor
			item_mat.albedo_color = Color(0.20, 0.70, 1.0)
			item_mat.emission_enabled = true
			item_mat.emission = Color(0.20, 0.70, 1.0)
			light_col = Color(0.25, 0.8, 1.0)
		"o2_canister":
			display_name = "Tanque O₂" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "O2 Canister"
			var c = CylinderMesh.new()
			c.top_radius = 0.12
			c.bottom_radius = 0.12
			c.height = 0.42
			mesh = c
			item_mat.albedo_color = Color(0.1, 0.85, 0.95)
			item_mat.metallic = 0.5
			light_col = Color(0.2, 0.9, 1.0)
		"alien_meat":
			display_name = "Carne Alienígena" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Alien Meat"
			var sp = SphereMesh.new()
			sp.radius = 0.18
			sp.height = 0.32
			mesh = sp
			item_mat.albedo_color = Color(0.85, 0.25, 0.3)
			item_mat.roughness = 0.6
			light_col = Color(1.0, 0.3, 0.3)
		"plant_fibers":
			display_name = "Fibras Vegetales" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Plant Fibers"
			var b = BoxMesh.new()
			b.size = Vector3(0.3, 0.12, 0.35)
			mesh = b
			item_mat.albedo_color = Color(0.35, 0.78, 0.28)
			light_col = Color(0.4, 0.9, 0.3)
		"bio_fuel":
			display_name = "Biocombustible" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Biofuel"
			var c = CylinderMesh.new()
			c.top_radius = 0.13
			c.bottom_radius = 0.13
			c.height = 0.38
			mesh = c
			item_mat.albedo_color = Color(0.25, 0.85, 0.35)
			item_mat.emission_enabled = true
			item_mat.emission = Color(0.25, 0.85, 0.35)
			light_col = Color(0.3, 1.0, 0.4)
		"pearl", "ocean_pearl":
			display_name = "Perla Oceánica" if (is_instance_valid(GameManager) and GameManager.current_language == "es") else "Ocean Pearl"
			var sp = SphereMesh.new()
			sp.radius = 0.16
			sp.height = 0.32
			mesh = sp
			item_mat.albedo_color = Color(0.95, 0.92, 0.88)
			item_mat.metallic = 0.4
			item_mat.roughness = 0.1
			light_col = Color(1.0, 0.95, 0.85)
		_:
			var b = BoxMesh.new()
			b.size = Vector3(0.28, 0.28, 0.28)
			mesh = b
			item_mat.albedo_color = Color(0.8, 0.75, 0.65)
			light_col = Color(0.8, 0.8, 0.9)
			
	if mesh:
		mesh_instance.mesh = mesh
		mesh_instance.material_override = item_mat
	
	var a_light = get_node_or_null("AuraLight") as OmniLight3D
	if not a_light:
		a_light = OmniLight3D.new()
		a_light.name = "AuraLight"
		a_light.omni_range = 2.4
		a_light.light_energy = 1.3
		add_child(a_light)
	a_light.light_color = light_col
	
	var lbl = get_node_or_null("Label3D") as Label3D
	if not lbl:
		lbl = Label3D.new()
		lbl.name = "Label3D"
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.pixel_size = 0.005
		lbl.font_size = 20
		lbl.position = Vector3(0.0, 0.45, 0.0)
		add_child(lbl)
	lbl.text = "[ %s x%d ]" % [display_name, item_count]
	lbl.modulate = light_col

func pick_up(player: Node3D) -> bool:
	if not is_instance_valid(GameManager) or not GameManager.crafting:
		return false
	var added = GameManager.crafting.add_item_to_best_body_slot(item_name, item_count)
	if added:
		AudioManager.play("collect", 1.1, 0.0)
		picked_up.emit(item_name, item_count)
		queue_free()
		return true
	else:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast("⚠ INVENTARIO LLENO: Libera ranuras del traje")
	return false
