extends Node

signal difficulty_changed(new_level: int)
signal planet_params_updated(params: Dictionary)
signal solar_system_updated(system_data: Dictionary)
signal language_changed(new_lang: String)
signal player_vital_updated(stat_name: String, current: float, maximum: float)
signal game_over(reason: String)
signal expedition_completed(summary: Dictionary)
signal luna_coins_changed(new_amount: int)
signal game_saved()
signal game_loaded()
signal escaped_systems_count_changed(new_count: int)
signal outro_sequence_triggered(telemetry: Dictionary)

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
var crafting: CraftingSystem = CraftingSystem.new()
var current_solar_system: Dictionary = {}
var current_planet: Dictionary = {}

# Default Settings Constants
const DEFAULT_LANGUAGE: String = "en"
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
var escaped_systems_count: int = 0 # 0 to 10 systems along the galactic corridor to Gargantua
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

# Planetary Weather & Atmosphere Feedback
var current_weather: String = "clear"
var current_weather_intensity: float = 0.0

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
		"thread_step_1": "[Thread 1/7 I/O] Cargando paquetes de recursos del sector...",
		"thread_step_2": "[Thread 2/7 CPU] Sintetizando topología y relieve planetario...",
		"thread_step_3": "[Thread 3/7 Malla] Construyendo geometría y normales de superficie...",
		"thread_step_4": "[Thread 4/7 Física] Compilando matriz de colisión trimesh...",
		"thread_step_5": "[Thread 5/7 Sector] Alineando módulo de aterrizaje y hábitat...",
		"thread_step_6": "[Thread 6/7 Biosfera] Sembrando yacimientos minerales y biosfera...",
		"thread_step_7": "[Pipeline GPU 7/7] Precalentando sombreadores y canal gráfico...",
		"thread_step_ready": "[Listo] Desplegando astronauta y telemetría de soporte vital...",
		"io_sub_1": "[Thread 1/7 I/O] (1/6) Desempaquetando entorno orbital y cielo...",
		"io_sub_2": "[Thread 1/7 I/O] (2/6) Desempaquetando módulo Apolo y geometría 3D...",
		"io_sub_3": "[Thread 1/7 I/O] (3/6) Desempaquetando cinemática EVA de astronauta...",
		"io_sub_4": "[Thread 1/7 I/O] (4/6) Desempaquetando catálogo de flora planetaria...",
		"io_sub_5": "[Thread 1/7 I/O] (5/6) Desempaquetando física de yacimientos minerales...",
		"io_sub_6": "[Thread 1/7 I/O] (6/6) Desempaquetando interfaz táctica HUD...",
		"cpu_sub_1": "[Thread 2/7 CPU] (Cara 1/6) Sintetizando relieve Cenit (Polo Norte)...",
		"cpu_sub_2": "[Thread 2/7 CPU] (Cara 2/6) Sintetizando relieve Nadir (Polo Sur)...",
		"cpu_sub_3": "[Thread 2/7 CPU] (Cara 3/6) Sintetizando relieve Hemisferio Occidental...",
		"cpu_sub_4": "[Thread 2/7 CPU] (Cara 4/6) Sintetizando relieve Hemisferio Oriental...",
		"cpu_sub_5": "[Thread 2/7 CPU] (Cara 5/6) Sintetizando relieve Meridiano Frontal...",
		"cpu_sub_6": "[Thread 2/7 CPU] (Cara 6/6) Sintetizando relieve Meridiano Posterior...",
		"mesh_sub_1": "[Thread 3/7 Malla] (1/3) Ensamblando búferes de geometría y UVs...",
		"mesh_sub_2": "[Thread 3/7 Malla] (2/3) Calculando normales facetadas por producto cruz...",
		"mesh_sub_3": "[Thread 3/7 Malla] (3/3) Compilando ArrayMesh y sombreadores...",
		"phys_sub_1": "[Thread 4/7 Física] (1/2) Compilando árbol de colisión BVH esférico...",
		"phys_sub_2": "[Thread 4/7 Física] (2/2) Vinculando matriz trimesh a gravedad radial...",
		"sect_sub_1": "[Thread 5/7 Sector] (1/3) Mapeando meseta de aterrizaje en el Polo Norte...",
		"sect_sub_2": "[Thread 5/7 Sector] (2/3) Ensamblando módulo de aterrizaje Apolo...",
		"sect_sub_3": "[Thread 5/7 Sector] (3/3) Alineando compuerta estanca a la normal polar...",
		"bio_sub_1": "[Thread 6/7 Biosfera] (1/6) Sembrando vegetación polar y templada...",
		"bio_sub_2": "[Thread 6/7 Biosfera] (2/6) Sembrando flora de valles y cañones...",
		"bio_sub_3": "[Thread 6/7 Biosfera] (3/6) Sembrando yacimientos de hierro y cobre...",
		"bio_sub_4": "[Thread 6/7 Biosfera] (4/6) Sembrando yacimientos de silicio y uranio...",
		"bio_sub_5": "[Thread 6/7 Biosfera] (5/6) Sembrando gemas y recursos exóticos...",
		"bio_sub_6": "[Thread 6/7 Biosfera] (6/6) Validando zonas de despeje y colisiones...",
		"shader_sub_1": "[Pipeline GPU 7/7] (1/13) Precalentando atmósfera y cielo procedural...",
		"shader_sub_2": "[Pipeline GPU 7/7] (2/13) Precalentando sombreador de relieve planetario...",
		"shader_sub_3": "[Pipeline GPU 7/7] (3/13) Precalentando sombras dinámicas de luz solar...",
		"shader_sub_4": "[Pipeline GPU 7/7] (4/13) Precalentando materiales metálicos PBR de nave...",
		"shader_sub_5": "[Pipeline GPU 7/7] (5/13) Precalentando yacimientos de hierro y cobre...",
		"shader_sub_6": "[Pipeline GPU 7/7] (6/13) Precalentando yacimientos de silicio y uranio...",
		"shader_sub_7": "[Pipeline GPU 7/7] (7/13) Precalentando sombreadores de biosfera vegetal...",
		"shader_sub_8": "[Pipeline GPU 7/7] (8/13) Precalentando cinemática y traje de astronauta...",
		"shader_sub_9": "[Pipeline GPU 7/7] (9/13) Activando cámara orbital 3D en segundo plano...",
		"shader_sub_10": "[Pipeline GPU 7/7] (10/13) Pre-activando matriz de física y colisión...",
		"shader_sub_11": "[Pipeline GPU 7/7] (11/13) Ensamblando telemetría táctica de soporte vital...",
		"shader_sub_12": "[Pipeline GPU 7/7] (12/13) Pre-renderizando sombreadores de visor y HUD...",
		"shader_sub_13": "[Pipeline GPU 7/7] (13/13) Sincronizando búferes finales a 60 FPS...",
		"stage_1": "Sincronizando telemetría orbital...",
		"stage_2": "Mapeando relieve y topografía...",
		"stage_3": "Calibrando composición atmosférica...",
		"stage_4": "Alineando módulo de descenso...",
		"continue_btn": "Presiona para descender",
		"spawn_now": "DESCENDER A LA SUPERFICIE",
		"ready_to_land": "Presionar aquí para empezar",
		"points_skins_hint": "Puntos canjeables por trajes",
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
		"store_title": "TIENDA LUNA",
		"store_desc": "Adquiere autorizaciones de vuelo y herramientas avanzadas de exploración.",
		"store_badge_locked_sector": "[ ⬡ SECTOR CLASIFICADO PRO // SECTOR 4-5 REQUERIDO ]",
		"store_badge_locked_editor": "[ ⬡ MÓDULO ARQUITECTO REQUERIDO ]",
		"menu_play_title": "JUGAR",
		"menu_play_sub": "Iniciar expedición al espacio profundo",
		"menu_architect_title": "MODO ARQUITECTO",
		"menu_architect_sub": "Generador de mundos y terraformación",
		"menu_store_title": "TIENDA LUNA",
		"menu_store_sub": "Licencias, propulsores, trajes y suministros",
		"menu_settings_title": "AJUSTES",
		"menu_settings_sub": "Volumen de audio e idioma de interfaz",
		"menu_exit_title": "SALIR",
		"menu_exit_sub": "Finalizar sesión de simulación",
		"tab_surface": "SUPERFICIE",
		"tab_atmosphere": "ATMÓSFERA",
		"tab_ocean": "OCÉANO",
		"tab_rings": "ANILLOS",
		"reward_coins_awarded": "+50 LUNA COINS ACREDITADAS",
		"reward_coins_feedback": "¡Transmisión completada! +50 Luna Coins acreditadas.",
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
		"editor_custom_desc": "Mundo terraformado diseñado a medida en el Modo Arquitecto.",
		"o2_label": "O₂",
		"fuel_label": "PROPULSIÓN",
		"hull_label": "BLINDAJE",
		"pause_title": "MISIÓN PAUSADA",
		"resume_btn": "CONTINUAR",
		"storage_title": "CAJÓN DE RECURSOS",
		"deposit_all": "DEPOSITAR RECURSOS",
		"crafting_title": "FABRICADOR DE CABINA",
		"hyperdrive_title": "HYPERDRIVE",
		"hyperdrive_status_dmg": "ESTADO: DAÑADO",
		"hyperdrive_status_ok": "ESTADO: OPERATIVO",
		"hyperdrive_activate": "🚀 ACTIVAR HYPERDRIVE 🚀",
		"starmap_title": "MAPA ESTELAR",
		"game_over_title": "SOPORTE VITAL COMPROMETIDO",
		"game_over_reason_o2": "Fallo crítico: Asfixia por falta de oxígeno.",
		"game_over_reason_hull": "Ruptura de traje: Blindaje térmico destruido.",
		"game_over_reason_hazard": "Ruptura de traje: Inmersión en fluido hostil.",
		"retry_btn": "REINTENTAR",
		"return_menu": "VOLVER AL MENÚ",
		"close_modal": "CERRAR",
		"craft_action": "Fabricar",
		"craft_wrench": "Llave de Presión (2 Hierro)",
		"craft_cables": "Cables Conductores x2 (1 Cobre)",
		"craft_microchip": "Microprocesador (1 Silicio + 1 Cable)",
		"craft_core": "Núcleo de Fisión (1 Uranio + 2 Hierro)",
		"tab_suits": "TRAJES",
		"tab_thrusters": "NAVES",
		"tab_packs": "PAQUETES",
		"watch_ad_btn": "VER TRANSMISIÓN (+50 ☾)",
		"watch_ad_desc": "Sintoniza una transmisión comercial de espacio profundo para recibir 50 Luna Coins gratis.",
		"pack_scout_name": "SUMINISTRO INICIAL",
		"pack_scout_desc": "Reserva de fondos para exploradores espaciales.",
		"pack_advanced_name": "EXPEDICIÓN AVANZADA",
		"pack_advanced_desc": "Vuelo sin anuncios y 800 Luna Coins.",
		"pack_protocol_name": "PROTOCOLO TOTAL VIP",
		"pack_protocol_desc": "Todo desbloqueado: Modo Arquitecto, trajes y propulsión, y 2500 Luna Coins.",
		"cam_mode": "CÁMARA",
		"context_mine": "EXTRAER",
		"context_open": "ABRIR ESCOTILLA",
		"context_close": "CERRAR ESCOTILLA",
		"context_storage": "ABRIR ALMACÉN",
		"context_craft": "USAR FABRICADOR",
		"context_hyperdrive": "NÚCLEO NAVE",
		"context_starmap": "MAPA ESTELAR"
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
		"thread_step_1": "[Thread 1/7 I/O] Loading sector resource packages...",
		"thread_step_2": "[Thread 2/7 CPU] Synthesizing planetary topology and relief...",
		"thread_step_3": "[Thread 3/7 Mesh] Constructing surface geometry and normals...",
		"thread_step_4": "[Thread 4/7 Physics] Compiling trimesh collision matrix...",
		"thread_step_5": "[Thread 5/7 Sector] Aligning descent module and habitat...",
		"thread_step_6": "[Thread 6/7 Biosphere] Seeding mineral deposits and biosphere...",
		"thread_step_7": "[GPU Pipeline 7/7] Pre-warming shaders and render pipeline...",
		"thread_step_ready": "[Ready] Deploying astronaut and life support telemetry...",
		"io_sub_1": "[Thread 1/7 I/O] (1/6) Unpacking orbital environment and sky...",
		"io_sub_2": "[Thread 1/7 I/O] (2/6) Unpacking Apollo module and 3D geometry...",
		"io_sub_3": "[Thread 1/7 I/O] (3/6) Unpacking astronaut EVA kinematics...",
		"io_sub_4": "[Thread 1/7 I/O] (4/6) Unpacking planetary biosphere catalog...",
		"io_sub_5": "[Thread 1/7 I/O] (5/6) Unpacking mineral deposits physics...",
		"io_sub_6": "[Thread 1/7 I/O] (6/6) Unpacking tactical HUD telemetry...",
		"cpu_sub_1": "[Thread 2/7 CPU] (Face 1/6) Synthesizing Zenith terrain (North Pole)...",
		"cpu_sub_2": "[Thread 2/7 CPU] (Face 2/6) Synthesizing Nadir terrain (South Pole)...",
		"cpu_sub_3": "[Thread 2/7 CPU] (Face 3/6) Synthesizing Western Hemisphere terrain...",
		"cpu_sub_4": "[Thread 2/7 CPU] (Face 4/6) Synthesizing Eastern Hemisphere terrain...",
		"cpu_sub_5": "[Thread 2/7 CPU] (Face 5/6) Synthesizing Prime Meridian terrain...",
		"cpu_sub_6": "[Thread 2/7 CPU] (Face 6/6) Synthesizing Antimeridian terrain...",
		"mesh_sub_1": "[Thread 3/7 Mesh] (1/3) Binding geometry buffers and UVs...",
		"mesh_sub_2": "[Thread 3/7 Mesh] (2/3) Computing cross-product faceted normals...",
		"mesh_sub_3": "[Thread 3/7 Mesh] (3/3) Compiling ArrayMesh and shaders...",
		"phys_sub_1": "[Thread 4/7 Physics] (1/2) Compiling spherical BVH collision tree...",
		"phys_sub_2": "[Thread 4/7 Physics] (2/2) Binding trimesh collision to radial gravity...",
		"sect_sub_1": "[Thread 5/7 Sector] (1/3) Mapping landing plateau at North Pole...",
		"sect_sub_2": "[Thread 5/7 Sector] (2/3) Assembling Apollo descent module...",
		"sect_sub_3": "[Thread 5/7 Sector] (3/3) Aligning airlock hatch to polar normal...",
		"bio_sub_1": "[Thread 6/7 Biosphere] (1/6) Seeding polar & temperate flora...",
		"bio_sub_2": "[Thread 6/7 Biosphere] (2/6) Seeding valley & canyon flora...",
		"bio_sub_3": "[Thread 6/7 Biosphere] (3/6) Seeding iron and copper veins...",
		"bio_sub_4": "[Thread 6/7 Biosphere] (4/6) Seeding silicon and uranium veins...",
		"bio_sub_5": "[Thread 6/7 Biosphere] (5/6) Seeding gemstones and rare minerals...",
		"bio_sub_6": "[Thread 6/7 Biosphere] (6/6) Validating clearance and collisions...",
		"shader_sub_1": "[GPU Pipeline 7/7] (1/13) Pre-warming procedural sky and atmosphere...",
		"shader_sub_2": "[GPU Pipeline 7/7] (2/13) Pre-warming planetary terrain shader...",
		"shader_sub_3": "[GPU Pipeline 7/7] (3/13) Pre-warming dynamic sunlight shadow cascades...",
		"shader_sub_4": "[GPU Pipeline 7/7] (4/13) Pre-warming spacecraft metallic PBR shaders...",
		"shader_sub_5": "[GPU Pipeline 7/7] (5/13) Pre-warming iron and copper deposit materials...",
		"shader_sub_6": "[GPU Pipeline 7/7] (6/13) Pre-warming silicon and uranium glow shaders...",
		"shader_sub_7": "[GPU Pipeline 7/7] (7/13) Pre-warming planetary flora biosphere shaders...",
		"shader_sub_8": "[GPU Pipeline 7/7] (8/13) Pre-warming astronaut EVA suit kinematics...",
		"shader_sub_9": "[GPU Pipeline 7/7] (9/13) Activating 3D orbital camera in background...",
		"shader_sub_10": "[GPU Pipeline 7/7] (10/13) Pre-activating physics matrix and contact...",
		"shader_sub_11": "[GPU Pipeline 7/7] (11/13) Assembling tactical life-support telemetry...",
		"shader_sub_12": "[GPU Pipeline 7/7] (12/13) Pre-rendering visor overlay and HUD shaders...",
		"shader_sub_13": "[GPU Pipeline 7/7] (13/13) Synchronizing final buffers at 60 FPS...",
		"stage_1": "Synchronizing orbital telemetry...",
		"stage_2": "Mapping terrain topography...",
		"stage_3": "Calibrating atmospheric density...",
		"stage_4": "Aligning descent lander...",
		"continue_btn": "Tap to initiate landing",
		"spawn_now": "DESCEND TO SURFACE",
		"ready_to_land": "Press here to start",
		"points_skins_hint": "Points redeemable for suits",
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
		"store_title": "LUNA STORE",
		"store_desc": "Acquire flight authorizations and specialized exploration modules.",
		"store_badge_locked_sector": "[ ⬡ CLASSIFIED PRO SECTOR // SECTOR 4-5 REQUIRED ]",
		"store_badge_locked_editor": "[ ⬡ ARCHITECT MODULE REQUIRED ]",
		"menu_play_title": "PLAY",
		"menu_play_sub": "Launch expedition into deep space",
		"menu_architect_title": "PLANET ARCHITECT",
		"menu_architect_sub": "Custom world generator & terraforming",
		"menu_store_title": "LUNA STORE",
		"menu_store_sub": "Licenses, thrusters, suits & supplies",
		"menu_settings_title": "SETTINGS",
		"menu_settings_sub": "Audio volume and interface language",
		"menu_exit_title": "EXIT",
		"menu_exit_sub": "Terminate simulation session",
		"tab_surface": "SURFACE",
		"tab_atmosphere": "ATMOSPHERE",
		"tab_ocean": "OCEAN",
		"tab_rings": "RINGS",
		"reward_coins_awarded": "+50 LUNA COINS AWARDED",
		"reward_coins_feedback": "Transmission completed! +50 Luna Coins added.",
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
		"editor_custom_desc": "Terraformed custom world crafted in Architect Mode.",
		"o2_label": "O₂",
		"fuel_label": "THRUST",
		"hull_label": "SUIT",
		"pause_title": "MISSION PAUSED",
		"resume_btn": "RESUME",
		"storage_title": "STORAGE CRATE",
		"deposit_all": "DEPOSIT ALL",
		"crafting_title": "SHIP FABRICATOR",
		"hyperdrive_title": "HYPERDRIVE",
		"hyperdrive_status_dmg": "STATUS: DAMAGED",
		"hyperdrive_status_ok": "STATUS: OPERATIONAL",
		"hyperdrive_activate": "🚀 ACTIVATE HYPERDRIVE 🚀",
		"starmap_title": "STAR MAP",
		"game_over_title": "LIFE SUPPORT OFFLINE",
		"game_over_reason_o2": "Critical failure: Asphyxiation from oxygen depletion.",
		"game_over_reason_hull": "Suit breach: Thermal integrity destroyed.",
		"game_over_reason_hazard": "Suit breach: Immersion in hostile fluid.",
		"retry_btn": "RETRY",
		"return_menu": "MAIN MENU",
		"close_modal": "CLOSE",
		"craft_action": "Craft",
		"craft_wrench": "Pressure Wrench (2 Iron)",
		"craft_cables": "Conductive Cables x2 (1 Copper)",
		"craft_microchip": "Microprocessor (1 Silicon + 1 Cable)",
		"craft_core": "Fission Core (1 Uranium + 2 Iron)",
		"tab_suits": "SUITS",
		"tab_thrusters": "SHIPS",
		"tab_packs": "PACKS",
		"watch_ad_btn": "WATCH TRANSMISSION (+50 ☾)",
		"watch_ad_desc": "Tune in to a deep space commercial transmission to receive 50 free Luna Coins.",
		"pack_scout_name": "STARTER SUPPLY",
		"pack_scout_desc": "Reserve funds for space explorers.",
		"pack_advanced_name": "ADVANCED EXPEDITION",
		"pack_advanced_desc": "Ad-free flight and 800 Luna Coins.",
		"pack_protocol_name": "VIP TOTAL PROTOCOL",
		"pack_protocol_desc": "All unlocked: Architect Mode, suits and thrusters, and 2500 Luna Coins.",
		"cam_mode": "CAMERA",
		"context_mine": "MINE",
		"context_open": "OPEN HATCH",
		"context_close": "CLOSE HATCH",
		"context_storage": "OPEN STORAGE",
		"context_craft": "USE FABRICATOR",
		"context_hyperdrive": "SHIP CORE",
		"context_starmap": "STAR MAP"
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

