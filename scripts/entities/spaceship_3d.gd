extends Node3D

signal hyperdrive_launched()
signal hull_integrity_changed(health_dict: Dictionary, is_breached: bool)
signal airlock_state_changed(is_open: bool, is_pressurized: bool, is_equalizing: bool)

@onready var interior_area: Area3D = $CabinInterior/InteriorArea
@onready var airlock_door: Node3D = $HullStructure/AirlockDoor
@onready var airlock_door_col: CollisionShape3D = $HullStructure/AirlockDoor/CollisionShape3D
@onready var airlock_light: OmniLight3D = $HullStructure/AirlockLight
@onready var airlock_trigger: Area3D = $HullStructure/AirlockTrigger
@onready var outer_cylinder: CSGCylinder3D = $HullStructure/CapsuleHull/OuterCylinder

var is_player_in_cabin: bool = false
var is_player_in_airlock: bool = false
var is_airlock_open: bool = false
var is_cabin_pressurized: bool = true # Pressurized when door is closed
var is_equalizing_pressure: bool = false
var player_ref: CharacterBody3D = null

# Hull Protection & Oxidation System
var capsule_hull_hp: float = 100.0
var is_hull_breached: bool = false
var active_hull_material: StandardMaterial3D = null

func _ready() -> void:
	interior_area.body_entered.connect(_on_cabin_entered)
	interior_area.body_exited.connect(_on_cabin_exited)
	airlock_trigger.body_entered.connect(_on_airlock_entered)
	airlock_trigger.body_exited.connect(_on_airlock_exited)
	
	# Duplicate material so this specific ship oxidizes independently
	if outer_cylinder and outer_cylinder.material:
		active_hull_material = outer_cylinder.material.duplicate()
		outer_cylinder.material = active_hull_material
	
	# Initial state: Door closed, cabin pressurized
	is_airlock_open = false
	is_cabin_pressurized = true
	if airlock_door:
		airlock_door.position.y = 1.35
	if airlock_door_col:
		airlock_door_col.set_deferred("disabled", false)
	if airlock_light:
		airlock_light.light_color = Color(0.2, 0.8, 1.0)

func _process(delta: float) -> void:
	var planet = GameManager.current_planet
	var temp = planet.get("temperature", 20.0)
	var is_hostile_temp = (temp > 65.0 or temp < -35.0)
	var lvl = planet.get("level", 0)

	# 1. Environmental damage to the Spaceship Hull first (Heat, Cold, Acid, Radiation)
	if is_hostile_temp or lvl >= 2:
		var dmg_rate = 0.8
		if temp > 100.0:
			dmg_rate += (temp - 100.0) * 0.05
		elif temp < -60.0:
			dmg_rate += abs(temp + 60.0) * 0.04
		if lvl >= 2:
			dmg_rate += float(lvl) * 0.6
			
		capsule_hull_hp = max(0.0, capsule_hull_hp - dmg_rate * delta)
		var was_breached = is_hull_breached
		is_hull_breached = (capsule_hull_hp <= 0.0)
		if is_hull_breached != was_breached:
			hull_integrity_changed.emit({"hull": capsule_hull_hp}, is_hull_breached)
			
		_update_hull_oxidation_visuals()

	# 2. Cabin survival & life support: ONLY when closed & pressurized!
	if is_player_in_cabin:
		if not is_airlock_open and is_cabin_pressurized and not is_hull_breached:
			# Pressurized habitat: 100% vital regeneration and complete thermal shield!
			GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 50.0 * delta)
			GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 20.0 * delta)
			GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 35.0 * delta)
		else:
			# Door open or hull breached: Cabin exposed to alien atmosphere!
			if not planet.get("has_oxygen", false):
				GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - 1.2 * delta)
			if is_hull_breached:
				if temp > 90.0:
					GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - (temp - 90.0) * 0.03 * delta)
				elif temp < -40.0:
					GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - abs(temp + 40.0) * 0.02 * delta)

# Visual Oxidation, Scorching & Thermal Damage
func _update_hull_oxidation_visuals() -> void:
	if not active_hull_material:
		return
	var dmg_ratio = clamp(1.0 - (capsule_hull_hp / 100.0), 0.0, 1.0)
	
	# Transitions from clean white alloy to oxidized rust-brown, then scorched charred black
	var clean_col = Color(0.92, 0.94, 0.97)
	var rust_col = Color(0.48, 0.28, 0.18)
	var scorched_col = Color(0.12, 0.08, 0.06)
	
	if dmg_ratio < 0.5:
		active_hull_material.albedo_color = clean_col.lerp(rust_col, dmg_ratio * 2.0)
		active_hull_material.roughness = lerp(0.35, 0.70, dmg_ratio * 2.0)
		active_hull_material.metallic = lerp(0.3, 0.15, dmg_ratio * 2.0)
	else:
		var severe_ratio = (dmg_ratio - 0.5) * 2.0
		active_hull_material.albedo_color = rust_col.lerp(scorched_col, severe_ratio)
		active_hull_material.roughness = lerp(0.70, 0.95, severe_ratio)
		active_hull_material.metallic = lerp(0.15, 0.05, severe_ratio)
		active_hull_material.emission_enabled = true
		active_hull_material.emission = Color(0.9, 0.25, 0.05) * severe_ratio * 1.5

