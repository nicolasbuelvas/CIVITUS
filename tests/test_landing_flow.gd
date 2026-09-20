extends Node3D

func _ready() -> void:
	print("[Test Landing Flow] Starting automated landing cinematic flow test...")
	var world_scene = load("res://scenes/world/world.tscn")
	var world = world_scene.instantiate()
	add_child(world)

	var planet = world.get_node("SphericalPlanet")
	
	# Wait until planet finishes generating
	if planet.is_generating:
		print("[Test Landing Flow] Waiting for planet generation...")
		await planet.planet_ready
		
	await get_tree().create_timer(0.3).timeout
	
	# Start landing cinematic sequence
	print("[Test Landing Flow] Starting landing cinematic sequence...")
	planet.start_landing_cinematic()
	
	var ship = planet.spaceship_instance
	var hud = world.get_node_or_null("HUD")
	
	# 1. Capture during descent (camera tracking from above, HUD hidden)
	await get_tree().create_timer(2.5).timeout
	print("[Test Landing Flow] Descent snapshot. Ship altitude: ", ship.global_position.y)
	print("[Test Landing Flow] HUD visible (should be false): ", hud.visible if hud else "no hud")
	assert(hud == null or hud.visible == false, "HUD must be hidden during descent!")
	_save_viewport("screenshot_flow_1_descent.png")
	
	# 2. Wait until touchdown
	print("[Test Landing Flow] Waiting for landing completed signal...")
	await ship.landing_completed
	print("[Test Landing Flow] Ship landed! Waiting 0.5s for ramp drop...")
	await get_tree().create_timer(0.5).timeout
	
	# Ramp should now be dropped & anchored
	var ramp = ship.get_node("HullStructure/BoardingRamp")
	print("[Test Landing Flow] Ramp rotation X: ", ramp.rotation.x)
	print("[Test Landing Flow] HUD visible (should still be false): ", hud.visible if hud else "no hud")
	assert(hud == null or hud.visible == false, "HUD must remain hidden immediately after landing!")
	_save_viewport("screenshot_flow_2_landed_ramp.png")
	
	# 3. Wait through the 2.0s delay
	print("[Test Landing Flow] Waiting through the 2-second post-landing exterior window...")
	await get_tree().create_timer(2.0).timeout
	print("[Test Landing Flow] Exterior wait done, starting zoom into spaceship...")
	
	# Wait for zoom in to reach cabin (1.3s) + 0.4s into the 1-second astronaut showcase
	await get_tree().create_timer(1.7).timeout
	print("[Test Landing Flow] Astronaut 1-second showcase snapshot...")
	_save_viewport("screenshot_flow_2b_astronaut_showcase.png")
	
	# 4. Wait for the remaining 0.6s of showcase + switch to first person
	print("[Test Landing Flow] Waiting for switch to first person...")
	await get_tree().create_timer(0.9).timeout
	
	var player = planet.player_instance
	print("[Test Landing Flow] Player action locked: ", player.is_action_locked if player else "no player")
	print("[Test Landing Flow] HUD visible (should now be true): ", hud.visible if hud else "no hud")
	assert(hud != null and hud.visible == true, "HUD must be visible after transition to 1st person!")
	assert(player != null and player.is_action_locked == false, "Player must be unlocked!")
	_save_viewport("screenshot_flow_3_first_person_hud.png")
	
	print("[Test Landing Flow] ALL FLOW STEPS VERIFIED AND PASSED!")
	get_tree().quit(0)

func _save_viewport(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://" + filename)
		print("[Test Landing Flow] Saved " + filename)