func generate_new_solar_system(custom_seed: int = -1, sys_progression: int = -1) -> void:
	# Discard previous solar system permanently and generate fresh one
	current_solar_system.clear()
	var progression_idx = sys_progression if sys_progression >= 0 else escaped_systems_count
	current_solar_system = SolarSystemClass.generate_system(custom_seed, progression_idx)
	
	# Default to the first planet (or habitable world)
	if current_solar_system.get("planets", []).size() > 0:
		select_planet(current_solar_system["planets"][0])
		
	solar_system_updated.emit(current_solar_system)

static func parse_color(val: Variant, default_color: Color = Color.WHITE) -> Color:
	if val is Color:
		return val
	if val is String:
		var s: String = val.strip_edges()
		if s.begins_with("(") and s.ends_with(")"):
			var parts = s.substr(1, s.length() - 2).split(",")
			if parts.size() >= 3:
				var r = float(parts[0].strip_edges())
				var g = float(parts[1].strip_edges())
				var b = float(parts[2].strip_edges())
				var a = float(parts[3].strip_edges()) if parts.size() > 3 else 1.0
				return Color(r, g, b, a)
		elif s.begins_with("#"):
			return Color.from_string(s, default_color)
		return Color.from_string(s, default_color)
	return default_color

func sanitize_planet_colors(dict: Dictionary) -> void:
	var color_keys = [
		"ocean_color", "beach_color", "land_color", "mountain_color", "peak_color",
		"atmosphere_color", "sky_color", "surface_color", "water_color"
	]
	for k in color_keys:
		if dict.has(k):
			dict[k] = parse_color(dict[k], Color.WHITE)

