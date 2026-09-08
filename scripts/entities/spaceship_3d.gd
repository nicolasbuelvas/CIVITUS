extends Node3D

signal hyperdrive_launched()
signal hull_integrity_changed(health_dict: Dictionary, is_breached: bool)

@onready var interior_area: Area3D = $CabinInterior/InteriorArea
@onready var outer_cylinder: CSGCylinder3D = $HullStructure/CapsuleHull/OuterCylinder
@onready var interior_light: OmniLight3D = $CabinInterior/InteriorLight
@onready var hatch_node: AnimatableBody3D = get_node_or_null("HullStructure/ApolloHatch")
@onready var hatch_col: CollisionShape3D = get_node_or_null("HullStructure/ApolloHatch/CollisionShape3D")

var is_player_in_cabin: bool = false
var is_hatch_open: bool = false
var is_operating_hatch: bool = false
var is_equalizing_pressure: bool = false
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
	
	# Initial state: Hatch closed, solid
	is_hatch_open = false
	is_operating_hatch = false
	is_equalizing_pressure = false
	if hatch_node:
		hatch_node.position.y = 1.35
	if hatch_col:
		hatch_col.set_deferred("disabled", false)
	
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

	# 2. Cabin is ALWAYS a 100% SAFE HAVEN
	if is_player_in_cabin:
		GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 60.0 * delta)
		GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 35.0 * delta)
		GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 45.0 * delta)

# Interaction prompt calculation based on exact player location
func get_hatch_interaction_state(p: CharacterBody3D) -> String:
	if is_operating_hatch:
		return ""
		
	var local_p = to_local(p.global_position)
	
	if not is_hatch_open:
		# Hatch is closed. Player can open it from inside near the hatch:
		if is_player_in_cabin and local_p.z > 0.2 and local_p.z < 3.2:
			return "open_hatch"
		return ""
	else:
		# Hatch is open. Player can close it ONLY from inside near the center:
		# local_p.z <= 1.5 prevents closing while in the doorway threshold or outside!
		if is_player_in_cabin and local_p.z <= 1.5 and local_p.length() < 2.5:
			return "close_hatch"
		return ""

# Hatch Opening Sequence: Atmospheric balancing + helmet donning + smooth slide open
func open_hatch() -> void:
	if is_operating_hatch or is_hatch_open:
		return
	is_operating_hatch = true
	is_equalizing_pressure = true
	
	# Atmospheric decompression / hiss sound
	AudioManager.play("airlock", 0.9, -2.0)
	
	# Character animation: putting on helmet before depressurization
	if player_ref and player_ref.has_method("animate_put_on_helmet"):
		player_ref.animate_put_on_helmet()
	elif player_ref and player_ref.has_method("set_suit_mode"):
		player_ref.set_suit_mode(true)
		
	# Equalization duration (1.4s)
	var tween = create_tween()
	tween.tween_interval(1.4)
	tween.tween_callback(func():
		is_equalizing_pressure = false
		_open_hatch_direct()
	)

func _open_hatch_direct() -> void:
	AudioManager.play("click", 1.1)
	if hatch_col:
		hatch_col.set_deferred("disabled", true)
	if hatch_node:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(hatch_node, "position:y", 3.65, 0.45)
		tw.tween_callback(func():
			is_hatch_open = true
			is_operating_hatch = false
		)
	else:
		is_hatch_open = true
		is_operating_hatch = false

# Hatch Closing Sequence: Fast and smooth seal (0.35s)
func close_hatch() -> void:
	if is_operating_hatch or not is_hatch_open:
		return
	is_operating_hatch = true
	AudioManager.play("airlock", 1.2, -4.0)
	
	if hatch_col:
		hatch_col.set_deferred("disabled", false)
	if hatch_node:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(hatch_node, "position:y", 1.35, 0.35)
		tw.tween_callback(func():
			is_hatch_open = false
			is_operating_hatch = false
			# Cabin is now sealed: take off helmet and reveal face
			if player_ref and player_ref.has_method("animate_take_off_helmet"):
				player_ref.animate_take_off_helmet()
			elif player_ref and player_ref.has_method("set_suit_mode"):
				player_ref.set_suit_mode(false)
		)
	else:
		is_hatch_open = false
		is_operating_hatch = false

func _update_hazard_oxidation_visuals(planet: Dictionary, temp: float) -> void:
	if not active_hull_material:
		return
		
	var dmg_ratio = clamp(1.0 - (capsule_hull_hp / 100.0), 0.0, 1.0)
	var clean_col = Color(0.88, 0.90, 0.94)
	var p_type = planet.get("type", "")

	if temp < -35.0 or p_type.contains("Cryo") or p_type.contains("Hielo"):
		var ice_cyan = Color(0.42, 0.70, 0.92)
		active_hull_material.albedo_color = clean_col.lerp(ice_cyan, 0.35 + dmg_ratio * 0.65)
		active_hull_material.roughness = 0.85
	elif temp > 75.0 or p_type.contains("Volcan") or p_type.contains("Lava"):
		var scorch_black = Color(0.14, 0.10, 0.08)
		active_hull_material.albedo_color = clean_col.lerp(scorch_black, 0.45 + dmg_ratio * 0.55)
		active_hull_material.roughness = 0.9
		if dmg_ratio > 0.3:
			active_hull_material.emission_enabled = true
			active_hull_material.emission = Color(0.9, 0.25, 0.05) * (dmg_ratio - 0.3) * 1.5
	elif p_type.contains("Toxic") or p_type.contains("Acido"):
		var acid_col = Color(0.46, 0.66, 0.24)
		active_hull_material.albedo_color = clean_col.lerp(acid_col, 0.4 + dmg_ratio * 0.6)
		active_hull_material.roughness = 0.8
	else:
		var dust_col = Color(0.68, 0.52, 0.22)
		active_hull_material.albedo_color = clean_col.lerp(dust_col, 0.35 + dmg_ratio * 0.65)
		active_hull_material.roughness = 0.75

func _on_cabin_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = true
		player_ref = body as CharacterBody3D
		if not is_hatch_open:
			if player_ref and player_ref.has_method("set_suit_mode"):
				player_ref.set_suit_mode(false)

func _on_cabin_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = false
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true)