# Manual & Interactive Airlock Control
func toggle_airlock() -> void:
	if is_equalizing_pressure:
		return
	if is_airlock_open:
		# Close airlock
		_close_airlock_sequence()
	else:
		# Open airlock
		_open_airlock_sequence()

func _open_airlock_sequence() -> void:
	if is_player_in_cabin and is_cabin_pressurized:
		# Inside cabin: Equalize pressure first!
		is_equalizing_pressure = true
		AudioManager.play("airlock", 0.9)
		if airlock_light:
			airlock_light.light_color = Color(1.0, 0.75, 0.15) # Amber equalizing
		# Put helmet ON before depressurization
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true)
		airlock_state_changed.emit(is_airlock_open, is_cabin_pressurized, is_equalizing_pressure)
		
		var tween = create_tween()
		tween.tween_interval(1.8)
		tween.tween_callback(func():
			is_equalizing_pressure = false
			is_cabin_pressurized = false
			_open_door_direct()
		)
	else:
		# Outside: Open door directly
		_open_door_direct()

func _close_airlock_sequence() -> void:
	_close_door_direct()
	if is_player_in_cabin:
		# Inside: Equalize pressure and repressurize cabin
		is_equalizing_pressure = true
		AudioManager.play("airlock", 1.0)
		if airlock_light:
			airlock_light.light_color = Color(1.0, 0.75, 0.15)
		airlock_state_changed.emit(is_airlock_open, is_cabin_pressurized, is_equalizing_pressure)
		
		var tween = create_tween()
		tween.tween_interval(1.8)
		tween.tween_callback(func():
			is_equalizing_pressure = false
			is_cabin_pressurized = true
			if airlock_light:
				airlock_light.light_color = Color(0.2, 0.8, 1.0) # Cyan pressurized safe
			# Safe! Remove helmet and show human face!
			if player_ref and player_ref.has_method("set_suit_mode"):
				player_ref.set_suit_mode(false)
			airlock_state_changed.emit(is_airlock_open, is_cabin_pressurized, is_equalizing_pressure)
		)

func _open_door_direct() -> void:
	is_airlock_open = true
	AudioManager.play("airlock", 1.1)
	if airlock_door_col:
		airlock_door_col.set_deferred("disabled", true)
	if airlock_light and not is_hull_breached:
		airlock_light.light_color = Color(0.2, 1.0, 0.4) # Green open
	if airlock_door:
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(airlock_door, "position:y", 3.4, 0.35)
	airlock_state_changed.emit(is_airlock_open, is_cabin_pressurized, is_equalizing_pressure)

func _close_door_direct() -> void:
	is_airlock_open = false
	AudioManager.play("airlock", 0.95)
	if airlock_door:
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(airlock_door, "position:y", 1.35, 0.35)
		tween.tween_callback(func():
			if not is_airlock_open and airlock_door_col:
				airlock_door_col.set_deferred("disabled", false)
			if airlock_light and not is_hull_breached and not is_equalizing_pressure:
				airlock_light.light_color = Color(0.2, 0.8, 1.0)
		)
	airlock_state_changed.emit(is_airlock_open, is_cabin_pressurized, is_equalizing_pressure)

func _on_airlock_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_airlock = true
		player_ref = body as CharacterBody3D

func _on_airlock_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_airlock = false

func _on_cabin_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = true
		player_ref = body as CharacterBody3D
		if is_cabin_pressurized and not is_airlock_open:
			if player_ref and player_ref.has_method("set_suit_mode"):
				player_ref.set_suit_mode(false)

func _on_cabin_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = false
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true)

func repair_hull_modules() -> bool:
	var inv = GameManager.crafting.inventory
	var iron = inv.get("iron", 0)
	var copper = inv.get("copper", 0)
	if iron >= 2 or copper >= 2:
		if iron >= 2:
			GameManager.crafting.remove_resource("iron", 2)
		else:
			GameManager.crafting.remove_resource("copper", 2)
		capsule_hull_hp = 100.0
		is_hull_breached = false
		_update_hull_oxidation_visuals()
		if airlock_light:
			airlock_light.light_color = Color(0.2, 1.0, 0.4)
		hull_integrity_changed.emit({"hull": capsule_hull_hp}, is_hull_breached)
		AudioManager.play("crafting", 1.0)
		return true
	return false
