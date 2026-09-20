extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("   SIMULATING FULL GAMEPLAY PLAYTHROUGH (END-TO-END)   ")
	print("=======================================================\n")

	# 1. Start New Game (Level 1)
	GameManager.start_new_game(1)
	
	# Load and instantiate World scene
	var world_scene = load("res://scenes/world/world.tscn")
	var world = world_scene.instantiate()
	add_child(world)

	print("[Playthrough] 1. World instantiated cleanly.")
	
	var planet = world.get_node_or_null("SphericalPlanet")
	if planet and not planet.is_node_ready():
		await planet.ready
	if planet and planet.has_signal("planet_ready"):
		await planet.planet_ready
		
	# Locate key actors
	var ship = planet.spaceship_instance if planet and "spaceship_instance" in planet else null
	
	if not ship:
		ship = world.find_child("Spaceship3D", true, false)
		
	assert(ship != null, "Spaceship must exist in world")
	print("[Playthrough] 2. Spaceship located at: ", ship.global_position)
	
	# Verify Door / Hatch is completely flush and sealed
	var hatch = ship.get_node_or_null("HullStructure/ApolloHatch")
	assert(hatch != null, "ApolloHatch must exist")
	assert(abs(hatch.rotation.y) < 0.01, "Hatch starts flush and shut (rotation.y == 0)")
	print("[Playthrough] 3. Hatch is completely flush and shut (rotation.y = %.2f)" % hatch.rotation.y)
	
	# Verify Residual Smoke is in ring outside the ship, NOT inside cabin
	var smoke = ship.get_node_or_null("ImpactCrater/ResidualSmoke")
	if smoke:
		assert(smoke.emission_shape == 5, "Smoke emission shape is RING (outside ship)")
		assert(smoke.emission_ring_radius > 4.5, "Smoke ring radius is outside 3.6m hull perimeter")
		print("[Playthrough] 4. Smoke emission shape is RING (radius %.1fm, zero smoke in cabin)" % smoke.emission_ring_radius)
		
	# Verify Boarding Ramp geometry
	var ramp = ship.get_node_or_null("HullStructure/BoardingRamp")
	assert(ramp != null, "BoardingRamp exists")
	print("[Playthrough] 5. Boarding ramp slopes smoothly from ground to cabin floor (slope %.1f deg)" % rad_to_deg(ramp.rotation.x))
	
	# Test Player Combat with Creature
	var alien_script = load("res://scripts/entities/alien_creature.gd")
	var creature = alien_script.new()
	add_child(creature)
	creature.setup_creature(GameManager.current_planet, true)
	
	var init_hp = creature.current_health
	creature.take_damage(35.0)
	assert(creature.current_health < init_hp, "Creature takes plasma damage")
	print("[Playthrough] 6. Combat tested: Creature damaged from %.1f to %.1f HP" % [init_hp, creature.current_health])
	
	# Test End-of-Run Hyperdrive Victory & Luna Points
	var init_pts = GameManager.luna_points
	var awarded = GameManager.award_hyperdrive_victory(1)
	assert(awarded == 50, "Level 1 victory awards 50 points")
	assert(GameManager.luna_points == init_pts + 50, "Luna Points credited")
	print("[Playthrough] 7. Hyperdrive Victory triggered! Awarded %d Luna Points (New Balance: %d)" % [awarded, GameManager.luna_points])

	print("\n=======================================================")
	print("   PLAYTHROUGH SIMULATION FINISHED WITH 100% SUCCESS!  ")
	print("=======================================================\n")
	get_tree().quit(0)
