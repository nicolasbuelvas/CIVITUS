extends CharacterBody3D
class_name AlienCreature

enum CreatureSize { SMALL, MEDIUM, COLOSSAL }
enum ElementalType { ORGANIC_CARBON, MINERAL_SILICON, MAGMA_PYRO, RADIOACTIVE_URANIUM, FUNGAL_SPORE }
enum LocomotionDomain { TERRESTRIAL_QUADRUPED, TERRESTRIAL_BIPED, AQUATIC_SWIMMER, AERIAL_FLOAT }
enum AIArchetype { PEACEFUL, NEUTRAL, AGGRESSIVE }

# 21 Fauna Sub-Species across 3 domains (7 land, 7 water, 7 air)
enum SubSpecies {
	# 7 Terrestres
	GRAZER_QUADRUPED,    # 0. Cuadrúpedo herbívoro pacífico con coraza y cuernos
	STRIDER_BIPED,       # 1. Bípedo zancudo veloz con patas largas y cuello estilizado
	ARMORED_COLOSSUS,    # 2. Coloso reptiliano acorazado con placas de roca dorsales
	HEXAPOD_LUMEN,       # 3. Insectoide de 6 patas con ojos y abdómen bioluminiscente
	ROLLING_SCARAB,      # 4. Escarabajo gigante rodante con coraza esférica
	FANGED_STALKER,      # 5. Depredador acechador carnívoro de colmillos prominentes
	BURROWING_MOLE,      # 6. Excavador topo con coraza pesada y garras anchas

	# 7 Acuáticos
	REEF_RAY,            # 7. Mantarraya plana de arrecife con aletas anchas
	LUMEN_JELLY,         # 8. Medusa bioluminiscente pulsante con tentáculos
	CRESTED_SHARK,       # 9. Depredador marino rápido con aleta dorsal puntiaguda
	SERPENT_EEL,         # 10. Anguila serpentina sinuosa de cuerpo alargado
	BENTHIC_TRILOBITE,   # 11. Trilobite bentónico acorazado de lecho marino
	LANTERN_ANGLER,      # 12. Pez abisal con señuelo bio-fotónico brillante
	OCEAN_LEVIATHAN,     # 13. Leviatán oceánico colosal con aletas dobles

	# 7 Aéreos
	AERO_RAY,            # 14. Planeador atmosférico plano con grandes alas
	DART_FLYER,          # 15. Avispa veloz con alas de alta frecuencia
	GAS_FLOAT_BALLOON,   # 16. Globo aerostático bio-gas con zarcillos colgantes
	MEMBRANE_WYVERN,     # 17. Criatura alada de doble ala membranosa
	MAGNETO_FLOATER,     # 18. Levitador con cristales magnéticos flotantes
	CRESTED_PTERO,       # 19. Pterosaurio alienígena con cresta cefálica
	SPORE_DRIFTER        # 20. Espora gigante flotante a la deriva del viento
}

signal creature_damaged(current_hp: float, max_hp: float)
signal creature_died(loot_dict: Dictionary)
signal creature_fed(reward_item: String)
signal creature_rescued(reward_item: String)

@export var max_health: float = 65.0
@export var is_aggressive: bool = false
@export var speed: float = 3.6

var current_health: float = 65.0
var is_dead: bool = false
var planet_radius: float = 160.0
var target_player: CharacterBody3D = null

# Morphological & Ecological attributes
var creature_size: CreatureSize = CreatureSize.MEDIUM
var elemental_type: ElementalType = ElementalType.ORGANIC_CARBON
var locomotion_domain: LocomotionDomain = LocomotionDomain.TERRESTRIAL_QUADRUPED
var ai_archetype: AIArchetype = AIArchetype.PEACEFUL
var sub_species: SubSpecies = SubSpecies.GRAZER_QUADRUPED

var is_being_carried: bool = false
var carrier_player: CharacterBody3D = null
var is_in_ragdoll: bool = false
var ragdoll_timer: float = 0.0
var is_stranded_on_land: bool = false
var is_fed: bool = false
var target_enemy: Node3D = null

var loot_item_defeat: String = "alien_chitin"
var loot_item_friendly: String = "biogel_sample"
var creature_color: Color = Color(0.35, 0.75, 0.45)
var secondary_color: Color = Color(0.20, 0.25, 0.22)
var eye_color: Color = Color(1.0, 0.85, 0.15)

# Aerial Flight & Landing states
enum FlightState { SOARING, SWOOPING, LANDING, PERCHED, TAKEOFF }
var flight_state: FlightState = FlightState.SOARING
var flight_state_timer: float = 6.0
var target_flight_altitude: float = 6.5

# Aquatic depth control
var preferred_depth_ratio: float = 0.5

# Mesh node references for articulated procedural animations
@onready var body_mesh: MeshInstance3D = get_node_or_null("Visuals/Thorax")
@onready var dorsal_ridge: MeshInstance3D = get_node_or_null("Visuals/Thorax/DorsalRidge")
@onready var heavy_armor: MeshInstance3D = get_node_or_null("Visuals/Thorax/HeavyArmor")
@onready var head_mesh: MeshInstance3D = get_node_or_null("Visuals/Head")
@onready var eye_l: MeshInstance3D = get_node_or_null("Visuals/Head/EyeL")
@onready var eye_r: MeshInstance3D = get_node_or_null("Visuals/Head/EyeR")
@onready var horn_l: MeshInstance3D = get_node_or_null("Visuals/Head/HornL")
@onready var horn_r: MeshInstance3D = get_node_or_null("Visuals/Head/HornR")
@onready var lantern_lure: MeshInstance3D = get_node_or_null("Visuals/Head/LanternLure")
@onready var mandible_l: MeshInstance3D = get_node_or_null("Visuals/Head/MandibleL")
@onready var mandible_r: MeshInstance3D = get_node_or_null("Visuals/Head/MandibleR")

@onready var leg_fl: Node3D = get_node_or_null("Visuals/LegFL")
@onready var leg_fr: Node3D = get_node_or_null("Visuals/LegFR")
@onready var leg_ml: Node3D = get_node_or_null("Visuals/LegML")
@onready var leg_mr: Node3D = get_node_or_null("Visuals/LegMR")
@onready var leg_rl: Node3D = get_node_or_null("Visuals/LegRL")
@onready var leg_rr: Node3D = get_node_or_null("Visuals/LegRR")
@onready var col_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

