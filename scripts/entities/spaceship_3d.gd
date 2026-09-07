extends Node3D

signal hyperdrive_launched()
signal hull_integrity_changed(health_dict: Dictionary, is_breached: bool)

@onready var interior_area: Area3D = $CabinInterior/InteriorArea
@onready var airlock_door: Node3D = $HullStructure/AirlockDoor
@onready var airlock_door_col: CollisionShape3D = $HullStructure/AirlockDoor/CollisionShape3D
@onready var airlock_light: OmniLight3D = $HullStructure/AirlockLight
@onready var airlock_trigger: Area3D = $HullStructure/AirlockTrigger
@onready var hyperdrive_light: OmniLight3D = $CabinInterior/HyperdriveCore/OmniLight3D
@onready var hyperdrive_core_mesh: MeshInstance3D = $CabinInterior/HyperdriveCore/CoreCylinder

var is_player_in_cabin: bool = false
var is_player_in_airlock: bool = false
var is_airlock_open: bool = false
var player_ref: CharacterBody3D = null

# Modular Hull System: Parts that degrade in hostile environments
var module_health: Dictionary = {
	"nose": 100.0,
	"port": 100.0,
	"starboard": 100.0,
	"roof": 100.0,
	"airlock": 100.0
}
var is_hull_breached: bool = false
var hazard_degradation_rate: float = 0.0

func _ready() -> void:
	interior_area.body_entered.connect(_on_cabin_entered)
	interior_area.body_exited.connect(_on_cabin_exited)
	airlock_trigger.body_entered.connect(_on_airlock_entered)
	airlock_trigger.body_exited.connect(_on_airlock_exited)
	
	GameManager.crafting.hyperdrive_repaired.connect(func(p): _update_hyperdrive_lights())
	_update_hyperdrive_lights()
	
	# Initial airlock closed state
	if airlock_door:
		airlock_door.position.y = 1.3
	if airlock_door_col:
		airlock_door_col.set_deferred("disabled", false)
	if airlock_light:
		airlock_light.light_color = Color(0.2, 0.8, 1.0)

	# Calibrate environmental hazards
	var planet = GameManager.current_planet
	var lvl = planet.get("level", 0)
	if lvl >= 2:
		hazard_degradation_rate = 0.45 * float(lvl)

func _process(delta: float) -> void:
	# 1. Environmental degradation on external modules
	if hazard_degradation_rate > 0.0:
		for k in module_health.keys():
			module_health[k] = max(0.0, module_health[k] - hazard_degradation_rate * delta)
		
		var min_hp = module_health.values().min()
		var breached_now = (min_hp <= 0.0)
		if breached_now != is_hull_breached:
			is_hull_breached = breached_now
			hull_integrity_changed.emit(module_health, is_hull_breached)

	# 2. Cabin survival & life support
	if is_player_in_cabin:
		if not is_hull_breached:
			# Pressurized habitat: 100% vital regeneration
			GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 50.0 * delta)
			GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 20.0 * delta)
			GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 35.0 * delta)
		else:
			# Hull breached: Life support offline! Cabin exposed to hostile atmosphere
			GameManager.player_stats.oxygen = max(0.0, GameManager.player_stats.oxygen - 2.5 * delta)
			GameManager.player_stats.hull = max(0.0, GameManager.player_stats.hull - 3.0 * delta)
			
			# Alarm light pulsation
			var pulse = sin(Time.get_ticks_msec() * 0.008) * 0.5 + 0.5
			if airlock_light:
				airlock_light.light_color = Color(1.0, 0.1, 0.1) * (0.4 + pulse * 0.6)

	# 3. Hyperdrive core rotation
	var prog = GameManager.crafting.get_hyperdrive_progress()
	var t = Time.get_ticks_msec() / 1000.0
	if hyperdrive_light:
		hyperdrive_light.light_energy = 1.0 + (prog * 2.5) + sin(t * (3.0 + prog * 4.0)) * 0.3
	if hyperdrive_core_mesh:
		hyperdrive_core_mesh.rotation.y += delta * (1.0 + prog * 3.0)

func get_lowest_module_health() -> float:
	return module_health.values().min()

func can_repair_hull() -> bool:
	return get_lowest_module_health() < 95.0

func repair_hull_modules() -> bool:
	var inv = GameManager.crafting.inventory
	var iron = inv.get("iron", 0)
	var copper = inv.get("copper", 0)
	if iron >= 2 or copper >= 2:
		if iron >= 2:
			GameManager.crafting.remove_resource("iron", 2)
		else:
			GameManager.crafting.remove_resource("copper", 2)
		for k in module_health.keys():
			module_health[k] = 100.0
		is_hull_breached = false
		if airlock_light:
			airlock_light.light_color = Color(0.2, 1.0, 0.4)
		hull_integrity_changed.emit(module_health, is_hull_breached)
		AudioManager.play("crafting", 1.0)
		return true
	return false

# Clean, robust proximity airlock
func _on_airlock_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_airlock = true
		player_ref = body as CharacterBody3D
		open_airlock()

func _on_airlock_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_airlock = false
		close_airlock()

func open_airlock() -> void:
	is_airlock_open = true
	AudioManager.play("airlock", 1.05)
	if airlock_door_col:
		airlock_door_col.set_deferred("disabled", true)
	if airlock_light and not is_hull_breached:
		airlock_light.light_color = Color(0.2, 1.0, 0.4) # Green open
	if airlock_door:
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(airlock_door, "position:y", 3.2, 0.35)

func close_airlock() -> void:
	is_airlock_open = false
	AudioManager.play("airlock", 0.95)
	if airlock_door:
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(airlock_door, "position:y", 1.3, 0.35)
		tween.tween_callback(func():
			if not is_airlock_open and airlock_door_col:
				airlock_door_col.set_deferred("disabled", false)
			if airlock_light and not is_hull_breached:
				airlock_light.light_color = Color(0.2, 0.8, 1.0)
		)

func _on_cabin_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = true
		player_ref = body as CharacterBody3D
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(false)

func _on_cabin_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = false
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true)

func _update_hyperdrive_lights() -> void:
	var prog = GameManager.crafting.get_hyperdrive_progress()
	if not hyperdrive_light: return
	if prog >= 1.0:
		hyperdrive_light.light_color = Color(0.2, 1.0, 0.4)
	elif prog > 0.3:
		hyperdrive_light.light_color = Color(0.2, 0.8, 1.0)
	else:
		hyperdrive_light.light_color = Color(1.0, 0.35, 0.15)

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