func select_planet(p_data: Dictionary) -> void:
	current_planet = p_data.duplicate(true)
	sanitize_planet_colors(current_planet)
	
	# Ensure host star data is always coherent with the current solar system
	if current_solar_system.has("star") and not current_planet.has("star"):
		current_planet["star"] = current_solar_system["star"].duplicate(true)
	elif not current_planet.has("star"):
		# Scientific default host star (Class G Solar analogue)
		current_planet["star"] = {
			"name": "Sol-Prime",
			"spectral_class": "G",
			"label": "Enana Amarilla (Clase G)",
			"temperature": 5778.0,
			"luminosity": 1.0,
			"color": Color(1.0, 0.96, 0.88),
			"hz_inner_au": 0.95,
			"hz_outer_au": 1.37
		}
		
	current_difficulty = p_data.get("level", 0) as Difficulty
	crafting.init_level_requirements(int(current_difficulty))
	reset_player_stats()
	planet_params_updated.emit(current_planet)

func reset_player_stats() -> void:
	player_stats.oxygen = 100.0
	player_stats.fuel = 100.0
	player_stats.hull = 100.0
	player_stats.temperature_suit = 22.0

func start_new_game(diff_level: int = 0) -> void:
	current_difficulty = diff_level as Difficulty
	crafting.reset_inventory()
	crafting.init_level_requirements(int(current_difficulty))
	reset_player_stats()
	escaped_systems_count = 0
	escaped_systems_count_changed.emit(0)

