extends Node3D

signal hyperdrive_launched()
signal hull_integrity_changed(health_dict: Dictionary, is_breached: bool)

@onready var interior_area: Area3D = $CabinInterior/InteriorArea
@onready var outer_cylinder: CSGCylinder3D = $HullStructure/CapsuleHull/OuterCylinder
@onready var shield_field: MeshInstance3D = get_node_or_null("HullStructure/AtmosphericShield")
@onready var interior_light: OmniLight3D = $CabinInterior/InteriorLight

var is_player_in_cabin: bool = false
var player_ref: CharacterBody3D = null

# Crash pod integrity & environmental weathering
var capsule_hull_hp: float = 100.0
var active_hull_material: StandardMaterial3D = null

func _ready() -> void:
	interior_area.body_entered.connect(_on_cabin_entered)
	interior_area.body_exited.connect(_on_cabin_exited)
	
	if outer_cylinder and outer_cylinder.material:
		active_hull_material = outer_cylinder.material.duplicate()
		outer_cylinder.material = active_hull_material
	
	# Apply initial planet-specific crash wear & scorch
	var planet = GameManager.current_planet
	_update_hazard_oxidation_visuals(planet, planet.get("temperature", 20.0))

func _process(delta: float) -> void:
	var planet = GameManager.current_planet
	var temp = planet.get("temperature", 20.0)
	var is_hostile_temp = (temp > 65.0 or temp < -35.0)
	var lvl = planet.get("level", 0)

	# 1. Environmental weathering to the outer hull
	if is_hostile_temp or lvl >= 2:
		var dmg_rate = 0.5
		if temp > 90.0:
			dmg_rate += (temp - 90.0) * 0.04
		elif temp < -50.0:
			dmg_rate += abs(temp + 50.0) * 0.03
		capsule_hull_hp = max(10.0, capsule_hull_hp - dmg_rate * delta)
		_update_hazard_oxidation_visuals(planet, temp)

	# 2. Cabin is ALWAYS a 100% SAFE HAVEN after crash landing!
	if is_player_in_cabin:
		# Rapid life-support regeneration & total immunity to exterior hazards
		GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 60.0 * delta)
		GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 35.0 * delta)
		GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 45.0 * delta)

# Environmental Dynamic Weathering / Scorch / Frost
func _update_hazard_oxidation_visuals(planet: Dictionary, temp: float) -> void:
	if not active_hull_material:
		return
		
	var dmg_ratio = clamp(1.0 - (capsule_hull_hp / 100.0), 0.0, 1.0)
	var clean_col = Color(0.88, 0.90, 0.94)
	var p_type = planet.get("type", "")

	if temp < -35.0 or p_type.contains("Cryo") or p_type.contains("Hielo"):
		# Frost & Glacial Ice
		var ice_cyan = Color(0.42, 0.70, 0.92)
		active_hull_material.albedo_color = clean_col.lerp(ice_cyan, 0.35 + dmg_ratio * 0.65)
		active_hull_material.roughness = 0.85
	elif temp > 75.0 or p_type.contains("Volcan") or p_type.contains("Lava"):
		# Atmospheric Reentry Heat Scorching
		var scorch_black = Color(0.14, 0.10, 0.08)
		active_hull_material.albedo_color = clean_col.lerp(scorch_black, 0.45 + dmg_ratio * 0.55)
		active_hull_material.roughness = 0.9
		if dmg_ratio > 0.3:
			active_hull_material.emission_enabled = true
			active_hull_material.emission = Color(0.9, 0.25, 0.05) * (dmg_ratio - 0.3) * 1.5
	elif p_type.contains("Toxic") or p_type.contains("Acido"):
		# Acid verdigris
		var acid_col = Color(0.46, 0.66, 0.24)
		active_hull_material.albedo_color = clean_col.lerp(acid_col, 0.4 + dmg_ratio * 0.6)
		active_hull_material.roughness = 0.8
	else:
		# Desert / Sulfur crash dust
		var dust_col = Color(0.68, 0.52, 0.22)
		active_hull_material.albedo_color = clean_col.lerp(dust_col, 0.35 + dmg_ratio * 0.65)
		active_hull_material.roughness = 0.75

func _on_cabin_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = true
		player_ref = body as CharacterBody3D
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(false) # Safe zone: remove helmet & show face!
		AudioManager.play("airlock", 1.2, -4.0)

func _on_cabin_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = false
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true) # Outside: put helmet on!
		AudioManager.play("airlock", 0.9, -6.0)