@onready var aquatic_parts: Node3D = get_node_or_null("Visuals/AquaticParts")
@onready var caudal_tail: Node3D = get_node_or_null("Visuals/AquaticParts/CaudalTail")
@onready var pectoral_l: MeshInstance3D = get_node_or_null("Visuals/AquaticParts/PectoralL")
@onready var pectoral_r: MeshInstance3D = get_node_or_null("Visuals/AquaticParts/PectoralR")
@onready var dorsal_fin: MeshInstance3D = get_node_or_null("Visuals/AquaticParts/DorsalFin")

@onready var aerial_parts: Node3D = get_node_or_null("Visuals/AerialParts")
@onready var wing_l: MeshInstance3D = get_node_or_null("Visuals/AerialParts/WingL")
@onready var wing_r: MeshInstance3D = get_node_or_null("Visuals/AerialParts/WingR")
@onready var gas_bladder: MeshInstance3D = get_node_or_null("Visuals/AerialParts/GasBladder")

var walk_cycle: float = 0.0
var wander_timer: float = 0.0
var wander_tangent: Vector3 = Vector3.FORWARD
var attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("creatures")
	add_to_group("interactable")
	floor_snap_length = 0.8
	floor_stop_on_slope = true
	floor_constant_speed = true
	current_health = max_health

func setup_creature(planet_params: Dictionary, aggressive: bool = false, domain_override: int = -1) -> void:
	add_to_group("creatures")
	is_aggressive = aggressive
	ai_archetype = AIArchetype.AGGRESSIVE if aggressive else AIArchetype.PEACEFUL
	is_fed = false
	is_being_carried = false
	is_dead = false
	target_enemy = null
	is_in_ragdoll = false
	attack_cooldown = 0.0
	current_health = max_health
	
	var p_type = planet_params.get("type", "Habitable")
	var lvl = planet_params.get("level", 1)
	var p_seed = planet_params.get("seed", 1337)
	var rng = RandomNumberGenerator.new()
	rng.seed = p_seed + int(position.length() * 100.0) + int(position.x * 17.0)
	
	# Determine domain
	var target_domain: LocomotionDomain
	if domain_override >= 0:
		target_domain = domain_override as LocomotionDomain
	elif planet_params.get("is_ocean_world", false) or p_type.contains("Océano"):
		target_domain = LocomotionDomain.AQUATIC_SWIMMER
	elif rng.randf() < 0.25 and planet_params.get("has_atmosphere", true):
		target_domain = LocomotionDomain.AERIAL_FLOAT
	elif rng.randf() < 0.30:
		target_domain = LocomotionDomain.TERRESTRIAL_BIPED
	else:
		target_domain = LocomotionDomain.TERRESTRIAL_QUADRUPED

	# Select one of the 7 subspecies for the chosen domain
	var chosen_species: SubSpecies
	match target_domain:
		LocomotionDomain.AQUATIC_SWIMMER:
			var aquatic_options = [
				SubSpecies.REEF_RAY,
				SubSpecies.LUMEN_JELLY,
				SubSpecies.CRESTED_SHARK,
				SubSpecies.SERPENT_EEL,
				SubSpecies.BENTHIC_TRILOBITE,
				SubSpecies.LANTERN_ANGLER,
				SubSpecies.OCEAN_LEVIATHAN
			]
			chosen_species = aquatic_options[rng.randi() % aquatic_options.size()]
		LocomotionDomain.AERIAL_FLOAT:
			var aerial_options = [
				SubSpecies.AERO_RAY,
				SubSpecies.DART_FLYER,
				SubSpecies.GAS_FLOAT_BALLOON,
				SubSpecies.MEMBRANE_WYVERN,
				SubSpecies.MAGNETO_FLOATER,
				SubSpecies.CRESTED_PTERO,
				SubSpecies.SPORE_DRIFTER
			]
			chosen_species = aerial_options[rng.randi() % aerial_options.size()]
		_:
			var land_options = [
				SubSpecies.GRAZER_QUADRUPED,
				SubSpecies.STRIDER_BIPED,
				SubSpecies.ARMORED_COLOSSUS,
				SubSpecies.HEXAPOD_LUMEN,
				SubSpecies.ROLLING_SCARAB,
				SubSpecies.FANGED_STALKER,
				SubSpecies.BURROWING_MOLE
			]
			chosen_species = land_options[rng.randi() % land_options.size()]

	configure_subspecies(chosen_species, planet_params, aggressive)

