extends Node3D

@onready var shelter_area: Area3D = $ShelterArea
@onready var sprite: Sprite3D = $Sprite3D

var is_player_in_shelter: bool = false

func _ready() -> void:
	shelter_area.body_entered.connect(_on_body_entered)
	shelter_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_player_in_shelter:
		# Rapidly replenish player oxygen and fuel
		GameManager.player_stats.oxygen = min(100.0, GameManager.player_stats.oxygen + 35.0 * delta)
		GameManager.player_stats.fuel = min(100.0, GameManager.player_stats.fuel + 40.0 * delta)
		# Recover suit integrity slightly
		GameManager.player_stats.hull = min(100.0, GameManager.player_stats.hull + 5.0 * delta)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_shelter = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		is_player_in_shelter = false

func launch_escape() -> void:
	# Rocket launch animation
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "position:y", 40.0, 2.5)
	tween.tween_callback(func():
		GameManager.expedition_completed.emit({
			"planet": GameManager.current_planet.get("name", "Unknown"),
			"difficulty": GameManager.current_planet.get("difficulty", 0),
			"minerals": GameManager.player_stats.minerals_collected
		})
	)
