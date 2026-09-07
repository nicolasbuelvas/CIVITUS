extends RefCounted
class_name SolarSystem

static func generate_system(seed_val: int = -1) -> Dictionary:
	if seed_val < 0:
		seed_val = randi() % 1000000 + 1
		
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	var star_prefixes = [
		"Kepler", "Gliese", "Aurelia", "Vega", "Polaris", 
		"Sirius", "Trappist", "Altair", "Antares", "Proxima",
		"Nemesis", "Epsilon", "Deneb", "Cygnus", "Rigel"
	]
	var star_suffixes = ["Prime", "Majoris", "Secundus", "Australis", "Borealis", "VII", "X", "Centauri"]
	
	var pfx = star_prefixes[rng.randi() % star_prefixes.size()]
	var num = 100 + (rng.randi() % 899)
	var system_name = "%s-%d" % [pfx, num]
	if rng.randf() > 0.6:
		system_name = "%s %s" % [pfx, star_suffixes[rng.randi() % star_suffixes.size()]]
	
	var ra_hours = rng.randi_range(0, 23)
	var ra_mins = rng.randi_range(0, 59)
	var dec_deg = rng.randi_range(-80, 80)
	var dec_mins = rng.randi_range(0, 59)
	var distance_ly = rng.randf_range(4.2, 2800.0)
	
	var coords_str = "RA %02dh %02dm | DEC %+03d° %02dm | DIST: %.0f AL" % [ra_hours, ra_mins, dec_deg, dec_mins, distance_ly]
	
	var planets = []
	var num_planets = 6 # Guaranteed 6 planets so levels 0, 1, 2, 3, 4, 5 are available in each system
	
	for lvl in range(num_planets):
		var p_seed = seed_val + (lvl * 1337) + 42
		var p_rng = RandomNumberGenerator.new()
		p_rng.seed = p_seed
		
		var roman_numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]
		var planet_name = "%s %s" % [system_name, roman_numerals[lvl]]
		
		var dist_au = 0.35 + (lvl * 0.72) + (p_rng.randf() * 0.15)
		var angle = p_rng.randf() * TAU
		var x_km = cos(angle) * dist_au * 149597.87
		var y_km = sin(angle) * dist_au * 149597.87
		var z_km = (p_rng.randf() - 0.5) * 18000.0
		var p_coords_str = "[X: %.0f km, Y: %.0f km, Z: %.0f km]" % [x_km, y_km, z_km]
		
		var planet_data = _build_planet_by_level(lvl, planet_name, dist_au, Vector3(x_km, y_km, z_km), p_coords_str, p_seed, p_rng)
		planets.append(planet_data)
		
	return {
		"system_name": system_name,
		"system_seed": seed_val,
		"coords_str": coords_str,
		"distance_ly": distance_ly,
		"planets": planets
	}