func configure_subspecies(species: SubSpecies, planet_params: Dictionary, aggressive: bool = false) -> void:
	sub_species = species
	is_aggressive = aggressive
	
	var p_type = planet_params.get("type", "Habitable")
	var lvl = planet_params.get("level", 1)
	var p_seed = planet_params.get("seed", 1337)
	
	match species:
		SubSpecies.GRAZER_QUADRUPED:
			locomotion_domain = LocomotionDomain.TERRESTRIAL_QUADRUPED
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.PEACEFUL
			speed = 3.2
			max_health = 60.0
		SubSpecies.STRIDER_BIPED:
			locomotion_domain = LocomotionDomain.TERRESTRIAL_BIPED
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.PEACEFUL
			speed = 4.8
			max_health = 45.0
		SubSpecies.ARMORED_COLOSSUS:
			locomotion_domain = LocomotionDomain.TERRESTRIAL_QUADRUPED
			creature_size = CreatureSize.COLOSSAL
			ai_archetype = AIArchetype.NEUTRAL
			speed = 2.4
			max_health = 160.0
		SubSpecies.HEXAPOD_LUMEN:
			locomotion_domain = LocomotionDomain.TERRESTRIAL_QUADRUPED
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.NEUTRAL
			speed = 3.8
			max_health = 50.0
		SubSpecies.ROLLING_SCARAB:
			locomotion_domain = LocomotionDomain.TERRESTRIAL_QUADRUPED
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.PEACEFUL
			speed = 4.2
			max_health = 55.0
		SubSpecies.FANGED_STALKER:
			locomotion_domain = LocomotionDomain.TERRESTRIAL_QUADRUPED
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.AGGRESSIVE
			is_aggressive = true
			speed = 4.4
			max_health = 80.0
		SubSpecies.BURROWING_MOLE:
			locomotion_domain = LocomotionDomain.TERRESTRIAL_QUADRUPED
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.NEUTRAL
			speed = 2.8
			max_health = 70.0

		SubSpecies.REEF_RAY:
			locomotion_domain = LocomotionDomain.AQUATIC_SWIMMER
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.PEACEFUL
			speed = 3.4
			max_health = 55.0
		SubSpecies.LUMEN_JELLY:
			locomotion_domain = LocomotionDomain.AQUATIC_SWIMMER
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.PEACEFUL
			speed = 2.6
			max_health = 40.0
		SubSpecies.CRESTED_SHARK:
			locomotion_domain = LocomotionDomain.AQUATIC_SWIMMER
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.AGGRESSIVE
			is_aggressive = true
			speed = 4.6
			max_health = 85.0
		SubSpecies.SERPENT_EEL:
			locomotion_domain = LocomotionDomain.AQUATIC_SWIMMER
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.NEUTRAL
			speed = 3.8
			max_health = 60.0
		SubSpecies.BENTHIC_TRILOBITE:
			locomotion_domain = LocomotionDomain.AQUATIC_SWIMMER
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.PEACEFUL
			speed = 2.2
			max_health = 65.0
		SubSpecies.LANTERN_ANGLER:
			locomotion_domain = LocomotionDomain.AQUATIC_SWIMMER
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.AGGRESSIVE
			is_aggressive = true
			speed = 3.5
			max_health = 75.0
		SubSpecies.OCEAN_LEVIATHAN:
			locomotion_domain = LocomotionDomain.AQUATIC_SWIMMER
			creature_size = CreatureSize.COLOSSAL
			ai_archetype = AIArchetype.NEUTRAL
			speed = 2.8
			max_health = 220.0

		SubSpecies.AERO_RAY:
			locomotion_domain = LocomotionDomain.AERIAL_FLOAT
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.PEACEFUL
			speed = 4.2
			max_health = 50.0
		SubSpecies.DART_FLYER:
			locomotion_domain = LocomotionDomain.AERIAL_FLOAT
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.PEACEFUL
			speed = 5.2
			max_health = 35.0
		SubSpecies.GAS_FLOAT_BALLOON:
			locomotion_domain = LocomotionDomain.AERIAL_FLOAT
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.PEACEFUL
			speed = 2.2
			max_health = 45.0
		SubSpecies.MEMBRANE_WYVERN:
			locomotion_domain = LocomotionDomain.AERIAL_FLOAT
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.AGGRESSIVE
			is_aggressive = true
			speed = 4.6
			max_health = 75.0
		SubSpecies.MAGNETO_FLOATER:
			locomotion_domain = LocomotionDomain.AERIAL_FLOAT
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.NEUTRAL
			speed = 3.2
			max_health = 55.0
		SubSpecies.CRESTED_PTERO:
			locomotion_domain = LocomotionDomain.AERIAL_FLOAT
			creature_size = CreatureSize.MEDIUM
			ai_archetype = AIArchetype.NEUTRAL
			speed = 4.0
			max_health = 65.0
		SubSpecies.SPORE_DRIFTER:
			locomotion_domain = LocomotionDomain.AERIAL_FLOAT
			creature_size = CreatureSize.SMALL
			ai_archetype = AIArchetype.PEACEFUL
			speed = 2.5
			max_health = 40.0

	# Preferred Depth Ratio for Aquatic Swimmers
	match species:
		SubSpecies.LANTERN_ANGLER, SubSpecies.BENTHIC_TRILOBITE, SubSpecies.SERPENT_EEL:
			preferred_depth_ratio = 0.80
		SubSpecies.CRESTED_SHARK, SubSpecies.OCEAN_LEVIATHAN:
			preferred_depth_ratio = 0.50
		SubSpecies.REEF_RAY, SubSpecies.LUMEN_JELLY:
			preferred_depth_ratio = 0.30
		_:
			preferred_depth_ratio = 0.50

	# Elemental and Color adaptation based on planetary conditions
	var rng_col = RandomNumberGenerator.new()
	rng_col.seed = p_seed + int(sub_species) * 101 + int(position.x * 23.0 + position.z * 47.0)
	
	var p_land: Color = planet_params.get("land_color", planet_params.get("surface_color", Color(0.32, 0.65, 0.28)))
	var p_water: Color = planet_params.get("water_color", planet_params.get("ocean_color", Color(0.12, 0.45, 0.85)))
	var p_mount: Color = planet_params.get("mountain_color", Color(0.45, 0.40, 0.35))
	var p_atmo: Color = planet_params.get("atmosphere_color", planet_params.get("sky_color", Color(0.40, 0.65, 0.95)))
	
	var base_biome_col: Color
	match locomotion_domain:
		LocomotionDomain.AQUATIC_SWIMMER:
			base_biome_col = p_water.lerp(p_mount, rng_col.randf_range(0.08, 0.28))
		LocomotionDomain.AERIAL_FLOAT:
			base_biome_col = p_atmo.lerp(Color.WHITE, rng_col.randf_range(0.15, 0.38))
		_:
			base_biome_col = p_land.lerp(p_mount, rng_col.randf_range(0.08, 0.35))
			
	var h_shift = rng_col.randf_range(-0.06, 0.06)
	var s_shift = rng_col.randf_range(-0.10, 0.12)
	var v_shift = rng_col.randf_range(-0.10, 0.12)
	var h = fmod(base_biome_col.h + h_shift + 1.0, 1.0)
	var s = clampf(base_biome_col.s + s_shift, 0.25, 0.95)
	var v = clampf(base_biome_col.v + v_shift, 0.25, 0.95)
	creature_color = Color.from_hsv(h, s, v)
	
	if is_aggressive:
		var warning_hue = fmod(creature_color.h + 0.5 + rng_col.randf_range(-0.08, 0.08), 1.0)
		creature_color = creature_color.lerp(Color.from_hsv(warning_hue, 0.85, 0.90), 0.55)

	var p_type_clean = p_type.to_lower().replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u")
	if p_type_clean.contains("volcan") or p_type_clean.contains("lava") or planet_params.get("is_molten", false):
		elemental_type = ElementalType.MAGMA_PYRO
		creature_color = creature_color.lerp(Color(0.98, 0.32, 0.08), 0.82)
		loot_item_defeat = "magma_carapace"
		loot_item_friendly = "pyro_crystal"
		max_health += 25.0
	elif p_type_clean.contains("toxic") or p_type_clean.contains("acido"):
		elemental_type = ElementalType.ORGANIC_CARBON
		creature_color = creature_color.lerp(Color(0.50, 0.88, 0.18), 0.65)
		loot_item_defeat = "toxic_gland"
		loot_item_friendly = "corrosive_filter"
		max_health += 15.0
	elif p_type_clean.contains("cryo") or p_type_clean.contains("hielo"):
		elemental_type = ElementalType.MINERAL_SILICON
		creature_color = creature_color.lerp(Color(0.38, 0.78, 0.95), 0.70)
		loot_item_defeat = "cryo_scale"
		loot_item_friendly = "permafrost_sample"
		max_health += 10.0
	elif p_type_clean.contains("desert") or p_type_clean.contains("desierto") or p_type_clean.contains("arido"):
		elemental_type = ElementalType.MINERAL_SILICON
		creature_color = creature_color.lerp(Color(0.85, 0.65, 0.30), 0.65)
		loot_item_defeat = "silicon_shell"
		loot_item_friendly = "dry_chitin"
	elif lvl >= 3:
		elemental_type = ElementalType.RADIOACTIVE_URANIUM
		creature_color = creature_color.lerp(Color(0.32, 0.95, 0.45), 0.65)
		loot_item_defeat = "depleted_uranium"
		loot_item_friendly = "uranium_rod"
		max_health += 20.0
	else:
		elemental_type = ElementalType.ORGANIC_CARBON
		loot_item_defeat = "alien_chitin"
		loot_item_friendly = "biogel_sample"

	secondary_color = creature_color.darkened(0.38).lerp(p_mount, 0.32)
	eye_color = Color(1.0, 0.85, 0.15) if not is_aggressive else Color(1.0, 0.22, 0.15)
	if elemental_type == ElementalType.RADIOACTIVE_URANIUM:
		eye_color = Color(0.35, 1.0, 0.35)
	elif elemental_type == ElementalType.MAGMA_PYRO:
		eye_color = Color(1.0, 0.50, 0.10)
	elif locomotion_domain == LocomotionDomain.AQUATIC_SWIMMER and sub_species == SubSpecies.LANTERN_ANGLER:
		eye_color = Color(0.20, 0.95, 1.0)

	# Scale Assembly
	var scale_mult = 1.0
	match creature_size:
		CreatureSize.SMALL:
			scale_mult = 0.65
		CreatureSize.COLOSSAL:
			scale_mult = 1.95
		_:
			scale_mult = 1.05
	scale = Vector3.ONE * scale_mult

	current_health = max_health

	# Materials
	var mat_primary = StandardMaterial3D.new()
	mat_primary.albedo_color = creature_color
	mat_primary.roughness = 0.55
	mat_primary.metallic = 0.30
	if is_aggressive or elemental_type == ElementalType.MAGMA_PYRO or elemental_type == ElementalType.RADIOACTIVE_URANIUM:
		mat_primary.emission_enabled = true
		mat_primary.emission = creature_color * 0.45

	var mat_secondary = StandardMaterial3D.new()
	mat_secondary.albedo_color = secondary_color
	mat_secondary.roughness = 0.45
	mat_secondary.metallic = 0.50

	var mat_eye = StandardMaterial3D.new()
	mat_eye.albedo_color = Color(0.08, 0.08, 0.08)
	mat_eye.emission_enabled = true
	mat_eye.emission = eye_color
	mat_eye.emission_energy_multiplier = 2.4

	if body_mesh: body_mesh.material_override = mat_primary
	if head_mesh: head_mesh.material_override = mat_primary
	if dorsal_ridge: dorsal_ridge.material_override = mat_secondary
	if heavy_armor: heavy_armor.material_override = mat_secondary
	if horn_l: horn_l.material_override = mat_secondary
	if horn_r: horn_r.material_override = mat_secondary
	if mandible_l: mandible_l.material_override = mat_secondary
	if mandible_r: mandible_r.material_override = mat_secondary
	if eye_l: eye_l.material_override = mat_eye
	if eye_r: eye_r.material_override = mat_eye
	if lantern_lure: lantern_lure.material_override = mat_eye

	for leg in [leg_fl, leg_fr, leg_ml, leg_mr, leg_rl, leg_rr]:
		if is_instance_valid(leg):
			for child in leg.get_children():
				if child is MeshInstance3D:
					child.material_override = mat_secondary

	if caudal_tail:
		for child in caudal_tail.get_children():
			if child is MeshInstance3D:
				child.material_override = mat_primary
	if pectoral_l: pectoral_l.material_override = mat_secondary
	if pectoral_r: pectoral_r.material_override = mat_secondary
	if dorsal_fin: dorsal_fin.material_override = mat_secondary
	if wing_l: wing_l.material_override = mat_secondary
	if wing_r: wing_r.material_override = mat_secondary
	if gas_bladder: gas_bladder.material_override = mat_primary

	_apply_subspecies_visuals()

	# Check if aquatic creature is initialized above sea level (stranded)
	if locomotion_domain == LocomotionDomain.AQUATIC_SWIMMER and position.length() >= planet_radius + 0.2:
		is_stranded_on_land = true

