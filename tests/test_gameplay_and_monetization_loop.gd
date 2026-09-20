extends Node

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("   CIVITUS MAIN GAME LOOP & REVENUECAT FREEMIUM TDD    ")
	print("=======================================================\n")

	test_luna_points_economy()
	test_freemium_store_rewards()
	test_difficulty_resource_distribution()
	test_interplanetary_flight_mechanics()
	test_alien_creature_combat_and_loot()
	test_hyperdrive_full_loop()

	print("\n=======================================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("=======================================================\n")

	get_tree().quit(0 if failed_count == 0 else 1)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_count += 1
		print("  [FAIL] %s" % test_name)

func assert_eq(val1, val2, test_name: String) -> void:
	if val1 == val2:
		passed_count += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_count += 1
		print("  [FAIL] %s (got %s, expected %s)" % [test_name, str(val1), str(val2)])

func test_luna_points_economy() -> void:
	print("--- 1. Testing Luna Points Freemium Economy ---")
	GameManager.luna_points = 0
	GameManager.add_luna_points(100)
	assert_eq(GameManager.luna_points, 100, "Adding 100 Luna Points increases balance to 100")
	
	var spent = GameManager.spend_luna_points(40)
	assert_true(spent, "Successfully spent 40 Luna Points")
	assert_eq(GameManager.luna_points, 60, "Balance reduced to 60")
	
	var overspent = GameManager.spend_luna_points(150)
	assert_true(not overspent, "Cannot spend more points than current balance")
	assert_eq(GameManager.luna_points, 60, "Balance remains 60 after rejected spend")

func test_freemium_store_rewards() -> void:
	print("--- 2. Testing Freemium Store & Luna Points Unlocks ---")
	# Awarding victory at difficulty 1
	var initial_pts = GameManager.luna_points
	GameManager.award_hyperdrive_victory(1)
	assert_eq(GameManager.luna_points, initial_pts + 50, "Difficulty 1 awards 50 Luna Points")
	
	# Awarding victory at difficulty 3
	GameManager.award_hyperdrive_victory(3)
	assert_eq(GameManager.luna_points, initial_pts + 50 + 180, "Difficulty 3 awards 180 Luna Points")

func test_difficulty_resource_distribution() -> void:
	print("--- 3. Testing Difficulty-Based Resource Spawning ---")
	# Level 1 starting planet must have all resources including uranium
	var l1_planet = { "level": 1, "type": "Habitable", "has_oxygen": true }
	var l1_ores = GameManager.get_planet_spawnable_ores(l1_planet)
	assert_true(l1_ores.has("iron"), "Level 1 planet spawns Iron")
	assert_true(l1_ores.has("copper"), "Level 1 planet spawns Copper")
	assert_true(l1_ores.has("silicon"), "Level 1 planet spawns Silicon")
	assert_true(l1_ores.has("uranium"), "Level 1 planet spawns Uranium (self-contained hyperdrive)")

	# Level 3 starting planet is stripped of Uranium (forcing interplanetary travel)
	var l3_start_planet = { "level": 3, "type": "Habitable", "has_oxygen": true }
	var l3_ores = GameManager.get_planet_spawnable_ores(l3_start_planet)
	assert_true(l3_ores.has("iron") and l3_ores.has("copper"), "Level 3 starting planet has basic metals")
	assert_true(not l3_ores.has("uranium"), "Level 3 starting planet has NO uranium (forces space travel)")

	# Level 3 volcanic/radioactive target planet in the same system contains Uranium
	var l3_volcanic_planet = { "level": 3, "type": "Volcan", "has_oxygen": false }
	var l3_volcanic_ores = GameManager.get_planet_spawnable_ores(l3_volcanic_planet)
	assert_true(l3_volcanic_ores.has("uranium"), "Volcanic/Radioactive planet hosts critical Uranium")

func test_interplanetary_flight_mechanics() -> void:
	print("--- 4. Testing Interplanetary Space Flight (Space Agency 2137 Style) ---")
	var p1 = { "name": "Aurelia Prime", "orbit_au": 1.0, "level": 2 }
	var p2 = { "name": "Aurelia IV (Magma)", "orbit_au": 2.4, "level": 3 }
	
	var dist_au = GameManager.calc_transit_distance_au(p1, p2)
	assert_true(abs(dist_au - 1.4) < 0.01, "Transit distance between 1.0 AU and 2.4 AU is 1.4 AU")
	
	var fuel_cost = GameManager.calc_transit_fuel_cost(dist_au)
	assert_true(fuel_cost >= 20.0 and fuel_cost <= 60.0, "Transit fuel cost is balanced between 20% and 60%")
	
	var eta_s = GameManager.calc_transit_flight_duration_s(dist_au)
	assert_true(eta_s >= 4.0 and eta_s <= 12.0, "Flight duration provides cinematic 4-12s space transit")

func test_alien_creature_combat_and_loot() -> void:
	print("--- 5. Testing Alien Creature Combat & Strict Loot Rule ---")
	var alien_script = load("res://scripts/entities/alien_creature.gd")
	assert_true(alien_script != null, "AlienCreature script loaded")
	
	var creature = alien_script.new()
	add_child(creature)
	creature.setup_creature({ "type": "Habitable", "level": 2 }, true) # Aggressive predator
	
	assert_true(creature.is_aggressive, "Hostile predator is marked aggressive")
	assert_true(creature.current_health > 0.0, "Creature spawns with full health")
	
	# Take damage from player plasma attack
	var loot = creature.take_damage(25.0)
	assert_true(creature.current_health < creature.max_health, "Creature health decreased after plasma hit")
	
	# Fatal blow
	var kill_loot = creature.take_damage(100.0)
	assert_true(creature.is_dead, "Creature enters dead state")
	assert_true(kill_loot.has("item"), "Creature drops loot on defeat")
	assert_eq(kill_loot["item"], "alien_chitin", "Defeated predator drops alien_chitin")
	
	# Strict Loot Rule: Feeding/helping peaceful creature yields DIFFERENT item
	var peaceful = alien_script.new()
	add_child(peaceful)
	peaceful.setup_creature({ "type": "Habitable", "level": 1 }, false)
	var feed_loot = peaceful.feed_creature("fiber")
	assert_true(feed_loot != "alien_chitin", "Strict Loot Rule: Feeding never gives same loot as killing")
	assert_eq(feed_loot, "biogel_sample", "Peaceful symbiotic feeding yields biogel_sample")
	
	creature.queue_free()
	peaceful.queue_free()

func test_hyperdrive_full_loop() -> void:
	print("--- 6. Testing Full Hyperdrive Game Loop ---")
	GameManager.start_new_game(1) # Easy
	assert_eq(GameManager.crafting.is_hyperdrive_complete(), false, "Hyperdrive starts damaged")
	
	# Supply required materials for level 1: 1 wrench, 2 wire, 10 uranium
	GameManager.crafting.inventory["iron"] = 10
	GameManager.crafting.inventory["copper"] = 10
	GameManager.crafting.inventory["uranium"] = 10
	
	# Craft parts
	GameManager.crafting.craft("wrench")
	GameManager.crafting.craft("wire") # crafts 2
	
	assert_eq(GameManager.crafting.inventory["wrench"], 1, "Crafted 1 wrench")
	assert_eq(GameManager.crafting.inventory["wire"], 2, "Crafted 2 wires")
	
	# Install parts into ship
	GameManager.crafting.install_part("wrench")
	GameManager.crafting.install_part("wire")
	GameManager.crafting.install_part("wire")
	
	for i in range(10):
		GameManager.crafting.inventory["uranium"] = 10
		GameManager.crafting.install_part("uranium")
		
	assert_true(GameManager.crafting.is_hyperdrive_complete(), "Hyperdrive is fully repaired!")
	assert_eq(GameManager.crafting.get_hyperdrive_progress(), 1.0, "Progress is 100%")
