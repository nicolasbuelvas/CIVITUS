extends RefCounted
class_name LandingFXProfile

# ==============================================================================
# LandingFXProfile
# Centralized astrophysical and chemical profile generator for:
# 1. Spaceship rocket engine nozzle thermal glow & cooldown
# 2. Supersonic exhaust plume shader parameters & atmospheric expansion
# 3. Engine exhaust trailing fire and vapor particles
# 4. Realistic ground interaction: radial flame deflection, billowing smoke,
#    surface dust shockwave, and glowing crater scorch marks per planet biome.
# ==============================================================================

static func get_profile(planet_params: Dictionary = {}) -> Dictionary:
	var lvl: int = int(planet_params.get("level", 0))
	var p_type: String = str(planet_params.get("type", ""))
	var has_atmo: bool = bool(planet_params.get("has_atmosphere", true))
	var temp: float = float(planet_params.get("temperature", 20.0))

	# Profile dictionary with full defaults
	var p: Dictionary = {
		"biome_name": "Habitable",
		"engine_core_color": Color(1.0, 0.98, 0.92, 1.0),
		"engine_flame_color": Color(1.0, 0.50, 0.08, 0.92),
		"engine_rim_color": Color(0.20, 0.55, 1.0, 0.55),
		"engine_light_color": Color(1.0, 0.62, 0.20, 1.0),
		"shock_diamond_freq": 18.0,
		"flame_speed": 28.0,
		"expansion_power": 1.3,
		"nozzle_heat_color": Color(1.0, 0.45, 0.08, 1.0),
		"engine_sparks_color": Color(1.0, 0.75, 0.25, 1.0),
		"engine_smoke_color": Color(0.55, 0.52, 0.50, 0.25),
		
		# Ground interaction
		"ground_fire_color": Color(1.0, 0.55, 0.10, 0.88),
		"ground_smoke_color": Color(0.38, 0.35, 0.32, 0.48),
		"ground_dust_color": Color(0.68, 0.58, 0.44, 0.65),
		"ground_spark_color": Color(1.0, 0.68, 0.18, 1.0),
		"crater_center_color": Color(0.08, 0.07, 0.06),
		"crater_edge_color": Color(0.22, 0.18, 0.14),
		"crater_ember_color": Color(1.0, 0.38, 0.05),
		"ground_smoke_buoyancy": Vector3(0, 0.75, 0),
		"ground_smoke_lifetime": 2.6,
		"ground_smoke_scale_max": 5.2,
		"ground_fire_scale_max": 3.4,
		"is_cryo_steam": false,
		"is_vacuum": false
	}

	if not has_atmo or p_type.contains("Luna") or p_type.contains("Barren") or p_type.contains("Vacio"):
		# Vacuum hard-dispersion plume (underexpanded bell, ballistic regolith)
		p["biome_name"] = "Vacio / Lunar"
		p["is_vacuum"] = true
		p["engine_core_color"] = Color(1.0, 0.96, 0.88, 1.0)
		p["engine_flame_color"] = Color(1.0, 0.58, 0.18, 0.80)
		p["engine_rim_color"] = Color(0.50, 0.70, 1.0, 0.35)
		p["engine_light_color"] = Color(1.0, 0.70, 0.30, 1.0)
		p["shock_diamond_freq"] = 8.0 # No atmospheric boundary to form tight shock diamonds
		p["flame_speed"] = 28.0
		p["expansion_power"] = 0.75 # Wide bell expansion in vacuum
		p["nozzle_heat_color"] = Color(1.0, 0.42, 0.08, 1.0)
		p["engine_sparks_color"] = Color(1.0, 0.70, 0.30, 0.9)
		p["engine_smoke_color"] = Color(0.60, 0.60, 0.65, 0.15)
		p["ground_fire_color"] = Color(1.0, 0.60, 0.18, 0.75)
		p["ground_smoke_color"] = Color(0.65, 0.65, 0.68, 0.35)
		p["ground_dust_color"] = Color(0.72, 0.72, 0.75, 0.60)
		p["ground_spark_color"] = Color(1.0, 0.70, 0.30, 0.9)
		p["crater_center_color"] = Color(0.08, 0.08, 0.09)
		p["crater_edge_color"] = Color(0.24, 0.24, 0.26)
		p["crater_ember_color"] = Color(1.0, 0.45, 0.10)
		p["ground_smoke_buoyancy"] = Vector3(0, 0.05, 0)
		p["ground_smoke_lifetime"] = 1.4
		p["ground_smoke_scale_max"] = 4.2
	elif p_type.contains("Oceán") or p_type.contains("Ocean") or bool(planet_params.get("is_ocean_world", false)):
		var chem: String = str(planet_params.get("ocean_chemical", ""))
		if chem == "magma" or lvl == 5 or planet_params.get("is_molten", false):
			# 100% Magma Ocean World: Supersonic retro-thruster impinges on molten lava sea
			p["biome_name"] = "Océano de Magma (Clase S)"
			p["engine_core_color"] = Color(1.0, 0.95, 0.85, 1.0)
			p["engine_flame_color"] = Color(1.0, 0.28, 0.04, 0.95)
			p["engine_rim_color"] = Color(1.0, 0.65, 0.10, 0.70)
			p["engine_light_color"] = Color(1.0, 0.40, 0.08, 1.0)
			p["shock_diamond_freq"] = 26.0
			p["flame_speed"] = 34.0
			p["expansion_power"] = 1.70
			p["nozzle_heat_color"] = Color(1.0, 0.50, 0.10, 1.0)
			p["engine_sparks_color"] = Color(1.0, 0.45, 0.05, 1.0)
			p["engine_smoke_color"] = Color(0.20, 0.12, 0.10, 0.60)
			p["ground_fire_color"] = Color(1.0, 0.32, 0.04, 0.95)
			p["ground_smoke_color"] = Color(0.12, 0.08, 0.06, 0.85) # Pitch black volcanic ash
			p["ground_dust_color"] = Color(0.35, 0.15, 0.10, 0.90) # Incandescent lava splatter
			p["ground_spark_color"] = Color(1.0, 0.55, 0.10, 1.0)
			p["crater_center_color"] = Color(0.15, 0.04, 0.02)
			p["crater_edge_color"] = Color(0.40, 0.12, 0.05)
			p["crater_ember_color"] = Color(1.0, 0.50, 0.05)
			p["ground_smoke_buoyancy"] = Vector3(0, 1.25, 0)
			p["ground_smoke_lifetime"] = 3.2
			p["ground_smoke_scale_max"] = 6.2
		elif chem == "sulfuric_acid" or lvl == 2:
			# 100% Sulfuric Acid Ocean World: Superheated acid vapor & chemical foam
			p["biome_name"] = "Océano Ácido (Clase V)"
			p["engine_core_color"] = Color(0.92, 1.0, 0.70, 1.0)
			p["engine_flame_color"] = Color(0.50, 0.90, 0.15, 0.92)
			p["engine_rim_color"] = Color(0.85, 0.95, 0.20, 0.65)
			p["engine_light_color"] = Color(0.68, 0.95, 0.20, 1.0)
			p["shock_diamond_freq"] = 24.0
			p["flame_speed"] = 32.0
			p["expansion_power"] = 1.60
			p["nozzle_heat_color"] = Color(0.85, 0.95, 0.20, 1.0)
			p["engine_sparks_color"] = Color(0.80, 1.0, 0.25, 1.0)
			p["engine_smoke_color"] = Color(0.55, 0.68, 0.18, 0.40)
			p["ground_fire_color"] = Color(0.55, 0.92, 0.18, 0.88)
			p["ground_smoke_color"] = Color(0.55, 0.65, 0.15, 0.70) # Corrosive sulfur smog
			p["ground_dust_color"] = Color(0.60, 0.85, 0.20, 0.80) # Acid spray
			p["ground_spark_color"] = Color(0.85, 1.0, 0.25, 1.0)
			p["crater_center_color"] = Color(0.08, 0.10, 0.04)
			p["crater_edge_color"] = Color(0.28, 0.32, 0.08)
			p["crater_ember_color"] = Color(0.75, 0.95, 0.15)
			p["ground_smoke_buoyancy"] = Vector3(0, 0.35, 0)
			p["ground_smoke_lifetime"] = 3.0
			p["ground_smoke_scale_max"] = 5.2
		elif chem == "methane" or lvl == 3:
			# 100% Cryogenic Methane Ocean World: Instant boiling sublimation & frost plume
			p["biome_name"] = "Océano de Metano (Clase K)"
			p["is_cryo_steam"] = true
			p["engine_core_color"] = Color(0.92, 0.98, 1.0, 1.0)
			p["engine_flame_color"] = Color(0.20, 0.72, 1.0, 0.92)
			p["engine_rim_color"] = Color(0.45, 0.35, 1.0, 0.60)
			p["engine_light_color"] = Color(0.30, 0.80, 1.0, 1.0)
			p["shock_diamond_freq"] = 20.0
			p["flame_speed"] = 30.0
			p["expansion_power"] = 1.25
			p["nozzle_heat_color"] = Color(0.40, 0.85, 1.0, 1.0)
			p["engine_sparks_color"] = Color(0.55, 0.90, 1.0, 1.0)
			p["engine_smoke_color"] = Color(0.85, 0.94, 1.0, 0.40)
			p["ground_fire_color"] = Color(0.25, 0.80, 1.0, 0.88)
			p["ground_smoke_color"] = Color(0.88, 0.95, 1.0, 0.78) # Boiling methane cyan/white cloud
			p["ground_dust_color"] = Color(0.80, 0.95, 1.0, 0.85) # Cryo-methane frost crystals
			p["ground_spark_color"] = Color(0.60, 0.90, 1.0, 1.0)
			p["crater_center_color"] = Color(0.04, 0.08, 0.14)
			p["crater_edge_color"] = Color(0.12, 0.30, 0.45)
			p["crater_ember_color"] = Color(0.45, 0.85, 1.0)
			p["ground_smoke_buoyancy"] = Vector3(0, 1.20, 0)
			p["ground_smoke_lifetime"] = 2.8
			p["ground_smoke_scale_max"] = 6.0
		elif chem == "hycean":
			# 100% Hycean Ocean World: Dense warm hydrogen greenhouse, ammonia-water steam
			p["biome_name"] = "Super-Océano Hiceánico (Clase Y)"
			p["engine_core_color"] = Color(0.95, 0.98, 1.0, 1.0)
			p["engine_flame_color"] = Color(0.40, 0.60, 1.0, 0.92)
			p["engine_rim_color"] = Color(0.65, 0.35, 1.0, 0.60)
			p["engine_light_color"] = Color(0.45, 0.65, 1.0, 1.0)
			p["shock_diamond_freq"] = 22.0
			p["flame_speed"] = 30.0
			p["expansion_power"] = 1.45
			p["nozzle_heat_color"] = Color(0.65, 0.60, 1.0, 1.0)
			p["engine_sparks_color"] = Color(0.70, 0.85, 1.0, 1.0)
			p["engine_smoke_color"] = Color(0.78, 0.85, 0.98, 0.45)
			p["ground_fire_color"] = Color(0.45, 0.65, 1.0, 0.88)
			p["ground_smoke_color"] = Color(0.75, 0.82, 0.95, 0.72) # Ammonia-water steam
			p["ground_dust_color"] = Color(0.60, 0.80, 0.95, 0.75) # Warm chemical mist
			p["ground_spark_color"] = Color(0.75, 0.88, 1.0, 1.0)
			p["crater_center_color"] = Color(0.06, 0.08, 0.22)
			p["crater_edge_color"] = Color(0.15, 0.25, 0.50)
			p["crater_ember_color"] = Color(0.65, 0.75, 1.0)
			p["ground_smoke_buoyancy"] = Vector3(0, 0.95, 0)
			p["ground_smoke_lifetime"] = 2.8
			p["ground_smoke_scale_max"] = 5.6
		else:
			# 100% Waterworld (H2O): Supersonic methalox burn on marine surface creates massive white steam plumes
			p["biome_name"] = "Océano Global (Clase O)"
			p["engine_core_color"] = Color(1.0, 0.98, 0.95, 1.0)
			p["engine_flame_color"] = Color(1.0, 0.52, 0.12, 0.92)
			p["engine_rim_color"] = Color(0.18, 0.65, 1.0, 0.65)
			p["engine_light_color"] = Color(1.0, 0.60, 0.20, 1.0)
			p["shock_diamond_freq"] = 19.0
			p["flame_speed"] = 28.0
			p["expansion_power"] = 1.30
			p["nozzle_heat_color"] = Color(1.0, 0.45, 0.08, 1.0)
			p["engine_sparks_color"] = Color(1.0, 0.75, 0.25, 1.0)
			p["engine_smoke_color"] = Color(0.85, 0.94, 1.0, 0.45)
			p["ground_fire_color"] = Color(1.0, 0.55, 0.12, 0.85)
			p["ground_smoke_color"] = Color(0.88, 0.96, 1.0, 0.75) # Dense marine steam plumes
			p["ground_dust_color"] = Color(0.70, 0.90, 1.0, 0.70) # Ocean mist & spray
			p["ground_spark_color"] = Color(1.0, 0.70, 0.25, 1.0)
			p["crater_center_color"] = Color(0.02, 0.12, 0.28) # Wet submerged reef / shoal
			p["crater_edge_color"] = Color(0.08, 0.35, 0.55)
			p["crater_ember_color"] = Color(0.95, 0.55, 0.15)
			p["ground_smoke_buoyancy"] = Vector3(0, 1.10, 0)
			p["ground_smoke_lifetime"] = 2.8
			p["ground_smoke_scale_max"] = 5.8
	elif p_type.contains("Desert") or p_type.contains("Desierto") or lvl == 1:
		# Mars-like: low atmospheric pressure, iron oxide sandstorms
		p["biome_name"] = "Desierto Rojo (Clase D)"
		p["engine_core_color"] = Color(1.0, 0.92, 0.78, 1.0)
		p["engine_flame_color"] = Color(1.0, 0.40, 0.06, 0.92)
		p["engine_rim_color"] = Color(0.85, 0.40, 0.10, 0.50)
		p["engine_light_color"] = Color(1.0, 0.50, 0.15, 1.0)
		p["shock_diamond_freq"] = 14.0
		p["flame_speed"] = 26.0
		p["expansion_power"] = 1.10
		p["nozzle_heat_color"] = Color(1.0, 0.35, 0.05, 1.0)
		p["engine_sparks_color"] = Color(1.0, 0.55, 0.15, 1.0)
		p["engine_smoke_color"] = Color(0.65, 0.38, 0.22, 0.30)
		p["ground_fire_color"] = Color(1.0, 0.42, 0.08, 0.88)
		p["ground_smoke_color"] = Color(0.60, 0.30, 0.16, 0.55) # Rolling terracotta dust clouds
		p["ground_dust_color"] = Color(0.85, 0.44, 0.22, 0.85)
		p["ground_spark_color"] = Color(1.0, 0.48, 0.10, 1.0)
		p["crater_center_color"] = Color(0.12, 0.06, 0.04)
		p["crater_edge_color"] = Color(0.35, 0.16, 0.08)
		p["crater_ember_color"] = Color(1.0, 0.32, 0.04)
		p["ground_smoke_buoyancy"] = Vector3(0, 0.45, 0)
		p["ground_smoke_lifetime"] = 2.8
		p["ground_smoke_scale_max"] = 5.8
	elif p_type.contains("Toxic") or p_type.contains("Acido") or lvl == 2:
		# Venus-like: hyperbaric sulfuric acid fog, hypergolic green combustion
		p["biome_name"] = "Sulfúrico Denso (Clase V)"
		p["engine_core_color"] = Color(0.92, 1.0, 0.65, 1.0)
		p["engine_flame_color"] = Color(0.48, 0.88, 0.12, 0.92) # Alien toxic emerald
		p["engine_rim_color"] = Color(0.82, 0.95, 0.15, 0.65) # Sulfur yellow fringe
		p["engine_light_color"] = Color(0.65, 0.95, 0.20, 1.0)
		p["shock_diamond_freq"] = 24.0 # Hyperbaric compression produces rapid diamonds
		p["flame_speed"] = 32.0
		p["expansion_power"] = 1.60
		p["nozzle_heat_color"] = Color(0.85, 0.95, 0.20, 1.0)
		p["engine_sparks_color"] = Color(0.75, 1.0, 0.25, 1.0)
		p["engine_smoke_color"] = Color(0.55, 0.68, 0.18, 0.35)
		p["ground_fire_color"] = Color(0.55, 0.92, 0.18, 0.88)
		p["ground_smoke_color"] = Color(0.50, 0.60, 0.14, 0.65) # Heavy toxic acid smog rolling along ground
		p["ground_dust_color"] = Color(0.65, 0.82, 0.18, 0.75)
		p["ground_spark_color"] = Color(0.85, 1.0, 0.25, 1.0)
		p["crater_center_color"] = Color(0.06, 0.08, 0.04)
		p["crater_edge_color"] = Color(0.25, 0.28, 0.08)
		p["crater_ember_color"] = Color(0.70, 0.95, 0.15)
		p["ground_smoke_buoyancy"] = Vector3(0, 0.25, 0) # Hugs the ground
		p["ground_smoke_lifetime"] = 3.0
		p["ground_smoke_scale_max"] = 5.0
	elif p_type.contains("Cryo") or p_type.contains("Hielo") or lvl == 3:
		# Subzero cryo: cyan hydrolox plasma plume & instant boiling steam sublimation
		p["biome_name"] = "Criogénico Glaciar (Clase K)"
		p["is_cryo_steam"] = true
		p["engine_core_color"] = Color(0.92, 0.98, 1.0, 1.0)
		p["engine_flame_color"] = Color(0.20, 0.72, 1.0, 0.92) # Pure cyan plasma
		p["engine_rim_color"] = Color(0.45, 0.35, 1.0, 0.60) # Violet ion edge
		p["engine_light_color"] = Color(0.30, 0.80, 1.0, 1.0)
		p["shock_diamond_freq"] = 20.0
		p["flame_speed"] = 30.0
		p["expansion_power"] = 1.25
		p["nozzle_heat_color"] = Color(0.40, 0.85, 1.0, 1.0)
		p["engine_sparks_color"] = Color(0.55, 0.90, 1.0, 1.0)
		p["engine_smoke_color"] = Color(0.85, 0.94, 1.0, 0.40)
		p["ground_fire_color"] = Color(0.25, 0.80, 1.0, 0.88)
		p["ground_smoke_color"] = Color(0.88, 0.95, 1.0, 0.75) # Colossal white-cyan steam cloud
		p["ground_dust_color"] = Color(0.85, 0.95, 1.0, 0.85) # Ice shards
		p["ground_spark_color"] = Color(0.60, 0.90, 1.0, 1.0)
		p["crater_center_color"] = Color(0.04, 0.08, 0.12)
		p["crater_edge_color"] = Color(0.15, 0.35, 0.48)
		p["crater_ember_color"] = Color(0.30, 0.85, 1.0)
		p["ground_smoke_buoyancy"] = Vector3(0, 1.20, 0) # Superheated steam rises fast in subzero atmosphere
		p["ground_smoke_lifetime"] = 3.2
		p["ground_smoke_scale_max"] = 6.8 # Expands into massive billowing steam
	elif p_type.contains("Singularidad") or p_type.contains("Void") or lvl == 4:
		# Relativistic dark plasma / antimatter drive
		p["biome_name"] = "Abismo Singular (Clase X)"
		p["engine_core_color"] = Color(1.0, 0.85, 1.0, 1.0)
		p["engine_flame_color"] = Color(0.72, 0.16, 1.0, 0.92) # Ultraviolet violet plasma
		p["engine_rim_color"] = Color(0.35, 0.10, 0.95, 0.70)
		p["engine_light_color"] = Color(0.85, 0.25, 1.0, 1.0)
		p["shock_diamond_freq"] = 26.0
		p["flame_speed"] = 34.0
		p["expansion_power"] = 1.40
		p["nozzle_heat_color"] = Color(0.95, 0.30, 1.0, 1.0)
		p["engine_sparks_color"] = Color(0.85, 0.40, 1.0, 1.0)
		p["engine_smoke_color"] = Color(0.35, 0.15, 0.45, 0.35)
		p["ground_fire_color"] = Color(0.80, 0.20, 1.0, 0.88)
		p["ground_smoke_color"] = Color(0.26, 0.10, 0.36, 0.58) # Swirling dark violet-obsidian vapor
		p["ground_dust_color"] = Color(0.48, 0.25, 0.62, 0.75)
		p["ground_spark_color"] = Color(0.95, 0.45, 1.0, 1.0)
		p["crater_center_color"] = Color(0.06, 0.02, 0.08)
		p["crater_edge_color"] = Color(0.22, 0.08, 0.30)
		p["crater_ember_color"] = Color(0.95, 0.25, 1.0)
		p["ground_smoke_buoyancy"] = Vector3(0, 0.60, 0)
		p["ground_smoke_lifetime"] = 2.8
		p["ground_smoke_scale_max"] = 5.4
	elif p_type.contains("Volcan") or p_type.contains("Lava") or p_type.contains("Igneo") or lvl >= 5:
		# Molten lava world: thermonuclear plasma exhaust & pitch black volcanic soot
		p["biome_name"] = "Infierno Ígneo (Clase S)"
		p["engine_core_color"] = Color(1.0, 1.0, 0.82, 1.0)
		p["engine_flame_color"] = Color(1.0, 0.20, 0.02, 0.98) # Blazing magma crimson
		p["engine_rim_color"] = Color(1.0, 0.60, 0.05, 0.75)
		p["engine_light_color"] = Color(1.0, 0.30, 0.08, 1.0)
		p["shock_diamond_freq"] = 16.0
		p["flame_speed"] = 36.0
		p["expansion_power"] = 1.35
		p["nozzle_heat_color"] = Color(1.0, 0.60, 0.10, 1.0)
		p["engine_sparks_color"] = Color(1.0, 0.45, 0.05, 1.0)
		p["engine_smoke_color"] = Color(0.20, 0.14, 0.12, 0.45)
		p["ground_fire_color"] = Color(1.0, 0.28, 0.04, 0.92)
		p["ground_smoke_color"] = Color(0.14, 0.10, 0.08, 0.75) # Dense pitch black volcanic ash smoke
		p["ground_dust_color"] = Color(0.25, 0.18, 0.15, 0.90)
		p["ground_spark_color"] = Color(1.0, 0.40, 0.05, 1.0)
		p["crater_center_color"] = Color(0.08, 0.03, 0.02)
		p["crater_edge_color"] = Color(0.35, 0.10, 0.05)
		p["crater_ember_color"] = Color(1.0, 0.45, 0.05)
		p["ground_smoke_buoyancy"] = Vector3(0, 1.15, 0)
		p["ground_smoke_lifetime"] = 3.0
		p["ground_smoke_scale_max"] = 6.2

	return p

# ==============================================================================
# Procedural Soft Particle Texture Helpers (Zero hard square artifacts)
# ==============================================================================

static var _soft_circle_tex: GradientTexture2D = null
static var _soft_smoke_tex: GradientTexture2D = null

static func get_soft_circle_texture() -> GradientTexture2D:
	if _soft_circle_tex != null:
		return _soft_circle_tex
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	_soft_circle_tex = tex
	return tex

static func get_soft_smoke_texture() -> GradientTexture2D:
	if _soft_smoke_tex != null:
		return _soft_smoke_tex
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.50, 1.0])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	_soft_smoke_tex = tex
	return tex

static func create_billboard_mat(tex: Texture2D, is_additive: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if is_additive else BaseMaterial3D.BLEND_MODE_MIX
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	return mat
