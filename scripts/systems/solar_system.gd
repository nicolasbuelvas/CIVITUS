extends RefCounted
class_name SolarSystem

# Spectral classifications for procedural central stars
# Physical properties calibrated so habitable zone falls within 0.2 AU to 6.5 AU
const SPECTRAL_CLASSES: Dictionary = {
	"O": {
		"label": "Hipergigante Azul (Clase O)",
		"temp_min": 25000.0,
		"temp_max": 35000.0,
		"lum_min": 12.0,
		"lum_max": 18.0,
		"color": Color(0.65, 0.78, 1.0)
	},
	"B": {
		"label": "Gigante Blanco-Azulada (Clase B)",
		"temp_min": 10000.0,
		"temp_max": 25000.0,
		"lum_min": 6.0,
		"lum_max": 12.0,
		"color": Color(0.78, 0.86, 1.0)
	},
	"A": {
		"label": "Estrella Blanca (Clase A)",
		"temp_min": 7500.0,
		"temp_max": 10000.0,
		"lum_min": 3.0,
		"lum_max": 6.0,
		"color": Color(0.92, 0.95, 1.0)
	},
	"F": {
		"label": "Enana Blanco-Amarilla (Clase F)",
		"temp_min": 6000.0,
		"temp_max": 7500.0,
		"lum_min": 1.4,
		"lum_max": 3.0,
		"color": Color(1.0, 0.96, 0.88)
	},
	"G": {
		"label": "Enana Amarilla (Clase G)",
		"temp_min": 5200.0,
		"temp_max": 6000.0,
		"lum_min": 0.8,
		"lum_max": 1.4,
		"color": Color(1.0, 0.92, 0.70)
	},
	"K": {
		"label": "Enana Naranja (Clase K)",
		"temp_min": 3700.0,
		"temp_max": 5200.0,
		"lum_min": 0.25,
		"lum_max": 0.75,
		"color": Color(1.0, 0.76, 0.45)
	},
	"M": {
		"label": "Enana Roja (Clase M)",
		"temp_min": 2600.0,
		"temp_max": 3700.0,
		"lum_min": 0.06,
		"lum_max": 0.22,
		"color": Color(1.0, 0.48, 0.28)
	}
}

