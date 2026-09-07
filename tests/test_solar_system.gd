extends Node

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("\n==========================================")
	print("   RUNNING SOLAR SYSTEM PROCEDURAL TESTS  ")
	print("==========================================\n")
	
	test_procedural_central_star()
	test_spectral_classes_and_ranges()
	test_habitable_zone_formula()
	test_variable_planet_counts()
	test_orbit_bounds_and_ordering()
	test_habitable_zone_flag_accuracy()
	test_airless_vacuum_physics()
	test_realistic_temperature_calculation()
	test_gravity_bounds()
	test_water_status_rules()
	test_dynamic_level_determination()
	test_telemetry_graph_metrics()
	test_system_graph_metrics()
	test_shader_parameters()
	test_seed_determinism()
	
	print("\n==========================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("==========================================\n")
	
	if failed_count == 0:
		print("ALL SOLAR SYSTEM TESTS PASSED SUCCESSFULLY! :)")
	else:
		print("SOME TESTS FAILED! :(")
		
	get_tree().quit(0 if failed_count == 0 else 1)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_count += 1
		print("  [FAIL] %s" % test_name)

func assert_almost_eq(val1: float, val2: float, margin: float, test_name: String) -> void:
	if abs(val1 - val2) <= margin:
		passed_count += 1
		print("  [PASS] %s (got %.4f, expected %.4f)" % [test_name, val1, val2])
	else:
		failed_count += 1
		print("  [FAIL] %s (got %.4f, expected %.4f, diff %.4f > %.4f)" % [test_name, val1, val2, abs(val1 - val2), margin])

func test_procedural_central_star() -> void:
	var sys = SolarSystem.generate_system(12345)
	assert_true(sys.has("star"), "System dictionary contains 'star' key")
	
	var star = sys.get("star", {})
	assert_true(star.has("name") and star["name"].length() > 0, "Star has valid procedural name: %s" % star.get("name", ""))
	assert_true(star.has("spectral_class"), "Star has spectral_class")
	assert_true(["O", "B", "A", "F", "G", "K", "M"].has(star["spectral_class"]), "Spectral class is one of O, B, A, F, G, K, M: %s" % star.get("spectral_class", ""))
	assert_true(star["temperature"] >= 2500.0 and star["temperature"] <= 40000.0, "Star temperature in valid range: %.1f K" % star.get("temperature", 0.0))
	assert_true(star["luminosity"] > 0.0, "Star luminosity is positive: %.2f L_sun" % star.get("luminosity", 0.0))
	assert_true(star.has("color") and star["color"] is Color, "Star has valid Color representation")
	assert_true(star.has("hz_inner_au") and star.has("hz_outer_au"), "Star has calculated habitable zone limits")
	assert_true(star["hz_inner_au"] < star["hz_outer_au"], "Habitable zone inner boundary < outer boundary (%.2f < %.2f)" % [star["hz_inner_au"], star["hz_outer_au"]])

func test_spectral_classes_and_ranges() -> void:
	var classes_found = {}
	# Across 150 seeds, ensure procedural star generation covers diverse spectral classes
	for s in range(150):
		var sys = SolarSystem.generate_system(s * 73 + 101)
		var s_class = sys["star"]["spectral_class"]
		classes_found[s_class] = classes_found.get(s_class, 0) + 1
		
	assert_true(classes_found.size() >= 4, "Diverse spectral classes generated across seeds (found %d distinct classes)" % classes_found.size())
	print("    Classes found: %s" % str(classes_found))

func test_habitable_zone_formula() -> void:
	var sys = SolarSystem.generate_system(42)
	var star = sys["star"]
	var lum = star["luminosity"]
	var expected_inner = sqrt(lum / 1.1)
	var expected_outer = sqrt(lum / 0.53)
	
	assert_almost_eq(star["hz_inner_au"], expected_inner, 0.01, "Habitable zone inner matches Kopparapu formula sqrt(L / 1.1)")
	assert_almost_eq(star["hz_outer_au"], expected_outer, 0.01, "Habitable zone outer matches Kopparapu formula sqrt(L / 0.53)")

func test_variable_planet_counts() -> void:
	var counts = {}
	var min_c = 999
	var max_c = -1
	
	for s in range(60):
		var sys = SolarSystem.generate_system(s * 91 + 7)
		var p_count = sys["planets"].size()
		counts[p_count] = counts.get(p_count, 0) + 1
		if p_count < min_c: min_c = p_count
		if p_count > max_c: max_c = p_count
		assert_true(p_count >= 4 and p_count <= 8, "Planet count is within [4, 8] (got %d)" % p_count)
		
	assert_true(min_c <= 5 and max_c >= 7, "Variable planet counts generated between 4 and 8 (min: %d, max: %d)" % [min_c, max_c])
	print("    Planet count distribution: %s" % str(counts))

func test_orbit_bounds_and_ordering() -> void:
	for s in range(25):
		var sys = SolarSystem.generate_system(s * 333 + 17)
		var planets = sys["planets"]
		for i in range(planets.size()):
			var orb = planets[i]["orbit_au"]
			assert_true(orb >= 0.2 and orb <= 6.5, "Planet %d orbit (%.2f AU) is within [0.2, 6.5] AU" % [i, orb])
			if i > 0:
				var prev_orb = planets[i - 1]["orbit_au"]
				assert_true(orb >= prev_orb, "Planets ordered by distance from star: %.2f >= %.2f" % [orb, prev_orb])

func test_habitable_zone_flag_accuracy() -> void:
	for s in range(20):
		var sys = SolarSystem.generate_system(s * 111 + 55)
		var star = sys["star"]
		var hz_inner = star["hz_inner_au"]
		var hz_outer = star["hz_outer_au"]
		for p in sys["planets"]:
			var orb = p["orbit_au"]
			var in_hz_calc = (orb >= hz_inner and orb <= hz_outer)
			assert_true(p["is_in_habitable_zone"] == in_hz_calc, "is_in_habitable_zone correctly reflects orbit position: orbit=%.2f, hz=[%.2f, %.2f]" % [orb, hz_inner, hz_outer])

func test_airless_vacuum_physics() -> void:
	var found_vacuum_world = false
	for s in range(50):
		var sys = SolarSystem.generate_system(s * 222 + 9)
		for p in sys["planets"]:
			if not p["has_atmosphere"]:
				found_vacuum_world = true
				assert_true(p["atmosphere"] == 0.0, "Vacuum world has atmosphere == 0.0 atm")
				assert_true(p["sky_color"] == Color.BLACK, "Vacuum world has sky_color == Color.BLACK")
				assert_true(p["atmosphere_color"] == Color.BLACK, "Vacuum world has atmosphere_color == Color.BLACK")
				assert_true(p["cloud_density"] == 0.0, "Vacuum world has cloud_density == 0.0")
				assert_true(p["has_oxygen"] == false, "Vacuum world has no oxygen")
				assert_true(p["water_status"] != "Líquida", "Vacuum world cannot have liquid water")
				break
		if found_vacuum_world:
			break
			
	assert_true(found_vacuum_world, "At least one procedural airless vacuum world was found and verified")

func test_realistic_temperature_calculation() -> void:
	var sys = SolarSystem.generate_system(777)
	var planets = sys["planets"]
	
	# In general, inner worlds receive significantly higher stellar flux than outer worlds
	var innermost = planets[0]
	var outermost = planets[planets.size() - 1]
	assert_true(innermost["temperature"] > outermost["temperature"], "Innermost world (%.0f°C) is hotter than outermost world (%.0f°C)" % [innermost["temperature"], outermost["temperature"]])
	
	for p in planets:
		assert_true(p["temperature"] >= -250.0 and p["temperature"] <= 1000.0, "Planet %s temperature within physical range: %.0f°C" % [p["name"], p["temperature"]])

func test_gravity_bounds() -> void:
	for s in range(25):
		var sys = SolarSystem.generate_system(s * 543 + 3)
		for p in sys["planets"]:
			var g_rel = p["gravity_g"]
			var g_ms2 = p["gravity"]
			assert_true(g_rel >= 0.20 and g_rel <= 3.50, "Gravity in G is within [0.2G, 3.5G]: %.2f G" % g_rel)
			assert_almost_eq(g_ms2, g_rel * 9.8, 0.2, "Gravity in m/s² matches gravity_g * 9.8")

func test_water_status_rules() -> void:
	var valid_statuses = ["Líquida", "Hielo Criogénico", "Seco / Desolado", "Lava Fundida", "Vapor Tóxico"]
	
	for s in range(30):
		var sys = SolarSystem.generate_system(s * 888 + 1)
		for p in sys["planets"]:
			var ws = p["water_status"]
			assert_true(valid_statuses.has(ws), "water_status '%s' is one of valid allowed strings" % ws)
			
			# CRITICAL RULE: "Líquida" only in habitable zone with oxygen/atmosphere
			if ws == "Líquida":
				assert_true(p["is_in_habitable_zone"] == true, "Liquid water world is strictly in habitable zone")
				assert_true(p["has_atmosphere"] == true, "Liquid water world has atmosphere")
				assert_true(p["has_oxygen"] == true, "Liquid water world has oxygen")

func test_dynamic_level_determination() -> void:
	# Test direct level assignment logic
	# Level 0: Habitable / Earth-like
	var p0 = {
		"is_in_habitable_zone": true, "has_atmosphere": true, "has_oxygen": true,
		"water_status": "Líquida", "temperature": 21.0, "gravity_g": 1.0, "radiation": 0.02
	}
	assert_true(SolarSystem.determine_level(p0) == 0, "Level 0 assigned when in HZ with oxygen, atmosphere, and liquid water")
	
	# If outside HZ, even with water string, cannot be Level 0
	var p0_outside = {
		"is_in_habitable_zone": false, "has_atmosphere": true, "has_oxygen": true,
		"water_status": "Líquida", "temperature": 21.0, "gravity_g": 1.0, "radiation": 0.02
	}
	assert_true(SolarSystem.determine_level(p0_outside) != 0, "Cannot be Level 0 outside habitable zone")
	
	# Level 5: Tartarus / Hell-Star Pro
	var p5 = {
		"is_in_habitable_zone": false, "has_atmosphere": true, "has_oxygen": false,
		"water_status": "Lava Fundida", "temperature": 550.0, "gravity_g": 3.0, "radiation": 1.5,
		"is_molten": true
	}
	assert_true(SolarSystem.determine_level(p5) == 5, "Level 5 assigned for molten lava hell planet")
	
	# Level 4: Singularity / Void Pro
	var p4 = {
		"is_in_habitable_zone": false, "has_atmosphere": true, "has_oxygen": false,
		"water_status": "Seco / Desolado", "temperature": 150.0, "gravity_g": 2.8, "radiation": 0.95,
		"is_singularity": true
	}
	assert_true(SolarSystem.determine_level(p4) == 4, "Level 4 assigned for extreme gravity / singularity")
	
	# Level 3: Cryogenic Glacial
	var p3 = {
		"is_in_habitable_zone": false, "has_atmosphere": true, "has_oxygen": false,
		"water_status": "Hielo Criogénico", "temperature": -140.0, "gravity_g": 0.6, "radiation": 0.35
	}
	assert_true(SolarSystem.determine_level(p3) == 3, "Level 3 assigned for cryogenic glacial world")
	
	# Level 2: Toxic / Dense greenhouse
	var p2 = {
		"is_in_habitable_zone": false, "has_atmosphere": true, "has_oxygen": false,
		"water_status": "Vapor Tóxico", "temperature": 145.0, "gravity_g": 0.9, "radiation": 0.25,
		"atmosphere": 2.5
	}
	assert_true(SolarSystem.determine_level(p2) == 2, "Level 2 assigned for toxic runaway greenhouse")
	
	# Level 1: Desertic / Thin atmosphere
	var p1 = {
		"is_in_habitable_zone": false, "has_atmosphere": true, "has_oxygen": false,
		"water_status": "Seco / Desolado", "temperature": -20.0, "gravity_g": 0.4, "radiation": 0.15,
		"atmosphere": 0.35
	}
	assert_true(SolarSystem.determine_level(p1) == 1, "Level 1 assigned for desertic thin atmosphere world")

func test_telemetry_graph_metrics() -> void:
	var sys = SolarSystem.generate_system(999)
	for p in sys["planets"]:
		assert_true(p.has("telemetry_graph"), "Planet has 'telemetry_graph' dictionary")
		var tg = p["telemetry_graph"]
		
		assert_true(tg.has("habitability") and tg["habitability"] >= 0.0 and tg["habitability"] <= 1.0, "habitability is in [0.0, 1.0]: %.2f" % tg["habitability"])
		assert_true(tg.has("atmosphere") and tg["atmosphere"] >= 0.0 and tg["atmosphere"] <= 1.0, "atmosphere is in [0.0, 1.0]: %.2f" % tg["atmosphere"])
		assert_true(tg.has("temperature") and tg["temperature"] >= 0.0 and tg["temperature"] <= 1.0, "temperature is in [0.0, 1.0]: %.2f" % tg["temperature"])
		assert_true(tg.has("radiation") and tg["radiation"] >= 0.0 and tg["radiation"] <= 1.0, "radiation is in [0.0, 1.0]: %.2f" % tg["radiation"])
		assert_true(tg.has("danger") and tg["danger"] >= 0.0 and tg["danger"] <= 1.0, "danger is in [0.0, 1.0]: %.2f" % tg["danger"])
		
		# Temperature normalization verification (-200°C to +800°C)
		var expected_norm_temp = clampf((p["temperature"] - (-200.0)) / (800.0 - (-200.0)), 0.0, 1.0)
		assert_almost_eq(tg["temperature"], expected_norm_temp, 0.001, "Normalized temperature matches (-200°C to +800°C) scale")

func test_system_graph_metrics() -> void:
	var sys = SolarSystem.generate_system(852)
	assert_true(sys.has("system_graph"), "System has 'system_graph' dictionary")
	var sg = sys["system_graph"]
	
	assert_true(sg.has("star_temp") and sg["star_temp"] == sys["star"]["temperature"], "system_graph star_temp matches star.temperature")
	assert_true(sg.has("hz_inner") and sg["hz_inner"] == sys["star"]["hz_inner_au"], "system_graph hz_inner matches star.hz_inner_au")
	assert_true(sg.has("hz_outer") and sg["hz_outer"] == sys["star"]["hz_outer_au"], "system_graph hz_outer matches star.hz_outer_au")
	assert_true(sg.has("planet_count") and sg["planet_count"] == sys["planets"].size(), "system_graph planet_count matches planets.size()")
	
	var expected_habitable = 0
	for p in sys["planets"]:
		if p["level"] == 0:
			expected_habitable += 1
	assert_true(sg.has("habitable_count") and sg["habitable_count"] == expected_habitable, "system_graph habitable_count (%d) matches Level 0 planet count (%d)" % [sg["habitable_count"], expected_habitable])

func test_shader_parameters() -> void:
	for s in range(30):
		var sys = SolarSystem.generate_system(s * 77 + 23)
		for p in sys["planets"]:
			if not p["has_atmosphere"]:
				assert_true(p["atmosphere_color"] == Color.BLACK, "Vacuum world atmosphere_color == Color.BLACK")
				assert_true(p["cloud_density"] == 0.0, "Vacuum world cloud_density == 0.0")
				assert_true(p["sky_color"] == Color.BLACK, "Vacuum world sky_color == Color.BLACK")
				
			if p["level"] == 5 or p.get("is_molten", false):
				assert_true(p["emission_energy"] > 0.0, "Molten world has glowing emission energy: %.1f" % p["emission_energy"])
				assert_true(p["emission_color"] != Color.BLACK, "Molten world has non-black emission color")
				
			if p["level"] == 4 or p.get("is_singularity", false):
				assert_true(p["emission_energy"] > 0.0, "Singularity world has glowing plasma emission energy: %.1f" % p["emission_energy"])
				assert_true(p["emission_color"] != Color.BLACK, "Singularity world has non-black emission color")
				
			if p.get("has_rings", false):
				assert_true(p.has("ring_color") and p["ring_color"] is Color, "Planets with rings have valid ring_color")

func test_seed_determinism() -> void:
	var sys1 = SolarSystem.generate_system(98765)
	var sys2 = SolarSystem.generate_system(98765)
	
	assert_true(sys1["system_name"] == sys2["system_name"], "System name is deterministic with same seed")
	assert_true(sys1["star"]["temperature"] == sys2["star"]["temperature"], "Star temperature is deterministic with same seed")
	assert_true(sys1["planets"].size() == sys2["planets"].size(), "Planet count is deterministic with same seed")
	for i in range(sys1["planets"].size()):
		assert_true(sys1["planets"][i]["name"] == sys2["planets"][i]["name"], "Planet %d name is deterministic" % i)
		assert_true(sys1["planets"][i]["orbit_au"] == sys2["planets"][i]["orbit_au"], "Planet %d orbit is deterministic" % i)
		assert_true(sys1["planets"][i]["level"] == sys2["planets"][i]["level"], "Planet %d level is deterministic" % i)
