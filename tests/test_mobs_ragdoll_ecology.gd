extends Node

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func assert_true(condition: bool, message: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % message)
	else:
		failed_tests += 1
		printerr("  [FAIL] %s" % message)

func _ready() -> void:
	print("==================================================")
	print("  TESTING MOBS DAMAGE, RAGDOLL, FEEDING & ECOLOGY ")
	print("==================================================")
	
	test_hostile_mob_damage_and_screen_kick()
	test_ragdoll_physics_and_planetary_gravity()
	test_hand_held_food_feeding_and_taming()
	test_carrying_tamed_pet_and_defense_ai()
	test_flora_ecological_spreading_and_aggressive_plants()
	test_horizon_lod_visibility()
	
	print("==================================================")
	print("RESULTS: %d PASSED, %d FAILED (TOTAL %d)" % [passed_tests, failed_tests, total_tests])
	print("==================================================")
	
	if failed_tests == 0:
		print("ALL REQUIREMENTS VERIFIED SUCCESSFULLY!")
	get_tree().quit(0 if failed_tests == 0 else 1)

func test_hostile_mob_damage_and_screen_kick() -> void:
	print("\n--- 1. Hostile Mob Damage, Knockback & Screen Kick ---")
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = char_scene.instantiate()
	add_child(player)
	player.add_to_group("player")
	player.global_position = Vector3(0, 160.0, 0)
	
	# Initial hull
	GameManager.player_stats.hull = 100.0
	player.screen_kick_trauma = 0.0
	
	var CreatureClass = load("res://scripts/entities/alien_creature.gd")
	var mob = CreatureClass.new()
	add_child(mob)
	mob.global_position = Vector3(0, 160.0, 1.8)
	mob.setup_creature({"type": "Habitable", "level": 2}, true) # Aggressive
	mob.target_player = player
	mob.attack_cooldown = 0.0
	
	# Perform hostile attack against astronaut
	mob._perform_attack(0.1)
	
	assert_true(GameManager.player_stats.hull < 100.0, "Hostile mob attack deals real damage to astronaut hull")
	assert_true(player.screen_kick_trauma > 0.0, "Hostile attack induces visual screen kick trauma on astronaut")
	assert_true(player.velocity.length() > 0.0, "Hostile attack applies physical knockback impulse to astronaut")
	
	# Clean up
	player.free()
	mob.free()

func test_ragdoll_physics_and_planetary_gravity() -> void:
	print("\n--- 2. Ragdoll Tumbling & Planetary Gravity on Hit/Defeat ---")
	var CreatureClass = load("res://scripts/entities/alien_creature.gd")
	var mob = CreatureClass.new()
	add_child(mob)
	mob.global_position = Vector3(0, 160.0, 0)
	mob.setup_creature({"type": "Habitable"}, false)
	
	# Hit with knockback impulse
	var impulse = Vector3(5.0, 3.0, 0.0)
	mob.take_damage(20.0, impulse)
	assert_true(mob.is_in_ragdoll, "Mob enters physical ragdoll state when receiving a heavy hit")
	assert_true(mob.ragdoll_timer > 0.0, "Mob has active ragdoll timer")
	assert_true(mob.velocity.length() > 0.0, "Mob inherits ballistic knockback velocity")
	
	# Simulate physics tick: gravity pulls towards planet core
	var initial_vel_y = mob.velocity.y
	mob._physics_process(0.1)
	assert_true(mob.velocity.y < initial_vel_y, "Planetary gravity acts on ragdoll mob tumbling")
	
	# Lethal blow
	mob.take_damage(200.0, Vector3(0, 4.0, 6.0))
	assert_true(mob.is_dead, "Mob dies from lethal damage")
	assert_true(mob.is_in_ragdoll, "Mob maintains ragdoll tumbling physics upon death")
	
	mob.free()

