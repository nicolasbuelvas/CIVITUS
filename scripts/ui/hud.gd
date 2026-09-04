extends Control

@onready var o2_bar: ProgressBar = $TopVitals/VBox/O2Container/ProgressBar
@onready var fuel_bar: ProgressBar = $TopVitals/VBox/FuelContainer/ProgressBar
@onready var hull_bar: ProgressBar = $TopVitals/VBox/HullContainer/ProgressBar
@onready var quota_label: Label = $TopVitals/VBox/QuotaContainer/QuotaLabel
@onready var planet_name_label: Label = $TopHeader/PlanetNameLabel
@onready var env_info_label: Label = $TopHeader/EnvInfoLabel
@onready var escape_button: Button = $ActionContainer/EscapeButton
@onready var game_over_panel: Panel = $GameOverModal
@onready var victory_panel: Panel = $VictoryModal
@onready var game_over_reason: Label = $GameOverModal/VBox/ReasonLabel

var player: CharacterBody3D = null

func _ready() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	escape_button.visible = false
	
	# Setup planet display
	var p = GameManager.current_planet
	planet_name_label.text = str(p.get("name", "Desconocido"))
	env_info_label.text = "GRAV: %.1f m/s² | TEMP: %.0f°C | NIVEL: %d" % [
		p.get("gravity", 9.8),
		p.get("temperature", 20.0),
		p.get("difficulty", 0)
	]
	
	GameManager.game_over.connect(_on_game_over)
	GameManager.expedition_completed.connect(_on_expedition_completed)

func init_player(p_node: CharacterBody3D) -> void:
	player = p_node
	player.stats_changed.connect(_on_stats_changed)

func _on_stats_changed(o2: float, fuel: float, hull: float, minerals: int) -> void:
	o2_bar.value = o2
	fuel_bar.value = fuel
	hull_bar.value = hull
	
	var target = GameManager.player_stats.target_minerals
	quota_label.text = "MINERALES: %d / %d" % [minerals, target]
	
	if minerals >= target:
		quota_label.modulate = Color.GREEN
		escape_button.visible = true
	else:
		quota_label.modulate = Color.WHITE
		escape_button.visible = false

func _on_rotate_left_pressed() -> void:
	if player:
		player.rotate_camera(-PI / 4.0)

func _on_rotate_right_pressed() -> void:
	if player:
		player.rotate_camera(PI / 4.0)

func _on_thrust_button_down() -> void:
	Input.action_press("jump_thrust")

func _on_thrust_button_up() -> void:
	Input.action_release("jump_thrust")

func _on_escape_button_pressed() -> void:
	# Find lander in world and launch
	var lander = get_tree().get_first_node_in_group("lander")
	if lander and lander.has_method("launch_escape"):
		lander.launch_escape()
	else:
		# Direct trigger
		GameManager.expedition_completed.emit({
			"planet": GameManager.current_planet.name,
			"minerals": GameManager.player_stats.minerals_collected
		})

func _on_game_over(reason: String) -> void:
	game_over_reason.text = reason
	game_over_panel.visible = true

func _on_expedition_completed(summary: Dictionary) -> void:
	victory_panel.visible = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/main_menu.tscn")