func _apply_subspecies_visuals() -> void:
	if aquatic_parts: aquatic_parts.visible = false
	if aerial_parts: aerial_parts.visible = false
	if leg_fl: leg_fl.visible = false
	if leg_fr: leg_fr.visible = false
	if leg_ml: leg_ml.visible = false
	if leg_mr: leg_mr.visible = false
	if leg_rl: leg_rl.visible = false
	if leg_rr: leg_rr.visible = false
	if horn_l: horn_l.visible = false
	if horn_r: horn_r.visible = false
	if heavy_armor: heavy_armor.visible = false
	if lantern_lure: lantern_lure.visible = false

	match locomotion_domain:
		LocomotionDomain.AQUATIC_SWIMMER:
			if aquatic_parts: aquatic_parts.visible = true
			if sub_species == SubSpecies.LANTERN_ANGLER:
				if lantern_lure: lantern_lure.visible = true
			elif sub_species == SubSpecies.BENTHIC_TRILOBITE:
				if heavy_armor: heavy_armor.visible = true
			elif sub_species == SubSpecies.REEF_RAY:
				if pectoral_l: pectoral_l.scale = Vector3(1.6, 1.0, 1.4)
				if pectoral_r: pectoral_r.scale = Vector3(1.6, 1.0, 1.4)
		LocomotionDomain.AERIAL_FLOAT:
			if aerial_parts: aerial_parts.visible = true
			if sub_species == SubSpecies.GAS_FLOAT_BALLOON or sub_species == SubSpecies.SPORE_DRIFTER:
				if gas_bladder: gas_bladder.visible = true
				if wing_l: wing_l.visible = false
				if wing_r: wing_r.visible = false
			else:
				if wing_l: wing_l.visible = true
				if wing_r: wing_r.visible = true
			if sub_species == SubSpecies.CRESTED_PTERO:
				if horn_l: horn_l.visible = true
				if horn_r: horn_r.visible = true
		_:
			if sub_species == SubSpecies.STRIDER_BIPED:
				if leg_rl: leg_rl.visible = true
				if leg_rr: leg_rr.visible = true
			elif sub_species == SubSpecies.HEXAPOD_LUMEN:
				if leg_fl: leg_fl.visible = true
				if leg_fr: leg_fr.visible = true
				if leg_ml: leg_ml.visible = true
				if leg_mr: leg_mr.visible = true
				if leg_rl: leg_rl.visible = true
				if leg_rr: leg_rr.visible = true
				if lantern_lure: lantern_lure.visible = true
			else:
				if leg_fl: leg_fl.visible = true
				if leg_fr: leg_fr.visible = true
				if leg_rl: leg_rl.visible = true
				if leg_rr: leg_rr.visible = true
				if sub_species == SubSpecies.GRAZER_QUADRUPED:
					if horn_l: horn_l.visible = true
					if horn_r: horn_r.visible = true
				elif sub_species == SubSpecies.ARMORED_COLOSSUS:
					if heavy_armor: heavy_armor.visible = true

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if is_being_carried:
		return
		
	var pos = global_position
	var p_len = pos.length()
	var up_dir = pos.normalized()
	if p_len < 0.01:
		up_dir = Vector3.UP

	# Evaluate terrain surface elevation at current radial direction
	var planet = get_parent()
	var surf_elev = 0.0
	if planet and planet.has_method("get_elevation_at_direction"):
		surf_elev = planet.get_elevation_at_direction(up_dir)
	elif planet and planet.has_method("_get_elevation"):
		surf_elev = planet._get_elevation(up_dir)
	var surf_r = planet_radius + surf_elev

	# EMERGENCY CORE-ESCAPE CLAMP: prevent any glitch from pulling creature inside core
	if p_len < surf_r * 0.6:
		global_position = up_dir * (surf_r + 0.65)
		p_len = global_position.length()
		velocity = Vector3.ZERO

	# 1. Domain-Specific Buoyancy, Hydrodynamics & Aerodynamics
	if locomotion_domain == LocomotionDomain.AQUATIC_SWIMMER:
		if p_len <= planet_radius:
			is_stranded_on_land = false
			velocity *= 0.94
			# Fish swim dynamically across the whole water column (not just surface!)
			var depth_span = maxf(1.6, planet_radius - surf_r)
			var depth_osc = sin(walk_cycle * 0.35 + float(sub_species)) * 0.22
			var target_r = surf_r + depth_span * clampf(preferred_depth_ratio + depth_osc, 0.15, 0.85)
			var depth_err = target_r - p_len
			velocity += up_dir * (depth_err * 3.2 * delta)
		else:
			velocity += -up_dir * 14.0 * delta
	elif locomotion_domain == LocomotionDomain.AERIAL_FLOAT:
		# Birds fly at different altitudes and land on the ground to rest / peck
		flight_state_timer -= delta
		if flight_state_timer <= 0.0:
			match flight_state:
				FlightState.SOARING:
					if randf() < 0.55:
						flight_state = FlightState.SWOOPING
						target_flight_altitude = randf_range(2.4, 4.5)
						flight_state_timer = randf_range(6.0, 10.0)
					else:
						flight_state = FlightState.LANDING
						flight_state_timer = randf_range(3.0, 5.0)
				FlightState.SWOOPING:
					if randf() < 0.50:
						flight_state = FlightState.LANDING
						flight_state_timer = randf_range(3.0, 5.0)
					else:
						flight_state = FlightState.SOARING
						target_flight_altitude = randf_range(6.5, 14.0)
						flight_state_timer = randf_range(8.0, 16.0)
				FlightState.LANDING:
					flight_state = FlightState.PERCHED
					flight_state_timer = randf_range(4.0, 8.0)
				FlightState.PERCHED:
					flight_state = FlightState.TAKEOFF
					velocity += up_dir * 6.5
					target_flight_altitude = randf_range(6.0, 10.0)
					flight_state_timer = 2.0
				FlightState.TAKEOFF:
					flight_state = FlightState.SOARING
					flight_state_timer = randf_range(8.0, 14.0)

		if flight_state == FlightState.PERCHED:
			# Landed on ground resting / pecking
			var gravity_accel = -up_dir * 14.0
			velocity += gravity_accel * delta
			velocity *= 0.85
		elif flight_state == FlightState.LANDING:
			# Gliding smoothly toward ground
			var target_r = surf_r + 0.45
			var alt_err = target_r - p_len
			velocity += up_dir * (alt_err * 2.5 * delta)
			velocity *= 0.92
		else:
			# Soaring or swooping in sky
			var target_r = surf_r + target_flight_altitude
			var alt_err = target_r - p_len
			velocity += up_dir * (alt_err * 3.5 * delta)
			velocity *= 0.96
	else:
		# Terrestrial: Standard gravity toward planet center
		var gravity_accel = -up_dir * 16.0
		velocity += gravity_accel * delta

	# STRICT ANTI-SPACE LAUNCH: Clamp outward radial velocity
	var radial_vel = velocity.dot(up_dir)
	if locomotion_domain != LocomotionDomain.AERIAL_FLOAT:
		if radial_vel > 2.0:
			velocity -= up_dir * (radial_vel - 2.0)
	else:
		if radial_vel > 3.0:
			velocity -= up_dir * (radial_vel - 3.0)

	# STRICT ROCK-SOLID ALTITUDE CLAMPS:
	# Crucial: Prevent ANY creature from penetrating the ground and getting sucked into planet core!
	if locomotion_domain == LocomotionDomain.AQUATIC_SWIMMER and not is_stranded_on_land:
		var min_seabed = surf_r + 0.35
		var max_ocean = planet_radius + 0.1
		if p_len < min_seabed:
			global_position = up_dir * min_seabed
			var v_in = velocity.dot(up_dir)
			if v_in < 0.0:
				velocity -= up_dir * v_in
		elif p_len > max_ocean:
			global_position = up_dir * max_ocean
			var v_out = velocity.dot(up_dir)
			if v_out > 0.0:
				velocity -= up_dir * v_out
	elif locomotion_domain == LocomotionDomain.AERIAL_FLOAT:
		var min_air_ground = surf_r + 0.35
		var max_air = surf_r + 18.0
		if p_len < min_air_ground:
			global_position = up_dir * min_air_ground
			var v_in = velocity.dot(up_dir)
			if v_in < 0.0:
				velocity -= up_dir * v_in
			if flight_state == FlightState.LANDING:
				flight_state = FlightState.PERCHED
				flight_state_timer = randf_range(4.0, 8.0)
		elif p_len > max_air:
			global_position = up_dir * max_air
			var v_out = velocity.dot(up_dir)
			if v_out > 0.0:
				velocity -= up_dir * v_out
	else:
		# Terrestrial: Hard floor and ceiling clamp
		var min_ground = surf_r + 0.55 * scale.y
		var max_ground = surf_r + 1.25 * scale.y
		if p_len < min_ground:
			global_position = up_dir * min_ground
			var v_in = velocity.dot(up_dir)
			if v_in < 0.0:
				velocity -= up_dir * v_in
		elif p_len > max_ground and not is_in_ragdoll and is_on_floor():
			global_position = up_dir * max_ground
			var v_out = velocity.dot(up_dir)
			if v_out > 0.0:
				velocity -= up_dir * v_out

	# Ragdoll Tumbling State with Planetary Gravity
	if is_in_ragdoll:
		ragdoll_timer -= delta
		velocity += -up_dir * 18.0 * delta # Planetary gravity toward core
		var rot_axis = up_dir.cross(velocity.normalized() + Vector3(0.015, 0.025, 0.035)).normalized()
		rotate(rot_axis, delta * 9.0)
		up_direction = up_dir
		move_and_slide()
		
		# Prevent falling below ground surface
		if p_len < surf_r + 0.35 * scale.y:
			global_position = up_dir * (surf_r + 0.35 * scale.y)
			var v_in = velocity.dot(up_dir)
			if v_in < 0.0:
				velocity -= up_dir * v_in
				
		if is_on_floor():
			velocity = velocity.slide(up_dir) * 0.84
			if ragdoll_timer <= 0.0 or velocity.length_squared() < 0.2:
				if is_dead:
					velocity = Vector3.ZERO
				else:
					is_in_ragdoll = false
					velocity = Vector3.ZERO
					global_transform.basis = Basis.looking_at(-wander_tangent, up_dir).orthonormalized()
		elif ragdoll_timer <= 0.0 and not is_dead:
			is_in_ragdoll = false
		return

	# Proximity Hazards
	if not is_instance_valid(target_player):
		var pl = get_tree().get_first_node_in_group("player")
		if pl is CharacterBody3D:
			target_player = pl
			
	if is_instance_valid(target_player):
		var dist_p = pos.distance_to(target_player.global_position)
		if elemental_type == ElementalType.MAGMA_PYRO and dist_p < 2.2:
			GameManager.player_stats.hull = maxf(0.0, GameManager.player_stats.hull - 5.5 * delta)
			GameManager.player_vital_updated.emit("hull", GameManager.player_stats.hull, 100.0)
		elif elemental_type == ElementalType.RADIOACTIVE_URANIUM and dist_p < 5.0:
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("trigger_suit_eva_alert"):
				hud.trigger_suit_eva_alert("ALERTA DOSIMÉTRICA • RADIACIÓN ALTA")

	# AI Tangent
	var desired_tangent = Vector3.ZERO
	if is_fed:
		# Tamed Pet Defense & Loyalty Follow AI
		if not is_instance_valid(target_enemy) or target_enemy.get("is_dead") == true:
			target_enemy = null
			var min_threat_dist: float = 16.0
			for other in get_tree().get_nodes_in_group("creatures"):
				if is_instance_valid(other) and other != self and not other.is_queued_for_deletion() and not other.get("is_dead") and other.get("is_aggressive"):
					var d_threat = pos.distance_to(other.global_position)
					if d_threat < min_threat_dist:
						min_threat_dist = d_threat
						target_enemy = other
		
		if is_instance_valid(target_enemy) and not target_enemy.get("is_dead"):
			var to_enemy = target_enemy.global_position - pos
			var dist_e = to_enemy.length()
			var tangent_to_enemy = (to_enemy - up_dir * to_enemy.dot(up_dir)).normalized()
			desired_tangent = tangent_to_enemy
			if dist_e < 2.3:
				_perform_attack(delta)
		elif is_instance_valid(target_player):
			var to_player = target_player.global_position - pos
			var dist_to_player = to_player.length()
			var tangent_to_player = (to_player - up_dir * to_player.dot(up_dir)).normalized()
			if dist_to_player > 4.2:
				desired_tangent = tangent_to_player
			elif dist_to_player < 1.8:
				desired_tangent = -tangent_to_player * 0.5
			else:
				desired_tangent = Vector3.ZERO
		else:
			desired_tangent = _get_wander_tangent(up_dir, delta)
	elif is_instance_valid(target_player):
		var p_pos = target_player.global_position
		var to_player = p_pos - pos
		var dist_to_player = to_player.length()
		var tangent_to_player = (to_player - up_dir * to_player.dot(up_dir)).normalized()
		
		if is_aggressive:
			# Check if retaliating against pet or rival in inter-mob combat
			if is_instance_valid(target_enemy) and not target_enemy.get("is_dead"):
				var to_enemy = target_enemy.global_position - pos
				var dist_e = to_enemy.length()
				var tangent_to_enemy = (to_enemy - up_dir * to_enemy.dot(up_dir)).normalized()
				desired_tangent = tangent_to_enemy
				if dist_e < 2.2:
					_perform_attack(delta)
			elif dist_to_player < 16.0:
				desired_tangent = tangent_to_player
				if dist_to_player < 2.2:
					_perform_attack(delta)
			else:
				# Territorial battles with other hostile mobs or wild pets
				if randf() < 0.05 and not is_instance_valid(target_enemy):
					for other in get_tree().get_nodes_in_group("creatures"):
						if is_instance_valid(other) and other != self and not other.get("is_dead"):
							if other.get("is_fed") or (other.get("is_aggressive") and other.get("sub_species") != sub_species):
								if pos.distance_to(other.global_position) < 6.0:
									target_enemy = other
									break
				desired_tangent = _get_wander_tangent(up_dir, delta)
		elif ai_archetype == AIArchetype.NEUTRAL:
			if dist_to_player < 1.5:
				desired_tangent = -tangent_to_player
			else:
				desired_tangent = _get_wander_tangent(up_dir, delta)
		else:
			if dist_to_player < 5.0:
				desired_tangent = -tangent_to_player
			else:
				desired_tangent = _get_wander_tangent(up_dir, delta)
	else:
		desired_tangent = _get_wander_tangent(up_dir, delta)
		
	# Movement & Determinant-Safe Basis
	var is_moving = desired_tangent.length_squared() > 0.01
	if is_moving:
		var target_vel = desired_tangent * speed
		var v_vertical = up_dir * velocity.dot(up_dir)
		velocity = v_vertical + target_vel
		
		var back_dir = -desired_tangent.normalized()
		var right_dir = up_dir.cross(back_dir).normalized()
		global_transform.basis = Basis(right_dir, up_dir, back_dir).orthonormalized()
		
		walk_cycle += delta * speed * 3.5
		
		if locomotion_domain == LocomotionDomain.AQUATIC_SWIMMER:
			if caudal_tail: caudal_tail.rotation.y = sin(walk_cycle) * 0.55
			if pectoral_l: pectoral_l.rotation.z = sin(walk_cycle) * 0.35
			if pectoral_r: pectoral_r.rotation.z = -sin(walk_cycle) * 0.35
		elif locomotion_domain == LocomotionDomain.AERIAL_FLOAT:
			if flight_state == FlightState.PERCHED:
				if wing_l: wing_l.rotation.z = lerp_angle(wing_l.rotation.z, -0.15, delta * 6.0)
				if wing_r: wing_r.rotation.z = lerp_angle(wing_r.rotation.z, 0.15, delta * 6.0)
			else:
				if wing_l: wing_l.rotation.z = sin(walk_cycle * 1.5) * 0.45
				if wing_r: wing_r.rotation.z = -sin(walk_cycle * 1.5) * 0.45
			if gas_bladder: gas_bladder.scale = Vector3.ONE * (1.0 + sin(walk_cycle) * 0.08)
		else:
			if leg_fl: leg_fl.rotation.x = sin(walk_cycle) * 0.45
			if leg_fr: leg_fr.rotation.x = -sin(walk_cycle) * 0.45
			if leg_ml: leg_ml.rotation.x = -sin(walk_cycle) * 0.40
			if leg_mr: leg_mr.rotation.x = sin(walk_cycle) * 0.40
			if leg_rl: leg_rl.rotation.x = -sin(walk_cycle) * 0.45
			if leg_rr: leg_rr.rotation.x = sin(walk_cycle) * 0.45
			if body_mesh: body_mesh.position.y = 0.5 + absf(sin(walk_cycle)) * 0.04
	else:
		var v_vertical = up_dir * velocity.dot(up_dir)
		velocity = v_vertical
		walk_cycle += delta * 1.2
		if body_mesh: body_mesh.position.y = 0.45 + sin(walk_cycle) * 0.02
		if leg_fl: leg_fl.rotation.x = lerp_angle(leg_fl.rotation.x, 0.0, delta * 8.0)
		if leg_fr: leg_fr.rotation.x = lerp_angle(leg_fr.rotation.x, 0.0, delta * 8.0)
		if leg_rl: leg_rl.rotation.x = lerp_angle(leg_rl.rotation.x, 0.0, delta * 8.0)
		if leg_rr: leg_rr.rotation.x = lerp_angle(leg_rr.rotation.x, 0.0, delta * 8.0)
		if caudal_tail: caudal_tail.rotation.y = lerp_angle(caudal_tail.rotation.y, 0.0, delta * 4.0)
		
	up_direction = up_dir
	if locomotion_domain != LocomotionDomain.AERIAL_FLOAT:
		if is_on_floor():
			var v_rad = velocity.dot(up_dir)
			if v_rad > 0.0:
				velocity -= up_dir * v_rad
	move_and_slide()