static func generate_system(seed_val: int = -1) -> Dictionary:
	if seed_val < 0:
		seed_val = randi() % 1000000 + 1
		
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# 1. Procedural Central Star Generation
	var star_prefixes = [
		"Kepler", "Gliese", "Aurelia", "Vega", "Polaris", 
		"Sirius", "Trappist", "Altair", "Antares", "Proxima",
		"Nemesis", "Epsilon", "Deneb", "Cygnus", "Rigel", "Sol"
	]
	var star_suffixes = ["Prime", "Majoris", "Secundus", "Australis", "Borealis", "VII", "X", "Centauri"]
	
	var pfx = star_prefixes[rng.randi() % star_prefixes.size()]
	var star_name = "%s-%d" % [pfx, 100 + (rng.randi() % 899)]
	if rng.randf() > 0.6:
		star_name = "%s %s" % [pfx, star_suffixes[rng.randi() % star_suffixes.size()]]
	var system_name = star_name
	
	# Spectral class selection
	var class_keys = ["M", "K", "G", "F", "A", "B", "O"]
	var weights = [25, 22, 20, 14, 10, 6, 3] # Realistic stellar population distribution
	var spectral_class = _pick_weighted(class_keys, weights, rng)
	var star_info = SPECTRAL_CLASSES[spectral_class]
	
	var star_temp = rng.randf_range(star_info["temp_min"], star_info["temp_max"])
	var star_lum = rng.randf_range(star_info["lum_min"], star_info["lum_max"])
	var star_color: Color = star_info["color"]
	
	# Calculated Goldilocks Habitable Zone [hz_inner_au, hz_outer_au]
	# Kopparapu / Kasting astrophysical formula
	var hz_inner_au = sqrt(star_lum / 1.1)
	var hz_outer_au = sqrt(star_lum / 0.53)
	
	var star_data: Dictionary = {
		"name": star_name,
		"spectral_class": spectral_class,
		"label": star_info["label"],
		"temperature": star_temp,
		"luminosity": star_lum,
		"color": star_color,
		"hz_inner_au": hz_inner_au,
		"hz_outer_au": hz_outer_au,
		"habitable_zone": [hz_inner_au, hz_outer_au]
	}
	
	# Celestial coordinates
	var ra_hours = rng.randi_range(0, 23)
	var ra_mins = rng.randi_range(0, 59)
	var dec_deg = rng.randi_range(-80, 80)
	var dec_mins = rng.randi_range(0, 59)
	var distance_ly = rng.randf_range(4.2, 2800.0)
	var coords_str = "RA %02dh %02dm | DEC %+03d° %02dm | DIST: %.0f AL" % [ra_hours, ra_mins, dec_deg, dec_mins, distance_ly]
	
	# 2. Variable number of planets: 4 to 8 procedural
	var num_planets = rng.randi_range(4, 8)
	
	# Determine target number of planets in the Habitable Zone:
	# Realistic astrobiological variance:
	# ~20% of systems: 0 planets in HZ (harsh barren systems)
	# ~50% of systems: 1 planet in HZ (standard single Earth-like system)
	# ~22% of systems: 2 planets in HZ (dual Goldilocks worlds, e.g. Earth & Mars analogues)
	# ~8% of systems:  3 planets in HZ (super-habitable resonance system like TRAPPIST-1)
	var hz_roll = rng.randf()
	var target_hz_planets: int = 1
	if hz_roll < 0.20:
		target_hz_planets = 0
	elif hz_roll < 0.70:
		target_hz_planets = 1
	elif hz_roll < 0.92:
		target_hz_planets = 2
	else:
		target_hz_planets = 3
	target_hz_planets = clampi(target_hz_planets, 0, num_planets - 1)
	
	# Generate strictly ordered orbits in [0.2, 6.5] AU
	var orbits = _generate_planet_orbits_variable_hz(num_planets, hz_inner_au, hz_outer_au, target_hz_planets, rng)
	
	# Find which planet indices reside in the HZ
	var hz_indices: Array[int] = []
	for idx in range(orbits.size()):
		var orb = orbits[idx]
		if orb >= hz_inner_au and orb <= hz_outer_au:
			hz_indices.append(idx)
			
	var planets: Array = []
	var roman_numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
	var habitable_count = 0
	
	for i in range(num_planets):
		var p_seed = seed_val + (i * 1337) + 42
		var p_rng = RandomNumberGenerator.new()
		p_rng.seed = p_seed
		
		var planet_name = "%s %s" % [system_name, roman_numerals[i]]
		var orbit_au = orbits[i]
		var is_hz = (orbit_au >= hz_inner_au and orbit_au <= hz_outer_au)
		var is_primary_hz = (hz_indices.size() > 0 and i == hz_indices[0])
		
		# Cartesian coordinates for starmap
		var angle = p_rng.randf() * TAU
		var x_km = cos(angle) * orbit_au * 149597.87
		var y_km = sin(angle) * orbit_au * 149597.87
		var z_km = (p_rng.randf() - 0.5) * 18000.0
		var p_coords_str = "[X: %.0f km, Y: %.0f km, Z: %.0f km]" % [x_km, y_km, z_km]
		
		var planet_data = _build_planet(
			i, planet_name, orbit_au, is_hz, is_primary_hz,
			star_lum, hz_inner_au, hz_outer_au,
			Vector3(x_km, y_km, z_km), p_coords_str, p_seed, p_rng
		)
		
		if planet_data["level"] == 0:
			habitable_count += 1
			
		planets.append(planet_data)
		
	var system_graph = {
		"star_temp": star_temp,
		"hz_inner": hz_inner_au,
		"hz_outer": hz_outer_au,
		"planet_count": planets.size(),
		"habitable_count": habitable_count
	}
	
	return {
		"system_name": system_name,
		"system_seed": seed_val,
		"coords_str": coords_str,
		"distance_ly": distance_ly,
		"star": star_data,
		"system_graph": system_graph,
		"planets": planets
	}

