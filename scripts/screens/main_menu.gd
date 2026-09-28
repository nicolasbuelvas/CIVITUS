extends Control

# View State
enum ViewState {
	ROOT_MENU,
	PLAY_SELECT,
	PLANET_SELECTOR
}

var current_view: ViewState = ViewState.ROOT_MENU

# 3D Node references
@onready var planet_pivot: Node3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot
@onready var planet_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot/PlanetMesh
@onready var rings_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot/RingsMesh
@onready var star_pivot: Node3D = $SubViewportContainer/SubViewport/World3D/StarPivot
@onready var star_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World3D/StarPivot/StarMesh
@onready var orbits_view: Node3D = $SubViewportContainer/SubViewport/World3D/OrbitsView
@onready var sun_light: DirectionalLight3D = $SubViewportContainer/SubViewport/World3D/SunLight
@onready var camera_3d: Camera3D = $SubViewportContainer/SubViewport/World3D/Camera3D

# UI References - Root Menu (Pure Game Art Symbology)
@onready var root_layer: Control = $MenuLayer/RootLayer
@onready var title_label: Label = $MenuLayer/RootLayer/BrandBox/Title
@onready var subtitle_label: Label = $MenuLayer/RootLayer/BrandBox/Subtitle

@onready var play_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/PlayBtn
@onready var planet_editor_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/PlanetEditorBtn
@onready var store_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/StoreBtn
@onready var settings_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/SettingsBtn
@onready var exit_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/ExitBtn

# UI References - Play Perspective (Only 2 options + Volver)
@onready var play_select_layer: Control = $MenuLayer/PlaySelectLayer
@onready var continue_row: HBoxContainer = $MenuLayer/PlaySelectLayer/ActionButtons/ContinueRow
@onready var continue_btn: BaseButton = $MenuLayer/PlaySelectLayer/ActionButtons/ContinueRow/ContinueBtn
@onready var continue_details: Label = $MenuLayer/PlaySelectLayer/ActionButtons/ContinueRow/ContinueInfo/ContinueDetails
@onready var new_game_btn: BaseButton = $MenuLayer/PlaySelectLayer/ActionButtons/NewGameRow/NewGameBtn
@onready var back_from_play_btn: BaseButton = $MenuLayer/PlaySelectLayer/ActionButtons/BackRow/BackFromPlayBtn

# UI References - Planet Selector
@onready var selector_layer: Control = $MenuLayer/PlanetSelectorLayer
@onready var system_name_label: Label = $MenuLayer/PlanetSelectorLayer/TopBar/SystemBox/SystemName
@onready var system_coords_label: Label = $MenuLayer/PlanetSelectorLayer/TopBar/SystemBox/SystemCoords
@onready var new_system_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/TopBar/NewSystemBtn

@onready var prev_planet_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/PrevBtn
@onready var next_planet_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/NextBtn
@onready var planet_badge_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/PlanetBadgeLabel

@onready var planet_tab_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/BottomDock/TabBar/PlanetTabBtn
@onready var system_tab_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/BottomDock/TabBar/SystemTabBtn

@onready var telemetry_card: PanelContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard
@onready var planet_info_box: VBoxContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox
@onready var planet_name_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/HeaderRow/PlanetName
@onready var planet_type_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/HeaderRow/PlanetType
@onready var toggle_details_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/HeaderRow/ToggleDetailsBtn

# Graphical Meters
@onready var meters_grid: GridContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid
@onready var hab_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/HabBox/Label
@onready var hab_bar: ProgressBar = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/HabBox/Bar
@onready var hab_val: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/HabBox/Val

@onready var atmo_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/AtmoBox/Label
@onready var atmo_bar: ProgressBar = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/AtmoBox/Bar
@onready var atmo_val: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/AtmoBox/Val

@onready var temp_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/TempBox/Label
@onready var temp_bar: ProgressBar = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/TempBox/Bar
@onready var temp_val: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/TempBox/Val

@onready var grav_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/GravBox/Label
@onready var grav_bar: ProgressBar = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/GravBox/Bar
@onready var grav_val: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/MetersGrid/GravBox/Val

# System Info Box
@onready var system_info_box: VBoxContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/SystemInfoBox
@onready var star_line: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/SystemInfoBox/StarLine
@onready var hab_zone_line: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/SystemInfoBox/HabZoneLine
@onready var planets_count_line: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/SystemInfoBox/PlanetsCountLine

@onready var back_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/BackBtn
@onready var unlock_ad_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/UnlockAdBtn
@onready var launch_btn: BaseButton = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/LaunchBtn

# UI References - Settings Modal
@onready var settings_modal: Panel = $MenuLayer/SettingsModal
@onready var settings_title_label: Label = $MenuLayer/SettingsModal/VBox/Title
@onready var lang_label: Label = $MenuLayer/SettingsModal/VBox/LangBox/Label
@onready var lang_option: OptionButton = $MenuLayer/SettingsModal/VBox/LangBox/OptionButton

@onready var master_label: Label = $MenuLayer/SettingsModal/VBox/MasterBox/Label
@onready var master_slider: HSlider = $MenuLayer/SettingsModal/VBox/MasterBox/HSlider
@onready var master_val_label: Label = $MenuLayer/SettingsModal/VBox/MasterBox/ValLabel

@onready var music_label: Label = $MenuLayer/SettingsModal/VBox/MusicBox/Label
@onready var music_slider: HSlider = $MenuLayer/SettingsModal/VBox/MusicBox/HSlider
@onready var music_val_label: Label = $MenuLayer/SettingsModal/VBox/MusicBox/ValLabel

@onready var sfx_label: Label = $MenuLayer/SettingsModal/VBox/SfxBox/Label
@onready var sfx_slider: HSlider = $MenuLayer/SettingsModal/VBox/SfxBox/HSlider
@onready var sfx_val_label: Label = $MenuLayer/SettingsModal/VBox/SfxBox/ValLabel

@onready var save_settings_btn: Button = $MenuLayer/SettingsModal/VBox/ButtonRow/SaveSettingsBtn
@onready var reset_defaults_btn: Button = $MenuLayer/SettingsModal/VBox/ButtonRow/ResetDefaultsBtn
@onready var close_settings_btn: Button = $MenuLayer/SettingsModal/VBox/ButtonRow/CloseSettingsBtn

# UI References - Store Modal
@onready var store_modal: Panel = $MenuLayer/StoreModal
@onready var store_title: Label = $MenuLayer/StoreModal/VBox/HeaderRow/Title
@onready var store_coins_badge: Label = $MenuLayer/StoreModal/VBox/HeaderRow/StoreCoinsBadge
@onready var tab_skins_btn: Button = $MenuLayer/StoreModal/VBox/CategoryTabs/TabSkinsBtn
@onready var tab_paints_btn: Button = $MenuLayer/StoreModal/VBox/CategoryTabs/TabPaintsBtn
@onready var tab_packs_btn: Button = $MenuLayer/StoreModal/VBox/CategoryTabs/TabPacksBtn
@onready var store_items_container: VBoxContainer = $MenuLayer/StoreModal/VBox/ItemsScroll/ItemsContainer
@onready var store_desc: Label = $MenuLayer/StoreModal/VBox/Desc
@onready var buy_no_ads_btn: Button = $MenuLayer/StoreModal/VBox/BuyNoAdsBtn
@onready var buy_full_game_btn: Button = $MenuLayer/StoreModal/VBox/BuyFullGameBtn
@onready var buy_editor_btn: Button = $MenuLayer/StoreModal/VBox/BuyEditorBtn
@onready var store_status_label: Label = $MenuLayer/StoreModal/VBox/StatusLabel
@onready var restore_btn: Button = $MenuLayer/StoreModal/VBox/BottomRow/RestoreBtn
@onready var close_store_btn: Button = $MenuLayer/StoreModal/VBox/BottomRow/CloseStoreBtn

# UI References - Ad Transmission Modal
@onready var ad_modal: Panel = $MenuLayer/AdTransmissionModal
@onready var ad_title: Label = $MenuLayer/AdTransmissionModal/Card/VBox/Title
@onready var ad_subtitle: Label = $MenuLayer/AdTransmissionModal/Card/VBox/Subtitle
@onready var ad_progress_bar: ProgressBar = $MenuLayer/AdTransmissionModal/Card/VBox/ProgressBar
@onready var ad_tip_label: Label = $MenuLayer/AdTransmissionModal/Card/VBox/TipLabel
@onready var ad_skip_btn: Button = $MenuLayer/AdTransmissionModal/Card/VBox/SkipBtn

# Warp Transition Overlay
@onready var warp_overlay: ColorRect = $MenuLayer/WarpOverlay
@onready var warp_label: Label = $MenuLayer/WarpOverlay/WarpLabel