func start_expedition() -> void:
	reset_player_stats()
	get_tree().change_scene_to_file("res://scenes/screens/loading_screen.tscn")

var custom_settings: Dictionary = {}

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("settings", "language", current_language)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	for k in custom_settings.keys():
		cfg.set_value("custom", k, custom_settings[k])
	cfg.save("user://settings.cfg")

func get_setting(key: String, default_val = null):
	match key:
		"master_volume": return master_volume
		"music_volume": return music_volume
		"sfx_volume": return sfx_volume
		"language": return current_language
		_: return custom_settings.get(key, default_val)

func load_setting(key: String, default_val = null):
	return get_setting(key, default_val)

func update_setting(key: String, val) -> void:
	custom_settings[key] = val
	match key:
		"master_volume":
			master_volume = float(val)
			_apply_audio_bus_volumes()
		"music_volume":
			music_volume = float(val)
			_apply_audio_bus_volumes()
		"sfx_volume":
			sfx_volume = float(val)
			_apply_audio_bus_volumes()
	save_settings()

func load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		current_language = cfg.get_value("settings", "language", DEFAULT_LANGUAGE)
		master_volume = cfg.get_value("audio", "master", DEFAULT_MASTER_VOLUME)
		music_volume = cfg.get_value("audio", "music", DEFAULT_MUSIC_VOLUME)
		sfx_volume = cfg.get_value("audio", "sfx", DEFAULT_SFX_VOLUME)
		if cfg.has_section("custom"):
			for k in cfg.get_section_keys("custom"):
				custom_settings[k] = cfg.get_value("custom", k)
		_apply_audio_bus_volumes()

