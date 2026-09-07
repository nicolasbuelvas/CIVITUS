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

# Default Settings Constants
const DEFAULT_LANGUAGE: String = "es"
const DEFAULT_MASTER_VOLUME: float = 0.85
const DEFAULT_MUSIC_VOLUME: float = 0.70
const DEFAULT_SFX_VOLUME: float = 0.90

# Settings
var current_language: String = DEFAULT_LANGUAGE # "es" or "en"
var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME

# Progression and Ads/VIP tracking
var expeditions_completed: int = 0
var temp_unlocked_vip_levels: Array[int] = []

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
		"spawn_now": "DESCENDER A LA SUPERFICIE",
		"background_loading": "Finalizando mapeo planetario...",
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
		"reset_defaults": "RESTABLECER",
		"discard_btn": "CERRAR",
		"system_info_tab": "SISTEMA SOLAR",
		"planet_info_tab": "PLANETA SELECCIONADO",
		"habitable_zone": "Zona Habitable",
		"water": "Agua / Hidrosfera",
		"hazard": "Nivel de Peligro",
		"star_type": "Estrella Central",
		"planets_count": "Cuerpos Orbitales",
		"store_title": "TERMINAL DE SUMINISTROS // LICENCIAS",
		"store_desc": "Adquiere autorizaciones de vuelo y herramientas avanzadas de exploración.",
		"buy_no_ads": "Supresión de Anuncios - $0.99 USD",
		"buy_no_ads_desc": "Elimina las transmisiones orbitales entre expediciones.",
		"buy_full_game": "Protocolo Total (Juego Completo) - $2.99 USD",
		"buy_full_game_desc": "Cero anuncios + Sectores VIP 4 y 5 + Modo Arquitecto permanente.",
		"buy_editor": "Módulo Arquitecto (Editor) - $1.99 USD",
		"buy_editor_desc": "Simulador de terraformación para personalizar mundos.",
		"restore_purchases": "RESTAURAR COMPRAS",
		"purchases_restored_ok": "Licencias sincronizadas correctamente.",
		"purchases_restored_none": "No se encontraron licencias previas registradas.",
		"unlock_ad_btn": "DESBLOQUEAR CON ANUNCIO",
		"ad_transmission_title": "TRANSMISIÓN ORBITAL EN CURSO",
		"ad_rewarded_title": "AUTORIZANDO SECTOR CLASIFICADO...",
		"ad_skip": "CONTINUAR",
		"ad_tip": "Puedes suprimir transmisiones permanentemente en la Tienda.",
		"planet_editor": "EDITOR DE PLANETAS",
		"architect_mode": "MODO ARQUITECTO",
		"editor_subtitle": "Diseño Planetario y Simulación de Atmósfera",
		"planet_name": "Nombre del Planeta",
		"radius_size": "Radio / Tamaño",
		"gravity_label": "Gravedad",
		"temp_label": "Temperatura",
		"atmosphere_density": "Densidad Atmosférica",
		"water_coverage": "Cobertura de Agua",
		"surface_color": "Color de Superficie",
		"atmosphere_tint": "Tinte Atmosférico",
		"planetary_rings": "Anillos Planetarios",
		"rings_tint": "Color de Anillos",
		"randomize": "ALEATORIO",
		"launch_custom": "INICIAR CON ESTE PLANETA",
		"store_editor_locked": "Modo Arquitecto Bloqueado",
		"store_editor_desc": "Desbloquea el Editor de Planetas para crear mundos personalizados con control total de física, biomas y atmósfera.",
		"color_rocky_grey": "Gris Rocoso",
		"color_desert_rust": "Óxido Desértico",
		"color_forest_green": "Verde Forestal",
		"color_oceanic_blue": "Azul Oceánico",
		"color_volcanic_obsidian": "Obsidiana Ígnea",
		"color_cryo_azure": "Azul Criogénico",
		"atmo_earth_cyan": "Cian Terrestre",
		"atmo_golden_dust": "Polvo Dorado",
		"atmo_alien_emerald": "Esmeralda Alien",
		"atmo_crimson_haze": "Bruma Carmesí",
		"atmo_violet_aurora": "Aurora Violeta",
		"atmo_vacuum": "Vacío (Sin Tinte)",
		"rings_ice": "Hielo Perlado",
		"rings_dust": "Polvo Áureo",
		"rings_obsidian": "Obsidiana Oscura",
		"rings_plasma": "Plasma Cuántico",
		"editor_custom_desc": "Mundo terraformado diseñado a medida en el Modo Arquitecto."
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
		"spawn_now": "DESCEND TO SURFACE",
		"background_loading": "Finalizing planetary mapping...",
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
		"reset_defaults": "RESET DEFAULTS",
		"discard_btn": "CLOSE",
		"system_info_tab": "SOLAR SYSTEM",
		"planet_info_tab": "SELECTED PLANET",
		"habitable_zone": "Habitable Zone",
		"water": "Hydrosphere / Water",
		"hazard": "Hazard Rating",
		"star_type": "Host Star",
		"planets_count": "Orbital Bodies",
		"store_title": "FLEET PROCUREMENT // LICENSES",
		"store_desc": "Acquire flight authorizations and specialized exploration modules.",
		"buy_no_ads": "Ad Suppression License - $0.99 USD",
		"buy_no_ads_desc": "Eliminates orbital broadcast ads between expeditions.",
		"buy_full_game": "Total Protocol (Full Game) - $2.99 USD",
		"buy_full_game_desc": "Zero ads + Pro Sectors 4 & 5 + Permanent Architect Mode.",
		"buy_editor": "Architect Module (Editor) - $1.99 USD",
		"buy_editor_desc": "Terraforming simulator to design customized planets.",
		"restore_purchases": "RESTORE PURCHASES",
		"purchases_restored_ok": "Licenses synchronized successfully.",
		"purchases_restored_none": "No prior registered licenses found.",
		"unlock_ad_btn": "UNLOCK WITH AD",
		"ad_transmission_title": "ORBITAL TRANSMISSION IN PROGRESS",
		"ad_rewarded_title": "AUTHORIZING CLASSIFIED SECTOR...",
		"ad_skip": "CONTINUE",
		"ad_tip": "You can permanently suppress transmissions in the Store.",
		"planet_editor": "PLANET EDITOR",
		"architect_mode": "ARCHITECT MODE",
		"editor_subtitle": "Planetary Design & Atmospheric Simulation",
		"planet_name": "Planet Name",
		"radius_size": "Radius / Size",
		"gravity_label": "Gravity",
		"temp_label": "Temperature",
		"atmosphere_density": "Atmospheric Density",
		"water_coverage": "Water Coverage",
		"surface_color": "Surface Base Color",
		"atmosphere_tint": "Atmosphere Tint",
		"planetary_rings": "Planetary Rings",
		"rings_tint": "Rings Tint",
		"randomize": "RANDOMIZE",
		"launch_custom": "LAUNCH WITH THIS PLANET",
		"store_editor_locked": "Architect Mode Restricted",
		"store_editor_desc": "Unlock the Planet Editor to craft custom worlds with full control over physics, biomes, and atmosphere.",
		"color_rocky_grey": "Rocky Grey",
		"color_desert_rust": "Desert Rust",
		"color_forest_green": "Forest Green",
		"color_oceanic_blue": "Oceanic Blue",
		"color_volcanic_obsidian": "Volcanic Obsidian",
		"color_cryo_azure": "Cryo Azure",
		"atmo_earth_cyan": "Earth Cyan",
		"atmo_golden_dust": "Golden Dust",
		"atmo_alien_emerald": "Alien Emerald",
		"atmo_crimson_haze": "Crimson Haze",
		"atmo_violet_aurora": "Violet Aurora",
		"atmo_vacuum": "Vacuum (No Tint)",
		"rings_ice": "Pearly Ice",
		"rings_dust": "Golden Dust",
		"rings_obsidian": "Dark Obsidian",
		"rings_plasma": "Quantum Plasma",
		"editor_custom_desc": "Terraformed custom world crafted in Architect Mode."
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
		current_language = cfg.get_value("settings", "language", DEFAULT_LANGUAGE)
		master_volume = cfg.get_value("audio", "master", DEFAULT_MASTER_VOLUME)
		music_volume = cfg.get_value("audio", "music", DEFAULT_MUSIC_VOLUME)
		sfx_volume = cfg.get_value("audio", "sfx", DEFAULT_SFX_VOLUME)
		_apply_audio_bus_volumes()

func _apply_audio_bus_volumes() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))

func reset_settings_to_default() -> void:
	current_language = DEFAULT_LANGUAGE
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	_apply_audio_bus_volumes()
	save_settings()
	language_changed.emit(DEFAULT_LANGUAGE)

# ----------------- VIP and Ads Progression -----------------

func _get_revenuecat_manager() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/RevenueCatManager")
	elif get_parent():
		return get_parent().get_node_or_null("RevenueCatManager")
	return null

func unlock_vip_temporarily(level: int) -> void:
	if not level in temp_unlocked_vip_levels:
		temp_unlocked_vip_levels.append(level)

func is_vip_unlocked(level: int) -> bool:
	if level < 4:
		return true
	var rcm = _get_revenuecat_manager()
	if rcm and rcm.has_premium_access():
		return true
	return level in temp_unlocked_vip_levels

func record_expedition_completed() -> bool:
	expeditions_completed += 1
	var rcm = _get_revenuecat_manager()
	var has_no_ads: bool = rcm.has_no_ads() if rcm else false
	var should_show_ad: bool = (expeditions_completed % 2 == 0) and not has_no_ads
	return should_show_ad