# 360-Degree Free Spherical Orbital Camera Controller
var cam_yaw: float = 0.25
var cam_pitch: float = 0.18
var cam_yaw_velocity: float = 0.04
var cam_pitch_velocity: float = 0.0

var is_dragging: bool = false
var last_drag_pos: Vector2 = Vector2.ZERO
var drag_travel: float = 0.0

# In-place 3D Planet Drag & Spin (Camera stays still)
var is_dragging_planet: bool = false
var planet_spin_vel_y: float = 0.05
var planet_spin_vel_x: float = 0.0

# Multi-touch pinch-to-zoom tracking
var active_touches: Dictionary = {}
var last_pinch_dist: float = 0.0
var is_pinching: bool = false

var camera_dist: float = 11.5
var target_camera_dist: float = 11.5
var current_focal_point: Vector3 = Vector3.ZERO
var target_focal_point: Vector3 = Vector3.ZERO

var selected_planet_index: int = 0
var active_info_tab: String = "planet" # "planet" or "system"
var is_transitioning: bool = false
var is_telemetry_expanded: bool = false

# Cached settings before opening modal for Cancel/Revert
var cached_master: float = 0.85
var cached_music: float = 0.70
var cached_sfx: float = 0.90
var cached_lang: String = "es"
var luna_badge_btn: Button = null
var luna_coins_label: Label = null

func _style_menu_button(btn: Button, border_color: Color, fill_color: Color = Color(0.08, 0.07, 0.16, 0.95)) -> void:
	if not btn: return
	var sb = StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border_color
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_right = 22
	sb.corner_radius_bottom_left = 22
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.13, 0.11, 0.24, 0.98)
	sb_hover.border_color = border_color.lightened(0.25)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)

func _ready() -> void:
	# Hide modals
	settings_modal.visible = false
	store_modal.visible = false
	
	# Top-Right Luna Coins Pill Badge (Circular icon with our game art + only the number!)
	var root_layer = get_node_or_null("MenuLayer/RootLayer")
	if root_layer:
		luna_badge_btn = Button.new()
		luna_badge_btn.name = "LunaCoinsPill"
		luna_badge_btn.custom_minimum_size = Vector2(85, 42)
		luna_badge_btn.anchors_preset = Control.PRESET_TOP_RIGHT
		luna_badge_btn.anchor_left = 1.0
		luna_badge_btn.anchor_right = 1.0
		luna_badge_btn.offset_left = -140.0
		luna_badge_btn.offset_top = 26.0
		luna_badge_btn.offset_right = -30.0
		luna_badge_btn.offset_bottom = 68.0
		
		var pill_sb = StyleBoxFlat.new()
		pill_sb.bg_color = Color(0.08, 0.07, 0.16, 0.95)
		pill_sb.border_width_left = 2
		pill_sb.border_width_top = 2
		pill_sb.border_width_right = 2
		pill_sb.border_width_bottom = 2
		pill_sb.border_color = Color(0.96, 0.66, 0.16, 1.0) # Gold rim
		pill_sb.corner_radius_top_left = 21
		pill_sb.corner_radius_top_right = 21
		pill_sb.corner_radius_bottom_right = 21
		pill_sb.corner_radius_bottom_left = 21
		pill_sb.content_margin_left = 8
		pill_sb.content_margin_right = 14
		pill_sb.content_margin_top = 4
		pill_sb.content_margin_bottom = 4
		luna_badge_btn.add_theme_stylebox_override("normal", pill_sb)
		
		var pill_hover = pill_sb.duplicate()
		pill_hover.bg_color = Color(0.13, 0.11, 0.24, 0.98)
		pill_hover.border_color = Color(1.0, 0.88, 0.35, 1.0)
		luna_badge_btn.add_theme_stylebox_override("hover", pill_hover)
		luna_badge_btn.add_theme_stylebox_override("pressed", pill_hover)
		
		var hbox = HBoxContainer.new()
		hbox.name = "HBox"
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 8)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var coin_icon = CircularArtButton.new()
		coin_icon.name = "CoinIcon"
		coin_icon.custom_minimum_size = Vector2(30, 30)
		coin_icon.icon_type = CircularArtButton.IconType.LUNA_COIN
		coin_icon.ring_thickness = 1.5
		coin_icon.ring_color = Color(0.96, 0.66, 0.16, 1.0)
		coin_icon.bg_color = Color(0.08, 0.07, 0.16, 0.95)
		coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(coin_icon)
		
		luna_coins_label = Label.new()
		luna_coins_label.name = "CoinsNum"
		luna_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		luna_coins_label.add_theme_font_size_override("font_size", 16)
		luna_coins_label.add_theme_color_override("font_color", Color(0.96, 0.66, 0.16))
		hbox.add_child(luna_coins_label)
		
		luna_badge_btn.add_child(hbox)
		luna_badge_btn.pressed.connect(_on_store_pressed)
		root_layer.add_child(luna_badge_btn)
	
	_update_luna_points_ui()
	GameManager.luna_points_changed.connect(func(_new_pts): _update_luna_points_ui())
	if GameManager.has_signal("luna_coins_changed"):
		GameManager.luna_coins_changed.connect(func(_new_pts): _update_luna_points_ui())
	
	# Connect Root Menu symbol buttons (Pure Game Art Symbology)
	play_btn.pressed.connect(_on_play_pressed)
	
	if planet_editor_btn:
		planet_editor_btn.pressed.connect(_on_planet_editor_pressed)
		
	if store_btn:
		store_btn.pressed.connect(_on_store_pressed)
	
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	
	if exit_btn:
		exit_btn.pressed.connect(_on_exit_pressed)
	
	# Connect Play Perspective buttons (Only 2 options + Volver)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
		
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game_pressed)
		
	if back_from_play_btn:
		back_from_play_btn.pressed.connect(_on_back_from_play_pressed)
	
	# Connect Store Category Tabs
	if tab_skins_btn:
		tab_skins_btn.pressed.connect(func(): _switch_store_tab("skins"))
	if tab_paints_btn:
		tab_paints_btn.pressed.connect(func(): _switch_store_tab("paints"))
	if tab_packs_btn:
		tab_packs_btn.pressed.connect(func(): _switch_store_tab("packs"))
	
	# Connect Store Modal buttons
	if buy_no_ads_btn:
		buy_no_ads_btn.pressed.connect(_on_buy_no_ads_pressed)
	if buy_full_game_btn:
		buy_full_game_btn.pressed.connect(_on_buy_full_game_pressed)
	if buy_editor_btn:
		buy_editor_btn.pressed.connect(_on_buy_editor_pressed)
	if restore_btn:
		restore_btn.pressed.connect(_on_restore_purchases_pressed)
	if close_store_btn:
		close_store_btn.pressed.connect(_on_close_store_pressed)
	
	# Connect Ad Modal buttons
	if ad_skip_btn:
		ad_skip_btn.pressed.connect(_on_ad_skip_pressed)
	if unlock_ad_btn:
		unlock_ad_btn.pressed.connect(_on_unlock_ad_pressed)
	
	# Connect RevenueCat signals
	RevenueCatManager.purchases_restored.connect(_on_purchases_restored)
	RevenueCatManager.entitlement_updated.connect(_on_entitlement_updated)
	
	# Connect Selector buttons
	new_system_btn.pressed.connect(_on_new_system_pressed)
	back_btn.pressed.connect(_on_back_to_menu_pressed)
	launch_btn.pressed.connect(_on_launch_pressed)
	prev_planet_btn.pressed.connect(_on_prev_planet_pressed)
	next_planet_btn.pressed.connect(_on_next_planet_pressed)
	
	planet_tab_btn.pressed.connect(_on_planet_tab_pressed)
	system_tab_btn.pressed.connect(_on_system_tab_pressed)
	
	# Connect Solar System Planet Selection
	if orbits_view and orbits_view.has_signal("planet_clicked"):
		orbits_view.planet_clicked.connect(_on_solar_system_planet_clicked)
	
	# Setup Settings UI
	_setup_settings_ui()
	
	# Connect Details Toggle
	if toggle_details_btn:
		toggle_details_btn.pressed.connect(_on_toggle_details_pressed)
	
	# Connect to GameManager signals
	GameManager.language_changed.connect(_on_language_changed)
	GameManager.solar_system_updated.connect(_on_solar_system_updated)
	
	# Update texts & initial view
	_apply_localization()
	_show_view(ViewState.ROOT_MENU)
	
	# Play distinct ambient menu theme
	if AudioManager.has_method("play_menu_music"):
		AudioManager.play_menu_music()
	
	# Procedural Showcase: Generate fresh solar system and pick a random featured planet on startup
	randomize()
	GameManager.generate_new_solar_system(randi() % 1000000)
	var planets = GameManager.current_solar_system.get("planets", [])
	if planets.size() > 0:
		selected_planet_index = randi() % planets.size()
		_select_planet(selected_planet_index)