func _apply_audio_bus_volumes() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var m_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(m_idx, "Music")
		AudioServer.set_bus_send(m_idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var s_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(s_idx, "SFX")
		AudioServer.set_bus_send(s_idx, "Master")

	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, master_volume <= 0.001)
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(max(0.001, master_volume)))
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_mute(music_idx, music_volume <= 0.001)
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(max(0.001, music_volume)))
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_mute(sfx_idx, sfx_volume <= 0.001)
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(max(0.001, sfx_volume)))

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

# ----------------- Luna Points & Freemium Economy -----------------

signal luna_points_changed(new_amount: int)
signal hyperdrive_mission_completed(reward_points: int)
signal interplanetary_transit_started(target_planet: Dictionary)
signal interplanetary_transit_completed(target_planet: Dictionary)

var luna_points: int = 0
var unlocked_skins: Array = ["apollo_white"]
var active_skin: String = "apollo_white"
var unlocked_ship_paints: Array = ["capsule_white"]
var active_ship_paint: String = "capsule_white"

var luna_coins: int:
	get: return luna_points
	set(v): luna_points = v

func add_luna_points(amount: int) -> void:
	if amount <= 0:
		return
	luna_points += amount
	luna_points_changed.emit(luna_points)
	luna_coins_changed.emit(luna_points)
	save_player_progression()

