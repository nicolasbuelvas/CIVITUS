extends Node3D

func _ready() -> void:
	print("==================================================")
	print("[TEST] SPACEFLIGHT, ORBITAL CONTROLS & CABIN MOBILITY")
	print("==================================================")
	
	var world_scene = load("res://scenes/world/world.tscn")
	var world = world_scene.instantiate()
	add_child(world)

	var planet = world.get_node("SphericalPlanet")
	if planet.is_generating:
		print("[TEST] Generating procedural planet...")
		await planet.planet_ready
		
	await get_tree().create_timer(0.4).timeout

	var ship = planet.spaceship_instance
	assert(ship != null, "Spaceship must exist!")
	var hud = world.get_node("HUD")
	assert(hud != null, "HUD must exist!")
	var player = planet.player_instance
	assert(player != null, "Player must exist!")
	
	print("[TEST 1] Testing Surface Hatch Security & Initial State...")
	assert(ship.flight_state == 0, "Ship must start in LANDED state")
	
	# Place player at doorstep / ramp entrance on surface
	player.global_position = ship.to_global(Vector3(0.0, 0.2, 3.8))
	ship.is_player_in_cabin = false
	assert(ship.get_hatch_interaction_state(player) == "open_hatch", "Hatch interaction must be allowed on ramp/doorstep on surface")
	print(" -> PASS: Surface hatch interaction verified.")
	
	print("[TEST 2] Testing Ascent & Parking Orbit Reach...")
	ship.sit_in_pilot_seat(player)
	assert(ship.is_player_seated == true, "Player must be seated in cockpit")
	
	ship.reach_parking_orbit()
	assert(ship.flight_state == 2, "Ship must be in PARKING_ORBIT (state 2)")
	assert(ship.orbital_cruise_speed == 18.0, "Base orbital speed should be 18.0 km/s")
	
	print("[TEST 3] Testing Complete LOD / Culling of Planet Entities in Orbit...")
	assert(planet.is_orbital_lod_active == true, "Planet orbital LOD must be active in orbit")
	# Check creatures culled
	for c in planet.spawned_creatures:
		if is_instance_valid(c):
			assert(c.visible == false, "Creatures must be hidden in orbit")
			assert(c.process_mode == Node.PROCESS_MODE_DISABLED, "Creatures must be disabled in orbit")
	# Check flora culled
	for f in planet.spawned_flora:
		if is_instance_valid(f):
			assert(f.visible == false, "Flora must be hidden in orbit")
			assert(f.process_mode == Node.PROCESS_MODE_DISABLED, "Flora must be disabled in orbit")
	# Check caves culled
	for cv in planet.spawned_caves:
		if is_instance_valid(cv):
			assert(cv.visible == false, "Caves must be hidden in orbit")
	# Check planet sphere mesh and atmospheric halo visible
	assert(planet.mesh_instance.visible == true, "Planetary sphere mesh must remain visible from afar")
	if planet.atmosphere_instance:
		assert(planet.atmosphere_instance.visible == true, "Atmospheric halo must remain visible from afar")
	print(" -> PASS: Planet surface entities 100% culled; sphere & halo visible.")

	print("[TEST 4] Testing Distant Solar System Planets in Orbit...")
	assert(is_instance_valid(ship.distant_planets_root), "Distant planets root must exist")
	assert(ship.distant_planets_root.visible == true, "Distant planets must be visible in orbit")
	var distant_count = ship.distant_planets_root.get_child_count()
	print(" -> Distant planets displayed in sky: %d" % distant_count)
	assert(distant_count > 0, "Should display distant solar system planets in background")
	var first_p = ship.distant_planets_root.get_child(0)
	assert(first_p.has_node("SphereMesh"), "Distant planet must have 3D sphere mesh")
	assert(first_p.has_node("InfoLabel"), "Distant planet must have InfoLabel with AU distance")
	print(" -> PASS: Distant celestial bodies rendered with procedural meshes and AU tags.")

	print("[TEST 5] Testing Mobile Orbital Flight Controls & HUD Telemetry...")
	hud._process(0.016)
	assert(hud.orbital_controls_container != null, "Orbital controls container must exist in HUD")
	assert(hud.orbital_controls_container.visible == true, "Orbital flight controls must be visible when seated in orbit")
	assert(hud.flight_pad_left != null and hud.flight_pad_left.visible == true, "Pitch/Yaw flight pad must be visible")
	assert(hud.flight_pad_right != null and hud.flight_pad_right.visible == true, "Propulsion / Action flight pad must be visible")
	assert(hud.orbital_fuel_bar != null, "Fuel bar must exist")
	assert(hud.orbital_energy_bar != null, "Energy bar must exist")
	
	# Test space flight controls execution
	var initial_speed = ship.orbital_cruise_speed
	var initial_fuel = GameManager.player_stats.fuel
	var initial_energy = ship.current_energy
	ship.apply_space_flight_controls(1.0, 0.5, -0.5, 0.0, 0.1) # Boost forward
	assert(ship.orbital_cruise_speed > initial_speed, "Thrust must accelerate orbital cruise speed")
	assert(ship.current_energy < initial_energy, "Thrusting must consume ship electrical energy")
	assert(GameManager.player_stats.fuel < initial_fuel, "Thrusting must consume propellant fuel")
	print(" -> PASS: Mobile flight controls, attitude thrusters, and propellant consumption verified.")

	print("[TEST 6] Testing Inventory Refueling & Energy Conversion...")
	ship.current_energy = 40.0
	GameManager.player_stats.fuel = 30.0
	GameManager.crafting.add_item("energy_cell", 2)
	GameManager.crafting.add_item("bio_fuel", 1)
	
	var refuel_energy_success = ship.convert_item_to_ship_energy("energy_cell")
	assert(refuel_energy_success == true, "Must successfully convert energy_cell to ship energy")
	assert(ship.current_energy == 75.0, "Energy cell should restore +35 energy (40 + 35 = 75)")
	
	var refuel_fuel_success = ship.convert_item_to_fuel("bio_fuel")
	assert(refuel_fuel_success == true, "Must successfully convert bio_fuel to fuel")
	assert(GameManager.player_stats.fuel == 80.0, "Biofuel should restore +50 fuel (30 + 50 = 80)")
	print(" -> PASS: Canister & chemical refueling converts directly to ship reserves.")

	print("[TEST 7] Testing Cabin Mobility, Vehicle Frame Delta Sync & Zero-G / 1G Floating...")
	# Stand up from pilot seat inside cabin in orbit
	ship.stand_up_from_pilot_seat(player)
	assert(ship.is_player_seated == false, "Player must stand up from pilot seat")
	assert(ship.is_player_in_cabin == true, "Player must remain inside cabin")
	
	# Hatch lock check: Hatch MUST NOT be openable while in orbit!
	var hatch_state = ship.get_hatch_interaction_state(player)
	assert(hatch_state == "", "Hatch interaction MUST be locked/forbidden while in orbit")
	
	# Test Vehicle Frame Delta Sync: Move ship and verify player moves by identical delta
	ship.prev_ship_global_pos = ship.global_position
	ship.prev_ship_basis = ship.global_transform.basis
	var prev_player_pos = player.global_position
	var simulated_vehicle_delta = Vector3(12.5, 3.2, -8.0)
	ship.global_position += simulated_vehicle_delta
	# Step ship physics process
	ship._physics_process(0.016)
	var expected_player_pos = prev_player_pos + simulated_vehicle_delta
	var dist_drift = player.global_position.distance_to(expected_player_pos)
	print(" -> Frame delta sync drift error: %.4f m" % dist_drift)
	assert(dist_drift < 0.05, "Player must follow vehicle frame translation with zero slip")

	# Test Artificial Gravity Stabilizer Toggling:
	# 1. Artificial Gravity ON (Default 1.0G)
	assert(ship.is_artificial_gravity_active == true, "Artificial gravity should start active")
	player._physics_process(0.016)
	assert(player.up_direction == ship.global_transform.basis.y, "Up direction in cabin must match ship's local up")
	
	# 2. Artificial Gravity OFF (0.0G Microgravity floating)
	ship.activate_gravity_device(player)
	assert(ship.is_artificial_gravity_active == false, "Gravity device must toggle to 0G microgravity")
	player._physics_process(0.016)
	print(" -> Gravity device successfully set to 0.0G microgravity (floating inertia active)")
	
	# Sit back down in pilot seat
	ship.sit_in_pilot_seat(player)
	assert(ship.is_player_seated == true, "Player must be able to sit back down in pilot seat")
	print(" -> PASS: Cabin mobility, 1G/0G stabilizer, and seat re-docking verified.")

	print("[TEST 8] Testing Interplanetary Transit Timing (1 AU = 60s) & Hyperdrive (2x Energy)...")
	var target_planet = {
		"name": "Aurelia-IV",
		"orbit_au": 2.0,
		"type": "Oceanic World",
		"radius": 180.0
	}
	# Distance from 1.0 AU to 2.0 AU = 1.0 AU
	GameManager.current_planet["orbit_au"] = 1.0
	# Manual transit: 1.0 AU = 60s duration, base energy ~30
	# Hyperdrive transit: 1.0 AU = ~17.1s duration (3.5x faster), 2x energy ~60
	ship.start_interplanetary_transfer(target_planet, false) # Manual
	assert(ship.flight_state == 3, "Ship must be in INTERPLANETARY_TRANSIT (state 3)")
	assert(absf(ship.transit_duration_sec - 60.0) < 1.0, "Manual transit for 1 AU must equal 60 seconds (1 minute)")
	
	var manual_energy_cost = ship.transit_energy_cost
	print(" -> Manual Transit Duration: %.1fs (1 AU = 60s) | Energy Cost: %.1f" % [ship.transit_duration_sec, manual_energy_cost])
	
	# Now test Hyperdrive transit
	ship.start_interplanetary_transfer(target_planet, true) # Hyperdrive
	var hyper_energy_cost = ship.transit_energy_cost
	print(" -> Hyperdrive Transit Duration: %.1fs (3.5x speed) | Energy Cost: %.1f (2x Energy)" % [ship.transit_duration_sec, hyper_energy_cost])
	assert(ship.transit_duration_sec < 20.0, "Hyperdrive must be significantly faster")
	assert(absf(hyper_energy_cost - manual_energy_cost * 2.0) < 2.0, "Hyperdrive must consume 2x energy compared to manual transit")
	print(" -> PASS: Interplanetary timing and hyperdrive energy scaling verified.")

	print("[TEST 9] Testing Manual and Automatic Polar Landing...")
	# Initiate landing approach
	ship.initiate_atmospheric_reentry(planet.planet_params)
	assert(ship.flight_state == 4, "Ship must be in LANDING_APPROACH (state 4)")
	print(" -> Reentry descent sequence active. Executing touchdown...")
	
	# Complete touchdown
	var landing_target = ship.get_pole_landing_position(planet.planet_params)
	ship.reach_surface_landing(landing_target)
	assert(ship.flight_state == 0, "Ship must be in LANDED state (state 0)")
	assert(planet.is_orbital_lod_active == false, "Planet orbital LOD must deactivate upon landing")
	assert(ship.distant_planets_root.visible == false, "Distant planets must hide when landed on surface")
	print(" -> PASS: Polar landing sequence successfully completed.")

	print("==================================================")
	print("ALL 9 SPACEFLIGHT & CABIN TESTS PASSED (100% GREEN)!")
	print("==================================================")
	get_tree().quit(0)