func _on_play_pressed() -> void:
	AudioManager.play("click")
	_show_view(ViewState.PLAY_SELECT)

func _on_back_from_play_pressed() -> void:
	AudioManager.play("click")
	_show_view(ViewState.ROOT_MENU)

func _on_new_game_pressed() -> void:
	AudioManager.play("click")
	_show_view(ViewState.PLANET_SELECTOR)

func _update_continue_button() -> void:
	if not continue_btn:
		return
	if GameManager.has_save_game():
		if continue_row:
			continue_row.visible = true
		continue_btn.disabled = false
		var summary = GameManager.get_save_summary()
		var p_name = summary.get("planet_name", "Expedición")
		var p_prog = int(summary.get("hyperdrive_progress", 0.0) * 100)
		if continue_details:
			continue_details.text = "%s • %d%%" % [p_name, p_prog]
	else:
		if continue_row:
			continue_row.visible = false
		continue_btn.disabled = true

func _on_continue_pressed() -> void:
	AudioManager.play("click")
	GameManager.load_game()

func _apply_localization() -> void:
	# Root Menu & Play Perspective Tooltips (No text buttons, pure symbology!)
	_update_continue_button()
	play_btn.tooltip_text = "Jugar" if GameManager.current_language == "es" else "Play"
	if new_game_btn:
		new_game_btn.tooltip_text = "Nueva Partida" if GameManager.current_language == "es" else "New Game"
	if continue_btn:
		continue_btn.tooltip_text = "Continuar" if GameManager.current_language == "es" else "Continue"
	if back_from_play_btn:
		back_from_play_btn.tooltip_text = "Volver" if GameManager.current_language == "es" else "Back"
	if planet_editor_btn:
		planet_editor_btn.tooltip_text = "Simulador Planetario" if GameManager.current_language == "es" else "Planet Simulator"
	if settings_btn:
		settings_btn.tooltip_text = "Ajustes" if GameManager.current_language == "es" else "Settings"
	if store_btn:
		store_btn.tooltip_text = "Tienda Luna" if GameManager.current_language == "es" else "Luna Store"
	if exit_btn:
		exit_btn.tooltip_text = "Salir" if GameManager.current_language == "es" else "Exit"
	
	# Selector Navigation Tooltips (Pure Game Art Symbology)
	if new_system_btn:
		new_system_btn.tooltip_text = GameManager.loc("new_system")
	if back_btn:
		back_btn.tooltip_text = GameManager.loc("back_menu")
	if planet_tab_btn:
		planet_tab_btn.tooltip_text = GameManager.loc("planet_info_tab")
	if system_tab_btn:
		system_tab_btn.tooltip_text = GameManager.loc("system_info_tab")
	if toggle_details_btn:
		toggle_details_btn.tooltip_text = "Telemetría" if GameManager.current_language == "es" else "Telemetry"
	if prev_planet_btn:
		prev_planet_btn.tooltip_text = "Planeta Anterior" if GameManager.current_language == "es" else "Previous Planet"
	if next_planet_btn:
		next_planet_btn.tooltip_text = "Planeta Siguiente" if GameManager.current_language == "es" else "Next Planet"
	
	# Settings Modal
	settings_title_label.text = GameManager.loc("settings_title")
	lang_label.text = GameManager.loc("lang_label")
	master_label.text = GameManager.loc("vol_master")
	music_label.text = GameManager.loc("vol_music")
	sfx_label.text = GameManager.loc("vol_sfx")
	save_settings_btn.text = GameManager.loc("save_btn")
	reset_defaults_btn.text = GameManager.loc("reset_defaults")
	close_settings_btn.text = GameManager.loc("discard_btn")
	
	# Store Modal
	store_title.text = GameManager.loc("store_title")
	store_desc.text = GameManager.loc("store_desc")
	if buy_no_ads_btn:
		buy_no_ads_btn.text = GameManager.loc("buy_no_ads")
	if buy_full_game_btn:
		buy_full_game_btn.text = GameManager.loc("buy_full_game")
	if buy_editor_btn:
		buy_editor_btn.text = GameManager.loc("buy_editor")
	if restore_btn:
		restore_btn.text = GameManager.loc("restore_purchases")
	if close_store_btn:
		close_store_btn.text = GameManager.loc("close")
	if unlock_ad_btn:
		if unlock_ad_btn is CircularArtButton:
			unlock_ad_btn.tooltip_text = GameManager.loc("unlock_ad_btn")
		else:
			unlock_ad_btn.text = GameManager.loc("unlock_ad_btn")
	if ad_tip_label:
		ad_tip_label.text = GameManager.loc("ad_tip")
	
	# Meters Labels
	hab_label.text = "%s:" % GameManager.loc("habitability")
	atmo_label.text = "%s:" % GameManager.loc("atmosphere")
	temp_label.text = "%s:" % GameManager.loc("temp")
	grav_label.text = "%s:" % GameManager.loc("gravity")
	
	_update_launch_button_text()
	_update_telemetry_ui()

func _show_view(new_view: ViewState) -> void:
	current_view = new_view
	match new_view:
		ViewState.ROOT_MENU:
			root_layer.visible = true
			if play_select_layer:
				play_select_layer.visible = false
			selector_layer.visible = false
			target_camera_dist = 12.0
			target_focal_point = Vector3.ZERO
			planet_pivot.visible = true
			planet_pivot.position = Vector3(2.4, 0.0, 0.0)
			if star_pivot:
				star_pivot.visible = false
			if orbits_view:
				orbits_view.visible = false
		ViewState.PLAY_SELECT:
			root_layer.visible = false
			if play_select_layer:
				play_select_layer.visible = true
			selector_layer.visible = false
			target_camera_dist = 12.0
			target_focal_point = Vector3.ZERO
			planet_pivot.visible = true
			planet_pivot.position = Vector3(2.4, 0.0, 0.0)
			if star_pivot:
				star_pivot.visible = false
			if orbits_view:
				orbits_view.visible = false
			_update_continue_button()
		ViewState.PLANET_SELECTOR:
			root_layer.visible = false
			if play_select_layer:
				play_select_layer.visible = false
			selector_layer.visible = true
			target_camera_dist = 11.5
			target_focal_point = Vector3.ZERO
			planet_pivot.visible = true
			planet_pivot.position = Vector3.ZERO # Planet centered in planet selector!
			if star_pivot:
				star_pivot.visible = true
			if orbits_view:
				orbits_view.visible = false
			_refresh_solar_system_ui()

func _process(delta: float) -> void:
	# Menu & Play Perspective: Stationary camera ("YO no giro con el"), 3D planet spins in-place
	if current_view == ViewState.ROOT_MENU or current_view == ViewState.PLAY_SELECT:
		if camera_3d:
			camera_3d.position = Vector3(0.0, 0.0, 12.0)
			camera_3d.rotation = Vector3.ZERO
		if planet_mesh and planet_pivot and planet_pivot.visible:
			if not is_dragging_planet:
				planet_spin_vel_y = lerp(planet_spin_vel_y, 0.05, delta * 2.0)
				planet_spin_vel_x = lerp(planet_spin_vel_x, 0.0, delta * 3.0)
				planet_mesh.rotate_y(planet_spin_vel_y * delta)
				if abs(planet_spin_vel_x) > 0.0001:
					planet_mesh.rotate_object_local(Vector3.RIGHT, planet_spin_vel_x * delta)
		if planet_pivot:
			planet_pivot.position.x = lerp(planet_pivot.position.x, 2.4, delta * 8.0)
		return

	# Orbital camera drift for planet selector
	if not is_dragging:
		cam_yaw += cam_yaw_velocity * delta
		cam_pitch += cam_pitch_velocity * delta
		cam_pitch = clamp(cam_pitch, -1.25, 1.25)
		cam_yaw_velocity = lerp(cam_yaw_velocity, 0.025, delta * 1.5)
		cam_pitch_velocity = lerp(cam_pitch_velocity, 0.0, delta * 2.5)
		
	# In PLANET_SELECTOR view, planet is perfectly centered at origin
	if planet_pivot and planet_pivot.visible:
		planet_pivot.position.x = lerp(planet_pivot.position.x, 0.0, delta * 8.0)
		if planet_mesh:
			planet_mesh.rotation.y += delta * 0.05
		
	# Star slow drift
	if star_pivot and star_pivot.visible:
		star_pivot.rotation.y += delta * 0.01
		
	# Smooth focal point and camera distance
	current_focal_point = current_focal_point.lerp(target_focal_point, delta * 7.0)
	camera_dist = lerp(camera_dist, target_camera_dist, delta * 7.0)
	
	# Position camera orbiting around current_focal_point
	if camera_3d:
		var quat = Quaternion.from_euler(Vector3(cam_pitch, cam_yaw, 0.0))
		var offset = quat * Vector3(0.0, 0.0, camera_dist)
		camera_3d.position = current_focal_point + offset
		camera_3d.look_at(current_focal_point, quat * Vector3.UP)

