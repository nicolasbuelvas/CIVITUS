extends Node

signal difficulty_changed(new_level: int)
signal planet_params_updated(params: Dictionary)
signal player_vital_updated(stat_name: String, current: float, maximum: float)
signal game_over(reason: String)
signal expedition_completed(summary: Dictionary)

enum Difficulty {
	LEVEL_0 = 0, # Tierra / Seguro
	LEVEL_1 = 1, # Marte/Luna / Moderado
	LEVEL_2 = 2, # Venus/Titán / Inseguro
	LEVEL_3 = 3, # Exótico / Peligroso
	LEVEL_4 = 4, # Vacío / Extremo (Premium)
	LEVEL_5 = 5  # Infierno / Mortal (Premium)
}

const CraftingSystemClass = preload("res://scripts/systems/crafting_system.gd")
const SolarSystemClass = preload("res://scripts/systems/solar_system.gd")

var current_difficulty: Difficulty = Difficulty.LEVEL_0
var is_sandbox: bool = false
var crafting = CraftingSystemClass.new()
var current_solar_system: Dictionary = {}

# Planet parameters generated or edited
var current_planet: Dictionary = {
	"name": "Civitus-Alpha",
	"seed": 1337,
	"difficulty": Difficulty.LEVEL_0,
	"gravity": 9.8,
	"temperature": 21.0,
	"atmosphere": 1.0,
	"radiation": 0.05,
	"has_oxygen": true,
	"coords_str": "[X: 14,290.4 km, Y: -2,450.1 km, Z: 8,910.0 km]",
	"surface_color": Color(0.28, 0.58, 0.35),
	"sky_color": Color(0.12, 0.22, 0.45)
}

# Player Expedition Session stats
var player_stats: Dictionary = {
	"oxygen": 100.0,
	"max_oxygen": 100.0,
	"fuel": 100.0,
	"max_fuel": 100.0,
	"hull": 100.0,
	"max_hull": 100.0,
	"temperature_suit": 22.0
}

func _ready() -> void:
	generate_planet(Difficulty.LEVEL_0)

func set_difficulty(level: Difficulty) -> void:
	current_difficulty = level
	is_sandbox = false
	generate_planet(level)
	difficulty_changed.emit(level)

func generate_planet(diff: Difficulty, custom_seed: int = -1) -> void:
	if custom_seed < 0:
		custom_seed = randi() % 100000
	
	var p_seed = custom_seed
	var rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	
	# Generate Solar System with coordinates (Waste of Space / KSP style)
	current_solar_system = SolarSystemClass.generate_system(p_seed)
	var p_idx = int(diff) % current_solar_system["planets"].size()
	var planet_data = current_solar_system["planets"][p_idx]
	
	var p: Dictionary = {
		"seed": p_seed,
		"difficulty": diff,
		"name": planet_data["name"],
		"coords_str": planet_data["coords_str"],
		"orbit_au": planet_data["orbit_au"],
		"type": planet_data["type"]
	}
	
	match diff:
		Difficulty.LEVEL_0:
			p["gravity"] = 9.8
			p["temperature"] = 22.0
			p["atmosphere"] = 1.0
			p["radiation"] = 0.01
			p["has_oxygen"] = true
			p["surface_color"] = Color(0.28, 0.58, 0.35)
			p["sky_color"] = Color(0.12, 0.22, 0.45)
		Difficulty.LEVEL_1:
			p["gravity"] = 6.5
			p["temperature"] = -25.0
			p["atmosphere"] = 0.4
			p["radiation"] = 0.12
			p["has_oxygen"] = false
			p["surface_color"] = Color(0.72, 0.34, 0.20)
			p["sky_color"] = Color(0.25, 0.12, 0.18)
		Difficulty.LEVEL_2:
			p["gravity"] = 11.2
			p["temperature"] = 140.0
			p["atmosphere"] = 2.2
			p["radiation"] = 0.25
			p["has_oxygen"] = false
			p["surface_color"] = Color(0.65, 0.62, 0.18)
			p["sky_color"] = Color(0.35, 0.32, 0.10)
		Difficulty.LEVEL_3:
			p["gravity"] = 4.0
			p["temperature"] = -160.0
			p["atmosphere"] = 0.1
			p["radiation"] = 0.45
			p["has_oxygen"] = false
			p["surface_color"] = Color(0.22, 0.45, 0.65)
			p["sky_color"] = Color(0.05, 0.08, 0.18)
		Difficulty.LEVEL_4:
			p["gravity"] = 15.5
			p["temperature"] = 380.0
			p["atmosphere"] = 3.5
			p["radiation"] = 0.85
			p["has_oxygen"] = false
			p["surface_color"] = Color(0.38, 0.15, 0.45)
			p["sky_color"] = Color(0.12, 0.04, 0.18)
		Difficulty.LEVEL_5:
			p["gravity"] = 22.0
			p["temperature"] = 720.0
			p["atmosphere"] = 5.0
			p["radiation"] = 1.50
			p["has_oxygen"] = false
			p["surface_color"] = Color(0.68, 0.12, 0.12)
			p["sky_color"] = Color(0.18, 0.02, 0.02)
			
	current_planet = p
	crafting.init_level_requirements(int(diff))
	reset_player_stats()
	planet_params_updated.emit(p)

func reset_player_stats() -> void:
	player_stats.oxygen = 100.0
	player_stats.fuel = 100.0
	player_stats.hull = 100.0
	player_stats.temperature_suit = 22.0

func start_expedition() -> void:
	reset_player_stats()
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")
