extends Node

signal difficulty_changed(new_level: int)
signal planet_params_updated(params: Dictionary)
signal solar_system_updated(system_data: Dictionary)
signal language_changed(new_lang: String)
signal player_vital_updated(stat_name: String, current: float, maximum: float)
signal game_over(reason: String)
signal expedition_completed(summary: Dictionary)

enum Difficulty {
	LEVEL_0 = 0, # Tierra / Seguro
	LEVEL_1 = 1, # Marte / Moderado
	LEVEL_2 = 2, # Venus / Inseguro
	LEVEL_3 = 3, # Criogénico / Peligroso
	LEVEL_4 = 4, # Singularity / Extremo (PRO)
	LEVEL_5 = 5  # Tartarus / Mortal (PRO)
}

const CraftingSystemClass = preload("res://scripts/systems/crafting_system.gd")
const SolarSystemClass = preload("res://scripts/systems/solar_system.gd")

var current_difficulty: Difficulty = Difficulty.LEVEL_0
var is_sandbox: bool = false
var crafting = CraftingSystemClass.new()
var current_solar_system: Dictionary = {}
var current_planet: Dictionary = {}

# Settings
var current_language: String = "es" # "es" or "en"
var master_volume: float = 0.85
var music_volume: float = 0.70
var sfx_volume: float = 0.90

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

# Localization Dictionary
const LOCALIZATION: Dictionary = {
	"es": {
		"play": "JUGAR",
		"settings": "AJUSTES",
		"store": "TIENDA",
		"exit": "SALIR",
		"start_expedition": "INICIAR EXPEDICIÓN",
		"unlock_tier": "DESBLOQUEAR EN TIENDA",
		"back": "VOLVER",
		"back_menu": "VOLVER AL MENÚ",
		"new_system": "EXPLORAR NUEVO SISTEMA",
		"system_label": "SISTEMA SOLAR",
		"loading": "Cargando coordenadas planetarias...",
		"loading_dots": "Cargando",
		"stage_1": "Sincronizando telemetría orbital...",
		"stage_2": "Mapeando relieve y topografía...",
		"stage_3": "Calibrando composición atmosférica...",
		"stage_4": "Alineando módulo de descenso...",
		"continue_btn": "Presiona para descender",
		"minigame_title": "Minijuego de Descenso",
		"minigame_sub": "A/D Rotar | W Propulsión",
		"altitude": "Altitud",
		"speed": "Velocidad",
		"fuel": "Combustible",
		"landings": "Aterrizajes",
		"points": "Puntos",
		"platform": "Plataforma de Descenso",
		"pro_sector_locked": "Sector Pro Bloqueado",
		"pro_sector_desc": "Desbloquea los sectores de peligro extremo 4 y 5 y el Modo Arquitecto con la Licencia de Espacio Profundo.",
		"monthly_pass": "Pase de Comandante - $1.99 USD / mes",
		"lifetime_pass": "Licencia Vitalicia Completa - $3.99 USD",
		"close": "Cerrar",
		"save": "Guardar",
		"language": "Idioma",
		"vol_master": "Volumen General",
		"vol_music": "Música",
		"vol_sfx": "Efectos",
		"gravity": "Gravedad",
		"temp": "Temp",
		"atmosphere": "Atmósfera",
		"radiation": "Radiación",
		"orbit": "Órbita",
		"primary_ore": "Recurso Clave",
		"level": "NIVEL",
		"settings_title": "CONFIGURACIÓN // AJUSTES",
		"lang_label": "Idioma de Interfaz:",
		"save_btn": "GUARDAR",
		"discard_btn": "CERRAR",
		"system_info_tab": "SISTEMA SOLAR",
		"planet_info_tab": "PLANETA SELECCIONADO",
		"habitable_zone": "Zona Habitable",
		"water": "Agua / Hidrosfera",
		"hazard": "Nivel de Peligro",
		"star_type": "Estrella Central",
		"planets_count": "Cuerpos Orbitales"
	},
	"en": {
		"play": "PLAY",
		"settings": "SETTINGS",
		"store": "STORE",
		"exit": "EXIT",
		"start_expedition": "LAUNCH EXPEDITION",
		"unlock_tier": "UNLOCK IN STORE",
		"back": "BACK",
		"back_menu": "BACK TO MENU",
		"new_system": "DISCOVER NEW SYSTEM",
		"system_label": "SOLAR SYSTEM",
		"loading": "Loading planetary coordinates...",
		"loading_dots": "Loading",
		"stage_1": "Synchronizing orbital telemetry...",
		"stage_2": "Mapping terrain topography...",
		"stage_3": "Calibrating atmospheric density...",
		"stage_4": "Aligning descent lander...",
		"continue_btn": "Tap to initiate landing",
		"minigame_title": "Descent Minigame",
		"minigame_sub": "A/D Rotate | W Main Burn",
		"altitude": "Altitude",
		"speed": "Velocity",
		"fuel": "Fuel",
		"landings": "Landings",
		"points": "Score",
		"platform": "Landing Beacon Pad",
		"pro_sector_locked": "Pro Sector Restricted",
		"pro_sector_desc": "Unlock extreme hazard sectors 4 and 5 along with Architect Mode via Deep Space License.",
		"monthly_pass": "Commander Pass - $1.99 USD / mo",
		"lifetime_pass": "Lifetime Access - $3.99 USD",
		"close": "Close",
		"save": "Save",
		"language": "Language",
		"vol_master": "Master Volume",
		"vol_music": "Music",
		"vol_sfx": "SFX",
		"gravity": "Gravity",
		"temp": "Temp",
		"atmosphere": "Atmosphere",
		"radiation": "Radiation",
		"orbit": "Orbit",
		"primary_ore": "Primary Ore",
		"level": "LEVEL",
		"settings_title": "SETTINGS // SYSTEM",
		"lang_label": "Interface Language:",
		"save_btn": "SAVE",
		"discard_btn": "CLOSE",
		"system_info_tab": "SOLAR SYSTEM",
		"planet_info_tab": "SELECTED PLANET",
		"habitable_zone": "Habitable Zone",
		"water": "Hydrosphere / Water",
		"hazard": "Hazard Rating",
		"star_type": "Host Star",
		"planets_count": "Orbital Bodies"
	}
}