func _gui_input(event: InputEvent) -> void:
	# Menu & Play Perspective: Drag directly rotates the 3D planet inside its right-hand zone
	if current_view == ViewState.ROOT_MENU or current_view == ViewState.PLAY_SELECT:
		var is_in_planet_zone = event.position.x >= get_viewport_rect().size.x * 0.28
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed and is_in_planet_zone:
					is_dragging_planet = true
					last_drag_pos = event.position
					planet_spin_vel_y = 0.0
					planet_spin_vel_x = 0.0
				else:
					is_dragging_planet = false
		elif event is InputEventMouseMotion and is_dragging_planet:
			var delta_pos = event.relative
			var sens = 0.005
			if planet_mesh:
				planet_mesh.rotate_y(delta_pos.x * sens)
				planet_mesh.rotate_object_local(Vector3.RIGHT, delta_pos.y * sens)
			planet_spin_vel_y = delta_pos.x * sens * 16.0
			planet_spin_vel_x = delta_pos.y * sens * 16.0
		elif event is InputEventScreenTouch:
			if event.pressed and is_in_planet_zone:
				is_dragging_planet = true
				last_drag_pos = event.position
				planet_spin_vel_y = 0.0
				planet_spin_vel_x = 0.0
			else:
				is_dragging_planet = false
		elif event is InputEventScreenDrag and is_dragging_planet:
			var delta_pos = event.relative
			var sens = 0.005
			if planet_mesh:
				planet_mesh.rotate_y(delta_pos.x * sens)
				planet_mesh.rotate_object_local(Vector3.RIGHT, delta_pos.y * sens)
			planet_spin_vel_y = delta_pos.x * sens * 16.0
			planet_spin_vel_x = delta_pos.y * sens * 16.0
		return

	# Free 360° omnidirectional orbit drag & mobile tap detection for Planet Selector
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_drag_pos = event.position
				drag_travel = 0.0
			else:
				is_dragging = false
				if drag_travel < 10.0 and active_info_tab == "system":
					_check_screen_tap_planet(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if active_info_tab == "planet":
				target_camera_dist = clamp(target_camera_dist - 0.6, 5.5, 20.0)
			else:
				target_camera_dist = clamp(target_camera_dist - 3.5, 18.0, 95.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if active_info_tab == "planet":
				target_camera_dist = clamp(target_camera_dist + 0.6, 5.5, 20.0)
			else:
				target_camera_dist = clamp(target_camera_dist + 3.5, 18.0, 95.0)
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta_pos = event.position - last_drag_pos
		last_drag_pos = event.position
		drag_travel += delta_pos.length()
		_apply_free_drag(delta_pos)
		
	elif event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
			if active_touches.size() == 1:
				is_dragging = true
				last_drag_pos = event.position
				drag_travel = 0.0
				is_pinching = false
			elif active_touches.size() >= 2:
				is_pinching = true
				is_dragging = false
				var keys = active_touches.keys()
				last_pinch_dist = active_touches[keys[0]].distance_to(active_touches[keys[1]])
		else:
			active_touches.erase(event.index)
			if active_touches.size() == 1:
				is_pinching = false
				is_dragging = true
				var remaining_key = active_touches.keys()[0]
				last_drag_pos = active_touches[remaining_key]
			elif active_touches.size() == 0:
				is_pinching = false
				is_dragging = false
				if drag_travel < 14.0 and active_info_tab == "system":
					_check_screen_tap_planet(event.position)
			
	elif event is InputEventScreenDrag:
		active_touches[event.index] = event.position
		if active_touches.size() >= 2:
			is_pinching = true
			is_dragging = false
			var keys = active_touches.keys()
			var current_dist = active_touches[keys[0]].distance_to(active_touches[keys[1]])
			if last_pinch_dist > 0.0:
				var pinch_delta = current_dist - last_pinch_dist
				if active_info_tab == "planet":
					target_camera_dist = clamp(target_camera_dist - pinch_delta * 0.035, 5.5, 20.0)
				else:
					target_camera_dist = clamp(target_camera_dist - pinch_delta * 0.14, 18.0, 95.0)
			last_pinch_dist = current_dist
		elif is_dragging and not is_pinching:
			drag_travel += event.relative.length()
			_apply_free_drag(event.relative)

func _check_screen_tap_planet(tap_pos: Vector2) -> void:
	if not camera_3d or not orbits_view:
		return
	var planets = GameManager.current_solar_system.get("planets", [])
	var closest_idx = -1
	var closest_dist = 48.0 # Generous 48px touch hitbox for mobile
	
	for i in range(planets.size()):
		var p_3d = orbits_view.get_planet_position(i)
		if camera_3d.is_position_behind(p_3d):
			continue
		var p_2d = camera_3d.unproject_position(p_3d)
		var d = tap_pos.distance_to(p_2d)
		if d < closest_dist:
			closest_dist = d
			closest_idx = i
			
	if closest_idx >= 0:
		_on_solar_system_planet_clicked(closest_idx)

func _on_solar_system_planet_clicked(idx: int) -> void:
	if is_transitioning:
		return
	AudioManager.play("click")
	_select_planet(idx)
	
	# ZOOM IN EFFECT:
	# Swoop camera from high solar system view directly down to selected planet & switch tab!
	is_transitioning = true
	var tween = create_tween()
	tween.tween_property(self, "target_camera_dist", 24.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_on_planet_tab_pressed()
	)
	tween.tween_property(self, "target_camera_dist", 11.5, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		is_transitioning = false
	)

func _apply_free_drag(delta_pos: Vector2) -> void:
	var sens = 0.005
	cam_yaw -= delta_pos.x * sens
	cam_pitch = clamp(cam_pitch - delta_pos.y * sens, -1.25, 1.25)
	cam_yaw_velocity = -delta_pos.x * sens * 14.0
	cam_pitch_velocity = -delta_pos.y * sens * 14.0

func _on_toggle_details_pressed() -> void:
	AudioManager.play("click")
	is_telemetry_expanded = !is_telemetry_expanded
	meters_grid.visible = is_telemetry_expanded
	if toggle_details_btn is CircularArtButton:
		toggle_details_btn.ring_color = Color(0.2, 0.95, 0.55) if is_telemetry_expanded else Color(0.4, 0.8, 1.0)
		toggle_details_btn.tooltip_text = "[ - INFO ]" if is_telemetry_expanded else "[ + INFO ]"
	else:
		toggle_details_btn.text = "[ - INFO ]" if is_telemetry_expanded else "[ + INFO ]"

# ----------------- Navigation & Button Callbacks -----------------

func _on_back_to_menu_pressed() -> void:
	AudioManager.play("click")
	_show_view(ViewState.ROOT_MENU)

func _on_new_system_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	AudioManager.play("hyperdrive", 1.0, 0.0)
	
	if warp_overlay:
		warp_overlay.visible = true
		warp_overlay.color = Color(0.08, 0.35, 0.85, 0.0)
		if warp_label:
			warp_label.text = "CALCULANDO SALTO HIPERESPACIAL..." if GameManager.current_language == "es" else "CALCULATING HYPERDRIVE VECTOR..."
	
	var tween = create_tween()
	# Phase 1: 0.0s - 1.8s Spool up, warp stretch FOV from 45 to 75, camera pull back
	tween.parallel().tween_property(self, "target_camera_dist", 30.0, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(camera_3d, "fov", 75.0, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if warp_overlay:
		tween.parallel().tween_property(warp_overlay, "color:a", 0.40, 1.8)
		
	# Phase 2: 1.8s - 2.4s Hyperspace jump flash peak & generate new solar system
	tween.tween_callback(func():
		if warp_label:
			warp_label.text = "TRÁNSITO HIPERESPACIAL EN CURSO..." if GameManager.current_language == "es" else "HYPERSPACE TRANSIT IN PROGRESS..."
		GameManager.generate_new_solar_system()
		_refresh_solar_system_ui()
	)
	if warp_overlay:
		tween.tween_property(warp_overlay, "color", Color(0.85, 0.95, 1.0, 0.70), 0.3)
		tween.tween_property(warp_overlay, "color", Color(0.08, 0.35, 0.85, 0.25), 0.3)
		
	# Phase 3: 2.4s - 4.0s Deceleration, drop out of hyperspace, smooth return to orbit
	tween.parallel().tween_property(self, "target_camera_dist", 11.5, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(camera_3d, "fov", 45.0, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if warp_overlay:
		tween.parallel().tween_property(warp_overlay, "color:a", 0.0, 1.6)
		
	tween.tween_callback(func():
		if warp_overlay:
			warp_overlay.visible = false
		is_transitioning = false
		_update_telemetry_ui()
	)

func _on_prev_planet_pressed() -> void:
	var planets = GameManager.current_solar_system.get("planets", [])
	if planets.is_empty() or is_transitioning:
		return
	var new_idx = (selected_planet_index - 1 + planets.size()) % planets.size()
	_transition_to_planet(new_idx)

func _on_next_planet_pressed() -> void:
	var planets = GameManager.current_solar_system.get("planets", [])
	if planets.is_empty() or is_transitioning:
		return
	var new_idx = (selected_planet_index + 1) % planets.size()
	_transition_to_planet(new_idx)

func _transition_to_planet(new_idx: int) -> void:
	AudioManager.play("click")
	if active_info_tab == "planet":
		is_transitioning = true
		var tween = create_tween()
		tween.tween_property(self, "target_camera_dist", 14.5, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			_select_planet(new_idx)
		)
		tween.tween_property(self, "target_camera_dist", 11.5, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			is_transitioning = false
		)
	else:
		_select_planet(new_idx)

func _on_solar_system_updated(sys: Dictionary) -> void:
	selected_planet_index = 0
	_update_star_visuals(sys)
	_refresh_solar_system_ui()

func _update_star_visuals(sys: Dictionary) -> void:
	if not star_mesh:
		return
	var star_data = sys.get("star", {})
	var star_col: Color = star_data.get("color", Color(1.0, 0.85, 0.35))
	var star_mat = star_mesh.get_surface_override_material(0) as StandardMaterial3D
	if not star_mat:
		star_mat = StandardMaterial3D.new()
		star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		star_mesh.set_surface_override_material(0, star_mat)
	star_mat.albedo_color = star_col

func _refresh_solar_system_ui() -> void:
	var sys = GameManager.current_solar_system
	if sys.is_empty():
		return
		
	var s_name = sys.get("system_name", "Kepler-452")
	var s_coords = sys.get("coords_str", "[RA: 00h 00m | DEC: +00° 00']")
	
	system_name_label.text = "%s: %s" % [GameManager.loc("system_label"), s_name]
	system_coords_label.text = s_coords
	
	if orbits_view and orbits_view.has_method("setup_system"):
		orbits_view.setup_system(sys, selected_planet_index)
		
	_update_planet_badge()
	_select_planet(selected_planet_index)

func _update_planet_badge() -> void:
	var sys = GameManager.current_solar_system
	var planets: Array = sys.get("planets", [])
	if planets.is_empty() or selected_planet_index >= planets.size():
		return
	var p_data = planets[selected_planet_index]
	var p_name = p_data.get("name", "Sector")
	var lvl = p_data.get("level", 0)
	var is_pro = (lvl >= 4)
	var badge = "Planeta %d de %d : %s [Nivel %d]" % [selected_planet_index + 1, planets.size(), p_name, lvl]
	if is_pro:
		badge += " ★ VIP"
	if planet_badge_label:
		planet_badge_label.text = badge

func _select_planet(idx: int) -> void:
	selected_planet_index = idx
	var planets = GameManager.current_solar_system.get("planets", [])
	if idx < 0 or idx >= planets.size():
		return
		
	var p = planets[idx]
	GameManager.select_planet(p)
	
	if orbits_view and orbits_view.has_method("set_selected_planet"):
		orbits_view.set_selected_planet(idx)
		
	# Space Engine / Universe Sandbox real-angle and apparent size of host star
	var sys = GameManager.current_solar_system
	var star_data = sys.get("star", {})
	var r_au = max(0.2, p.get("orbit_au", 1.0))
	var s_lum = star_data.get("luminosity", 1.0)
	var s_col: Color = star_data.get("color", Color(1.0, 0.92, 0.70))
	
	if star_pivot:
		var orb_angle = p.get("orbit_angle", float(idx) * 0.8)
		var star_horiz = Vector2(cos(orb_angle + PI), sin(orb_angle + PI)).normalized()
		var star_dir = Vector3(star_horiz.x, 0.32, star_horiz.y).normalized()
		var star_dist = 85.0 # Fixed celestial background distance
		star_pivot.position = star_dir * star_dist
		
		# Apparent size: closer = huge radiant sun, far = small brilliant diamond starlight
		var apparent_r = clamp((2.2 * sqrt(s_lum)) / sqrt(r_au), 0.55, 5.2)
		star_pivot.scale = Vector3.ONE * apparent_r
		
		# Coherent physical lighting intensity & color
		# Logarithmic exposure curve ensures illuminated side is always crisp and visible
		var flux = s_lum / (r_au * r_au)
		var light_energy = clamp(1.4 + 0.65 * log(max(0.05, flux) + 1.0), 1.15, 2.8)
		if sun_light:
			sun_light.light_energy = light_energy
			sun_light.light_color = s_col
			sun_light.look_at_from_position(star_pivot.position, Vector3.ZERO, Vector3.UP)
			
		# Update star surface material shader
		if star_mesh:
			var s_mat = star_mesh.get_surface_override_material(0) as ShaderMaterial
			if not s_mat:
				s_mat = star_mesh.material_override as ShaderMaterial
			if s_mat:
				s_mat.set_shader_parameter("star_color", s_col)
				s_mat.set_shader_parameter("corona_color", s_col.lerp(Color(1.0, 0.35, 0.1), 0.55))
	
	# Update 3D planet appearance via shader uniforms
	_apply_planet_to_3d_mesh(p)
	
	# Update UI & planet badge
	_update_planet_badge()
	_update_telemetry_ui()
	_update_launch_button_text()

func _apply_planet_to_3d_mesh(p: Dictionary) -> void:
	if not planet_mesh:
		return
		
	var mat = planet_mesh.get_surface_override_material(0) as ShaderMaterial
	if not mat:
		mat = planet_mesh.material_override as ShaderMaterial
	if not mat:
		return
		
	mat.set_shader_parameter("ocean_color", p.get("ocean_color", Color(0.04, 0.22, 0.55)))
	mat.set_shader_parameter("shore_color", p.get("shore_color", Color(0.12, 0.48, 0.72)))
	mat.set_shader_parameter("beach_color", p.get("beach_color", Color(0.82, 0.75, 0.52)))
	mat.set_shader_parameter("land_color", p.get("land_color", Color(0.20, 0.55, 0.26)))
	mat.set_shader_parameter("mountain_color", p.get("mountain_color", Color(0.48, 0.42, 0.36)))
	mat.set_shader_parameter("peak_color", p.get("peak_color", Color(0.92, 0.96, 1.0)))
	mat.set_shader_parameter("atmosphere_color", p.get("atmosphere_color", Color(0.30, 0.70, 1.0)))
	mat.set_shader_parameter("cloud_color", p.get("cloud_color", Color(1.0, 1.0, 1.0)))
	mat.set_shader_parameter("emission_color", p.get("emission_color", Color(0, 0, 0)))
	mat.set_shader_parameter("emission_energy", p.get("emission_energy", 0.0))
	mat.set_shader_parameter("water_threshold", p.get("water_threshold", 0.46))
	mat.set_shader_parameter("mountain_threshold", p.get("mountain_threshold", 0.72))
	mat.set_shader_parameter("peak_threshold", p.get("peak_threshold", 0.88))
	mat.set_shader_parameter("cloud_density", p.get("cloud_density", 0.52))
	mat.set_shader_parameter("cloud_speed", p.get("cloud_speed", 0.03))
	mat.set_shader_parameter("noise_scale", p.get("noise_scale", 2.4))
	mat.set_shader_parameter("seed_offset", float(int(p.get("seed", 1337)) % 1000))
	
	# Planetary Rings
	if rings_mesh:
		var has_rings = p.get("has_rings", false)
		rings_mesh.visible = has_rings
		if has_rings:
			var ring_mat = rings_mesh.material_override as ShaderMaterial
			if ring_mat:
				ring_mat.set_shader_parameter("ring_color", p.get("ring_color", Color(0.8, 0.8, 0.9)))

func _update_telemetry_ui() -> void:
	var p = GameManager.current_planet
	if p.is_empty():
		return
		
	var p_name = p.get("name", "Sector")
	var p_lvl = p.get("level", 0)
	var p_type = p.get("type_label", "Cuerpo Rocoso")
	
	# Planet Tab Data
	planet_name_label.text = "%s [%s %d]" % [p_name, GameManager.loc("level"), p_lvl]
	planet_type_label.text = p_type
	if toggle_details_btn:
		if toggle_details_btn is CircularArtButton:
			toggle_details_btn.ring_color = Color(0.2, 0.95, 0.55) if is_telemetry_expanded else Color(0.4, 0.8, 1.0)
			toggle_details_btn.tooltip_text = "[ - INFO ]" if is_telemetry_expanded else "[ + INFO ]"
		else:
			toggle_details_btn.text = "[ - INFO ]" if is_telemetry_expanded else "[ + INFO ]"
	if meters_grid:
		meters_grid.visible = is_telemetry_expanded
	
	var tg = p.get("telemetry_graph", {})
	var hab_score = tg.get("habitability", 0.85) * 100.0
	var atmo_score = tg.get("atmosphere", 0.5) * 100.0
	var temp_score = tg.get("temperature", 0.45) * 100.0
	var grav_score = tg.get("gravity", 0.40) * 100.0
	
	hab_bar.value = hab_score
	hab_val.text = "%d%%" % int(hab_score)
	
	var has_atmo = p.get("has_atmosphere", true)
	if not has_atmo:
		atmo_bar.value = 0.0
		atmo_val.text = "0.00 atm (Vacío)"
	else:
		atmo_bar.value = atmo_score
		atmo_val.text = "%.2f atm" % p.get("atmosphere", 1.0)
		
	temp_bar.value = temp_score
	temp_val.text = "%.0f °C" % p.get("temperature", 21.0)
	
	grav_bar.value = grav_score
	var g = p.get("gravity", 9.8)
	grav_val.text = "%.2f G (%.1f m/s²)" % [g / 9.8, g]
	
	# System Tab Data
	var sys = GameManager.current_solar_system
	var star_data = sys.get("star", {})
	var star_name = star_data.get("name", sys.get("system_name", "Kepler"))
	var spectral = star_data.get("spectral_class", "G2V")
	var s_temp = star_data.get("temperature", 5780)
	star_line.text = "%s: %s (Clase %s • %d K)" % [GameManager.loc("star_type"), star_name, spectral, s_temp]
	
	var hz_in = star_data.get("hz_inner_au", 0.85)
	var hz_out = star_data.get("hz_outer_au", 1.65)
	hab_zone_line.text = "%s (Goldilocks): %.2f AU ───── %.2f AU" % [GameManager.loc("habitable_zone"), hz_in, hz_out]
	
	var sg = sys.get("system_graph", {})
	var num_planets = sg.get("planet_count", sys.get("planets", []).size())
	var hab_count = sg.get("habitable_count", 1)
	planets_count_line.text = "%s: %d planetas (%d en zona habitable) • Radiación: %.2f rad/s" % [
		GameManager.loc("planets_count"), num_planets, hab_count, p.get("radiation", 0.01)
	]

func _on_planet_tab_pressed() -> void:
	AudioManager.play("click")
	active_info_tab = "planet"
	planet_info_box.visible = true
	system_info_box.visible = false
	if planet_tab_btn is CircularArtButton:
		planet_tab_btn.ring_color = Color(0.2, 0.85, 1.0)
	else:
		planet_tab_btn.modulate = Color(1.0, 1.0, 1.0)
	if system_tab_btn is CircularArtButton:
		system_tab_btn.ring_color = Color(0.4, 0.5, 0.65)
	else:
		system_tab_btn.modulate = Color(0.65, 0.75, 0.85, 0.6)
	
	# Show close-up planet and host star in distance
	planet_pivot.visible = true
	if star_pivot:
		star_pivot.visible = true
	if orbits_view:
		orbits_view.visible = false
		
	target_focal_point = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(self, "target_camera_dist", 11.5, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_system_tab_pressed() -> void:
	AudioManager.play("click")
	active_info_tab = "system"
	planet_info_box.visible = false
	system_info_box.visible = true
	if planet_tab_btn is CircularArtButton:
		planet_tab_btn.ring_color = Color(0.4, 0.5, 0.65)
	else:
		planet_tab_btn.modulate = Color(0.65, 0.75, 0.85, 0.6)
	if system_tab_btn is CircularArtButton:
		system_tab_btn.ring_color = Color(0.85, 0.65, 0.2)
	else:
		system_tab_btn.modulate = Color(1.0, 1.0, 1.0)
	
	# HIDE close-up planet and background star to completely resolve floating/duplicate bugs!
	planet_pivot.visible = false
	if star_pivot:
		star_pivot.visible = false
	if orbits_view:
		orbits_view.visible = true
		orbits_view.setup_system(GameManager.current_solar_system, selected_planet_index)
		
	target_focal_point = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(self, "target_camera_dist", 56.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _update_launch_button_text() -> void:
	var p = GameManager.current_planet
	var is_locked = p.get("is_locked", false) and not GameManager.is_vip_unlocked(p.get("level", 0))
	
	if launch_btn is CircularArtButton:
		if is_locked:
			launch_btn.icon_name = "coin"
			launch_btn.ring_color = Color(1.0, 0.7, 0.2)
			launch_btn.tooltip_text = GameManager.loc("unlock_tier")
		else:
			launch_btn.icon_name = "thrust"
			launch_btn.ring_color = Color(0.2, 0.95, 0.55)
			launch_btn.tooltip_text = GameManager.loc("start_expedition")
	else:
		if is_locked:
			launch_btn.text = GameManager.loc("unlock_tier")
			launch_btn.modulate = Color(1.0, 0.7, 0.2)
		else:
			launch_btn.text = GameManager.loc("start_expedition")
			launch_btn.modulate = Color(0.2, 0.9, 0.45)

func _on_launch_pressed() -> void:
	AudioManager.play("click")
	var p = GameManager.current_planet
	var is_locked = p.get("is_locked", false) and not GameManager.is_vip_unlocked(p.get("level", 0))
	
	if is_locked:
		open_store_modal(GameManager.loc("pro_sector_locked"), GameManager.loc("pro_sector_desc"))
		return
		
	GameManager.start_expedition()

# ----------------- Settings & Store Modals (Mutual Exclusivity) -----------------

func _setup_settings_ui() -> void:
	lang_option.clear()
	lang_option.add_item("Español", 0)
	lang_option.add_item("English", 1)
	lang_option.selected = 0 if GameManager.current_language == "es" else 1
	lang_option.item_selected.connect(_on_lang_selected)
	
	master_slider.value = GameManager.master_volume
	music_slider.value = GameManager.music_volume
	sfx_slider.value = GameManager.sfx_volume
	
	_update_slider_labels()
	
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	
	reset_defaults_btn.pressed.connect(Callable(self, "_on_reset_defaults_pressed"))

func _update_slider_labels() -> void:
	master_val_label.text = "%d%%" % int(master_slider.value * 100)
	music_val_label.text = "%d%%" % int(music_slider.value * 100)
	sfx_val_label.text = "%d%%" % int(sfx_slider.value * 100)

func _on_settings_pressed() -> void:
	AudioManager.play("click")
	# Mutual exclusivity: Close store if open
	store_modal.visible = false
	
	# Cache current settings for Discard/Close
	cached_master = GameManager.master_volume
	cached_music = GameManager.music_volume
	cached_sfx = GameManager.sfx_volume
	cached_lang = GameManager.current_language
	
	master_slider.value = cached_master
	music_slider.value = cached_music
	sfx_slider.value = cached_sfx
	lang_option.selected = 0 if cached_lang == "es" else 1
	_update_slider_labels()
	
	settings_modal.visible = true

func _on_save_settings_pressed() -> void:
	AudioManager.play("click")
	GameManager.master_volume = master_slider.value
	GameManager.music_volume = music_slider.value
	GameManager.sfx_volume = sfx_slider.value
	GameManager.save_settings()
	settings_modal.visible = false

func _on_close_settings_pressed() -> void:
	AudioManager.play("click")
	# Discard uncommitted changes: revert to cached
	GameManager.master_volume = cached_master
	GameManager.music_volume = cached_music
	GameManager.sfx_volume = cached_sfx
	if GameManager.current_language != cached_lang:
		GameManager.set_language(cached_lang)
	GameManager._apply_audio_bus_volumes()
	settings_modal.visible = false

func _on_reset_defaults_pressed() -> void:
	AudioManager.play("click")
	GameManager.reset_settings_to_default()
	master_slider.value = GameManager.master_volume
	music_slider.value = GameManager.music_volume
	sfx_slider.value = GameManager.sfx_volume
	_update_slider_labels()
	lang_option.selected = 0
	cached_master = GameManager.master_volume
	cached_music = GameManager.music_volume
	cached_sfx = GameManager.sfx_volume
	cached_lang = GameManager.current_language

func _on_lang_selected(idx: int) -> void:
	var lang = "es" if idx == 0 else "en"
	GameManager.set_language(lang)

func _on_language_changed(_new_lang: String) -> void:
	_apply_localization()

func _on_master_slider_changed(val: float) -> void:
	master_val_label.text = "%d%%" % int(val * 100)
	var idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val))

func _on_music_slider_changed(val: float) -> void:
	music_val_label.text = "%d%%" % int(val * 100)
	var idx = AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val))

func _on_sfx_slider_changed(val: float) -> void:
	sfx_val_label.text = "%d%%" % int(val * 100)
	var idx = AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val))

func _on_planet_editor_pressed() -> void:
	AudioManager.play("click")
	if RevenueCatManager.has_planet_editor():
		get_tree().change_scene_to_file("res://scenes/screens/planet_editor.tscn")
	else:
		open_store_modal(GameManager.loc("store_editor_locked"), GameManager.loc("store_editor_desc"), true)

func _on_store_pressed() -> void:
	AudioManager.play("click")
	# Mutual exclusivity: Close settings if open
	settings_modal.visible = false
	open_store_modal(GameManager.loc("pro_sector_locked"), GameManager.loc("pro_sector_desc"), false)

var current_store_tab: String = "skins"

const STORE_ITEMS: Array[Dictionary] = [
	# Skins
	{
		"id": "apollo_white",
		"category": "skins",
		"name": "APOLO CLÁSICO",
		"badge": "[EVA-01]",
		"color": Color(0.9, 0.9, 0.95),
		"cost": 0,
		"currency": "coins",
		"desc": "Traje presurizado estándar de polímero aislante."
	},
	{
		"id": "solar_gold",
		"category": "skins",
		"name": "SOLAR ÁUREO",
		"badge": "[EVA-02]",
		"color": Color(0.96, 0.66, 0.16),
		"cost": 150,
		"currency": "coins",
		"desc": "Aleación reflectante con protección contra radiación solar."
	},
	{
		"id": "abyssal_onyx",
		"category": "skins",
		"name": "ABISAL ÓNIX",
		"badge": "[EVA-03]",
		"color": Color(0.18, 0.18, 0.22),
		"cost": 250,
		"currency": "coins",
		"desc": "Blindaje de nanotubos de carbono de absorción térmica."
	},
	{
		"id": "cyber_neon",
		"category": "skins",
		"name": "CIBER NEÓN",
		"badge": "[EVA-04]",
		"color": Color(0.15, 0.85, 1.0),
		"cost": 400,
		"currency": "coins",
		"desc": "Canalización de plasma frío electroluminiscente."
	},
	# Propulsion
	{
		"id": "capsule_white",
		"category": "paints",
		"name": "CÁPSULA BLANCA",
		"badge": "[HULL-01]",
		"color": Color(0.85, 0.85, 0.9),
		"cost": 0,
		"currency": "coins",
		"desc": "Blindaje cerámico para reentrada atmosférica."
	},
	{
		"id": "plasma_cyan",
		"category": "paints",
		"name": "PLASMA CIAN",
		"badge": "[HULL-02]",
		"color": Color(0.2, 0.85, 1.0),
		"cost": 100,
		"currency": "coins",
		"desc": "Tobera de empuje iónico con aceleración de xenón."
	},
	{
		"id": "solar_fire",
		"category": "paints",
		"name": "FUEGO SOLAR",
		"badge": "[HULL-03]",
		"color": Color(1.0, 0.5, 0.1),
		"cost": 200,
		"currency": "coins",
		"desc": "Combustión metanox de alta temperatura y pluma dorada."
	},
	{
		"id": "amethyst_singularity",
		"category": "paints",
		"name": "AMATISTA",
		"badge": "[HULL-04]",
		"color": Color(0.75, 0.25, 0.95),
		"cost": 350,
		"currency": "coins",
		"desc": "Propulsión exótica de taquiones con rastro violeta."
	},
	# Packs
	{
		"id": "watch_ad_coins",
		"category": "packs",
		"name": "TRANSMISIÓN ORBITAL",
		"badge": "[GRATIS +50]",
		"color": Color(0.2, 0.85, 1.0),
		"cost_label": "VER ANUNCIO (+50)",
		"reward_coins": 50,
		"is_ad": true,
		"currency": "ad",
		"desc": "Sintoniza una transmisión comercial de espacio profundo para recibir 50 Luna Coins gratis."
	},
	{
		"id": "pack_scout",
		"category": "packs",
		"name": "SUMINISTRO INICIAL",
		"badge": "[+250 COINS]",
		"color": Color(1.0, 0.85, 0.25),
		"cost_label": "$0.99 USD",
		"reward_coins": 250,
		"currency": "real",
		"desc": "Reserva de fondos para exploradores espaciales."
	},
	{
		"id": "pack_explorer",
		"category": "packs",
		"name": "EXPEDICIÓN AVANZADA",
		"badge": "[+800 + SIN ADS]",
		"color": Color(0.35, 0.85, 1.0),
		"cost_label": "$1.99 USD",
		"reward_coins": 800,
		"no_ads": true,
		"currency": "real",
		"desc": "Vuelo sin publicidad y 800 Luna Coins."
	},
	{
		"id": "pack_protocol",
		"category": "packs",
		"name": "PROTOCOLO TOTAL VIP",
		"badge": "[VIP COMPLETO]",
		"color": Color(0.4, 0.95, 0.5),
		"cost_label": "$4.99 USD",
		"reward_coins": 2500,
		"unlock_all": true,
		"currency": "real",
		"desc": "Todo desbloqueado: editor de planetas, cosméticos y 2500 Luna Coins."
	}
]

func _update_luna_points_ui() -> void:
	if luna_coins_label:
		luna_coins_label.text = "%d" % GameManager.luna_points
	elif luna_badge_btn:
		luna_badge_btn.text = "%d" % GameManager.luna_points
	if store_coins_badge:
		store_coins_badge.text = "%d LUNA COINS" % GameManager.luna_points

func _switch_store_tab(tab: String) -> void:
	AudioManager.play("click")
	current_store_tab = tab
	if tab_skins_btn:
		tab_skins_btn.modulate = Color(1.0, 0.9, 0.4) if tab == "skins" else Color(0.7, 0.7, 0.7)
	if tab_paints_btn:
		tab_paints_btn.modulate = Color(1.0, 0.9, 0.4) if tab == "paints" else Color(0.7, 0.7, 0.7)
	if tab_packs_btn:
		tab_packs_btn.modulate = Color(1.0, 0.9, 0.4) if tab == "packs" else Color(0.7, 0.7, 0.7)
	_render_store_items()

func _render_store_items() -> void:
	if not store_items_container:
		return
	for c in store_items_container.get_children():
		c.queue_free()
		
	for it in STORE_ITEMS:
		if it["category"] != current_store_tab:
			continue
			
		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.04, 0.07, 0.12, 0.88)
		card_sb.border_width_left = 1
		card_sb.border_width_top = 1
		card_sb.border_width_right = 1
		card_sb.border_width_bottom = 1
		card_sb.border_color = (it["color"] as Color).lerp(Color(0.96, 0.66, 0.16), 0.4)
		card_sb.corner_radius_top_left = 8
		card_sb.corner_radius_top_right = 8
		card_sb.corner_radius_bottom_right = 8
		card_sb.corner_radius_bottom_left = 8
		card_sb.content_margin_left = 14
		card_sb.content_margin_right = 14
		card_sb.content_margin_top = 10
		card_sb.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_sb)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		
		# Visual badge
		var badge_lbl = Label.new()
		badge_lbl.text = it["badge"]
		badge_lbl.modulate = it["color"]
		badge_lbl.custom_minimum_size = Vector2(90, 0)
		badge_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(badge_lbl)
		
		# Info Box
		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.add_theme_constant_override("separation", 2)
		
		var name_lbl = Label.new()
		name_lbl.text = it["name"]
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.modulate = Color(0.95, 0.95, 0.98)
		info_box.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = it["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.65, 0.72, 0.82)
		info_box.add_child(desc_lbl)
		row.add_child(info_box)
		
		# Action Button
		var act_btn = Button.new()
		act_btn.custom_minimum_size = Vector2(140, 36)
		act_btn.add_theme_font_size_override("font_size", 12)
		
		var is_skin = it["category"] == "skins"
		var is_paint = it["category"] == "paints"
		var is_pack = it["category"] == "packs"
		
		if is_skin:
			var unlocked = it["cost"] == 0 or it["id"] in GameManager.unlocked_skins
			var equipped = GameManager.active_skin == it["id"]
			if equipped:
				act_btn.text = "EQUIPADO ✓"
				act_btn.disabled = true
				_style_menu_button(act_btn, Color(0.2, 0.85, 0.4), Color(0.04, 0.14, 0.08))
			elif unlocked:
				act_btn.text = "EQUIPAR"
				_style_menu_button(act_btn, Color(0.2, 0.75, 1.0), Color(0.04, 0.11, 0.18))
				act_btn.pressed.connect(func():
					GameManager.active_skin = it["id"]
					GameManager.save_player_progression()
					AudioManager.play("click")
					_render_store_items()
				)
			else:
				act_btn.text = "%d LUNA COINS" % it["cost"]
				_style_menu_button(act_btn, Color(0.96, 0.66, 0.16), Color(0.14, 0.09, 0.03))
				act_btn.pressed.connect(func():
					if GameManager.spend_luna_coins(it["cost"]):
						GameManager.unlocked_skins.append(it["id"])
						GameManager.active_skin = it["id"]
						GameManager.save_player_progression()
						AudioManager.play("click")
						_update_luna_points_ui()
						_render_store_items()
					else:
						if store_status_label:
							store_status_label.visible = true
							store_status_label.text = "LUNA COINS INSUFICIENTES (FALTAN %d)" % (it["cost"] - GameManager.luna_points)
							store_status_label.modulate = Color(1.0, 0.4, 0.4)
				)
		elif is_paint:
			var unlocked = it["cost"] == 0 or it["id"] in GameManager.unlocked_ship_paints
			var equipped = GameManager.active_ship_paint == it["id"]
			if equipped:
				act_btn.text = "EQUIPADO ✓"
				act_btn.disabled = true
				_style_menu_button(act_btn, Color(0.2, 0.85, 0.4), Color(0.04, 0.14, 0.08))
			elif unlocked:
				act_btn.text = "EQUIPAR"
				_style_menu_button(act_btn, Color(0.2, 0.75, 1.0), Color(0.04, 0.11, 0.18))
				act_btn.pressed.connect(func():
					GameManager.active_ship_paint = it["id"]
					GameManager.save_player_progression()
					AudioManager.play("click")
					_render_store_items()
				)
			else:
				act_btn.text = "%d LUNA COINS" % it["cost"]
				_style_menu_button(act_btn, Color(0.96, 0.66, 0.16), Color(0.14, 0.09, 0.03))
				act_btn.pressed.connect(func():
					if GameManager.spend_luna_coins(it["cost"]):
						GameManager.unlocked_ship_paints.append(it["id"])
						GameManager.active_ship_paint = it["id"]
						GameManager.save_player_progression()
						AudioManager.play("click")
						_update_luna_points_ui()
						_render_store_items()
					else:
						if store_status_label:
							store_status_label.visible = true
							store_status_label.text = "LUNA COINS INSUFICIENTES (FALTAN %d)" % (it["cost"] - GameManager.luna_points)
							store_status_label.modulate = Color(1.0, 0.4, 0.4)
				)
		elif is_pack:
			act_btn.text = it["cost_label"]
			_style_menu_button(act_btn, Color(0.96, 0.66, 0.16), Color(0.14, 0.09, 0.03))
			if it.get("is_ad", false):
				_style_menu_button(act_btn, Color(0.2, 0.85, 1.0), Color(0.04, 0.12, 0.18))
				act_btn.pressed.connect(func():
					AudioManager.play("click")
					AdManager.show_rewarded_ad(func():
						GameManager.add_luna_coins(50)
						_update_luna_points_ui()
						if store_status_label:
							store_status_label.visible = true
							store_status_label.text = "TRANSMISIÓN COMPLETADA: +50 LUNA COINS"
							store_status_label.modulate = Color(0.3, 0.95, 0.5)
					)
				)
			else:
				act_btn.pressed.connect(func():
					AudioManager.play("click")
					GameManager.add_luna_coins(it["reward_coins"])
					if it.get("no_ads", false):
						RevenueCatManager.has_purchased_no_ads = true
					if it.get("unlock_all", false):
						RevenueCatManager.has_full_game_access = true
						RevenueCatManager.has_purchased_editor = true
						RevenueCatManager.has_purchased_no_ads = true
					_update_luna_points_ui()
					_render_store_items()
					if store_status_label:
						store_status_label.visible = true
						store_status_label.text = "SUMINISTRO CONFIRMADO: +%d LUNA COINS" % it["reward_coins"]
						store_status_label.modulate = Color(0.3, 0.95, 0.5)
				)
			
		row.add_child(act_btn)
		card.add_child(row)
		store_items_container.add_child(card)

func open_store_modal(title: String, desc: String, _highlight_editor: bool = false) -> void:
	store_title.text = title if not title.is_empty() else "TIENDA LUNA"
	_update_luna_points_ui()
	_switch_store_tab(current_store_tab)
	store_modal.visible = true
	if store_status_label:
		store_status_label.visible = false

func _on_close_store_pressed() -> void:
	AudioManager.play("click")
	store_modal.visible = false

func _on_buy_no_ads_pressed() -> void:
	AudioManager.play("click")
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_NO_ADS)
	store_modal.visible = false
	_update_launch_button_text()