func add_luna_coins(amount: int) -> void:
	add_luna_points(amount)

func spend_luna_points(amount: int) -> bool:
	if amount <= 0 or luna_points < amount:
		return false
	luna_points -= amount
	luna_points_changed.emit(luna_points)
	luna_coins_changed.emit(luna_points)
	save_player_progression()
	return true

func spend_luna_coins(amount: int) -> bool:
	return spend_luna_points(amount)

func award_hyperdrive_victory(difficulty_level: int) -> int:
	var reward = 50
	match difficulty_level:
		0, 1: reward = 50
		2: reward = 100
		3: reward = 180
		4: reward = 280
		_: reward = 450
		
	add_luna_points(reward)
	hyperdrive_mission_completed.emit(reward)
	record_expedition_completed()
	return reward

func save_player_progression() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("economy", "luna_points", luna_points)
	cfg.set_value("economy", "luna_coins", luna_points)
	cfg.set_value("customization", "unlocked_skins", unlocked_skins)
	cfg.set_value("customization", "active_skin", active_skin)
	cfg.set_value("customization", "unlocked_ship_paints", unlocked_ship_paints)
	cfg.set_value("customization", "active_ship_paint", active_ship_paint)
	cfg.save("user://progression.cfg")

func load_player_progression() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://progression.cfg") == OK:
		luna_points = cfg.get_value("economy", "luna_coins", cfg.get_value("economy", "luna_points", 0))
		unlocked_skins = cfg.get_value("customization", "unlocked_skins", ["apollo_white"])
		active_skin = cfg.get_value("customization", "active_skin", "apollo_white")
		unlocked_ship_paints = cfg.get_value("customization", "unlocked_ship_paints", ["capsule_white"])
		active_ship_paint = cfg.get_value("customization", "active_ship_paint", "capsule_white")