func test_hand_held_food_feeding_and_taming() -> void:
	print("\n--- 3. Hand-Held Food Feeding Requirement & Taming ---")
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = char_scene.instantiate()
	add_child(player)
	player.add_to_group("player")
	
	var CreatureClass = load("res://scripts/entities/alien_creature.gd")
	var mob = CreatureClass.new()
	add_child(mob)
	mob.global_position = Vector3(0, 160.0, 1.5)
	mob.setup_creature({"type": "Habitable"}, false)
	mob.creature_size = CreatureClass.CreatureSize.SMALL
	
	# 1. Empty hands check
	var crafting = GameManager.crafting
	for k in crafting.inventory.keys():
		crafting.inventory[k] = 0
	for s_key in crafting.ALL_BODY_SLOTS:
		crafting.body_slots[s_key] = {"item": "", "count": 0}
	assert_true(not player.has_held_food(), "Player has empty hands (no food held)")
	
	# Interact with creature with empty hands
	player.nearby_interactable = mob
	player.current_interactable_type = "feed"
	player.interact_with_creature(mob)
	assert_true(not mob.is_fed, "Cannot feed mob with empty hands: mob remains untamed")
	
	# 2. Equip edible food in hand slot
	crafting.add_resource("plant_fibers", 2)
	assert_true(player.has_held_food(), "Player is holding edible food in hand slot")
	var held_item = player.get_held_food_item()
	assert_true(held_item.get("item", "") == "plant_fibers", "Held food item identified as plant_fibers")
	
	# Feed creature with held food
	player.interact_with_creature(mob)
	assert_true(mob.is_fed, "Feeding with hand-held food pacifies and tames the mob")
	assert_true(crafting.get_item_count("plant_fibers") == 1, "Feeding consumes 1 food item from hand slot")
	
	player.free()
	mob.free()

func test_carrying_tamed_pet_and_defense_ai() -> void:
	print("\n--- 4. Pet Carrying, Pose, Defense AI & Inter-Mob Combat ---")
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = char_scene.instantiate()
	add_child(player)
	player.add_to_group("player")
	player.global_position = Vector3(0, 160.0, 0)
	
	var CreatureClass = load("res://scripts/entities/alien_creature.gd")
	var pet = CreatureClass.new()
	add_child(pet)
	pet.global_position = Vector3(0, 160.0, 1.0)
	pet.setup_creature({"type": "Habitable"}, false)
	pet.creature_size = CreatureClass.CreatureSize.SMALL
	
	# Check carrying condition: can ONLY pick up AFTER fed/tamed
	assert_true(not pet.can_be_carried(), "Wild untamed creature cannot be picked up or carried")
	pet.is_fed = true
	assert_true(pet.can_be_carried(), "Tamed creature CAN be picked up and carried")
	
	# Pick up tamed pet
	player.pick_up_creature(pet)
	assert_true(player.carried_creature == pet, "Astronaut is holding the tamed creature")
	assert_true(pet.is_being_carried, "Pet is marked as carried")
	
	# Carry pose check: held in front at chest height
	player._physics_process(0.016)
	var up_dir = player.global_position.normalized()
	var forward = -player.global_transform.basis.z
	var pet_offset = pet.global_position - player.global_position
	assert_true(pet_offset.dot(up_dir) > 0.8, "Pet is carried comfortably at chest height (not dragging on ground)")
	assert_true(pet_offset.dot(forward) > 0.3, "Pet is held out in front of the astronaut with two hands")
	
	# Drop/Release pet
	player.drop_carried_creature()
	assert_true(player.carried_creature == null, "Pet released from astronaut hands")
	assert_true(pet.is_fed, "Released pet remains loyal and tamed")
	assert_true(pet.target_player == player, "Tamed pet follows player as companion")
	
	# Inter-Mob Combat & Pet Defense AI:
	# Spawn a hostile predator attacking the player
	var predator = CreatureClass.new()
	add_child(predator)
	predator.global_position = Vector3(0, 160.0, 3.0)
	predator.setup_creature({"type": "Habitable"}, true) # Aggressive predator
	predator.target_player = player
	
	# Pet defense AI scan
	pet._physics_process(0.1)
	assert_true(pet.target_enemy == predator, "Tamed pet actively defends player and targets hostile predator")
	
	# Pet attacks hostile predator
	var initial_predator_hp = predator.current_health
	pet._perform_attack(0.1, true)
	assert_true(predator.current_health < initial_predator_hp, "Inter-mob combat: Pet deals damage to hostile mob")
	assert_true(predator.is_in_ragdoll, "Inter-mob combat: Attacked mob enters ragdoll/knockback state")
	
	player.free()
	pet.free()
	predator.free()