static func _generate_planet_orbits_variable_hz(
	count: int, hz_inner: float, hz_outer: float, target_hz_count: int, rng: RandomNumberGenerator
) -> Array[float]:
	var orbits: Array[float] = []
	var min_orbit = 0.22
	var max_orbit = 6.45
	
	if target_hz_count == 0:
		# No planets in HZ: all planets placed either before hz_inner or after hz_outer
		var before_room = maxf(0.0, hz_inner - 0.08 - min_orbit)
		var after_room = maxf(0.0, max_orbit - (hz_outer + 0.12))
		
		var count_before = 0
		if before_room > 0.3 and after_room > 0.5:
			count_before = clampi(int(round(float(count) * (before_room / (before_room + after_room)))), 1, count - 1)
		elif before_room > 0.3:
			count_before = count
		else:
			count_before = 0
		var count_after = count - count_before
		
		# Generate orbits before HZ
		if count_before > 0:
			var step_b = before_room / float(count_before + 1)
			var cur_b = min_orbit
			for i in range(count_before):
				cur_b += rng.randf_range(step_b * 0.7, step_b * 1.3)
				orbits.append(clampf(cur_b, min_orbit, hz_inner - 0.05))
				
		# Generate orbits after HZ
		if count_after > 0:
			var step_a = after_room / float(count_after + 1)
			var cur_a = hz_outer + 0.12
			for i in range(count_after):
				cur_a += rng.randf_range(step_a * 0.7, step_a * 1.3)
				orbits.append(clampf(cur_a, hz_outer + 0.06, max_orbit))
	else:
		# target_hz_count is 1, 2, or 3
		target_hz_count = clampi(target_hz_count, 1, min(count - 1, 3))
		var hz_step = (hz_outer - hz_inner) / float(target_hz_count + 1)
		var hz_orbits: Array[float] = []
		for h in range(target_hz_count):
			var h_dist = hz_inner + hz_step * float(h + 1) + rng.randf_range(-hz_step * 0.2, hz_step * 0.2)
			hz_orbits.append(clampf(h_dist, hz_inner + 0.03, hz_outer - 0.03))
			
		# Remaining planets outside HZ
		var remaining = count - target_hz_count
		var before_room = maxf(0.0, hz_inner - 0.08 - min_orbit)
		var after_room = maxf(0.0, max_orbit - (hz_outer + 0.12))
		
		var rem_before = 0
		if before_room > 0.35 and after_room > 0.5:
			rem_before = clampi(int(round(float(remaining) * (before_room / (before_room + after_room)))), 1, remaining - 1)
		elif before_room > 0.35:
			rem_before = remaining
		else:
			rem_before = 0
		var rem_after = remaining - rem_before
		
		# Inner planets
		if rem_before > 0:
			var step_b = before_room / float(rem_before + 1)
			var cur_b = min_orbit
			for i in range(rem_before):
				cur_b += rng.randf_range(step_b * 0.7, step_b * 1.3)
				orbits.append(clampf(cur_b, min_orbit, hz_inner - 0.05))
				
		# Habitable planets
		for h_orb in hz_orbits:
			orbits.append(h_orb)
			
		# Outer planets
		if rem_after > 0:
			var step_a = after_room / float(rem_after + 1)
			var cur_a = hz_outer + 0.10
			for i in range(rem_after):
				cur_a += rng.randf_range(step_a * 0.7, step_a * 1.3)
				orbits.append(clampf(cur_a, hz_outer + 0.05, max_orbit))

	orbits.sort()
	# Monotonic safety enforcement with minimum 0.18 AU separation
	for i in range(orbits.size()):
		orbits[i] = clampf(orbits[i], 0.20, 6.50)
		if i > 0 and orbits[i] <= orbits[i - 1]:
			orbits[i] = clampf(orbits[i - 1] + 0.18, 0.20, 6.50)
			
	return orbits