func _on_buy_full_game_pressed() -> void:
	AudioManager.play("click")
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_FULL_GAME)
	store_modal.visible = false
	_update_launch_button_text()

func _on_buy_editor_pressed() -> void:
	AudioManager.play("click")
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_PLANET_EDITOR)
	store_modal.visible = false
	_update_launch_button_text()
	if RevenueCatManager.has_planet_editor():
		get_tree().change_scene_to_file("res://scenes/screens/planet_editor.tscn")

func _on_restore_purchases_pressed() -> void:
	AudioManager.play("click")
	if store_status_label:
		store_status_label.visible = true
		store_status_label.text = "Sincronizando con Samsung Galaxy Store..." if GameManager.current_language == "es" else "Synchronizing with Samsung Galaxy Store..."
		store_status_label.modulate = Color(0.35, 0.85, 1.0)
	RevenueCatManager.restore_purchases()

func _on_purchases_restored(success: bool) -> void:
	if store_status_label:
		store_status_label.visible = true
		if success and (RevenueCatManager.has_premium_access() or RevenueCatManager.has_no_ads() or RevenueCatManager.has_planet_editor()):
			store_status_label.text = GameManager.loc("purchases_restored_ok")
			store_status_label.modulate = Color(0.35, 0.9, 0.6)
		else:
			store_status_label.text = GameManager.loc("purchases_restored_none")
			store_status_label.modulate = Color(0.9, 0.7, 0.3)
	_update_launch_button_text()