func _ready() -> void:
	if DisplayServer.has_method("screen_set_orientation"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	load_settings()
	generate_new_solar_system()

func loc(key: String) -> String:
	var lang_dict = LOCALIZATION.get(current_language, LOCALIZATION["es"])
	return lang_dict.get(key, key)

func set_language(lang: String) -> void:
	if lang in ["es", "en"]:
		current_language = lang
		save_settings()
		language_changed.emit(lang)

func generate_new_solar_system(custom_seed: int = -1) -> void:
	# Discard previous solar system permanently and generate fresh one
	current_solar_system.clear()
	current_solar_system = SolarSystemClass.generate_system(custom_seed)
	
	# Default to the first habitable planet (Level 0)
	if current_solar_system.get("planets", []).size() > 0:
		select_planet(current_solar_system["planets"][0])
		
	solar_system_updated.emit(current_solar_system)

func select_planet(p_data: Dictionary) -> void:
	current_planet = p_data.duplicate(true)
	current_difficulty = p_data.get("level", 0) as Difficulty
	crafting.init_level_requirements(int(current_difficulty))
	reset_player_stats()
	planet_params_updated.emit(current_planet)

func reset_player_stats() -> void:
	player_stats.oxygen = 100.0
	player_stats.fuel = 100.0
	player_stats.hull = 100.0
	player_stats.temperature_suit = 22.0

func start_expedition() -> void:
	reset_player_stats()
	get_tree().change_scene_to_file("res://scenes/screens/loading_screen.tscn")

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("settings", "language", current_language)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save("user://settings.cfg")

func load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		current_language = cfg.get_value("settings", "language", "es")
		master_volume = cfg.get_value("audio", "master", 0.85)
		music_volume = cfg.get_value("audio", "music", 0.70)
		sfx_volume = cfg.get_value("audio", "sfx", 0.90)
		_apply_audio_bus_volumes()

func _apply_audio_bus_volumes() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