static func _generate_planet_orbits(count: int, hz_inner: float, hz_outer: float, rng: RandomNumberGenerator) -> Array[float]:
	var orbits: Array[float] = []
	
	# Determine target habitable orbit inside Goldilocks zone
	var hz_mid = (hz_inner + hz_outer) * 0.5
	var hz_target = rng.randf_range(hz_inner + (hz_outer - hz_inner) * 0.15, hz_outer - (hz_outer - hz_inner) * 0.15)
	hz_target = clampf(hz_target, 0.22, 6.4)
	
	# Determine how many planets fit inside and outside the HZ
	var min_orbit = 0.22
	var max_orbit = 6.45
	
	# Choose which slot gets the primary habitable planet
	# Inner slot for hot stars (where HZ is far out), middle/outer slot for cool stars
	var hz_slot = clampi(int(round((hz_target - min_orbit) / (max_orbit - min_orbit) * (count - 1))), 0, count - 1)
	
	# Generate monotonically increasing orbits
	var cur_dist = min_orbit
	for i in range(count):
		if i == hz_slot:
			cur_dist = maxf(cur_dist, hz_target)
			orbits.append(clampf(cur_dist, 0.2, 6.5))
			cur_dist += rng.randf_range(0.35, 0.75)
		elif i < hz_slot:
			var remaining_slots_before = hz_slot - i
			var room = (hz_target - 0.25) - cur_dist
			var step = room / float(remaining_slots_before + 1)
			cur_dist += rng.randf_range(step * 0.7, step * 1.3)
			orbits.append(clampf(cur_dist, 0.2, 6.5))
		else:
			var remaining_slots_after = (count - 1) - i
			var room_after = max_orbit - cur_dist
			var step_after = room_after / float(remaining_slots_after + 1)
			cur_dist += rng.randf_range(maxf(0.3, step_after * 0.7), maxf(0.5, step_after * 1.3))
			orbits.append(clampf(cur_dist, 0.2, 6.5))
			
	orbits.sort()
	# Final check: enforce strictly bounded in [0.2, 6.5]
	for idx in range(orbits.size()):
		orbits[idx] = clampf(orbits[idx], 0.2, 6.5)
		
	return orbits