func _get_wander_tangent(up_dir: Vector3, delta: float) -> Vector3:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(3.5, 8.0)
		var rand_vec = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		wander_tangent = (rand_vec - up_dir * rand_vec.dot(up_dir)).normalized()
	return wander_tangent

func _perform_attack(delta: float, force: bool = false) -> void:
	attack_cooldown -= delta
	if force or attack_cooldown <= 0.0:
		attack_cooldown = 1.2
		var dmg = 12.0
		var knock_force = 9.0
		if creature_size == CreatureSize.COLOSSAL:
			dmg = 26.0
			knock_force = 16.0
		elif creature_size == CreatureSize.SMALL:
			dmg = 7.0
			knock_force = 6.0
		
		var up_dir = global_position.normalized()
		
		if is_fed and is_instance_valid(target_enemy) and not target_enemy.get("is_dead"):
			# Tamed companion defends player by attacking hostile mob!
			var knock = (target_enemy.global_position - global_position).normalized() * knock_force + up_dir * 3.5
			if target_enemy.has_method("take_plasma_damage"):
				target_enemy.take_plasma_damage(dmg, knock)
			elif target_enemy.has_method("take_damage"):
				target_enemy.take_damage(dmg, knock)
			# Enemy retaliates against pet
			if target_enemy.get("target_enemy") == null:
				target_enemy.set("target_enemy", self)
			AudioManager.play("thruster", 1.4, -4.0)
		elif is_aggressive and is_instance_valid(target_enemy) and not target_enemy.get("is_dead"):
			# Hostile mob attacks pet or rival in inter-mob battle!
			var knock = (target_enemy.global_position - global_position).normalized() * knock_force + up_dir * 3.5
			if target_enemy.has_method("take_plasma_damage"):
				target_enemy.take_plasma_damage(dmg, knock)
			elif target_enemy.has_method("take_damage"):
				target_enemy.take_damage(dmg, knock)
			AudioManager.play("thruster", 1.4, -4.0)
		elif target_player and target_player.has_method("take_damage"):
			# Hostile mob attacks player with real damage, screen kick, sound, and knockback!
			target_player.take_damage(dmg, global_position)
			AudioManager.play("thruster", 1.4, -2.0)

