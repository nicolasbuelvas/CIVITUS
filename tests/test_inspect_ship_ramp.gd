extends Node3D

func _ready() -> void:
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.15, 0.18, 0.25)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.65, 0.7)
	env.environment = e
	add_child(env)

	var light = DirectionalLight3D.new()
	add_child(light)
	light.position = Vector3(5, 10, 8)
	light.look_at(Vector3.ZERO, Vector3.UP)

	# Ground reference mesh at Y = -0.94 (exact ground level under ship)
	var ground = MeshInstance3D.new()
	var g_mesh = PlaneMesh.new()
	g_mesh.size = Vector2(20, 20)
	ground.mesh = g_mesh
	ground.position = Vector3(0, -0.94, 0)
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.4, 0.35, 0.3)
	ground.material_override = g_mat
	add_child(ground)

	var ship_scene = load("res://scenes/entities/spaceship_3d.tscn")
	var ship = ship_scene.instantiate()
	add_child(ship)

	var ramp = ship.get_node("HullStructure/BoardingRamp")
	var ramp_mesh = ramp.get_node("MeshInstance3D")
	var ramp_col = ramp.get_node("CollisionShape3D")

	# Position BoardingRamp pivot at door sill
	ramp.position = Vector3(0, 0.14, 3.45)
	
	# Mesh and shape centered at local Z = 1.425 (half of 2.85m), so top edge is at pivot (0, 0, 0)
	var box_m = BoxMesh.new()
	box_m.size = Vector3(2.0, 0.10, 2.85)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.16, 0.2)
	mat.metallic = 0.7
	mat.roughness = 0.5
	box_m.material = mat
	ramp_mesh.mesh = box_m
	ramp_mesh.transform = Transform3D(Basis.IDENTITY, Vector3(0, -0.05, 1.425))

	var box_s = BoxShape3D.new()
	box_s.size = Vector3(2.0, 0.12, 2.85)
	ramp_col.shape = box_s
	ramp_col.transform = Transform3D(Basis.IDENTITY, Vector3(0, -0.05, 1.425))

	# Test anchored angle (22.27 deg = 0.3886 rad)
	var target_angle = 0.3886
	ramp.rotation = Vector3(target_angle, 0, 0)

	print("[Ramp Test] Pivot Pos: ", ramp.global_position)
	print("[Ramp Test] Top contact: ", ramp.to_global(Vector3(0, 0, 0)))
	print("[Ramp Test] Bottom contact: ", ramp.to_global(Vector3(0, 0, 2.85)))

	# Camera looking directly at entrance/ramp
	var cam = Camera3D.new()
	add_child(cam)
	cam.position = Vector3(3.5, 0.3, 8.5)
	cam.look_at(Vector3(0, -0.3, 4.8), Vector3.UP)
	cam.current = true

	await get_tree().create_timer(0.5).timeout
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://test_ship_ramp_front.png")
		print("[Ramp Test] Saved test_ship_ramp_front.png")

	# Camera looking at ramp from side profile
	cam.position = Vector3(6.5, -0.2, 4.8)
	cam.look_at(Vector3(0, -0.4, 4.8), Vector3.UP)
	await get_tree().create_timer(0.3).timeout
	img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://test_ship_ramp_side.png")
		print("[Ramp Test] Saved test_ship_ramp_side.png")

	get_tree().quit(0)
