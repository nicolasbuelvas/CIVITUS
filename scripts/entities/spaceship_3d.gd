extends Node3D

signal hyperdrive_launched()

@onready var interior_area: Area3D = $CabinInterior/InteriorArea
@onready var hyperdrive_light: OmniLight3D = $CabinInterior/HyperdriveCore/OmniLight3D
@onready var hyperdrive_core_mesh: MeshInstance3D = $CabinInterior/HyperdriveCore/CoreCylinder

var is_player_in_cabin: bool = false
var player_ref: CharacterBody3D = null

func _ready() -> void:
	interior_area.body_entered.connect(_on_cabin_entered)
	interior_area.body_exited.connect(_on_cabin_exited)
	GameManager.crafting.hyperdrive_repaired.connect(func(p): _update_hyperdrive_lights())
	_update_hyperdrive_lights()

func _process(delta: float) -> void:
	if is_player_in_cabin:
		# Recharge vitals inside the pressurized cabin
		GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 45.0 * delta)
		GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 15.0 * delta)
		GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 30.0 * delta)
	
	# Hyperdrive pulse
	var prog = GameManager.crafting.get_hyperdrive_progress()
	var t = Time.get_ticks_msec() / 1000.0
	hyperdrive_light.light_energy = 1.0 + (prog * 3.0) + sin(t * (4.0 + prog * 6.0)) * 0.4

func _on_cabin_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = true
		player_ref = body as CharacterBody3D
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(false) # Take off helmet inside!
		AudioManager.play("airlock", 1.0)

func _on_cabin_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_cabin = false
		if player_ref and player_ref.has_method("set_suit_mode"):
			player_ref.set_suit_mode(true) # Put helmet back on outside!
		AudioManager.play("airlock", 0.9)

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
	tween.tween_property(self, "position:y", position.y + 80.0, 3.5)
	tween.tween_callback(func():
		GameManager.expedition_completed.emit({
			"planet": GameManager.current_planet.get("name", "Unknown"),
			"difficulty": GameManager.current_planet.get("difficulty", 0),
			"hyperdrive": "100% OPERATIVO"
		})
	)