static func _build_planet_by_level(lvl: int, p_name: String, orbit_au: float, coords: Vector3, coords_str: String, p_seed: int, rng: RandomNumberGenerator) -> Dictionary:
	var p: Dictionary = {
		"name": p_name,
		"index": lvl,
		"level": lvl,
		"orbit_au": orbit_au,
		"coords": coords,
		"coords_str": coords_str,
		"seed": p_seed,
		"is_locked": (lvl >= 4)
	}
	
	match lvl:
		0: # Nivel 0: Terranova (Tierra - Muy Seguro)
			p["type_label"] = "Rocoso Templado (Clase H)"
			p["description"] = "Mundo templado con hidrosfera estable, atmósfera respirable y baja actividad sísmica."
			p["gravity"] = 9.8
			p["temperature"] = 21.0
			p["atmosphere"] = 1.0
			p["radiation"] = 0.01
			p["has_oxygen"] = true
			p["primary_ore"] = "Hierro / Cobre"
			p["surface_color"] = Color(0.28, 0.58, 0.35)
			p["sky_color"] = Color(0.12, 0.22, 0.45)
			# Shader Params
			p["ocean_color"] = Color(0.04, 0.22, 0.55)
			p["shore_color"] = Color(0.12, 0.48, 0.72)
			p["beach_color"] = Color(0.82, 0.75, 0.52)
			p["land_color"] = Color(0.20, 0.55, 0.26)
			p["mountain_color"] = Color(0.48, 0.42, 0.36)
			p["peak_color"] = Color(0.92, 0.96, 1.0)
			p["atmosphere_color"] = Color(0.30, 0.70, 1.0)
			p["cloud_color"] = Color(1.0, 1.0, 1.0)
			p["emission_color"] = Color(0.0, 0.0, 0.0)
			p["emission_energy"] = 0.0
			p["water_threshold"] = 0.46
			p["mountain_threshold"] = 0.72
			p["peak_threshold"] = 0.88
			p["cloud_density"] = 0.52
			p["cloud_speed"] = 0.03
			p["has_rings"] = false
			p["noise_scale"] = 2.4
			
		1: # Nivel 1: Ares Prime (Marte - Moderado)
			p["type_label"] = "Desierto Rojo (Clase D)"
			p["description"] = "Corteza rica en óxido de hierro con valles fósiles y tormentas de polvo seco."
			p["gravity"] = 3.7
			p["temperature"] = -25.0
			p["atmosphere"] = 0.38
			p["radiation"] = 0.14
			p["has_oxygen"] = false
			p["primary_ore"] = "Hierro / Titanio"
			p["surface_color"] = Color(0.72, 0.34, 0.18)
			p["sky_color"] = Color(0.28, 0.14, 0.12)
			# Shader Params
			p["ocean_color"] = Color(0.45, 0.20, 0.12)
			p["shore_color"] = Color(0.60, 0.28, 0.15)
			p["beach_color"] = Color(0.75, 0.35, 0.18)
			p["land_color"] = Color(0.72, 0.34, 0.18)
			p["mountain_color"] = Color(0.50, 0.22, 0.12)
			p["peak_color"] = Color(0.85, 0.65, 0.55)
			p["atmosphere_color"] = Color(0.85, 0.45, 0.25)
			p["cloud_color"] = Color(0.80, 0.55, 0.40)
			p["emission_color"] = Color(0.0, 0.0, 0.0)
			p["emission_energy"] = 0.0
			p["water_threshold"] = 0.0 # No oceans
			p["mountain_threshold"] = 0.65
			p["peak_threshold"] = 0.85
			p["cloud_density"] = 0.25
			p["cloud_speed"] = 0.05
			p["has_rings"] = false
			p["noise_scale"] = 3.0
			
		2: # Nivel 2: Vesper Acid (Venus - Inseguro)
			p["type_label"] = "Sulfúrico Denso (Clase V)"
			p["description"] = "Superficie hiperbárica bajo nubes de ácido sulfúrico concentrado y niebla corrosiva."
			p["gravity"] = 8.9
			p["temperature"] = 145.0
			p["atmosphere"] = 2.4
			p["radiation"] = 0.28
			p["has_oxygen"] = false
			p["primary_ore"] = "Azufre / Silicio"
			p["surface_color"] = Color(0.68, 0.62, 0.15)
			p["sky_color"] = Color(0.35, 0.32, 0.08)
			# Shader Params
			p["ocean_color"] = Color(0.55, 0.52, 0.10)
			p["shore_color"] = Color(0.65, 0.58, 0.12)
			p["beach_color"] = Color(0.72, 0.68, 0.22)
			p["land_color"] = Color(0.48, 0.42, 0.18)
			p["mountain_color"] = Color(0.38, 0.32, 0.12)
			p["peak_color"] = Color(0.75, 0.70, 0.30)
			p["atmosphere_color"] = Color(0.85, 0.80, 0.25)
			p["cloud_color"] = Color(0.92, 0.88, 0.45)
			p["emission_color"] = Color(0.45, 0.40, 0.05)
			p["emission_energy"] = 0.15
			p["water_threshold"] = 0.38
			p["mountain_threshold"] = 0.68
			p["peak_threshold"] = 0.85
			p["cloud_density"] = 0.75
			p["cloud_speed"] = 0.07
			p["has_rings"] = false
			p["noise_scale"] = 2.6
			
		3: # Nivel 3: Boreas Cryo (Glaciar - Peligroso)
			p["type_label"] = "Criogénico Glaciar (Clase K)"
			p["description"] = "Desierto de nitrógeno sólido y glaciares de metano. Frío criogénico letal."
			p["gravity"] = 4.2
			p["temperature"] = -165.0
			p["atmosphere"] = 0.18
			p["radiation"] = 0.42
			p["has_oxygen"] = false
			p["primary_ore"] = "Hielo de Metano / Uranio"
			p["surface_color"] = Color(0.20, 0.48, 0.68)
			p["sky_color"] = Color(0.04, 0.08, 0.18)
			# Shader Params
			p["ocean_color"] = Color(0.06, 0.20, 0.42)
			p["shore_color"] = Color(0.15, 0.45, 0.65)
			p["beach_color"] = Color(0.60, 0.85, 0.95)
			p["land_color"] = Color(0.25, 0.55, 0.75)
			p["mountain_color"] = Color(0.40, 0.68, 0.88)
			p["peak_color"] = Color(0.95, 0.98, 1.0)
			p["atmosphere_color"] = Color(0.25, 0.75, 0.95)
			p["cloud_color"] = Color(0.85, 0.95, 1.0)
			p["emission_color"] = Color(0.0, 0.0, 0.0)
			p["emission_energy"] = 0.0
			p["water_threshold"] = 0.35
			p["mountain_threshold"] = 0.60
			p["peak_threshold"] = 0.78
			p["cloud_density"] = 0.35
			p["cloud_speed"] = 0.02
			p["has_rings"] = true
			p["ring_color"] = Color(0.70, 0.85, 0.98)
			p["noise_scale"] = 2.8
			
		4: # Nivel 4: Singularity Void (Extremo - Pro)
			p["type_label"] = "Abismo Singular (Clase X • PRO)"
			p["description"] = "Corteza de basalto ultradenso perforada por fracturas de plasma cuántico violeta."
			p["gravity"] = 21.5
			p["temperature"] = 380.0
			p["atmosphere"] = 3.8
			p["radiation"] = 0.88
			p["has_oxygen"] = false
			p["primary_ore"] = "Materia Oscura / Platino"
			p["surface_color"] = Color(0.22, 0.08, 0.35)
			p["sky_color"] = Color(0.08, 0.02, 0.14)
			# Shader Params (MUCHISIMO MEJOR: plasma rifts + aura violeta intensa)
			p["ocean_color"] = Color(0.10, 0.02, 0.18)
			p["shore_color"] = Color(0.28, 0.05, 0.42)
			p["beach_color"] = Color(0.45, 0.10, 0.65)
			p["land_color"] = Color(0.12, 0.08, 0.16)
			p["mountain_color"] = Color(0.22, 0.14, 0.28)
			p["peak_color"] = Color(0.48, 0.25, 0.62)
			p["atmosphere_color"] = Color(0.85, 0.25, 1.0)
			p["cloud_color"] = Color(0.65, 0.20, 0.85)
			p["emission_color"] = Color(0.95, 0.20, 1.0)
			p["emission_energy"] = 3.5 # Glowing intense violet plasma
			p["water_threshold"] = 0.40
			p["mountain_threshold"] = 0.68
			p["peak_threshold"] = 0.84
			p["cloud_density"] = 0.62
			p["cloud_speed"] = 0.08
			p["has_rings"] = true
			p["ring_color"] = Color(0.85, 0.35, 1.0)
			p["noise_scale"] = 3.5
			
		5: # Nivel 5: Tartarus Hell-Star (Mortal - Pro)
			p["type_label"] = "Infierno Ígneo (Clase S • PRO)"
			p["description"] = "Mares incandescentes de magma vivo bajo columnas volcánicas masivas y radiación extrema."
			p["gravity"] = 31.0
			p["temperature"] = 820.0
			p["atmosphere"] = 5.6
			p["radiation"] = 1.65
			p["has_oxygen"] = false
			p["primary_ore"] = "Uranio Hiperdenso / Antimateria"
			p["surface_color"] = Color(0.78, 0.18, 0.08)
			p["sky_color"] = Color(0.22, 0.02, 0.02)
			# Shader Params (MUCHISIMO MEJOR: incandescent glowing lava oceans & cracks)
			p["ocean_color"] = Color(1.0, 0.32, 0.02)
			p["shore_color"] = Color(1.0, 0.65, 0.05)
			p["beach_color"] = Color(0.95, 0.45, 0.05)
			p["land_color"] = Color(0.15, 0.08, 0.08)
			p["mountain_color"] = Color(0.25, 0.12, 0.10)
			p["peak_color"] = Color(0.45, 0.20, 0.15)
			p["atmosphere_color"] = Color(1.0, 0.45, 0.10)
			p["cloud_color"] = Color(0.35, 0.15, 0.12)
			p["emission_color"] = Color(1.0, 0.40, 0.05)
			p["emission_energy"] = 4.8 # Blazing lava emission
			p["water_threshold"] = 0.52
			p["mountain_threshold"] = 0.75
			p["peak_threshold"] = 0.90
			p["cloud_density"] = 0.58
			p["cloud_speed"] = 0.10
			p["has_rings"] = true
			p["ring_color"] = Color(1.0, 0.55, 0.15)
			p["noise_scale"] = 4.0
			
	return p