# Carrying & Interaction Interface
func can_be_carried() -> bool:
	return is_fed and not is_dead and not is_aggressive and creature_size != CreatureSize.COLOSSAL

func pick_up(carrier: Node3D) -> void:
	is_being_carried = true
	carrier_player = carrier
	if is_fed:
		target_player = carrier
	if col_shape: col_shape.set_deferred("disabled", true)
	AudioManager.play("hop", 1.1, 0.0)

func drop_gently() -> void:
	is_being_carried = false
	if is_fed and is_instance_valid(carrier_player):
		target_player = carrier_player
	carrier_player = null
	if col_shape: col_shape.set_deferred("disabled", false)
	AudioManager.play("hop", 0.9, 0.0)
	if is_stranded_on_land and global_position.length() < planet_radius + 0.1:
		rescue_creature()

func throw_ballistic(throw_impulse: Vector3) -> void:
	is_being_carried = false
	carrier_player = null
	if col_shape: col_shape.set_deferred("disabled", false)
	velocity = throw_impulse
	is_in_ragdoll = true
	ragdoll_timer = 2.0
	AudioManager.play("thruster", 1.5, -2.0)

func rescue_creature() -> String:
	is_stranded_on_land = false
	var reward = "ocean_pearl"
	creature_rescued.emit(reward)
	if GameManager and GameManager.crafting:
		GameManager.crafting.add_resource("ocean_pearl", 1)
		GameManager.crafting.add_resource("pearl", 1)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("¡CRIATURA RESCATADA! Devuelta al océano.")
	AudioManager.play("collect", 1.3, 2.0)
	return reward

