extends Node3D

signal open_crafting_menu()
signal open_hyperdrive_menu()
signal open_starmap_menu()

@onready var interior_area: Area3D = $InteriorArea
@onready var hyperdrive_core_mesh: MeshInstance3D = $HyperdriveCore/CoreMesh
@onready var hyperdrive_light: OmniLight3D = $HyperdriveCore/OmniLight3D

var is_player_inside: bool = false

func _ready() -> void:
	interior_area.body_entered.connect(_on_body_entered)
	interior_area.body_exited.connect(_on_body_exited)
	GameManager.crafting.hyperdrive_repaired.connect(_on_part_installed)
	_update_hyperdrive_visuals()

func _process(delta: float) -> void:
	if is_player_inside:
		# Rapidly replenish O2 and Hull inside the warm, pressurized ship!
		GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 40.0 * delta)
		GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 10.0 * delta)
		GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 25.0 * delta)
	
	# Pulse hyperdrive light based on repair progress
	var prog = GameManager.crafting.get_hyperdrive_progress()
	var t = Time.get_ticks_msec() / 1000.0
	hyperdrive_light.light_energy = 1.0 + (prog * 3.0) + sin(t * (3.0 + prog * 8.0)) * (0.3 + prog * 0.5)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_inside = true
		AudioManager.play("airlock", 1.0)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_inside = false
		AudioManager.play("airlock", 0.9)

func _on_part_installed(part_name: String) -> void:
	_update_hyperdrive_visuals()
	AudioManager.play("craft", 1.1)

func _update_hyperdrive_visuals() -> void:
	var prog = GameManager.crafting.get_hyperdrive_progress()
	if prog >= 1.0:
		hyperdrive_light.light_color = Color(0.2, 1.0, 0.4) # Glowing ready green
	elif prog > 0.4:
		hyperdrive_light.light_color = Color(0.2, 0.8, 1.0) # Cyan charging
	else:
		hyperdrive_light.light_color = Color(1.0, 0.4, 0.2) # Orange broken

func trigger_hyperjump() -> void:
	if not GameManager.crafting.is_hyperdrive_complete():
		return
		
	AudioManager.play("hyperdrive", 1.0)
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y + 60.0, 3.5)
	tween.tween_callback(func():
		GameManager.expedition_completed.emit({
			"planet": GameManager.current_planet.get("name", "Unknown"),
			"difficulty": GameManager.current_planet.get("difficulty", 0),
			"hyperdrive": "100% OPERATIONAL"
		})
	)