static func _build_planet(
	idx: int, p_name: String, orbit_au: float, is_hz: bool, is_primary_hz: bool,
	star_lum: float, hz_inner: float, hz_outer: float,
	coords: Vector3, coords_str: String, p_seed: int, rng: RandomNumberGenerator
) -> Dictionary:
	
	# 1. Equilibrium temperature from star luminosity and distance (inverse square law)
	# T_eq_K = 278 * (L / d^2)^0.25
	var flux = star_lum / (orbit_au * orbit_au)
	var t_eq_k = 278.0 * pow(flux, 0.25)
	
	# 2. Physical atmosphere & water determination
	var has_atmosphere: bool = true
	var atmosphere: float = 1.0
	var has_oxygen: bool = false
	var water_status: String = "Seco / Desolado"
	var gravity_g: float = 1.0
	var radiation: float = 0.05
	var greenhouse_k: float = 0.0
	var is_molten: bool = false
	var is_singularity: bool = false
	
	if is_primary_hz:
		# Primary habitable candidate in Goldilocks zone
		has_atmosphere = true
		atmosphere = round(rng.randf_range(0.92, 1.18) * 100.0) / 100.0
		has_oxygen = true
		water_status = "Líquida" # ONLY in habitable zone with oxygen/atmosphere
		greenhouse_k = 33.0
		gravity_g = round(rng.randf_range(0.85, 1.15) * 100.0) / 100.0
		radiation = round(rng.randf_range(0.01, 0.04) * 100.0) / 100.0
	elif is_hz:
		# Secondary body in HZ (e.g. airless moon or arid desert)
		if rng.randf() > 0.5:
			has_atmosphere = false # Airless vacuum world in HZ (Moon-like)
			atmosphere = 0.0
			has_oxygen = false
			water_status = "Seco / Desolado"
			greenhouse_k = 0.0
			gravity_g = round(rng.randf_range(0.20, 0.45) * 100.0) / 100.0
			radiation = round(rng.randf_range(0.15, 0.35) * 100.0) / 100.0
		else:
			has_atmosphere = true
			atmosphere = round(rng.randf_range(0.30, 0.55) * 100.0) / 100.0
			has_oxygen = false
			water_status = "Seco / Desolado"
			greenhouse_k = 12.0
			gravity_g = round(rng.randf_range(0.35, 0.70) * 100.0) / 100.0
			radiation = round(rng.randf_range(0.08, 0.20) * 100.0) / 100.0
	else:
		# Outside habitable zone
		if orbit_au < hz_inner:
			# Closer to star than habitable zone
			if orbit_au < 0.45 or t_eq_k > 440.0:
				# Scorching close to star: Tartarus molten lava or airless vacuum
				if rng.randf() > 0.4:
					# Tartarus / Hell-Star (Level 5)
					is_molten = true
					has_atmosphere = true
					atmosphere = round(rng.randf_range(4.2, 5.8) * 100.0) / 100.0
					has_oxygen = false
					water_status = "Lava Fundida"
					greenhouse_k = 240.0
					gravity_g = round(rng.randf_range(2.5, 3.5) * 100.0) / 100.0
					radiation = round(rng.randf_range(1.2, 1.8) * 100.0) / 100.0
				else:
					# Airless vacuum world (Mercury-like, Level 1)
					has_atmosphere = false
					atmosphere = 0.0
					has_oxygen = false
					water_status = "Seco / Desolado"
					greenhouse_k = 0.0
					gravity_g = round(rng.randf_range(0.25, 0.60) * 100.0) / 100.0
					radiation = round(rng.randf_range(0.25, 0.50) * 100.0) / 100.0
			else:
				# Intermediate inner zone: Toxic Venus-like (Level 2) or Desert (Level 1)
				if rng.randf() > 0.35:
					# Toxic runaway greenhouse (Level 2)
					has_atmosphere = true
					atmosphere = round(rng.randf_range(2.0, 3.2) * 100.0) / 100.0
					has_oxygen = false
					water_status = "Vapor Tóxico"
					greenhouse_k = 180.0
					gravity_g = round(rng.randf_range(0.85, 1.20) * 100.0) / 100.0
					radiation = round(rng.randf_range(0.20, 0.35) * 100.0) / 100.0
				else:
					has_atmosphere = true
					atmosphere = round(rng.randf_range(0.35, 0.60) * 100.0) / 100.0
					has_oxygen = false
					water_status = "Seco / Desolado"
					greenhouse_k = 15.0
					gravity_g = round(rng.randf_range(0.35, 0.70) * 100.0) / 100.0
					radiation = round(rng.randf_range(0.10, 0.25) * 100.0) / 100.0
		else:
			# Far outer planets (orbit_au > hz_outer)
			if (idx == 4 or idx == 6 or rng.randf() < 0.25) and not is_singularity:
				# Singularity / Void Pro candidate (Level 4)
				is_singularity = true
				has_atmosphere = true
				atmosphere = round(rng.randf_range(3.2, 4.4) * 100.0) / 100.0
				has_oxygen = false
				water_status = "Seco / Desolado"
				greenhouse_k = 90.0
				gravity_g = round(rng.randf_range(2.35, 3.20) * 100.0) / 100.0
				radiation = round(rng.randf_range(0.85, 1.25) * 100.0) / 100.0
			else:
				# Cryogenic Glacial / Ice giant moons (Level 3)
				var airless_ice = (rng.randf() < 0.25)
				if airless_ice:
					has_atmosphere = false
					atmosphere = 0.0
					has_oxygen = false
					water_status = "Hielo Criogénico"
					greenhouse_k = 0.0
					gravity_g = round(rng.randf_range(0.25, 0.50) * 100.0) / 100.0
					radiation = round(rng.randf_range(0.30, 0.55) * 100.0) / 100.0
				else:
					has_atmosphere = true
					atmosphere = round(rng.randf_range(0.15, 0.38) * 100.0) / 100.0
					has_oxygen = false
					water_status = "Hielo Criogénico"
					greenhouse_k = 6.0
					gravity_g = round(rng.randf_range(0.40, 0.85) * 100.0) / 100.0
					radiation = round(rng.randf_range(0.30, 0.50) * 100.0) / 100.0

	# Calculate final temperature in Celsius from equilibrium + greenhouse effect
	var temp_k = t_eq_k + greenhouse_k
	var temperature = round(temp_k - 273.15)
	
	# Gravity bounded strictly between 0.2G and 3.5G
	gravity_g = clampf(gravity_g, 0.20, 3.50)
	var gravity_ms2 = round(gravity_g * 9.8 * 10.0) / 10.0
	
	# Dynamically determine level (0 to 5)
	var temp_dict = {
		"is_in_habitable_zone": is_hz,
		"has_atmosphere": has_atmosphere,
		"has_oxygen": has_oxygen,
		"water_status": water_status,
		"temperature": temperature,
		"gravity_g": gravity_g,
		"gravity": gravity_ms2,
		"radiation": radiation,
		"atmosphere": atmosphere,
		"is_molten": is_molten,
		"is_singularity": is_singularity
	}
	var level = determine_level(temp_dict)
	
	var p: Dictionary = {
		"name": p_name,
		"index": idx,
		"level": level,
		"orbit_au": orbit_au,
		"is_in_habitable_zone": is_hz,
		"has_atmosphere": has_atmosphere,
		"atmosphere": atmosphere,
		"has_oxygen": has_oxygen,
		"water_status": water_status,
		"temperature": temperature,
		"gravity": gravity_ms2,
		"gravity_g": gravity_g,
		"radiation": radiation,
		"coords": coords,
		"coords_str": coords_str,
		"seed": p_seed,
		"is_locked": (level >= 4),
		"is_molten": is_molten,
		"is_singularity": is_singularity
	}
	
	# Apply visual theme, descriptions, and shader parameters by dynamically computed level
	_apply_level_visuals(p, level, rng)
	
	# 4. Airless Vacuum Physics rule enforcement:
	# When has_atmosphere == false: atmosphere_color = Color.BLACK, cloud_density = 0.0, sky_color = Color.BLACK
	if not has_atmosphere:
		p["atmosphere"] = 0.0
		p["atmosphere_color"] = Color.BLACK
		p["cloud_density"] = 0.0
		p["cloud_color"] = Color.BLACK
		p["sky_color"] = Color.BLACK
		p["has_oxygen"] = false
		if level == 1:
			p["type_label"] = "Mundo Estéril al Vacío (Clase D)"
			p["type"] = "Vacío / Rocoso"
			p["description"] = "Cuerpo rocoso sin atmósfera sometido al vacío espacial directo. Superficie craterizada y silente."
			p["water_threshold"] = 0.0
			p["surface_color"] = Color(0.42, 0.42, 0.45)
			p["land_color"] = Color(0.38, 0.38, 0.40)
			p["mountain_color"] = Color(0.28, 0.28, 0.30)
			p["peak_color"] = Color(0.60, 0.60, 0.65)
			p["emission_color"] = Color.BLACK
			p["emission_energy"] = 0.0
			
	# Telemetry graph dictionary (normalized 0.0 to 1.0)
	p["telemetry_graph"] = calculate_telemetry_graph(p)
	
	return p

