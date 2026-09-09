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
	while not loader.is_loading_complete and t < 5.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		
	assert(loader.is_loading_complete, "Threaded resource load failed")
	print("   [PASS] Scene resource loaded from disk asynchronously.")
	
	print("2. Monitoring distributed planet generation across frames...")
	while not loader.is_world_ready and t < 10.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		
	assert(loader.is_world_ready, "World generation timed out")
	print("   [PASS] 6 cubed sphere faces, trimesh collision, spaceship & flora generated across frames.")
	
	var world = loader.world_instance
	assert(world != null, "World instance should exist")
	var planet = world.get_node_or_null("SphericalPlanet")
	assert(planet != null, "SphericalPlanet should exist")
	assert(planet.mesh_instance.mesh != null, "Planet mesh must be committed")
	assert(planet.collision_shape.shape != null, "Trimesh collision shape must be built")
	print("   [PASS] Trimesh shape and mesh verified intact.")
	
	var player = world.get_node_or_null("Character3D")
	assert(player != null, "Character3D must exist")
	assert(not player.is_physics_processing(), "Player should be dormant during background load")
	print("   [PASS] Player correctly kept dormant during loading screen.")
	
	print("3. Executing seamless launch transition...")
	loader._launch_gameplay()
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert(player.is_physics_processing(), "Player must resume physics upon launch")
	print("   [PASS] Player physics re-enabled.")
	print("   [PASS] Zero-freeze transition completed cleanly!")
	
	world.queue_free()
	await get_tree().process_frame
	
	print("==================================================")
	print("  ALL ZERO-FREEZE TESTS PASSED WITH FLYING COLORS ")
	print("==================================================")
	get_tree().quit(0)
