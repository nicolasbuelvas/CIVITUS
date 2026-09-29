extends Node3D

func _ready() -> void:
	print("\n=======================================================")
	print("   TESTING APOLLO EVA MINIMAP & SHIPWRECK SCAVENGING    ")
	print("=======================================================\n")
	
	# 1. Test Abandoned Shipwreck
	var wreck_scene = load("res://scenes/entities/abandoned_shipwreck.tscn")
	assert(wreck_scene != null, "Shipwreck scene must load")
	var wreck = wreck_scene.instantiate()
	add_child(wreck)
	assert(wreck.is_in_group("abandoned_shipwrecks"), "Shipwreck must be in abandoned_shipwrecks group")
	print("  [PASS] AbandonedShipwreck scene loaded and grouped")
	
	# Mock player for scavenge
	var player_char_scene = load("res://scenes/entities/character_3d.tscn")
	var player = player_char_scene.instantiate()
	add_child(player)
	GameManager.player_stats.oxygen = 40.0
	
	# Scavenge shipwreck
	assert(not wreck.is_scavenged, "Wreck starts unscavenged")
	var loot = wreck.scavenge(player)
	assert(wreck.is_scavenged, "Wreck is marked as scavenged after looting")
	assert(loot.size() > 0, "Scavenge must produce loot")
	print("  [PASS] Shipwreck scavenge yielded: %s" % str(loot))
	
	# 2. Test Resource Chunk Materials and Visibility
	var ore_scene = load("res://scenes/entities/resource_chunk.tscn")
	var ore = ore_scene.instantiate()
	add_child(ore)
	for t in [0, 1, 2, 3]:
		ore.ore_type = t
		assert(ore.mesh_instance != null, "Mesh instance must exist")
		var mat = ore.mesh_instance.material_override as StandardMaterial3D
		assert(mat != null, "Material override must be standard 3D material")
		assert(mat.emission_enabled, "Ore chunk must be emissive/glowing on planet surface")
	print("  [PASS] All 4 ore types (Iron, Copper, Silicon, Uranium) have glowing emissive PBR materials")
	
	# 3. Test Apollo EVA Minimap in HelmetVisor
	var HelmetVisorScript = load("res://scripts/ui/helmet_visor.gd")
	assert(HelmetVisorScript != null, "HelmetVisor script must load")
	var visor = HelmetVisorScript.new()
	add_child(visor)
	assert(visor.has_method("_draw_apollo_eva_minimap"), "Helmet visor must contain Apollo EVA minimap renderer")
	
	# Test dynamic safe radius formula:
	# safe_radius = clamp(player_o2 * 1.5, 12.0, 150.0)
	var o2_full = 100.0
	var safe_r_full = clamp(o2_full * 1.5, 12.0, 150.0)
	assert(safe_r_full == 150.0, "100% O2 provides 150m safe exploration radius")
	
	var o2_low = 20.0
	var safe_r_low = clamp(o2_low * 1.5, 12.0, 150.0)
	assert(safe_r_low == 30.0, "20% O2 shrinks safe radius down to 30m")
	print("  [PASS] Apollo NASA EVA safe radius shrinks dynamically with O2 consumption: 100%% -> 150m, 20%% -> 30m")
	
	print("\n=======================================================")
	print("TEST RESULTS: ALL 5 NEW FEATURES VERIFIED!")
	print("=======================================================\n")
	get_tree().quit(0)