# Determine level (0 to 5) dynamically based on physics and environment
static func determine_level(p: Dictionary) -> int:
	var in_hz: bool = p.get("is_in_habitable_zone", false)
	var has_atmo: bool = p.get("has_atmosphere", true)
	var has_oxy: bool = p.get("has_oxygen", false)
	var water_stat: String = p.get("water_status", "")
	var temp: float = p.get("temperature", 0.0)
	var grav_g: float = p.get("gravity_g", p.get("gravity", 9.8) / 9.8)
	var rad: float = p.get("radiation", 0.0)
	var is_molten: bool = p.get("is_molten", false) or water_stat == "Lava Fundida"
	var is_singularity: bool = p.get("is_singularity", false)

	# Level 0: Habitable / Earth-like (ONLY when in habitable zone with oxygen & water)
	if in_hz and has_atmo and has_oxy and water_stat == "Líquida":
		return 0

	# Level 5: Tartarus / Hell-Star Pro (scorching molten lava close to star)
	if is_molten or temp >= 320.0 or water_stat == "Lava Fundida":
		return 5

	# Level 4: Singularity / Void Pro (extreme gravity/plasma)
	if is_singularity or grav_g >= 2.25 or rad >= 0.80:
		return 4

	# Level 3: Cryogenic Glacial / Ice giant moons
	if water_stat == "Hielo Criogénico" or temp <= -50.0:
		return 3

	# Level 2: Toxic / Acidic / Dense greenhouse (e.g. Venus-like)
	if water_stat == "Vapor Tóxico" or (has_atmo and temp >= 60.0 and p.get("atmosphere", 1.0) >= 1.8):
		return 2

	# Level 1: Desertic / Thin atmosphere (e.g. Mars-like or vacuum)
	return 1