func _on_entitlement_updated(_entitlement: String, _active: bool) -> void:
	_update_launch_button_text()

# ----------------- Ads & VIP Transmission System -----------------

var current_ad_is_rewarded: bool = false
var ad_tween: Tween = null

func _on_unlock_ad_pressed() -> void:
	AudioManager.play("click")
	_show_ad_transmission(true)

func _show_ad_transmission(is_rewarded: bool) -> void:
	current_ad_is_rewarded = is_rewarded
	if not ad_modal:
		return
		
	ad_modal.visible = true
	ad_progress_bar.value = 0.0
	ad_skip_btn.disabled = true
	
	if is_rewarded:
		ad_title.text = GameManager.loc("ad_rewarded_title")
		ad_subtitle.text = "Sincronizando baliza de acceso clasificado con la flota orbital..." if GameManager.current_language == "es" else "Synchronizing classified beacon access with orbital fleet..."
		ad_skip_btn.text = "AUTORIZANDO (3s)..." if GameManager.current_language == "es" else "AUTHORIZING (3s)..."
	else:
		ad_title.text = GameManager.loc("ad_transmission_title")
		ad_subtitle.text = "Transmisión de telemetría interplanetaria en curso..." if GameManager.current_language == "es" else "Interplanetary telemetry broadcast in progress..."
		ad_skip_btn.text = "TRANSMISIÓN (3s)..." if GameManager.current_language == "es" else "BROADCAST (3s)..."
	
	if ad_tween:
		ad_tween.kill()
	ad_tween = create_tween()
	ad_tween.tween_property(ad_progress_bar, "value", 100.0, 3.0).set_trans(Tween.TRANS_LINEAR)
	ad_tween.finished.connect(_on_ad_finished)

func _on_ad_finished() -> void:
	ad_skip_btn.disabled = false
	ad_skip_btn.text = GameManager.loc("ad_skip")
	if current_ad_is_rewarded:
		var p = GameManager.current_planet
		var p_lvl = p.get("level", 0)
		GameManager.unlock_vip_temporarily(p_lvl)
		_update_launch_button_text()

func _on_ad_skip_pressed() -> void:
	AudioManager.play("click")
	ad_modal.visible = false
	if current_ad_is_rewarded:
		var p = GameManager.current_planet
		var p_lvl = p.get("level", 0)
		GameManager.unlock_vip_temporarily(p_lvl)
		_update_launch_button_text()
		_on_launch_pressed()

func _on_exit_pressed() -> void:
	AudioManager.play("click")
	get_tree().quit(0)