func take_damage(dmg: float, hit_impulse: Vector3 = Vector3.ZERO) -> Dictionary:
	if is_dead:
		return {}
	is_fed = false
	if ai_archetype == AIArchetype.NEUTRAL or ai_archetype == AIArchetype.PEACEFUL:
		is_aggressive = true
		ai_archetype = AIArchetype.AGGRESSIVE
	current_health = maxf(0.0, current_health - dmg)
	creature_damaged.emit(current_health, max_health)
	AudioManager.play("mine", 1.3, 0.0)
	
	var up_dir = global_position.normalized()
	if hit_impulse == Vector3.ZERO:
		var from_pos = global_position - global_transform.basis.z
		if is_instance_valid(target_player):
			from_pos = target_player.global_position
		var knock_dir = (global_position - from_pos).normalized()
		var tangent_knock = (knock_dir - up_dir * knock_dir.dot(up_dir)).normalized()
		var pwr = 8.5 if creature_size != CreatureSize.COLOSSAL else 4.0
		hit_impulse = tangent_knock * pwr + up_dir * 3.8
		
	if current_health > 0.0:
		is_in_ragdoll = true
		ragdoll_timer = 0.80
		velocity = hit_impulse
		
	if body_mesh and body_mesh.material_override is StandardMaterial3D:
		var m = body_mesh.material_override as StandardMaterial3D
		m.albedo_color = Color.WHITE
		get_tree().create_timer(0.08).timeout.connect(func():
			if is_instance_valid(m): m.albedo_color = creature_color
		)
	if current_health <= 0.0:
		return _die(hit_impulse)
	return {}