# Telemetry metrics dictionary for clean graphical UI (normalized 0.0 to 1.0 floats)
static func calculate_telemetry_graph(p: Dictionary) -> Dictionary:
	var temp: float = p.get("temperature", 20.0)
	var atmo: float = p.get("atmosphere", 1.0)
	var rad: float = p.get("radiation", 0.05)
	var lvl: int = p.get("level", 0)
	var has_atmo: bool = p.get("has_atmosphere", true)
	var has_oxy: bool = p.get("has_oxygen", false)
	var water_stat: String = p.get("water_status", "")

	# 1. Temperature: normalized from -200°C to +800°C (0.0 to 1.0)
	var norm_temp = clampf((temp - (-200.0)) / (800.0 - (-200.0)), 0.0, 1.0)

	# 2. Atmosphere: normalized 0.0 to 1.0 (from 0.0 to ~5.0 atm)
	var norm_atmo = 0.0
	if has_atmo:
		norm_atmo = clampf(atmo / 4.5, 0.0, 1.0)

	# 3. Radiation: normalized 0.0 to 1.0 (from 0.0 to 2.0 rad/s)
	var norm_rad = clampf(rad / 2.0, 0.0, 1.0)

	# 4. Habitability: 0.0 to 1.0
	var habitability: float = 0.0
	if lvl == 0 and has_oxy and water_stat == "Líquida":
		var temp_factor = 1.0 - clampf(abs(temp - 21.0) / 40.0, 0.0, 0.4)
		var atmo_factor = 1.0 - clampf(abs(atmo - 1.0) / 1.0, 0.0, 0.3)
		habitability = clampf(0.92 * temp_factor * atmo_factor, 0.75, 1.0)
	elif lvl == 1:
		habitability = 0.15 if not has_atmo else 0.40
	elif lvl == 2:
		habitability = 0.18
	elif lvl == 3:
		habitability = 0.10
	elif lvl == 4:
		habitability = 0.03
	elif lvl == 5:
		habitability = 0.0
	habitability = clampf(habitability, 0.0, 1.0)

	# 5. Danger: 0.0 to 1.0
	var danger: float = 0.0
	match lvl:
		0: danger = 0.08
		1: danger = 0.35 if not has_atmo else 0.28
		2: danger = 0.58
		3: danger = 0.72
		4: danger = 0.90
		5: danger = 0.98
		_: danger = 0.50
	danger = clampf(danger, 0.0, 1.0)

	return {
		"habitability": habitability,
		"atmosphere": norm_atmo,
		"temperature": norm_temp,
		"radiation": norm_rad,
		"danger": danger
	}

