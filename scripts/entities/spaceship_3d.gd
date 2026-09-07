extends Node3D

signal hyperdrive_launched()

@onready var interior_area: Area3D = $CabinInterior/InteriorArea
@onready var airlock_outer_door: Node3D = $HullStructure/AirlockChamber/OuterDoor
@onready var airlock_inner_door: Node3D = $HullStructure/AirlockChamber/InnerDoor
@onready var airlock_light: OmniLight3D = $HullStructure/AirlockChamber/AirlockLight
@onready var airlock_trigger: Area3D = $HullStructure/AirlockChamber/AirlockTrigger
@onready var hyperdrive_light: OmniLight3D = $CabinInterior/HyperdriveCore/OmniLight3D
@onready var hyperdrive_core_mesh: MeshInstance3D = $CabinInterior/HyperdriveCore/CoreCylinder

var is_player_in_cabin: bool = false
var is_player_in_airlock: bool = false
var player_ref: CharacterBody3D = null

enum AirlockState { CLOSED, OPENING_OUTER, OPEN_OUTER, PRESSURIZING, OPENING_INNER, OPEN_INNER }
var airlock_state: AirlockState = AirlockState.CLOSED

func _ready() -> void:
	interior_area.body_entered.connect(_on_cabin_entered)
	interior_area.body_exited.connect(_on_cabin_exited)
	airlock_trigger.body_entered.connect(_on_airlock_entered)
	airlock_trigger.body_exited.connect(_on_airlock_exited)
	
	GameManager.crafting.hyperdrive_repaired.connect(func(p): _update_hyperdrive_lights())
	_update_hyperdrive_lights()
	_update_airlock_visuals(0.0, 0.0, Color(0.2, 0.8, 1.0))

func _process(delta: float) -> void:
	if is_player_in_cabin:
		# Recharge vitals safely inside the pressurized cabin
		GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 50.0 * delta)
		GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 20.0 * delta)
		GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 35.0 * delta)
	
	# Hyperdrive pulse animation
	var prog = GameManager.crafting.get_hyperdrive_progress()
	var t = Time.get_ticks_msec() / 1000.0
	hyperdrive_light.light_energy = 1.2 + (prog * 3.5) + sin(t * (4.0 + prog * 6.0)) * 0.4
	if hyperdrive_core_mesh:
		hyperdrive_core_mesh.rotation.y += delta * (1.0 + prog * 4.0)

func _on_airlock_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_airlock = true
		player_ref = body as CharacterBody3D
		_cycle_airlock_inbound()

func _on_airlock_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_airlock = false
		_cycle_airlock_close()

func _cycle_airlock_inbound() -> void:
	AudioManager.play("airlock", 1.1)
	# Smoothly open outer door, then pressurize
	var tween = create_tween().set_parallel(false)
	# Outer door slide open
	tween.tween_property(airlock_outer_door, "position:y", 2.2, 0.4)
	tween.tween_interval(0.5)
	# Close outer door & pressurize
	tween.tween_property(airlock_outer_door, "position:y", 0.0, 0.3)
	tween.tween_callback(func():
		AudioManager.play("airlock", 0.95)
		airlock_light.light_color = Color(1.0, 0.8, 0.2) # Yellow pressurizing
	)
	tween.tween_interval(0.4)
	# Open inner door & turn green
	tween.tween_property(airlock_inner_door, "position:y", 2.2, 0.35)
	tween.tween_callback(func():
		airlock_light.light_color = Color(0.2, 1.0, 0.4) # Green pressurized
	)

func _cycle_airlock_close() -> void:
	var tween = create_tween()
	tween.tween_property(airlock_outer_door, "position:y", 0.0, 0.4)
	tween.tween_property(airlock_inner_door, "position:y", 0.0, 0.4)
	tween.tween_callback(func():
		airlock_light.light_color = Color(0.2, 0.8, 1.0)
	)

func _update_airlock_visuals(outer_y: float, inner_y: float, col: Color) -> void:
	if airlock_outer_door: airlock_outer_door.position.y = outer_y
	if airlock_inner_door: airlock_inner_door.position.y = inner_y
	if airlock_light: airlock_light.light_color = col

func _on_cabin_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = true
		player_ref = body as CharacterBody3D
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(false) # Remove helmet inside pressurized cabin!

func _on_cabin_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = false
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true) # Put helmet back on outside!

func _update_hyperdrive_lights() -> void:
	var prog = GameManager.crafting.get_hyperdrive_progress()
	if prog >= 1.0:
		hyperdrive_light.light_color = Color(0.2, 1.0, 0.4) # Green ready
	elif prog > 0.3:
		hyperdrive_light.light_color = Color(0.2, 0.8, 1.0) # Cyan charging
	else:
		hyperdrive_light.light_color = Color(1.0, 0.35, 0.15) # Orange offline

func trigger_hyperjump() -> void:
	AudioManager.play("hyperdrive", 1.0)
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y + 120.0, 3.5)
	tween.tween_callback(func():
		GameManager.expedition_completed.emit({
			"planet": GameManager.current_planet.get("name", "Unknown"),
			"difficulty": GameManager.current_planet.get("difficulty", 0),
			"hyperdrive": "100% OPERATIVO"
		})
	)