func take_plasma_damage(amount: float, hit_impulse: Vector3 = Vector3.ZERO) -> void:
	take_damage(amount, hit_impulse)

func feed_creature(food_item: String = "plant_fibers") -> String:
	if is_dead or creature_size == CreatureSize.COLOSSAL:
		return ""
	is_fed = true
	is_aggressive = false
	ai_archetype = AIArchetype.PEACEFUL
	current_health = max_health
	
	# Warm friendly eye glow
	eye_color = Color(0.2, 0.95, 0.45)
	if eye_l and eye_l.material_override is StandardMaterial3D:
		(eye_l.material_override as StandardMaterial3D).emission = eye_color
	if eye_r and eye_r.material_override is StandardMaterial3D:
		(eye_r.material_override as StandardMaterial3D).emission = eye_color
	
	AudioManager.play("collect", 1.25, 2.0)
	AudioManager.play("hop", 1.2, 0.0)
	creature_fed.emit(loot_item_friendly)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_status_toast"):
		hud.show_status_toast("¡CRIATURA DOMADA! Alimentada con %s. Te seguirá y defenderá." % food_item.capitalize().replace("_", " "))
		
	var tw = create_tween()
	tw.tween_property(self, "scale", scale * 1.25, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", scale, 0.22)
	
	if GameManager and GameManager.crafting:
		GameManager.crafting.add_resource("biogel_sample", 1)
	return loot_item_friendly

func _die(death_impulse: Vector3 = Vector3.ZERO) -> Dictionary:
	is_dead = true
	is_in_ragdoll = true
	ragdoll_timer = 1.4
	
	var up_dir = global_position.normalized()
	if death_impulse != Vector3.ZERO:
		velocity = death_impulse * 1.25
	else:
		velocity = -global_transform.basis.z * 5.0 + up_dir * 4.5
		
	collision_layer = 0
	collision_mask = 1
	if is_instance_valid(carrier_player):
		carrier_player.drop_carried_creature()
		
	var loot = { "item": loot_item_defeat, "amount": 2, "alien_meat": 2, "alien_chitin": 1 }
	creature_died.emit(loot)
	AudioManager.play("collect", 0.9, 2.0)
	AudioManager.play("hop", 0.7, 4.0)
	
	if GameManager and GameManager.crafting:
		GameManager.crafting.add_resource("alien_meat", 2)
		GameManager.crafting.add_resource("alien_chitin", 1)
		if is_aggressive:
			GameManager.crafting.add_resource("alien_fang", 1)
			loot["alien_fang"] = 1
		if elemental_type == ElementalType.MAGMA_PYRO:
			GameManager.crafting.add_resource("iron", 2)
		elif elemental_type == ElementalType.RADIOACTIVE_URANIUM:
			GameManager.crafting.add_resource("uranium", 2)
		elif elemental_type == ElementalType.MINERAL_SILICON:
			GameManager.crafting.add_resource("silicon", 2)
		else:
			GameManager.crafting.add_resource("copper", 1)
			
	var tw = create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
	return loot

func set_lod_level(level: int) -> void:
	if level >= 3:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	visible = true
	match level:
		0:
			process_mode = Node.PROCESS_MODE_INHERIT
			set_physics_process(true)
			set_process(true)
			_set_shadow_casting(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
			if lantern_lure: lantern_lure.visible = (sub_species == SubSpecies.LANTERN_ANGLER or sub_species == SubSpecies.HEXAPOD_LUMEN)
		1:
			process_mode = Node.PROCESS_MODE_INHERIT
			set_physics_process(true)
			set_process(true)
			_set_shadow_casting(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		2:
			process_mode = Node.PROCESS_MODE_DISABLED
			set_physics_process(false)
			set_process(false)
			_set_shadow_casting(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			if horn_l: horn_l.visible = false
			if horn_r: horn_r.visible = false
			if lantern_lure: lantern_lure.visible = false

func _set_shadow_casting(setting: GeometryInstance3D.ShadowCastingSetting) -> void:
	if body_mesh: body_mesh.cast_shadow = setting
	if head_mesh: head_mesh.cast_shadow = setting
