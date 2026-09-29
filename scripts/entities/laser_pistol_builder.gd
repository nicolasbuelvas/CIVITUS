extends RefCounted
class_name LaserPistolBuilder

# =============================================================================
# PROCEDURAL 3D LASER PISTOL ASSET BUILDER
# Generates a detailed, clean sci-fi energy sidearm in pure code.
# Used for character hand props, back hooks, dropped items, and 3D preview.
# =============================================================================

static func create_laser_pistol() -> Node3D:
	var root = Node3D.new()
	root.name = "LaserPistol"
	
	# Materials
	var chassis_mat = StandardMaterial3D.new()
	chassis_mat.albedo_color = Color(0.14, 0.16, 0.20) # Deep charcoal titanium
	chassis_mat.metallic = 0.88
	chassis_mat.roughness = 0.28
	
	var grip_mat = StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.08, 0.08, 0.10) # Carbon textured grip
	grip_mat.metallic = 0.20
	grip_mat.roughness = 0.65
	
	var accent_mat = StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.96, 0.66, 0.16) # Aerospace Gold trims
	accent_mat.metallic = 0.92
	accent_mat.roughness = 0.22
	
	var energy_mat = StandardMaterial3D.new()
	energy_mat.albedo_color = Color(0.18, 0.88, 1.0) # High-energy plasma cyan
	energy_mat.emission_enabled = true
	energy_mat.emission = Color(0.18, 0.88, 1.0)
	energy_mat.emission_energy_multiplier = 3.2
	
	# 1. Main Receiver / Slide
	var receiver = MeshInstance3D.new()
	receiver.name = "Receiver"
	var rec_mesh = BoxMesh.new()
	rec_mesh.size = Vector3(0.048, 0.065, 0.19)
	rec_mesh.material = chassis_mat
	receiver.mesh = rec_mesh
	receiver.position = Vector3(0.0, 0.04, -0.04)
	root.add_child(receiver)
	
	# Top Sighting Rail / Heatsink
	var rail = MeshInstance3D.new()
	rail.name = "TopRail"
	var rail_mesh = BoxMesh.new()
	rail_mesh.size = Vector3(0.032, 0.015, 0.17)
	rail_mesh.material = accent_mat
	rail.mesh = rail_mesh
	rail.position = Vector3(0.0, 0.078, -0.04)
	root.add_child(rail)
	
	# Heatsink Vents (3 side fins on left and right)
	for i in range(3):
		var fin_z = -0.01 - float(i) * 0.035
		var fin_l = MeshInstance3D.new()
		var fin_mesh = BoxMesh.new()
		fin_mesh.size = Vector3(0.052, 0.008, 0.016)
		fin_mesh.material = energy_mat
		fin_l.mesh = fin_mesh
		fin_l.position = Vector3(0.0, 0.045, fin_z)
		root.add_child(fin_l)
	
	# 2. Ergonomic Pistol Grip
	var grip = MeshInstance3D.new()
	grip.name = "Grip"
	var grip_mesh = BoxMesh.new()
	grip_mesh.size = Vector3(0.042, 0.11, 0.055)
	grip_mesh.material = grip_mat
	grip.mesh = grip_mesh
	grip.position = Vector3(0.0, -0.035, 0.035)
	grip.rotation.x = deg_to_rad(-18.0)
	root.add_child(grip)
	
	# Grip Base Plate
	var base_plate = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(0.046, 0.015, 0.065)
	base_mesh.material = accent_mat
	base_plate.mesh = base_mesh
	base_plate.position = Vector3(0.0, -0.09, 0.052)
	base_plate.rotation.x = deg_to_rad(-18.0)
	root.add_child(base_plate)
	
	# 3. Trigger Guard & Trigger
	var guard = MeshInstance3D.new()
	var guard_mesh = BoxMesh.new()
	guard_mesh.size = Vector3(0.018, 0.035, 0.045)
	guard_mesh.material = chassis_mat
	guard.mesh = guard_mesh
	guard.position = Vector3(0.0, -0.008, -0.015)
	root.add_child(guard)
	
	var trigger = MeshInstance3D.new()
	var trig_mesh = PrismMesh.new()
	trig_mesh.size = Vector3(0.014, 0.022, 0.018)
	trig_mesh.material = accent_mat
	trigger.mesh = trig_mesh
	trigger.position = Vector3(0.0, -0.005, 0.0)
	trigger.rotation.x = deg_to_rad(140.0)
	root.add_child(trigger)
	
	# 4. Energy Battery Pack (Forward Cell under barrel)
	var battery = MeshInstance3D.new()
	battery.name = "BatteryPack"
	var bat_mesh = CylinderMesh.new()
	bat_mesh.top_radius = 0.016
	bat_mesh.bottom_radius = 0.016
	bat_mesh.height = 0.075
	bat_mesh.material = energy_mat
	battery.mesh = bat_mesh
	battery.position = Vector3(0.0, 0.012, -0.065)
	battery.rotation.x = deg_to_rad(90.0)
	root.add_child(battery)
	
	# Battery Housing Clamp
	var bat_clamp = MeshInstance3D.new()
	var clamp_mesh = BoxMesh.new()
	clamp_mesh.size = Vector3(0.044, 0.032, 0.03)
	clamp_mesh.material = chassis_mat
	bat_clamp.mesh = clamp_mesh
	bat_clamp.position = Vector3(0.0, 0.012, -0.065)
	root.add_child(bat_clamp)
	
	# 5. Barrel Assembly
	var barrel = MeshInstance3D.new()
	barrel.name = "Barrel"
	var bar_mesh = CylinderMesh.new()
	bar_mesh.top_radius = 0.018
	bar_mesh.bottom_radius = 0.022
	bar_mesh.height = 0.12
	bar_mesh.material = chassis_mat
	barrel.mesh = bar_mesh
	barrel.position = Vector3(0.0, 0.04, -0.17)
	barrel.rotation.x = deg_to_rad(90.0)
	root.add_child(barrel)
	
	# Muzzle Collimator Ring
	var muzzle_ring = MeshInstance3D.new()
	var ring_mesh = CylinderMesh.new()
	ring_mesh.top_radius = 0.024
	ring_mesh.bottom_radius = 0.024
	ring_mesh.height = 0.02
	ring_mesh.material = accent_mat
	muzzle_ring.mesh = ring_mesh
	muzzle_ring.position = Vector3(0.0, 0.04, -0.22)
	muzzle_ring.rotation.x = deg_to_rad(90.0)
	root.add_child(muzzle_ring)
	
	# 6. Glowing Plasma Energy Emitter Lens
	var emitter = MeshInstance3D.new()
	emitter.name = "EnergyEmitter"
	var emit_mesh = SphereMesh.new()
	emit_mesh.radius = 0.015
	emit_mesh.height = 0.022
	emit_mesh.material = energy_mat
	emitter.mesh = emit_mesh
	emitter.position = Vector3(0.0, 0.04, -0.232)
	root.add_child(emitter)
	
	# Muzzle point marker for raycast origin
	var muzzle_point = Marker3D.new()
	muzzle_point.name = "MuzzlePoint"
	muzzle_point.position = Vector3(0.0, 0.04, -0.24)
	root.add_child(muzzle_point)
	
	return root