func test_flora_ecological_spreading_and_aggressive_plants() -> void:
	print("\n--- 5. Flora Ecological Spreading & Aggressive Flora Behaviors ---")
	var flora_scene = load("res://scenes/entities/procedural_flora.tscn")
	var tree_scene = load("res://scenes/entities/paper_tree.tscn")
	
	# 1. Passive Tree / Flora Spreading
	var tree = tree_scene.instantiate()
	add_child(tree)
	tree.global_position = Vector3(0, 160.0, 0)
	tree.expansion_timer = 0.0 # Force trigger expansion
	tree._attempt_tree_expansion()
	assert_true(tree.expansion_timer > 30.0, "Tree resets expansion cycle after ecological reproduction")
	
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = char_scene.instantiate()
	add_child(player)
	player.add_to_group("player")
	
	# 2. Aggressive Flora: Carnivorous Pitcher Plant
	var snapper = flora_scene.instantiate()
	add_child(snapper)
	snapper.global_position = Vector3(0, 160.0, 0)
	snapper.setup_flora(snapper.FloraType.CARNIVOROUS_SNAPPER, {"type": "Habitable"})
	
	player.global_position = Vector3(0, 160.0, 1.2) # Within 2.5m snapping range
	GameManager.player_stats.hull = 100.0
	
	snapper._process(0.1)
	assert_true(snapper.is_snapper_shut, "Carnivorous pitcher plant snaps jaws shut on nearby prey")
	assert_true(GameManager.player_stats.hull < 100.0, "Carnivorous plant deals bite damage to player")
	
	# 3. Aggressive Flora: Toxic Spore Pod
	var spore_pod = flora_scene.instantiate()
	add_child(spore_pod)
	spore_pod.global_position = Vector3(0, 160.0, 0)
	spore_pod.setup_flora(spore_pod.FloraType.SPORE_POD_BULB, {"type": "Habitable"})
	
	GameManager.player_stats.hull = 100.0
	player.global_position = Vector3(0, 160.0, 1.5)
	spore_pod._process(0.1)
	assert_true(GameManager.player_stats.hull < 100.0, "Toxic spore pod bursts with toxic damage when stepped near")
	
	# 4. Aggressive Flora: Thorn Bush / Cactus
	var cactus = flora_scene.instantiate()
	add_child(cactus)
	cactus.global_position = Vector3(0, 160.0, 0)
	cactus.setup_flora(cactus.FloraType.COLUMNAR_CACTUS, {"type": "Habitable"})
	player.global_position = Vector3(0, 160.0, 1.0) # Within 1.6m thorn range
	
	GameManager.player_stats.hull = 100.0
	cactus._process(0.1)
	assert_true(GameManager.player_stats.hull < 100.0, "Thorn bush pricks nearby intruder with physical thorn damage")
	
	tree.queue_free()
	snapper.queue_free()
	spore_pod.queue_free()
	cactus.queue_free()
	player.queue_free()

func test_horizon_lod_visibility() -> void:
	print("\n--- 6. Horizon-Based Progressive LOD & Smooth Visibility ---")
	var PlanetClass = load("res://scripts/world/spherical_planet.gd")
	var planet = Node3D.new()
	planet.set_script(PlanetClass)
	planet.radius = 160.0
	add_child(planet)
	
	var flora_scene = load("res://scenes/entities/procedural_flora.tscn")
	
	# Entity 1: Near player (15m)
	var near_flora = flora_scene.instantiate()
	near_flora.position = Vector3(0, 160.0, 15.0)
	near_flora.setup_flora(near_flora.FloraType.FAN_FERN, {"type": "Habitable"})
	planet.add_child(near_flora)
	planet.spawned_flora.append(near_flora)
	
	# Entity 2: Distant on visible hemisphere (65m)
	var mid_flora = flora_scene.instantiate()
	mid_flora.position = Vector3(0, 160.0, 65.0)
	mid_flora.setup_flora(mid_flora.FloraType.FAN_FERN, {"type": "Habitable"})
	planet.add_child(mid_flora)
	planet.spawned_flora.append(mid_flora)
	
	# Entity 3: Behind planetary horizon curvature (opposite hemisphere)
	var occluded_flora = flora_scene.instantiate()
	occluded_flora.position = Vector3(0, -160.0, 0.0)
	occluded_flora.setup_flora(occluded_flora.FloraType.FAN_FERN, {"type": "Habitable"})
	planet.add_child(occluded_flora)
	planet.spawned_flora.append(occluded_flora)
	
	var char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = char_scene.instantiate()
	player.position = Vector3(0, 160.0, 0.0)
	planet.add_child(player)
	planet.player_instance = player
	
	planet.update_radial_streaming(player.global_position)
	
	assert_true(near_flora.visible, "Near entity is visible in full detail")
	assert_true(near_flora.lod_level == 0, "Near entity operates at LOD 0 (High detail)")
	assert_true(mid_flora.visible, "Distant entity remains visible without popping out")
	assert_true(mid_flora.lod_level >= 1, "Distant entity uses progressive LOD 1 or 2 to optimize shaders/CPU")
	assert_true(not occluded_flora.visible, "Entity occluded behind planetary curvature horizon is culled")
	assert_true(occluded_flora.lod_level == 3, "Horizon occluded entity is set to LOD 3 (culled)")
	
	planet.queue_free()