# ----------------- Save / Load Persistent Game State (Continuar / Nueva Partida) -----------------
const SAVEGAME_PATH: String = "user://civitus_saved_game.json"
const CURRENT_SAVE_VERSION: int = 2

func has_save_game() -> bool:
	if not FileAccess.file_exists(SAVEGAME_PATH):
		return false
	var summary = get_save_summary()
	if summary.is_empty():
		return false
	if int(summary.get("save_version", 0)) != CURRENT_SAVE_VERSION:
		# Auto-wipe outdated or corrupted saves from earlier versions/updates
		wipe_save_game()
		return false
	return true

func wipe_save_game() -> void:
	if FileAccess.file_exists(SAVEGAME_PATH):
		var da = DirAccess.open("user://")
		if da:
			da.remove("civitus_saved_game.json")

func get_save_summary() -> Dictionary:
	if not FileAccess.file_exists(SAVEGAME_PATH):
		return {}
	var file = FileAccess.open(SAVEGAME_PATH, FileAccess.READ)
	if not file:
		return {}
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	if data is Dictionary:
		return data
	return {}

func save_game() -> bool:
	var ship = get_tree().get_first_node_in_group("spaceship")
	var ship_energy_val = 100.0
	var o2_tube_1_val = 100.0
	var o2_tube_2_val = 100.0
	var flight_state_val = 0
	if is_instance_valid(ship):
		if "current_energy" in ship: ship_energy_val = float(ship.current_energy)
		if "o2_tube_1_charge" in ship: o2_tube_1_val = float(ship.o2_tube_1_charge)
		if "o2_tube_2_charge" in ship: o2_tube_2_val = float(ship.o2_tube_2_charge)
		if "flight_state" in ship: flight_state_val = int(ship.flight_state)

	var save_data: Dictionary = {
		"save_version": CURRENT_SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"current_planet": current_planet,
		"current_solar_system": current_solar_system,
		"difficulty": int(current_difficulty),
		"player_stats": player_stats.duplicate(true),
		"planet_name": current_planet.get("name", "Gliese Australis III"),
		"inventory": crafting.inventory.duplicate(true) if crafting else {},
		"body_slots": crafting.body_slots.duplicate(true) if crafting else {},
		"ship_storage": crafting.ship_storage.duplicate(true) if crafting else {},
		"installed_parts": crafting.installed_parts.duplicate(true) if crafting else {},
		"hyperdrive_requirements": crafting.hyperdrive_requirements.duplicate(true) if crafting else {},
		"hyperdrive_progress": crafting.get_hyperdrive_progress() if crafting else 0.0,
		"ship_energy": ship_energy_val,
		"o2_tube_1_charge": o2_tube_1_val,
		"o2_tube_2_charge": o2_tube_2_val,
		"flight_state": flight_state_val,
		"escaped_systems_count": escaped_systems_count
	}
	var file = FileAccess.open(SAVEGAME_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(save_data, "	"))
	file.close()
	game_saved.emit()
	return true

func load_game() -> bool:
	if not has_save_game():
		return false
	var data = get_save_summary()
	if data.is_empty():
		return false
	if int(data.get("save_version", 0)) != CURRENT_SAVE_VERSION:
		wipe_save_game()
		return false
		
	if data.has("current_planet") and not data["current_planet"].is_empty():
		current_planet = data["current_planet"]
		sanitize_planet_colors(current_planet)
	if data.has("current_solar_system") and not data["current_solar_system"].is_empty():
		current_solar_system = data["current_solar_system"]
	if data.has("difficulty"):
		current_difficulty = data["difficulty"] as Difficulty
	if data.has("player_stats"):
		player_stats = data["player_stats"]
	if data.has("escaped_systems_count"):
		escaped_systems_count = clampi(int(data["escaped_systems_count"]), 0, 10)
		escaped_systems_count_changed.emit(escaped_systems_count)
		
	if crafting:
		if data.has("inventory"):
			crafting.inventory = data["inventory"]
		if data.has("body_slots"):
			crafting.body_slots = data["body_slots"]
		if data.has("ship_storage"):
			crafting.ship_storage = data["ship_storage"]
		if data.has("installed_parts"):
			crafting.installed_parts = data["installed_parts"]
		if data.has("hyperdrive_requirements"):
			crafting.hyperdrive_requirements = data["hyperdrive_requirements"]
			
	game_loaded.emit()
	if is_inside_tree() and get_tree().current_scene and not get_tree().current_scene.name.begins_with("Test"):
		get_tree().change_scene_to_file("res://scenes/screens/loading_screen.tscn")
	return true

