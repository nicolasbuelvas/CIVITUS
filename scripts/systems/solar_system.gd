extends RefCounted
class_name SolarSystem

static func generate_system(seed_val: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	var star_names = ["Kepler-452", "Aurelia Prime", "Gliese-667", "Sirius Beta", "Proxima Centauri", "Sol Invictus"]
	var system_name = star_names[rng.randi() % star_names.size()]
	
	var planets = []
	var planet_types = ["Terran", "Martian", "Acidic", "Cryo-Ice", "Volcanic", "Gas Giant"]
	var num_planets = 5 + (rng.randi() % 3)
	
	for i in range(num_planets):
		var dist_au = 0.4 + (i * 0.7) + (rng.randf() * 0.2)
		var angle = rng.randf() * TAU
		var x_coord = cos(angle) * dist_au * 149597.87 # In thousand km
		var y_coord = sin(angle) * dist_au * 149597.87
		var z_coord = (rng.randf() - 0.5) * 12000.0
		
		var p_type = planet_types[i % planet_types.size()]
		var p_name = "%s-%c" % [system_name, 65 + i]
		
		planets.append({
			"name": p_name,
			"index": i,
			"type": p_type,
			"orbit_au": dist_au,
			"coords": Vector3(x_coord, y_coord, z_coord),
			"coords_str": "[X: %.1f km, Y: %.1f km, Z: %.1f km]" % [x_coord, y_coord, z_coord],
			"hazard_level": i,
			"primary_ore": ["Iron", "Copper", "Silicon", "Titanium", "Uranium"][i % 5]
		})
		
	return {
		"system_name": system_name,
		"star_coords": Vector3.ZERO,
		"planets": planets
	}