static func _apply_level_visuals(p: Dictionary, lvl: int, rng: RandomNumberGenerator) -> void:
	match lvl:
		0: # Level 0: Habitable / Earth-like (only in HZ with oxygen and liquid water)
			p["type_label"] = "Rocoso Templado (Clase H)"
			p["type"] = "Habitable"
			p["description"] = "Mundo templado con hidrosfera líquida estable, atmósfera respirable y baja actividad sísmica."
			p["primary_ore"] = "Hierro / Cobre"
			p["surface_color"] = Color(0.28, 0.58, 0.35)
			p["sky_color"] = Color(0.12, 0.22, 0.45)
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
			
		1: # Level 1: Desertic / Thin atmosphere (e.g. Mars-like)
			p["type_label"] = "Desierto Rojo (Clase D)"
			p["type"] = "Desértico"
			p["description"] = "Corteza rica en óxido de hierro con valles fósiles, atmósfera tenue y tormentas de polvo seco."
			p["primary_ore"] = "Hierro / Titanio"
			p["surface_color"] = Color(0.72, 0.34, 0.18)
			p["sky_color"] = Color(0.28, 0.14, 0.12)
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
			p["water_threshold"] = 0.0
			p["mountain_threshold"] = 0.65
			p["peak_threshold"] = 0.85
			p["cloud_density"] = 0.25
			p["cloud_speed"] = 0.05
			p["has_rings"] = false
			p["noise_scale"] = 3.0
			
		2: # Level 2: Toxic / Acidic / Dense greenhouse (e.g. Venus-like)
			p["type_label"] = "Sulfúrico Denso (Clase V)"
			p["type"] = "Tóxico"
			p["description"] = "Superficie hiperbárica bajo nubes de ácido sulfúrico concentrado y niebla corrosiva."
			p["primary_ore"] = "Azufre / Silicio"
			p["surface_color"] = Color(0.68, 0.62, 0.15)
			p["sky_color"] = Color(0.35, 0.32, 0.08)
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
			
		3: # Level 3: Cryogenic Glacial / Ice giant moons
			p["type_label"] = "Criogénico Glaciar (Clase K)"
			p["type"] = "Glaciar"
			p["description"] = "Desierto de nitrógeno sólido y glaciares de metano. Frío criogénico letal."
			p["primary_ore"] = "Hielo de Metano / Uranio"
			p["surface_color"] = Color(0.20, 0.48, 0.68)
			p["sky_color"] = Color(0.04, 0.08, 0.18)
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
			
		4: # Level 4: Singularity / Void Pro (extreme gravity/plasma)
			p["type_label"] = "Abismo Singular (Clase X • PRO)"
			p["type"] = "Singularidad"
			p["description"] = "Corteza de basalto ultradenso perforada por fracturas de plasma cuántico violeta."
			p["primary_ore"] = "Materia Oscura / Platino"
			p["surface_color"] = Color(0.22, 0.08, 0.35)
			p["sky_color"] = Color(0.08, 0.02, 0.14)
			p["ocean_color"] = Color(0.10, 0.02, 0.18)
			p["shore_color"] = Color(0.28, 0.05, 0.42)
			p["beach_color"] = Color(0.45, 0.10, 0.65)
			p["land_color"] = Color(0.12, 0.08, 0.16)
			p["mountain_color"] = Color(0.22, 0.14, 0.28)
			p["peak_color"] = Color(0.48, 0.25, 0.62)
			p["atmosphere_color"] = Color(0.85, 0.25, 1.0)
			p["cloud_color"] = Color(0.65, 0.20, 0.85)
			p["emission_color"] = Color(0.95, 0.20, 1.0) # glowing plasma emission
			p["emission_energy"] = 3.5
			p["water_threshold"] = 0.40
			p["mountain_threshold"] = 0.68
			p["peak_threshold"] = 0.84
			p["cloud_density"] = 0.62
			p["cloud_speed"] = 0.08
			p["has_rings"] = true
			p["ring_color"] = Color(0.85, 0.35, 1.0)
			p["noise_scale"] = 3.5
			
		5: # Level 5: Tartarus / Hell-Star Pro (scorching molten lava close to star)
			p["type_label"] = "Infierno Ígneo (Clase S • PRO)"
			p["type"] = "Ígneo"
			p["description"] = "Mares incandescentes de magma vivo bajo columnas volcánicas masivas y radiación extrema."
			p["primary_ore"] = "Uranio Hiperdenso / Antimateria"
			p["surface_color"] = Color(0.78, 0.18, 0.08)
			p["sky_color"] = Color(0.22, 0.02, 0.02)
			p["ocean_color"] = Color(1.0, 0.32, 0.02) # glowing lava ocean
			p["shore_color"] = Color(1.0, 0.65, 0.05)
			p["beach_color"] = Color(0.95, 0.45, 0.05)
			p["land_color"] = Color(0.15, 0.08, 0.08)
			p["mountain_color"] = Color(0.25, 0.12, 0.10)
			p["peak_color"] = Color(0.45, 0.20, 0.15)
			p["atmosphere_color"] = Color(1.0, 0.45, 0.10)
			p["cloud_color"] = Color(0.35, 0.15, 0.12)
			p["emission_color"] = Color(1.0, 0.40, 0.05) # glowing lava emission
			p["emission_energy"] = 4.8
			p["water_threshold"] = 0.52
			p["mountain_threshold"] = 0.75
			p["peak_threshold"] = 0.90
			p["cloud_density"] = 0.58
			p["cloud_speed"] = 0.10
			p["has_rings"] = true
			p["ring_color"] = Color(1.0, 0.55, 0.15)
			p["noise_scale"] = 4.0

static func _pick_weighted(items: Array, weights: Array, rng: RandomNumberGenerator) -> Variant:
	var total = 0
	for w in weights:
		total += w
	var r = rng.randi_range(0, total - 1)
	var accum = 0
	for i in range(items.size()):
		accum += weights[i]
		if r < accum:
			return items[i]
	return items[items.size() - 1]
