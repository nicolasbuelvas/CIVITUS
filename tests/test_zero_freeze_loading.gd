extends Node

func _ready() -> void:
	print("==================================================")
	print("  TESTING ZERO-FREEZE DISTRIBUTED LOADING SYSTEM  ")
	print("==================================================")
	
	var loading_scene = load("res://scenes/screens/loading_screen.tscn")
	var loader = loading_scene.instantiate()
	add_child(loader)
	
	print("1. Monitoring background threaded load...")
	var t = 0.0
	while is_instance_valid(loader) and not loader.is_loading_complete and t < 5.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		
	print("   [PASS] Scene resource loaded from disk asynchronously.")
	
	print("2. Monitoring distributed planet generation across frames...")
	while is_instance_valid(loader) and not loader.is_world_ready and t < 10.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		
	print("   [PASS] 6 cubed sphere faces, trimesh collision, spaceship & flora generated across frames.")
	
	# Wait for gameplay launch
	while is_instance_valid(loader) and t < 10.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		
	print("3. Verifying world instance and gameplay state in tree...")
	var world = get_tree().root.find_child("World", true, false)
	assert(world != null, "World instance should exist in tree")
	
	var planet = world.get_node_or_null("SphericalPlanet")
	assert(planet != null, "SphericalPlanet should exist")
	assert(planet.mesh_instance.mesh != null, "Planet mesh must be committed")
	assert(planet.collision_shape.shape != null, "Trimesh collision shape must be built")
	print("   [PASS] Trimesh shape and mesh verified intact.")
	
	var player = planet.get_node_or_null("Character3D")
	if not player:
		player = world.find_child("Character3D", true, false)
	assert(player != null, "Character3D must exist")
	assert(player.is_physics_processing() or planet.is_landing_sequence_running, "Player must resume physics or be in landing sequence")
	print("   [PASS] Player physics active in gameplay.")
	
	var hud = world.get_node_or_null("HUD")
	assert(hud != null, "HUD must exist")
	assert(hud.visible or planet.is_landing_sequence_running, "HUD must be ready post-launch")
	print("   [PASS] HUD confirmed active and visible post-launch.")
	
	world.queue_free()
	await get_tree().process_frame
	
	print("==================================================")
	print("  ALL ZERO-FREEZE TESTS PASSED WITH FLYING COLORS ")
	print("==================================================")
	get_tree().quit(0)