func new_game() -> void:
	start_new_game(0)
	start_expedition()

# ----------------- Difficulty & Interplanetary Travel (Space Agency 2137) -----------------

func get_planet_spawnable_ores(planet_data: Dictionary) -> Array:
	var lvl = planet_data.get("level", 0)
	var p_type = planet_data.get("type", "Habitable")
	
	# Easy / Level 0-1: Self-contained world with ALL ores to craft the hyperdrive directly
	if lvl <= 1:
		return ["iron", "copper", "silicon", "uranium"]
		
	# Higher Dificulty: Starting habitable planet lacks Uranium (forces planetary exploration)
	if p_type.contains("Habitable") or p_type.contains("Tierra"):
		return ["iron", "copper", "silicon"]
		
	# Extreme / Hostile Planets contain heavy reactor elements (Uranium)
	if p_type.contains("Volcan") or p_type.contains("Lava") or p_type.contains("Toxic") or p_type.contains("Acido") or lvl >= 4:
		return ["iron", "silicon", "uranium"]
		
	# Cryogenic / Cold worlds
	if p_type.contains("Cryo") or p_type.contains("Hielo"):
		return ["copper", "silicon", "uranium"]
		
	return ["iron", "copper", "silicon"]

func calc_transit_distance_au(p1: Dictionary, p2: Dictionary) -> float:
	var au1 = p1.get("orbit_au", 1.0)
	var au2 = p2.get("orbit_au", 1.0)
	return absf(au1 - au2)

func calc_transit_fuel_cost(dist_au: float) -> float:
	return clampf(20.0 + dist_au * 25.0, 20.0, 75.0)

func calc_transit_flight_duration_s(dist_au: float) -> float:
	return clampf(4.0 + dist_au * 4.0, 4.0, 12.0)

func start_interplanetary_transit(target_planet: Dictionary) -> void:
	interplanetary_transit_started.emit(target_planet)
	select_planet(target_planet)
	interplanetary_transit_completed.emit(target_planet)

# ----------------- 10-System Journey & Gargantua Outro -----------------

func is_in_gargantua_system() -> bool:
	return escaped_systems_count >= 9 or bool(current_solar_system.get("is_gargantua", false))

func trigger_victory_outro() -> Dictionary:
	escaped_systems_count = 10
	escaped_systems_count_changed.emit(escaped_systems_count)
	var victory_telemetry = {
		"status": "ESCAPED THE EVENT HORIZON - HOMEWORLD RESTORED",
		"escaped_systems_count": 10,
		"final_system": "Gargantua",
		"homeworld_restored": true,
		"time_dilation_overcome": true,
		"planet": current_planet.get("name", "Miller"),
		"difficulty": int(current_difficulty),
		"telemetry": {
			"total_systems_traversed": 10,
			"galactic_corridor_cleared": true,
			"singularity_status": "Event Horizon Escaped",
			"black_hole": "Gargantua Supermassive Black Hole",
			"time_dilation_ratio": "61,320:1 Relativistic Factor Overcome",
			"tidal_wave_hazard": "Surpassed",
			"crew_status": "Vital Signs Nominal - Homeworld Coordinates Restored"
		},
		"credits": [
			"CIVITUS: THE UNMILKY WAY HOME",
			"EXPEDITION COMMANDER: DEEP SPACE SURVIVOR",
			"CORRIDOR SURVEY: ALL 10 SOLAR SYSTEMS TRAVERSED",
			"ASTROPHYSICS: RELATIVISTIC SINGULARITY OVERCOME",
			"HOMEWORLD RESTORATION PROTOCOL COMPLETE",
			"THANK YOU FOR PLAYING CIVITUS!"
		]
	}
	save_game()
	outro_sequence_triggered.emit(victory_telemetry)
	expedition_completed.emit(victory_telemetry)
	return victory_telemetry

func complete_expedition(summary: Dictionary = {}) -> Dictionary:
	if is_in_gargantua_system() or escaped_systems_count >= 9:
		return trigger_victory_outro()
	else:
		escaped_systems_count += 1
		escaped_systems_count_changed.emit(escaped_systems_count)
		generate_new_solar_system()
		save_game()
		var res = summary.duplicate()
		res["escaped_systems_count"] = escaped_systems_count
		res["planet"] = current_planet.get("name", "")
		res["difficulty"] = int(current_difficulty)
		expedition_completed.emit(res)
		return res



