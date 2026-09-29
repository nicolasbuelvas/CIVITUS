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
@onready var root_brand_box: VBoxContainer = $MenuLayer/RootLayer/BrandBox
@onready var title_label: Label = $MenuLayer/RootLayer/BrandBox/Title
@onready var subtitle_label: Label = $MenuLayer/RootLayer/BrandBox/Subtitle
@onready var root_action_buttons: VBoxContainer = $MenuLayer/RootLayer/ActionButtons

@onready var play_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/PlayRow/PlayBtn
@onready var planet_editor_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/PlanetEditorRow/PlanetEditorBtn
@onready var store_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/StoreRow/StoreBtn
@onready var settings_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/SettingsRow/SettingsBtn
@onready var exit_btn: BaseButton = $MenuLayer/RootLayer/ActionButtons/ExitRow/ExitBtn

@onready var play_title: Label = $MenuLayer/RootLayer/ActionButtons/PlayRow/PlayInfo/PlayTitle
@onready var play_subtitle: Label = $MenuLayer/RootLayer/ActionButtons/PlayRow/PlayInfo/PlaySubtitle
@onready var editor_title: Label = $MenuLayer/RootLayer/ActionButtons/PlanetEditorRow/EditorInfo/EditorTitle
@onready var editor_subtitle: Label = $MenuLayer/RootLayer/ActionButtons/PlanetEditorRow/EditorInfo/EditorSubtitle
@onready var store_title_label: Label = $MenuLayer/RootLayer/ActionButtons/StoreRow/StoreInfo/StoreTitle
@onready var store_subtitle_label: Label = $MenuLayer/RootLayer/ActionButtons/StoreRow/StoreInfo/StoreSubtitle
@onready var settings_title_row: Label = $MenuLayer/RootLayer/ActionButtons/SettingsRow/SettingsInfo/SettingsTitle
@onready var settings_subtitle_row: Label = $MenuLayer/RootLayer/ActionButtons/SettingsRow/SettingsInfo/SettingsSubtitle
@onready var exit_title: Label = $MenuLayer/RootLayer/ActionButtons/ExitRow/ExitInfo/ExitTitle
@onready var exit_subtitle: Label = $MenuLayer/RootLayer/ActionButtons/ExitRow/ExitInfo/ExitSubtitle

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
@onready var settings_dimmer: ColorRect = $MenuLayer/SettingsDimmer
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
@onready var store_dimmer: ColorRect = $MenuLayer/StoreDimmer
@onready var store_modal: Panel = $MenuLayer/StoreModal
@onready var store_title: Label = $MenuLayer/StoreModal/VBox/HeaderRow/Title
@onready var store_coins_badge: Label = $MenuLayer/StoreModal/VBox/HeaderRow/StoreCoinsBadge
@onready var sector_notice_badge: Label = $MenuLayer/StoreModal/VBox/SectorNoticeBadge
@onready var tab_skins_btn: Button = $MenuLayer/StoreModal/VBox/CategoryTabs/TabSkinsBtn
@onready var tab_paints_btn: Button = $MenuLayer/StoreModal/VBox/CategoryTabs/TabPaintsBtn
@onready var tab_packs_btn: Button = $MenuLayer/StoreModal/VBox/CategoryTabs/TabPacksBtn
@onready var items_scroll: ScrollContainer = $MenuLayer/StoreModal/VBox/ItemsScroll
@onready var store_items_container: VBoxContainer = $MenuLayer/StoreModal/VBox/ItemsScroll/ItemsContainer
@onready var store_desc: Label = $MenuLayer/StoreModal/VBox/Desc
@onready var buy_no_ads_btn: Button = $MenuLayer/StoreModal/VBox/BuyNoAdsBtn
@onready var buy_full_game_btn: Button = $MenuLayer/StoreModal/VBox/BuyFullGameBtn
@onready var buy_editor_btn: Button = $MenuLayer/StoreModal/VBox/BuyEditorBtn
@onready var store_status_label: Label = $MenuLayer/StoreModal/VBox/StatusLabel
@onready var restore_btn: Button = $MenuLayer/StoreModal/VBox/BottomRow/RestoreBtn
@onready var close_store_btn: Button = $MenuLayer/StoreModal/VBox/BottomRow/CloseStoreBtn

# 3D Showcase and Interactive Checkout
var showcase_container: VBoxContainer = null
var showcase_viewport: SubViewport = null
var showcase_pivot: Node3D = null
var showcase_cam: Camera3D = null
var showcase_astronaut: Node3D = null
var showcase_ship: Node3D = null
var showcase_title_lbl: Label = null
var showcase_desc_lbl: Label = null
var showcase_action_btn: Button = null
var current_suit_index: int = 0
var current_ship_index: int = 0
var is_dragging_showcase: bool = false
var showcase_spin_vel_y: float = 0.35
var showcase_spin_vel_x: float = 0.0

var tab_active_sb: StyleBoxFlat = null
var tab_inactive_sb: StyleBoxFlat = null
var active_checkout_modal: Control = null

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

func _set_modal_open_state(modal_open: bool) -> void:
	if root_brand_box:
		root_brand_box.visible = not modal_open
	if root_action_buttons:
		root_action_buttons.visible = not modal_open

func _ready() -> void:
	_init_tab_styles()
	_setup_store_showcase()
	
	# Hide modals & full-screen dimmers
	if settings_dimmer:
		settings_dimmer.visible = false
	if settings_modal:
		settings_modal.visible = false
	if store_dimmer:
		store_dimmer.visible = false
	if store_modal:
		store_modal.visible = false
	_set_modal_open_state(false)
	
	# Connect dimmer backdrops so clicking them safely dismisses modal
	if settings_dimmer:
		settings_dimmer.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_close_settings_pressed()
		)
	if store_dimmer:
		store_dimmer.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_close_store_pressed()
		)
	
	# Focus mode NONE on store tabs so no blue focus rectangles appear
	if tab_skins_btn:
		tab_skins_btn.focus_mode = Control.FOCUS_NONE
	if tab_paints_btn:
		tab_paints_btn.focus_mode = Control.FOCUS_NONE
	if tab_packs_btn:
		tab_packs_btn.focus_mode = Control.FOCUS_NONE
	
	# Connect row text clicks to corresponding buttons
	for row_data in [
		[get_node_or_null("MenuLayer/RootLayer/ActionButtons/PlayRow"), play_btn],
		[get_node_or_null("MenuLayer/RootLayer/ActionButtons/PlanetEditorRow"), planet_editor_btn],
		[get_node_or_null("MenuLayer/RootLayer/ActionButtons/StoreRow"), store_btn],
		[get_node_or_null("MenuLayer/RootLayer/ActionButtons/SettingsRow"), settings_btn],
		[get_node_or_null("MenuLayer/RootLayer/ActionButtons/ExitRow"), exit_btn]
	]:
		var r_node = row_data[0]
		var b_node = row_data[1]
		if r_node and b_node:
			r_node.mouse_filter = Control.MOUSE_FILTER_PASS
			var info_col = r_node.get_node_or_null(r_node.name.replace("Row", "Info"))
			if not info_col and r_node.get_child_count() > 1:
				info_col = r_node.get_child(1)
			if info_col:
				info_col.mouse_filter = Control.MOUSE_FILTER_PASS
				info_col.gui_input.connect(func(ev: InputEvent):
					if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
						b_node.emit_signal("pressed")
				)
	
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
	# Root Menu & Play Perspective Tooltips and Labels
	_update_continue_button()
	play_btn.tooltip_text = "Jugar" if GameManager.current_language == "es" else "Play"
	if play_title:
		play_title.text = GameManager.loc("menu_play_title")
	if play_subtitle:
		play_subtitle.text = GameManager.loc("menu_play_sub")
	if editor_title:
		editor_title.text = GameManager.loc("menu_architect_title")
	if editor_subtitle:
		editor_subtitle.text = GameManager.loc("menu_architect_sub")
	if store_title_label:
		store_title_label.text = GameManager.loc("menu_store_title")
	if store_subtitle_label:
		store_subtitle_label.text = GameManager.loc("menu_store_sub")
	if settings_title_row:
		settings_title_row.text = GameManager.loc("menu_settings_title")
	if settings_subtitle_row:
		settings_subtitle_row.text = GameManager.loc("menu_settings_sub")
	if exit_title:
		exit_title.text = GameManager.loc("menu_exit_title")
	if exit_subtitle:
		exit_subtitle.text = GameManager.loc("menu_exit_sub")
		
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
	
	# Settings Modal (Pure Iconography Style)
	settings_title_label.text = "[ ⬡  ⚙  ⬡ ]"
	lang_label.text = "🌐"
	master_label.text = "🔊"
	music_label.text = "🎵"
	sfx_label.text = "⚡"
	save_settings_btn.text = "✓"
	reset_defaults_btn.text = "↺"
	close_settings_btn.text = "✕"
	
	# Store Modal
	store_title.text = GameManager.loc("store_title")
	store_desc.text = GameManager.loc("store_desc")
	if tab_skins_btn:
		tab_skins_btn.text = GameManager.loc("tab_suits")
	if tab_paints_btn:
		tab_paints_btn.text = GameManager.loc("tab_thrusters")
	if tab_packs_btn:
		tab_packs_btn.text = GameManager.loc("tab_packs")
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
	# 3D Store Showcase Turntable Spin
	if showcase_pivot and showcase_container and showcase_container.visible:
		if not is_dragging_showcase:
			showcase_spin_vel_y = lerp(showcase_spin_vel_y, 0.35, delta * 2.0)
			showcase_spin_vel_x = lerp(showcase_spin_vel_x, 0.0, delta * 3.0)
			showcase_pivot.rotate_y(showcase_spin_vel_y * delta)
			if abs(showcase_spin_vel_x) > 0.0001:
				showcase_pivot.rotate_object_local(Vector3.RIGHT, showcase_spin_vel_x * delta)

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

# Subsystems Settings State
var settings_tab_idx: int = 0
var tab_btn_audio: Button
var tab_btn_graphics: Button
var tab_btn_controls: Button
var tab_btn_system: Button
var settings_subsystem_container: VBoxContainer
var sub_panel_audio: VBoxContainer
var sub_panel_graphics: VBoxContainer
var sub_panel_controls: VBoxContainer
var sub_panel_system: VBoxContainer

var lang_btn_es: Button
var lang_btn_en: Button
var fps_btn_30: Button
var fps_btn_60: Button
var fps_btn_max: Button
var preset_btn_eco: Button
var preset_btn_med: Button
var preset_btn_high: Button
var invert_y_btn: Button

func _setup_settings_ui() -> void:
	# 1. Holographic Aerospace Modal Styling
	var panel_sb = StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.06, 0.05, 0.12, 0.96)
	panel_sb.border_color = Color(0.96, 0.66, 0.16, 0.90) # Amber circuit rim
	panel_sb.border_width_left = 2
	panel_sb.border_width_top = 2
	panel_sb.border_width_right = 2
	panel_sb.border_width_bottom = 2
	panel_sb.corner_radius_top_left = 14
	panel_sb.corner_radius_top_right = 14
	panel_sb.corner_radius_bottom_left = 14
	panel_sb.corner_radius_bottom_right = 14
	panel_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	panel_sb.shadow_size = 20
	settings_modal.add_theme_stylebox_override("panel", panel_sb)
	settings_modal.custom_minimum_size = Vector2(520, 0)
	
	if settings_title_label:
		settings_title_label.text = "[ ⬡  AJUSTES // SETTINGS  ⬡ ]"
		settings_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		settings_title_label.add_theme_color_override("font_color", Color(0.96, 0.72, 0.22))
		settings_title_label.add_theme_font_size_override("font_size", 16)

	# 2. Build or Reconfigure Subsystem Tabs
	var vbox = settings_modal.get_node_or_null("VBox")
	if not vbox: return
	vbox.add_theme_constant_override("separation", 10)
	
	# Hide legacy LangBox, MasterBox, MusicBox, SfxBox directly
	var old_lang = vbox.get_node_or_null("LangBox")
	if old_lang: old_lang.visible = false
	var old_master = vbox.get_node_or_null("MasterBox")
	if old_master: old_master.visible = false
	var old_music = vbox.get_node_or_null("MusicBox")
	if old_music: old_music.visible = false
	var old_sfx = vbox.get_node_or_null("SfxBox")
	if old_sfx: old_sfx.visible = false

	# Clean Tab Header Bar
	var tab_bar = vbox.get_node_or_null("SubsystemTabBar") as HBoxContainer
	if not tab_bar:
		tab_bar = HBoxContainer.new()
		tab_bar.name = "SubsystemTabBar"
		tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		tab_bar.add_theme_constant_override("separation", 8)
		vbox.add_child(tab_bar)
		vbox.move_child(tab_bar, 1)
		
		tab_btn_audio = _create_tab_button("🔊 AUDIO")
		tab_btn_graphics = _create_tab_button("🖥️ VIDEO")
		tab_btn_controls = _create_tab_button("🎮 CONTROLES")
		tab_btn_system = _create_tab_button("🌐 SISTEMA")
		
		tab_bar.add_child(tab_btn_audio)
		tab_bar.add_child(tab_btn_graphics)
		tab_bar.add_child(tab_btn_controls)
		tab_bar.add_child(tab_btn_system)
		
		tab_btn_audio.pressed.connect(func(): _switch_settings_tab(0))
		tab_btn_graphics.pressed.connect(func(): _switch_settings_tab(1))
		tab_btn_controls.pressed.connect(func(): _switch_settings_tab(2))
		tab_btn_system.pressed.connect(func(): _switch_settings_tab(3))

	# Container for the 4 Subsystem Panels (adaptive size, zero dead space)
	settings_subsystem_container = vbox.get_node_or_null("Subsystems") as VBoxContainer
	if not settings_subsystem_container:
		settings_subsystem_container = VBoxContainer.new()
		settings_subsystem_container.name = "Subsystems"
		settings_subsystem_container.custom_minimum_size = Vector2(490, 0)
		vbox.add_child(settings_subsystem_container)
		vbox.move_child(settings_subsystem_container, 2)
		
		_build_subsystem_panels()

	_switch_settings_tab(0)

	# 3. Action Buttons
	var btn_save_sb = StyleBoxFlat.new()
	btn_save_sb.bg_color = Color(0.12, 0.38, 0.22, 0.95)
	btn_save_sb.border_color = Color(0.25, 0.95, 0.45)
	btn_save_sb.set_border_width_all(2)
	btn_save_sb.set_corner_radius_all(8)
	save_settings_btn.text = "✓"
	save_settings_btn.custom_minimum_size = Vector2(80, 38)
	save_settings_btn.add_theme_stylebox_override("normal", btn_save_sb)
	save_settings_btn.add_theme_font_size_override("font_size", 18)

	var btn_reset_sb = StyleBoxFlat.new()
	btn_reset_sb.bg_color = Color(0.1, 0.2, 0.32, 0.95)
	btn_reset_sb.border_color = Color(0.3, 0.8, 1.0)
	btn_reset_sb.set_border_width_all(2)
	btn_reset_sb.set_corner_radius_all(8)
	reset_defaults_btn.text = "↺"
	reset_defaults_btn.custom_minimum_size = Vector2(80, 38)
	reset_defaults_btn.add_theme_stylebox_override("normal", btn_reset_sb)
	reset_defaults_btn.add_theme_font_size_override("font_size", 18)
	reset_defaults_btn.pressed.connect(Callable(self, "_on_reset_defaults_pressed"))

	var btn_close_sb = StyleBoxFlat.new()
	btn_close_sb.bg_color = Color(0.32, 0.1, 0.12, 0.95)
	btn_close_sb.border_color = Color(0.95, 0.35, 0.35)
	btn_close_sb.set_border_width_all(2)
	btn_close_sb.set_corner_radius_all(8)
	close_settings_btn.text = "✕"
	close_settings_btn.custom_minimum_size = Vector2(80, 38)
	close_settings_btn.add_theme_stylebox_override("normal", btn_close_sb)
	close_settings_btn.add_theme_font_size_override("font_size", 18)

func _create_tab_button(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(105, 32)
	btn.focus_mode = Control.FOCUS_NONE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.9)
	sb.border_color = Color(0.3, 0.4, 0.55, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_font_size_override("font_size", 11)
	return btn

func _switch_settings_tab(idx: int) -> void:
	settings_tab_idx = idx
	var tabs = [tab_btn_audio, tab_btn_graphics, tab_btn_controls, tab_btn_system]
	var panels = [sub_panel_audio, sub_panel_graphics, sub_panel_controls, sub_panel_system]
	
	for i in range(tabs.size()):
		var btn = tabs[i]
		var pnl = panels[i]
		if not is_instance_valid(btn) or not is_instance_valid(pnl): continue
		var is_active = (i == idx)
		pnl.visible = is_active
		
		var sb = StyleBoxFlat.new()
		if is_active:
			sb.bg_color = Color(0.18, 0.24, 0.38, 0.95)
			sb.border_color = Color(0.96, 0.66, 0.16) # Amber glow
			sb.set_border_width_all(2)
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		else:
			sb.bg_color = Color(0.08, 0.10, 0.16, 0.85)
			sb.border_color = Color(0.25, 0.30, 0.42, 0.6)
			sb.set_border_width_all(1)
			btn.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
		sb.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sb)
	
	_adapt_modal_size()

func _adapt_modal_size() -> void:
	if not is_instance_valid(settings_modal): return
	var vbox = settings_modal.get_node_or_null("VBox") as VBoxContainer
	if not vbox: return
	vbox.reset_size()
	var min_h = vbox.get_combined_minimum_size().y + 44.0
	var min_w = 520.0
	settings_modal.offset_left = -min_w * 0.5
	settings_modal.offset_right = min_w * 0.5
	settings_modal.offset_top = -min_h * 0.5
	settings_modal.offset_bottom = min_h * 0.5

func _build_subsystem_panels() -> void:
	# Shared styleboxes
	var track_sb = StyleBoxFlat.new()
	track_sb.bg_color = Color(0.12, 0.14, 0.22, 0.9)
	track_sb.set_corner_radius_all(4)
	track_sb.content_margin_top = 4
	track_sb.content_margin_bottom = 4

	var fill_sb = StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.2, 0.85, 1.0, 0.95)
	fill_sb.corner_radius_top_left = 4
	fill_sb.corner_radius_bottom_left = 4
	fill_sb.content_margin_top = 4
	fill_sb.content_margin_bottom = 4

	var val_badge_sb = StyleBoxFlat.new()
	val_badge_sb.bg_color = Color(0.09, 0.11, 0.18, 0.9)
	val_badge_sb.border_color = Color(0.2, 0.85, 1.0, 0.6)
	val_badge_sb.set_border_width_all(1)
	val_badge_sb.set_corner_radius_all(6)
	val_badge_sb.content_margin_left = 6
	val_badge_sb.content_margin_right = 6

	# --- 1. Audio Subsystem Panel ---
	sub_panel_audio = VBoxContainer.new()
	sub_panel_audio.name = "AudioPanel"
	sub_panel_audio.add_theme_constant_override("separation", 10)
	settings_subsystem_container.add_child(sub_panel_audio)
	
	sub_panel_audio.add_child(_create_slider_row("🔊", "MASTER", master_slider, master_val_label, track_sb, fill_sb, val_badge_sb))
	sub_panel_audio.add_child(_create_slider_row("🎵", "MÚSICA", music_slider, music_val_label, track_sb, fill_sb, val_badge_sb))
	sub_panel_audio.add_child(_create_slider_row("⚡", "EFECTOS", sfx_slider, sfx_val_label, track_sb, fill_sb, val_badge_sb))

	# Connect audio sliders
	master_slider.value = GameManager.master_volume
	music_slider.value = GameManager.music_volume
	sfx_slider.value = GameManager.sfx_volume
	_update_slider_labels()
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	# --- 2. Graphics Subsystem Panel ---
	sub_panel_graphics = VBoxContainer.new()
	sub_panel_graphics.name = "GraphicsPanel"
	sub_panel_graphics.add_theme_constant_override("separation", 10)
	settings_subsystem_container.add_child(sub_panel_graphics)
	
	# FPS Row
	var fps_row = HBoxContainer.new()
	var fps_lbl = Label.new()
	fps_lbl.text = "⏱️ FPS // LÍMITE:"
	fps_lbl.custom_minimum_size = Vector2(170, 28)
	fps_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	fps_row.add_child(fps_lbl)
	
	fps_btn_30 = _create_pill_button("30")
	fps_btn_60 = _create_pill_button("60")
	fps_btn_max = _create_pill_button("MAX")
	fps_row.add_child(fps_btn_30)
	fps_row.add_child(fps_btn_60)
	fps_row.add_child(fps_btn_max)
	fps_btn_30.pressed.connect(func(): _set_fps_limit(30))
	fps_btn_60.pressed.connect(func(): _set_fps_limit(60))
	fps_btn_max.pressed.connect(func(): _set_fps_limit(0))
	sub_panel_graphics.add_child(fps_row)
	_update_fps_pills(Engine.max_fps)

	# Presets Row
	var pres_row = HBoxContainer.new()
	var pres_lbl = Label.new()
	pres_lbl.text = "🖥️ CALIDAD // SHADERS:"
	pres_lbl.custom_minimum_size = Vector2(170, 28)
	pres_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	pres_row.add_child(pres_lbl)
	
	preset_btn_eco = _create_pill_button("ECO")
	preset_btn_med = _create_pill_button("MEDIO")
	preset_btn_high = _create_pill_button("ALTO")
	pres_row.add_child(preset_btn_eco)
	pres_row.add_child(preset_btn_med)
	pres_row.add_child(preset_btn_high)
	preset_btn_eco.pressed.connect(func(): _set_quality_preset(0))
	preset_btn_med.pressed.connect(func(): _set_quality_preset(1))
	preset_btn_high.pressed.connect(func(): _set_quality_preset(2))
	sub_panel_graphics.add_child(pres_row)
	_update_preset_pills(1)

	# Bloom / Visor Glow Row
	var bloom_row = HBoxContainer.new()
	var bloom_lbl = Label.new()
	bloom_lbl.text = "✨ BRILLO VISOR / BLOOM:"
	bloom_lbl.custom_minimum_size = Vector2(170, 28)
	bloom_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	bloom_row.add_child(bloom_lbl)
	var bloom_btn = _create_pill_button("ACTIVO")
	bloom_row.add_child(bloom_btn)
	bloom_btn.pressed.connect(func():
		var is_on = bloom_btn.text == "ACTIVO"
		bloom_btn.text = "DESACTIVADO" if is_on else "ACTIVO"
		_style_pill(bloom_btn, not is_on)
		GameManager.update_setting("bloom_enabled", not is_on)
	)
	_style_pill(bloom_btn, true)
	sub_panel_graphics.add_child(bloom_row)

	# --- 3. Controls Subsystem Panel ---
	sub_panel_controls = VBoxContainer.new()
	sub_panel_controls.name = "ControlsPanel"
	sub_panel_controls.add_theme_constant_override("separation", 10)
	settings_subsystem_container.add_child(sub_panel_controls)
	
	# Invert Y Row
	var inv_row = HBoxContainer.new()
	var inv_lbl = Label.new()
	inv_lbl.text = "🎮 INVERTIR EJE Y:"
	inv_lbl.custom_minimum_size = Vector2(170, 28)
	inv_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	inv_row.add_child(inv_lbl)
	invert_y_btn = _create_pill_button("NORMAL")
	inv_row.add_child(invert_y_btn)
	invert_y_btn.pressed.connect(func():
		var is_inv = invert_y_btn.text == "INVERTIDO"
		invert_y_btn.text = "NORMAL" if is_inv else "INVERTIDO"
		_style_pill(invert_y_btn, not is_inv)
		GameManager.update_setting("invert_y", not is_inv)
	)
	sub_panel_controls.add_child(inv_row)

	# Mobile Touch Scale Row
	var scale_row = HBoxContainer.new()
	var scale_lbl = Label.new()
	scale_lbl.text = "📱 TAMAÑO CONTROLES:"
	scale_lbl.custom_minimum_size = Vector2(170, 28)
	scale_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	scale_row.add_child(scale_lbl)
	var scale_s = _create_pill_button("CHICO")
	var scale_m = _create_pill_button("NORMAL")
	var scale_l = _create_pill_button("GRANDE")
	scale_row.add_child(scale_s)
	scale_row.add_child(scale_m)
	scale_row.add_child(scale_l)
	scale_s.pressed.connect(func():
		GameManager.update_setting("touch_scale", 0.85)
		_style_pill(scale_s, true); _style_pill(scale_m, false); _style_pill(scale_l, false)
	)
	scale_m.pressed.connect(func():
		GameManager.update_setting("touch_scale", 1.0)
		_style_pill(scale_s, false); _style_pill(scale_m, true); _style_pill(scale_l, false)
	)
	scale_l.pressed.connect(func():
		GameManager.update_setting("touch_scale", 1.2)
		_style_pill(scale_s, false); _style_pill(scale_m, false); _style_pill(scale_l, true)
	)
	_style_pill(scale_m, true)
	sub_panel_controls.add_child(scale_row)

	# Open Interactive HUD Layout Editor Button
	var edit_row = HBoxContainer.new()
	edit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var edit_btn = _create_pill_button("🎮 ABRIR EDITOR Y VISTA PREVIA DE CONTROLES")
	edit_btn.custom_minimum_size = Vector2(340, 36)
	edit_row.add_child(edit_btn)
	edit_btn.pressed.connect(func():
		AudioManager.play("click")
		_open_control_layout_editor()
	)
	sub_panel_controls.add_child(edit_row)

	# Reset Controls Layout Row
	var rst_ctrl_row = HBoxContainer.new()
	rst_ctrl_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var rst_ctrl_btn = _create_pill_button("↺ RESTABLECER DISTRIBUCIÓN DE FÁBRICA")
	rst_ctrl_btn.custom_minimum_size = Vector2(340, 32)
	rst_ctrl_row.add_child(rst_ctrl_btn)
	rst_ctrl_btn.pressed.connect(func():
		AudioManager.play("click")
		GameManager.update_setting("touch_scale", 1.0)
		GameManager.update_setting("invert_y", false)
		GameManager.update_setting("custom_touch_layout", {})
		_style_pill(scale_s, false); _style_pill(scale_m, true); _style_pill(scale_l, false)
		invert_y_btn.text = "NORMAL"
		_style_pill(invert_y_btn, false)
	)
	sub_panel_controls.add_child(rst_ctrl_row)

	# --- 4. System & Language Subsystem Panel ---
	sub_panel_system = VBoxContainer.new()
	sub_panel_system.name = "SystemPanel"
	sub_panel_system.add_theme_constant_override("separation", 10)
	settings_subsystem_container.add_child(sub_panel_system)
	
	# Language Selector Row
	var lang_row = HBoxContainer.new()
	var lang_title = Label.new()
	lang_title.text = "🌐 IDIOMA // LANGUAGE:"
	lang_title.custom_minimum_size = Vector2(170, 32)
	lang_title.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	lang_row.add_child(lang_title)
	
	lang_btn_es = _create_pill_button("🇪🇸 ESPAÑOL")
	lang_btn_es.custom_minimum_size = Vector2(120, 32)
	lang_btn_en = _create_pill_button("🇬🇧 ENGLISH")
	lang_btn_en.custom_minimum_size = Vector2(120, 32)
	lang_row.add_child(lang_btn_es)
	lang_row.add_child(lang_btn_en)
	lang_btn_es.pressed.connect(func(): _set_language_pill("es"))
	lang_btn_en.pressed.connect(func(): _set_language_pill("en"))
	sub_panel_system.add_child(lang_row)
	_update_language_pills()

	# Units Row
	var unit_row = HBoxContainer.new()
	var unit_lbl = Label.new()
	unit_lbl.text = "🌡️ UNIDADES DE MEDIDA:"
	unit_lbl.custom_minimum_size = Vector2(170, 28)
	unit_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	unit_row.add_child(unit_lbl)
	var unit_c = _create_pill_button("°C / METRO")
	unit_c.custom_minimum_size = Vector2(120, 32)
	var unit_k = _create_pill_button("K / KILÓMETRO")
	unit_k.custom_minimum_size = Vector2(120, 32)
	unit_row.add_child(unit_c)
	unit_row.add_child(unit_k)
	unit_c.pressed.connect(func():
		GameManager.update_setting("units", "metric")
		_style_pill(unit_c, true); _style_pill(unit_k, false)
	)
	unit_k.pressed.connect(func():
		GameManager.update_setting("units", "kelvin")
		_style_pill(unit_c, false); _style_pill(unit_k, true)
	)
	_style_pill(unit_c, true)
	sub_panel_system.add_child(unit_row)

	# System Version info
	var ver_row = HBoxContainer.new()
	ver_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ver_lbl = Label.new()
	ver_lbl.text = "CIVITUS v1.4.0 • SISTEMA MÓVIL // SHIPATON BUILD"
	ver_lbl.add_theme_color_override("font_color", Color(0.45, 0.55, 0.70))
	ver_lbl.add_theme_font_size_override("font_size", 10)
	ver_row.add_child(ver_lbl)
	sub_panel_system.add_child(ver_row)

var hud_layout_editor_modal: Control = null

func _open_control_layout_editor() -> void:
	if is_instance_valid(hud_layout_editor_modal):
		hud_layout_editor_modal.queue_free()
		
	hud_layout_editor_modal = Control.new()
	hud_layout_editor_modal.name = "HUDLayoutEditor"
	hud_layout_editor_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	$MenuLayer.add_child(hud_layout_editor_modal)
	
	# Backdrop
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.07, 0.94)
	hud_layout_editor_modal.add_child(bg)
	
	# Top Toolbar
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(720, 52)
	top_bar.position = Vector2((1280 - 720) * 0.5, 16)
	var tb_sb = StyleBoxFlat.new()
	tb_sb.bg_color = Color(0.08, 0.1, 0.18, 0.95)
	tb_sb.border_color = Color(0.96, 0.66, 0.16)
	tb_sb.set_border_width_all(2)
	tb_sb.set_corner_radius_all(10)
	top_bar.add_theme_stylebox_override("panel", tb_sb)
	hud_layout_editor_modal.add_child(top_bar)
	
	var tb_hbox = HBoxContainer.new()
	tb_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tb_hbox.add_theme_constant_override("separation", 16)
	top_bar.add_child(tb_hbox)
	
	var title = Label.new()
	title.text = "[ 🎮 ARRASTRA LOS BOTONES PARA EDITAR SU POSICIÓN ]"
	title.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	tb_hbox.add_child(title)
	
	var btn_rst = _create_pill_button("↺ RESTABLECER")
	var btn_save = _create_pill_button("✓ GUARDAR")
	var btn_close = _create_pill_button("✕ SALIR")
	tb_hbox.add_child(btn_rst)
	tb_hbox.add_child(btn_save)
	tb_hbox.add_child(btn_close)
	
	# Draggable Widget Container
	var widgets_container = Control.new()
	widgets_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layout_editor_modal.add_child(widgets_container)
	
	var default_positions = {
		"joystick": Vector2(80, 500),
		"jump": Vector2(1160, 560),
		"laser": Vector2(1060, 600),
		"sprint": Vector2(1160, 440),
		"backpack": Vector2(1060, 480),
		"starmap": Vector2(640, 40)
	}
	
	var current_layout = GameManager.load_setting("custom_touch_layout", default_positions.duplicate())
	var widget_nodes = {}
	
	for key in default_positions.keys():
		var w = _create_draggable_hud_widget(key, current_layout.get(key, default_positions[key]))
		widgets_container.add_child(w)
		widget_nodes[key] = w
		
	btn_rst.pressed.connect(func():
		AudioManager.play("click")
		for k in default_positions.keys():
			widget_nodes[k].position = default_positions[k]
	)
	btn_save.pressed.connect(func():
		AudioManager.play("click")
		var saved_layout = {}
		for k in widget_nodes.keys():
			saved_layout[k] = widget_nodes[k].position
		GameManager.update_setting("custom_touch_layout", saved_layout)
		hud_layout_editor_modal.queue_free()
	)
	btn_close.pressed.connect(func():
		AudioManager.play("click")
		hud_layout_editor_modal.queue_free()
	)

func _create_draggable_hud_widget(key: String, initial_pos: Vector2) -> Control:
	var w = Control.new()
	w.custom_minimum_size = Vector2(68, 68)
	w.size = Vector2(68, 68)
	w.position = initial_pos
	
	var art_btn = CircularArtButton.new()
	art_btn.custom_minimum_size = Vector2(68, 68)
	art_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match key:
		"joystick": art_btn.icon_name = "controls"
		"jump": art_btn.icon_name = "thrust"
		"laser": art_btn.icon_name = "mine"
		"sprint": art_btn.icon_name = "sprint"
		"backpack": art_btn.icon_name = "backpack"
		"starmap": art_btn.icon_name = "starmap"
	w.add_child(art_btn)
	
	var border = ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(0.2, 0.85, 1.0, 0.8)
	border.border_width = 1.5
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.add_child(border)
	
	var dragging = false
	var drag_offset = Vector2.ZERO
	w.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.pressed:
					dragging = true
					drag_offset = ev.position
				else:
					dragging = false
		elif ev is InputEventMouseMotion and dragging:
			w.position += ev.position - drag_offset
			w.position.x = clampf(w.position.x, 20.0, 1280.0 - 88.0)
			w.position.y = clampf(w.position.y, 20.0, 720.0 - 88.0)
		elif ev is InputEventScreenTouch:
			if ev.pressed:
				dragging = true
				drag_offset = ev.position
			else:
				dragging = false
		elif ev is InputEventScreenDrag and dragging:
			w.position += ev.relative
			w.position.x = clampf(w.position.x, 20.0, 1280.0 - 88.0)
			w.position.y = clampf(w.position.y, 20.0, 720.0 - 88.0)
	)
	return w

func _create_slider_row(icon_char: String, label_str: String, sld: HSlider, val_lbl: Label, track_sb: StyleBox, fill_sb: StyleBox, badge_sb: StyleBox) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	
	var icn = Label.new()
	icn.text = icon_char
	icn.custom_minimum_size = Vector2(28, 28)
	icn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(icn)
	
	var lbl = Label.new()
	lbl.text = label_str
	lbl.custom_minimum_size = Vector2(110, 28)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	lbl.add_theme_font_size_override("font_size", 11)
	row.add_child(lbl)
	
	# Reparent slider and val label into this new row
	if sld.get_parent():
		sld.get_parent().remove_child(sld)
	sld.add_theme_stylebox_override("slider", track_sb)
	sld.add_theme_stylebox_override("grabber_area", fill_sb)
	sld.add_theme_stylebox_override("grabber_area_highlight", fill_sb)
	sld.custom_minimum_size = Vector2(200, 24)
	sld.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sld)
	
	if val_lbl.get_parent():
		val_lbl.get_parent().remove_child(val_lbl)
	val_lbl.add_theme_stylebox_override("normal", badge_sb)
	val_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	val_lbl.custom_minimum_size = Vector2(50, 24)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(val_lbl)
	
	return row

func _create_pill_button(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(80, 30)
	btn.focus_mode = Control.FOCUS_NONE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.9)
	sb.border_color = Color(0.25, 0.35, 0.50, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_font_size_override("font_size", 11)
	return btn

func _set_language_pill(lang: String) -> void:
	AudioManager.play("click")
	GameManager.set_language(lang)
	_update_language_pills()

func _update_language_pills() -> void:
	var is_es = (GameManager.current_language == "es")
	_style_pill(lang_btn_es, is_es)
	_style_pill(lang_btn_en, not is_es)

func _set_fps_limit(fps: int) -> void:
	AudioManager.play("click")
	Engine.max_fps = fps
	GameManager.update_setting("max_fps", fps)
	_update_fps_pills(fps)

func _update_fps_pills(fps: int) -> void:
	_style_pill(fps_btn_30, fps == 30)
	_style_pill(fps_btn_60, fps == 60)
	_style_pill(fps_btn_max, fps <= 0 or fps > 60)

func _set_quality_preset(level: int) -> void:
	AudioManager.play("click")
	_update_preset_pills(level)
	GameManager.update_setting("quality_preset", level)
	var vp = get_viewport()
	if vp:
		match level:
			0: # ECO (Mobile low power)
				vp.scaling_3d_scale = 0.75
				RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
				RenderingServer.directional_shadow_atlas_set_size(1024, true)
			1: # MEDIO (Mobile 60fps balanced)
				vp.scaling_3d_scale = 1.0
				RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_2X)
				RenderingServer.directional_shadow_atlas_set_size(2048, true)
			2: # ALTO (Full Fidelity)
				vp.scaling_3d_scale = 1.0
				RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_4X)
				RenderingServer.directional_shadow_atlas_set_size(4096, true)

func _update_preset_pills(level: int) -> void:
	_style_pill(preset_btn_eco, level == 0)
	_style_pill(preset_btn_med, level == 1)
	_style_pill(preset_btn_high, level == 2)

func _style_pill(btn: Button, is_active: bool) -> void:
	if not is_instance_valid(btn): return
	var sb = StyleBoxFlat.new()
	if is_active:
		sb.bg_color = Color(0.18, 0.26, 0.42, 0.95)
		sb.border_color = Color(0.96, 0.66, 0.16) # Amber selected
		sb.set_border_width_all(2)
		btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	else:
		sb.bg_color = Color(0.08, 0.10, 0.16, 0.85)
		sb.border_color = Color(0.25, 0.30, 0.42, 0.6)
		sb.set_border_width_all(1)
		btn.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)

func _update_slider_labels() -> void:
	master_val_label.text = "%d%%" % int(master_slider.value * 100)
	music_val_label.text = "%d%%" % int(music_slider.value * 100)
	sfx_val_label.text = "%d%%" % int(sfx_slider.value * 100)

func _on_settings_pressed() -> void:
	AudioManager.play("click")
	# Mutual exclusivity: Close store if open
	if store_modal:
		store_modal.visible = false
	if store_dimmer:
		store_dimmer.visible = false
	
	# Cache current settings for Discard/Close
	cached_master = GameManager.master_volume
	cached_music = GameManager.music_volume
	cached_sfx = GameManager.sfx_volume
	cached_lang = GameManager.current_language
	
	master_slider.value = cached_master
	music_slider.value = cached_music
	sfx_slider.value = cached_sfx
	if lang_option: lang_option.selected = 0 if cached_lang == "es" else 1
	_update_language_pills()
	_update_slider_labels()
	
	if settings_dimmer:
		settings_dimmer.visible = true
	settings_modal.visible = true
	_adapt_modal_size()
	_set_modal_open_state(true)

func _on_save_settings_pressed() -> void:
	AudioManager.play("click")
	GameManager.master_volume = master_slider.value
	GameManager.music_volume = music_slider.value
	GameManager.sfx_volume = sfx_slider.value
	GameManager.save_settings()
	if settings_dimmer:
		settings_dimmer.visible = false
	settings_modal.visible = false
	_set_modal_open_state(false)

func _on_close_settings_pressed() -> void:
	AudioManager.play("click")
	# Discard uncommitted changes: revert to cached
	GameManager.master_volume = cached_master
	GameManager.music_volume = cached_music
	GameManager.sfx_volume = cached_sfx
	if GameManager.current_language != cached_lang:
		GameManager.set_language(cached_lang)
	GameManager._apply_audio_bus_volumes()
	if settings_dimmer:
		settings_dimmer.visible = false
	settings_modal.visible = false
	_set_modal_open_state(false)

func _on_reset_defaults_pressed() -> void:
	AudioManager.play("click")
	GameManager.reset_settings_to_default()
	master_slider.value = GameManager.master_volume
	music_slider.value = GameManager.music_volume
	sfx_slider.value = GameManager.sfx_volume
	_update_slider_labels()
	if lang_option: lang_option.selected = 0 if GameManager.current_language == "es" else 1
	_update_language_pills()
	_update_fps_pills(60)
	_update_preset_pills(1)
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
	GameManager.music_volume = val
	var idx = AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, val <= 0.001)
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(0.001, val)))
	if is_instance_valid(AudioManager) and AudioManager.music_player:
		if val <= 0.001:
			AudioManager.music_player.volume_db = -80.0
		else:
			AudioManager.music_player.volume_db = AudioManager.default_music_volume_db + linear_to_db(val)

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
	if settings_modal:
		settings_modal.visible = false
	if settings_dimmer:
		settings_dimmer.visible = false
	open_store_modal()

var current_store_tab: String = "skins"

const SUIT_ITEMS: Array[Dictionary] = [
	{
		"id": "apollo_white",
		"category": "skins",
		"name": "APOLO CLÁSICO",
		"badge": "[EVA-01]",
		"color": Color(0.92, 0.94, 0.97),
		"cost": 0,
		"currency": "coins",
		"desc": "Traje presurizado estándar de polímero aislante multicapa."
	},
	{
		"id": "solar_gold",
		"category": "skins",
		"name": "SOLAR ÁUREO",
		"badge": "[EVA-02]",
		"color": Color(0.96, 0.75, 0.16),
		"cost": 150,
		"currency": "coins",
		"desc": "Aleación reflectante con protección contra radiación solar y llamaradas estelares."
	},
	{
		"id": "abyssal_onyx",
		"category": "skins",
		"name": "ABISAL ÓNIX",
		"badge": "[EVA-03]",
		"color": Color(0.12, 0.14, 0.18),
		"cost": 250,
		"currency": "coins",
		"desc": "Blindaje de nanotubos de carbono de absorción térmica y sigilo en el vacío."
	},
	{
		"id": "cyber_neon",
		"category": "skins",
		"name": "CIBER NEÓN",
		"badge": "[EVA-04]",
		"color": Color(0.15, 0.85, 1.0),
		"cost": 400,
		"currency": "coins",
		"desc": "Canalización de plasma frío electroluminiscente con soporte vital presurizado."
	}
]

const SHIP_ITEMS: Array[Dictionary] = [
	{
		"id": "capsule_white",
		"category": "paints",
		"name": "CÁPSULA BLANCA",
		"badge": "[HULL-01]",
		"color": Color(0.92, 0.92, 0.95),
		"cost": 0,
		"currency": "coins",
		"desc": "Blindaje cerámico de ablación térmica estándar para reentrada atmosférica."
	},
	{
		"id": "plasma_cyan",
		"category": "paints",
		"name": "PLASMA CIAN",
		"badge": "[HULL-02]",
		"color": Color(0.15, 0.75, 0.95),
		"cost": 100,
		"currency": "coins",
		"desc": "Tobera de empuje iónico con aceleración magnética de xenón electroluminiscente."
	},
	{
		"id": "solar_fire",
		"category": "paints",
		"name": "FUEGO SOLAR",
		"badge": "[HULL-03]",
		"color": Color(0.98, 0.48, 0.08),
		"cost": 200,
		"currency": "coins",
		"desc": "Combustión metanox de alta temperatura y pluma expansiva de propulsión rápida."
	},
	{
		"id": "amethyst_singularity",
		"category": "paints",
		"name": "SIGILO AMATISTA",
		"badge": "[HULL-04]",
		"color": Color(0.65, 0.18, 0.85),
		"cost": 350,
		"currency": "coins",
		"desc": "Propulsión exótica de taquiones con rastro violeta y blindaje antirradar de obsidiana."
	}
]

const PACK_ITEMS: Array[Dictionary] = [
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
		"desc": "Sintoniza una transmisión comercial de espacio profundo (5s) para recibir 50 Luna Coins gratis."
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
		"desc": "Reserva de fondos para exploradores espaciales novatos."
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
		"desc": "Vuelo sin publicidad de por vida y 800 Luna Coins inmediatas."
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
		"desc": "Todo desbloqueado: editor de planetas, cosméticos exclusivos, sin anuncios y 2500 Luna Coins."
	}
]

# Combined list for backwards compatibility
const STORE_ITEMS: Array[Dictionary] = [
	# Skins
	SUIT_ITEMS[0], SUIT_ITEMS[1], SUIT_ITEMS[2], SUIT_ITEMS[3],
	# Paints
	SHIP_ITEMS[0], SHIP_ITEMS[1], SHIP_ITEMS[2], SHIP_ITEMS[3],
	# Packs
	PACK_ITEMS[0], PACK_ITEMS[1], PACK_ITEMS[2], PACK_ITEMS[3]
]

func _update_luna_points_ui() -> void:
	if luna_coins_label:
		luna_coins_label.text = "%d" % GameManager.luna_points
	elif luna_badge_btn:
		luna_badge_btn.text = "%d" % GameManager.luna_points
	if store_coins_badge:
		store_coins_badge.text = "%d LUNA COINS" % GameManager.luna_points

func _init_tab_styles() -> void:
	if tab_active_sb:
		return
	tab_active_sb = StyleBoxFlat.new()
	tab_active_sb.bg_color = Color(0.08, 0.26, 0.46, 0.95)
	tab_active_sb.border_width_left = 1
	tab_active_sb.border_width_top = 1
	tab_active_sb.border_width_right = 1
	tab_active_sb.border_width_bottom = 1
	tab_active_sb.border_color = Color(0.2, 0.85, 1.0)
	tab_active_sb.corner_radius_top_left = 6
	tab_active_sb.corner_radius_top_right = 6
	tab_active_sb.corner_radius_bottom_right = 6
	tab_active_sb.corner_radius_bottom_left = 6

	tab_inactive_sb = StyleBoxFlat.new()
	tab_inactive_sb.bg_color = Color(0.03, 0.05, 0.10, 0.85)
	tab_inactive_sb.border_width_left = 1
	tab_inactive_sb.border_width_top = 1
	tab_inactive_sb.border_width_right = 1
	tab_inactive_sb.border_width_bottom = 1
	tab_inactive_sb.border_color = Color(0.18, 0.24, 0.35, 0.6)
	tab_inactive_sb.corner_radius_top_left = 6
	tab_inactive_sb.corner_radius_top_right = 6
	tab_inactive_sb.corner_radius_bottom_right = 6
	tab_inactive_sb.corner_radius_bottom_left = 6

func _setup_store_showcase() -> void:
	if showcase_container:
		return
	
	_init_tab_styles()
	
	var store_vbox = get_node_or_null("MenuLayer/StoreModal/VBox")
	if not store_vbox:
		return
		
	showcase_container = VBoxContainer.new()
	showcase_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	showcase_container.custom_minimum_size = Vector2(0, 270)
	showcase_container.add_theme_constant_override("separation", 8)
	
	# Top Stepper Row with 3D Viewport
	var stepper_row = HBoxContainer.new()
	stepper_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stepper_row.add_theme_constant_override("separation", 10)
	showcase_container.add_child(stepper_row)
	
	var prev_btn = Button.new()
	prev_btn.text = "◄"
	prev_btn.custom_minimum_size = Vector2(40, 40)
	prev_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_menu_button(prev_btn, Color(0.2, 0.85, 1.0), Color(0.04, 0.10, 0.18))
	stepper_row.add_child(prev_btn)
	prev_btn.pressed.connect(func():
		AudioManager.play("click")
		if current_store_tab == "skins":
			current_suit_index = (current_suit_index - 1 + SUIT_ITEMS.size()) % SUIT_ITEMS.size()
		elif current_store_tab == "paints":
			current_ship_index = (current_ship_index - 1 + SHIP_ITEMS.size()) % SHIP_ITEMS.size()
		_update_showcase_display()
	)
	
	var vp_container = SubViewportContainer.new()
	vp_container.custom_minimum_size = Vector2(320, 175)
	vp_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vp_container.stretch = true
	stepper_row.add_child(vp_container)
	
	showcase_viewport = SubViewport.new()
	showcase_viewport.transparent_bg = true
	showcase_viewport.size = Vector2(320, 175)
	showcase_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	showcase_viewport.own_world_3d = true
	vp_container.add_child(showcase_viewport)
	
	var next_btn = Button.new()
	next_btn.text = "►"
	next_btn.custom_minimum_size = Vector2(40, 40)
	next_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_menu_button(next_btn, Color(0.2, 0.85, 1.0), Color(0.04, 0.10, 0.18))
	stepper_row.add_child(next_btn)
	next_btn.pressed.connect(func():
		AudioManager.play("click")
		if current_store_tab == "skins":
			current_suit_index = (current_suit_index + 1) % SUIT_ITEMS.size()
		elif current_store_tab == "paints":
			current_ship_index = (current_ship_index + 1) % SHIP_ITEMS.size()
		_update_showcase_display()
	)
	
	# Viewport 3D Setup
	showcase_cam = Camera3D.new()
	showcase_cam.position = Vector3(0, 0.25, 2.4)
	showcase_cam.fov = 44.0
	showcase_viewport.add_child(showcase_cam)
	
	var key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-25, 45, 0)
	key_light.light_energy = 1.6
	key_light.light_color = Color(1.0, 0.96, 0.92)
	showcase_viewport.add_child(key_light)
	
	var fill_light = DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(20, -135, 0)
	fill_light.light_energy = 0.85
	fill_light.light_color = Color(0.25, 0.75, 1.0)
	showcase_viewport.add_child(fill_light)
	
	showcase_pivot = Node3D.new()
	showcase_viewport.add_child(showcase_pivot)
	
	showcase_astronaut = _build_astronaut_preview()
	showcase_pivot.add_child(showcase_astronaut)
	
	showcase_ship = _build_spaceship_preview()
	showcase_pivot.add_child(showcase_ship)
	
	# Touch & Mouse 360-Degree Model Drag Rotation
	vp_container.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				is_dragging_showcase = ev.pressed
		elif ev is InputEventScreenTouch:
			is_dragging_showcase = ev.pressed
		elif ev is InputEventMouseMotion and is_dragging_showcase:
			if showcase_pivot:
				var dx = ev.relative.x * 0.008
				var dy = ev.relative.y * 0.008
				showcase_spin_vel_y = dx * 15.0
				showcase_spin_vel_x = dy * 15.0
				showcase_pivot.rotate_y(dx)
				showcase_pivot.rotate_object_local(Vector3.RIGHT, dy)
		elif ev is InputEventScreenDrag and is_dragging_showcase:
			if showcase_pivot:
				var dx = ev.relative.x * 0.008
				var dy = ev.relative.y * 0.008
				showcase_spin_vel_y = dx * 15.0
				showcase_spin_vel_x = dy * 15.0
				showcase_pivot.rotate_y(dx)
				showcase_pivot.rotate_object_local(Vector3.RIGHT, dy)
	)
	
	# Bottom Item Card Panel
	var card_panel = PanelContainer.new()
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.04, 0.07, 0.12, 0.92)
	card_sb.border_width_left = 1
	card_sb.border_width_top = 1
	card_sb.border_width_right = 1
	card_sb.border_width_bottom = 1
	card_sb.border_color = Color(0.2, 0.75, 1.0, 0.5)
	card_sb.corner_radius_top_left = 8
	card_sb.corner_radius_top_right = 8
	card_sb.corner_radius_bottom_right = 8
	card_sb.corner_radius_bottom_left = 8
	card_sb.content_margin_left = 16
	card_sb.content_margin_right = 16
	card_sb.content_margin_top = 8
	card_sb.content_margin_bottom = 8
	card_panel.add_theme_stylebox_override("panel", card_sb)
	showcase_container.add_child(card_panel)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 3)
	card_panel.add_child(info_vbox)
	
	showcase_title_lbl = Label.new()
	showcase_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	showcase_title_lbl.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(showcase_title_lbl)
	
	showcase_desc_lbl = Label.new()
	showcase_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	showcase_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	showcase_desc_lbl.add_theme_font_size_override("font_size", 11)
	showcase_desc_lbl.modulate = Color(0.68, 0.76, 0.86)
	info_vbox.add_child(showcase_desc_lbl)
	
	showcase_action_btn = Button.new()
	showcase_action_btn.custom_minimum_size = Vector2(200, 34)
	showcase_action_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	showcase_action_btn.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(showcase_action_btn)
	
	# Add to StoreModal/VBox right next to items_scroll
	store_vbox.add_child(showcase_container)
	if items_scroll:
		store_vbox.move_child(showcase_container, items_scroll.get_index())

func _build_astronaut_preview() -> Node3D:
	var root_node = Node3D.new()
	root_node.name = "AstronautPreview"
	
	var suit_mat = StandardMaterial3D.new()
	suit_mat.resource_local_to_scene = true
	suit_mat.albedo_color = Color(0.92, 0.94, 0.97)
	suit_mat.metallic = 0.1
	suit_mat.roughness = 0.35
	root_node.set_meta("suit_material", suit_mat)
	
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.14, 0.16, 0.22)
	dark_mat.roughness = 0.5
	dark_mat.metallic = 0.7
	
	var visor_mat = StandardMaterial3D.new()
	visor_mat.resource_local_to_scene = true
	visor_mat.albedo_color = Color(1.0, 0.78, 0.15)
	visor_mat.metallic = 0.98
	visor_mat.roughness = 0.05
	visor_mat.emission_enabled = true
	visor_mat.emission = Color(0.4, 0.3, 0.05)
	visor_mat.emission_energy_multiplier = 0.9
	root_node.set_meta("visor_material", visor_mat)
	
	var torso = MeshInstance3D.new()
	var torso_m = BoxMesh.new()
	torso_m.size = Vector3(0.68, 0.78, 0.44)
	torso.mesh = torso_m
	torso.material_override = suit_mat
	torso.position = Vector3(0, 0.85, 0)
	root_node.add_child(torso)
	
	var chest = MeshInstance3D.new()
	var chest_m = BoxMesh.new()
	chest_m.size = Vector3(0.42, 0.32, 0.12)
	chest.mesh = chest_m
	chest.material_override = dark_mat
	chest.position = Vector3(0, 0.90, 0.26)
	root_node.add_child(chest)
	
	var pack = MeshInstance3D.new()
	var pack_m = BoxMesh.new()
	pack_m.size = Vector3(0.56, 0.70, 0.28)
	pack.mesh = pack_m
	pack.material_override = dark_mat
	pack.position = Vector3(0, 0.88, -0.32)
	root_node.add_child(pack)
	
	for side in [-0.18, 0.18]:
		var cyl = MeshInstance3D.new()
		var cyl_m = CylinderMesh.new()
		cyl_m.top_radius = 0.08
		cyl_m.bottom_radius = 0.08
		cyl_m.height = 0.58
		cyl.mesh = cyl_m
		var o2_mat = StandardMaterial3D.new()
		o2_mat.albedo_color = Color(0.15, 0.75, 0.95)
		o2_mat.emission_enabled = true
		o2_mat.emission = Color(0.1, 0.5, 0.8)
		cyl.material_override = o2_mat
		cyl.position = Vector3(side, 0.90, -0.44)
		root_node.add_child(cyl)
		
	var helmet = MeshInstance3D.new()
	var helmet_m = SphereMesh.new()
	helmet_m.radius = 0.32
	helmet_m.height = 0.62
	helmet.mesh = helmet_m
	helmet.material_override = suit_mat
	helmet.position = Vector3(0, 1.48, 0)
	root_node.add_child(helmet)
	
	var visor = MeshInstance3D.new()
	var visor_m = SphereMesh.new()
	visor_m.radius = 0.24
	visor_m.height = 0.38
	visor.mesh = visor_m
	visor.material_override = visor_mat
	visor.position = Vector3(0, 1.48, 0.16)
	visor.scale = Vector3(1.1, 0.75, 0.7)
	root_node.add_child(visor)
	
	for side in [-0.46, 0.46]:
		var arm = MeshInstance3D.new()
		var arm_m = BoxMesh.new()
		arm_m.size = Vector3(0.20, 0.68, 0.20)
		arm.mesh = arm_m
		arm.material_override = suit_mat
		arm.position = Vector3(side, 0.82, 0)
		root_node.add_child(arm)
		
		var glove = MeshInstance3D.new()
		var glove_m = BoxMesh.new()
		glove_m.size = Vector3(0.22, 0.18, 0.22)
		glove.mesh = glove_m
		glove.material_override = dark_mat
		glove.position = Vector3(side, 0.44, 0)
		root_node.add_child(glove)
		
	for side in [-0.20, 0.20]:
		var leg = MeshInstance3D.new()
		var leg_m = BoxMesh.new()
		leg_m.size = Vector3(0.24, 0.74, 0.24)
		leg.mesh = leg_m
		leg.material_override = suit_mat
		leg.position = Vector3(side, 0.37, 0)
		root_node.add_child(leg)
		
		var boot = MeshInstance3D.new()
		var boot_m = BoxMesh.new()
		boot_m.size = Vector3(0.26, 0.16, 0.34)
		boot.mesh = boot_m
		boot.material_override = dark_mat
		boot.position = Vector3(side, 0.08, 0.05)
		root_node.add_child(boot)
		
	root_node.position = Vector3(0, -0.85, 0)
	return root_node

func _build_spaceship_preview() -> Node3D:
	var root_node = Node3D.new()
	root_node.name = "SpaceshipPreview"
	
	var hull_mat = StandardMaterial3D.new()
	hull_mat.resource_local_to_scene = true
	hull_mat.albedo_color = Color(0.92, 0.92, 0.95)
	hull_mat.metallic = 0.2
	hull_mat.roughness = 0.35
	root_node.set_meta("hull_material", hull_mat)
	
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.14, 0.16, 0.20)
	dark_mat.metallic = 0.8
	dark_mat.roughness = 0.4
	
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.15, 0.85, 1.0, 0.85)
	glass_mat.metallic = 0.9
	glass_mat.roughness = 0.1
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.1, 0.6, 0.9)
	glass_mat.emission_energy_multiplier = 0.8
	
	var nozzle_mat = StandardMaterial3D.new()
	nozzle_mat.resource_local_to_scene = true
	nozzle_mat.albedo_color = Color(0.2, 0.22, 0.25)
	nozzle_mat.metallic = 0.9
	nozzle_mat.roughness = 0.2
	nozzle_mat.emission_enabled = true
	nozzle_mat.emission = Color(0.2, 0.8, 1.0)
	nozzle_mat.emission_energy_multiplier = 1.2
	root_node.set_meta("nozzle_material", nozzle_mat)
	
	var fuselage = MeshInstance3D.new()
	var fuse_m = CylinderMesh.new()
	fuse_m.top_radius = 0.45
	fuse_m.bottom_radius = 0.85
	fuse_m.height = 1.8
	fuselage.mesh = fuse_m
	fuselage.material_override = hull_mat
	fuselage.rotation_degrees = Vector3(90, 0, 0)
	root_node.add_child(fuselage)
	
	var nose = MeshInstance3D.new()
	var nose_m = CylinderMesh.new()
	nose_m.top_radius = 0.05
	nose_m.bottom_radius = 0.45
	nose_m.height = 0.75
	nose.mesh = nose_m
	nose.material_override = hull_mat
	nose.rotation_degrees = Vector3(90, 0, 0)
	nose.position = Vector3(0, 0, 1.27)
	root_node.add_child(nose)
	
	var canopy = MeshInstance3D.new()
	var can_m = SphereMesh.new()
	can_m.radius = 0.32
	can_m.height = 0.7
	canopy.mesh = can_m
	canopy.material_override = glass_mat
	canopy.scale = Vector3(0.9, 0.55, 1.2)
	canopy.position = Vector3(0, 0.38, 0.55)
	root_node.add_child(canopy)
	
	for side in [-1.0, 1.0]:
		var wing = MeshInstance3D.new()
		var wing_m = BoxMesh.new()
		wing_m.size = Vector3(0.85, 0.06, 0.95)
		wing.mesh = wing_m
		wing.material_override = hull_mat
		wing.position = Vector3(side * 0.95, -0.05, -0.2)
		wing.rotation_degrees = Vector3(0, side * -12, side * -6)
		root_node.add_child(wing)
		
		var tip = MeshInstance3D.new()
		var tip_m = CylinderMesh.new()
		tip_m.top_radius = 0.08
		tip_m.bottom_radius = 0.10
		tip_m.height = 0.45
		tip.mesh = tip_m
		tip.material_override = dark_mat
		tip.rotation_degrees = Vector3(90, 0, 0)
		tip.position = Vector3(side * 1.38, -0.02, -0.25)
		root_node.add_child(tip)
		
	var nozzle = MeshInstance3D.new()
	var noz_m = CylinderMesh.new()
	noz_m.top_radius = 0.40
	noz_m.bottom_radius = 0.60
	noz_m.height = 0.45
	nozzle.mesh = noz_m
	nozzle.material_override = nozzle_mat
	nozzle.rotation_degrees = Vector3(90, 0, 0)
	nozzle.position = Vector3(0, 0, -1.05)
	root_node.add_child(nozzle)
	
	root_node.scale = Vector3(0.82, 0.82, 0.82)
	root_node.position = Vector3(0, 0, 0)
	return root_node

func _switch_store_tab(tab: String) -> void:
	AudioManager.play("click")
	current_store_tab = tab
	_init_tab_styles()
	_setup_store_showcase()
	
	if tab_skins_btn:
		tab_skins_btn.add_theme_stylebox_override("normal", tab_active_sb if tab == "skins" else tab_inactive_sb)
		tab_skins_btn.modulate = Color(1.0, 1.0, 1.0) if tab == "skins" else Color(0.65, 0.72, 0.8)
	if tab_paints_btn:
		tab_paints_btn.add_theme_stylebox_override("normal", tab_active_sb if tab == "paints" else tab_inactive_sb)
		tab_paints_btn.modulate = Color(1.0, 1.0, 1.0) if tab == "paints" else Color(0.65, 0.72, 0.8)
	if tab_packs_btn:
		tab_packs_btn.add_theme_stylebox_override("normal", tab_active_sb if tab == "packs" else tab_inactive_sb)
		tab_packs_btn.modulate = Color(1.0, 1.0, 1.0) if tab == "packs" else Color(0.65, 0.72, 0.8)
		
	if tab == "skins" or tab == "paints":
		if items_scroll: items_scroll.visible = false
		if showcase_container: showcase_container.visible = true
		_update_showcase_display()
	else:
		if showcase_container: showcase_container.visible = false
		if items_scroll: items_scroll.visible = true
		_render_store_items()

func _update_showcase_display() -> void:
	if not showcase_container:
		return
		
	if current_store_tab == "skins":
		if showcase_astronaut: showcase_astronaut.visible = true
		if showcase_ship: showcase_ship.visible = false
		if showcase_cam: showcase_cam.position = Vector3(0, 0.25, 2.4)
		
		var it = SUIT_ITEMS[current_suit_index]
		var suit_mat = showcase_astronaut.get_meta("suit_material") as StandardMaterial3D
		var visor_mat = showcase_astronaut.get_meta("visor_material") as StandardMaterial3D
		
		if suit_mat:
			suit_mat.albedo_color = it["color"]
			if it["id"] == "solar_gold":
				suit_mat.metallic = 0.92
				suit_mat.roughness = 0.15
				suit_mat.emission_enabled = true
				suit_mat.emission = Color(0.4, 0.25, 0.05)
				suit_mat.emission_energy_multiplier = 0.8
				if visor_mat: visor_mat.albedo_color = Color(1.0, 0.92, 0.45)
			elif it["id"] == "abyssal_onyx":
				suit_mat.metallic = 0.75
				suit_mat.roughness = 0.25
				suit_mat.emission_enabled = false
				if visor_mat: visor_mat.albedo_color = Color(0.2, 0.85, 1.0)
			elif it["id"] == "cyber_neon":
				suit_mat.metallic = 0.85
				suit_mat.roughness = 0.2
				suit_mat.emission_enabled = true
				suit_mat.emission = Color(0.15, 0.85, 1.0)
				suit_mat.emission_energy_multiplier = 0.7
				if visor_mat: visor_mat.albedo_color = Color(0.15, 0.95, 1.0)
			else:
				suit_mat.metallic = 0.10
				suit_mat.roughness = 0.35
				suit_mat.emission_enabled = false
				if visor_mat: visor_mat.albedo_color = Color(1.0, 0.78, 0.15)
				
		showcase_title_lbl.text = "[ %d / %d ] %s  %s" % [current_suit_index + 1, SUIT_ITEMS.size(), it["badge"], it["name"]]
		showcase_title_lbl.modulate = it["color"]
		showcase_desc_lbl.text = it["desc"]
		
		# Button Action
		for c in showcase_action_btn.get_signal_connection_list("pressed"):
			showcase_action_btn.disconnect("pressed", c["callable"])
			
		var unlocked = (it["cost"] == 0 or it["id"] in GameManager.unlocked_skins)
		var equipped = (GameManager.active_skin == it["id"])
		
		if equipped:
			showcase_action_btn.text = "EQUIPADO ✓"
			showcase_action_btn.disabled = true
			_style_menu_button(showcase_action_btn, Color(0.2, 0.85, 0.4), Color(0.04, 0.14, 0.08))
		elif unlocked:
			showcase_action_btn.text = "EQUIPAR"
			showcase_action_btn.disabled = false
			_style_menu_button(showcase_action_btn, Color(0.2, 0.75, 1.0), Color(0.04, 0.11, 0.18))
			showcase_action_btn.pressed.connect(func():
				GameManager.active_skin = it["id"]
				GameManager.save_player_progression()
				AudioManager.play("click")
				_update_showcase_display()
			)
		else:
			showcase_action_btn.text = "%d LUNA COINS" % it["cost"]
			showcase_action_btn.disabled = false
			_style_menu_button(showcase_action_btn, Color(0.96, 0.66, 0.16), Color(0.14, 0.09, 0.03))
			showcase_action_btn.pressed.connect(func():
				if GameManager.spend_luna_coins(it["cost"]):
					GameManager.unlocked_skins.append(it["id"])
					GameManager.active_skin = it["id"]
					GameManager.save_player_progression()
					AudioManager.play("click")
					_update_luna_points_ui()
					_update_showcase_display()
				else:
					if store_status_label:
						store_status_label.visible = true
						store_status_label.text = "LUNA COINS INSUFICIENTES (FALTAN %d)" % (it["cost"] - GameManager.luna_points)
						store_status_label.modulate = Color(1.0, 0.4, 0.4)
			)
			
	elif current_store_tab == "paints":
		if showcase_astronaut: showcase_astronaut.visible = false
		if showcase_ship: showcase_ship.visible = true
		if showcase_cam: showcase_cam.position = Vector3(0, 0.35, 2.7)
		
		var it = SHIP_ITEMS[current_ship_index]
		var hull_mat = showcase_ship.get_meta("hull_material") as StandardMaterial3D
		var nozzle_mat = showcase_ship.get_meta("nozzle_material") as StandardMaterial3D
		
		if hull_mat:
			hull_mat.albedo_color = it["color"]
			if it["id"] == "plasma_cyan":
				hull_mat.metallic = 0.85
				hull_mat.roughness = 0.18
				if nozzle_mat: nozzle_mat.emission = Color(0.15, 0.85, 1.0)
			elif it["id"] == "solar_fire":
				hull_mat.metallic = 0.80
				hull_mat.roughness = 0.20
				if nozzle_mat: nozzle_mat.emission = Color(1.0, 0.5, 0.08)
			elif it["id"] == "amethyst_singularity":
				hull_mat.metallic = 0.90
				hull_mat.roughness = 0.15
				if nozzle_mat: nozzle_mat.emission = Color(0.75, 0.25, 0.95)
			else:
				hull_mat.metallic = 0.20
				hull_mat.roughness = 0.35
				if nozzle_mat: nozzle_mat.emission = Color(0.2, 0.8, 1.0)
				
		showcase_title_lbl.text = "[ %d / %d ] %s  %s" % [current_ship_index + 1, SHIP_ITEMS.size(), it["badge"], it["name"]]
		showcase_title_lbl.modulate = it["color"]
		showcase_desc_lbl.text = it["desc"]
		
		# Button Action
		for c in showcase_action_btn.get_signal_connection_list("pressed"):
			showcase_action_btn.disconnect("pressed", c["callable"])
			
		var unlocked = (it["cost"] == 0 or it["id"] in GameManager.unlocked_ship_paints)
		var equipped = (GameManager.active_ship_paint == it["id"])
		
		if equipped:
			showcase_action_btn.text = "EQUIPADO ✓"
			showcase_action_btn.disabled = true
			_style_menu_button(showcase_action_btn, Color(0.2, 0.85, 0.4), Color(0.04, 0.14, 0.08))
		elif unlocked:
			showcase_action_btn.text = "EQUIPAR"
			showcase_action_btn.disabled = false
			_style_menu_button(showcase_action_btn, Color(0.2, 0.75, 1.0), Color(0.04, 0.11, 0.18))
			showcase_action_btn.pressed.connect(func():
				GameManager.active_ship_paint = it["id"]
				GameManager.save_player_progression()
				AudioManager.play("click")
				_update_showcase_display()
			)
		else:
			showcase_action_btn.text = "%d LUNA COINS" % it["cost"]
			showcase_action_btn.disabled = false
			_style_menu_button(showcase_action_btn, Color(0.96, 0.66, 0.16), Color(0.14, 0.09, 0.03))
			showcase_action_btn.pressed.connect(func():
				if GameManager.spend_luna_coins(it["cost"]):
					GameManager.unlocked_ship_paints.append(it["id"])
					GameManager.active_ship_paint = it["id"]
					GameManager.save_player_progression()
					AudioManager.play("click")
					_update_luna_points_ui()
					_update_showcase_display()
				else:
					if store_status_label:
						store_status_label.visible = true
						store_status_label.text = "LUNA COINS INSUFICIENTES (FALTAN %d)" % (it["cost"] - GameManager.luna_points)
						store_status_label.modulate = Color(1.0, 0.4, 0.4)
			)

func _render_store_items() -> void:
	if not store_items_container:
		return
	for c in store_items_container.get_children():
		c.queue_free()
		
	for it in PACK_ITEMS:
		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.04, 0.07, 0.12, 0.90)
		card_sb.border_width_left = 1
		card_sb.border_width_top = 1
		card_sb.border_width_right = 1
		card_sb.border_width_bottom = 1
		card_sb.border_color = (it["color"] as Color).lerp(Color(0.2, 0.85, 1.0), 0.4)
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
		
		# Visual Thumbnail
		var thumb_panel = PanelContainer.new()
		thumb_panel.custom_minimum_size = Vector2(40, 40)
		var thumb_sb = StyleBoxFlat.new()
		thumb_sb.bg_color = Color(0.03, 0.06, 0.10, 0.95)
		thumb_sb.border_width_left = 1
		thumb_sb.border_width_top = 1
		thumb_sb.border_width_right = 1
		thumb_sb.border_width_bottom = 1
		thumb_sb.border_color = (it["color"] as Color).lerp(Color(0.2, 0.85, 1.0), 0.5)
		thumb_sb.corner_radius_top_left = 4
		thumb_sb.corner_radius_top_right = 4
		thumb_sb.corner_radius_bottom_right = 4
		thumb_sb.corner_radius_bottom_left = 4
		thumb_panel.add_theme_stylebox_override("panel", thumb_sb)
		
		var thumb_tex = TextureRect.new()
		thumb_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb_tex.custom_minimum_size = Vector2(32, 32)
		thumb_tex.texture = load("res://assets/sprites/crystal_gold.png")
		thumb_tex.modulate = it["color"]
		thumb_panel.add_child(thumb_tex)
		row.add_child(thumb_panel)
		
		# Badge
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
		act_btn.text = it["cost_label"]
		
		if it.get("is_ad", false):
			_style_menu_button(act_btn, Color(0.2, 0.85, 1.0), Color(0.04, 0.12, 0.18))
			act_btn.pressed.connect(func():
				AudioManager.play("click")
				AdManager.show_rewarded_ad(func():
					GameManager.add_luna_coins(50)
					_update_luna_points_ui()
					if store_status_label:
						store_status_label.visible = true
						store_status_label.text = GameManager.loc("reward_coins_feedback")
						store_status_label.modulate = Color(1.0, 0.85, 0.25)
				)
			)
		else:
			_style_menu_button(act_btn, Color(0.96, 0.66, 0.16), Color(0.14, 0.09, 0.03))
			act_btn.pressed.connect(func():
				AudioManager.play("click")
				_show_checkout_modal(it)
			)
			
		row.add_child(act_btn)
		card.add_child(row)
		store_items_container.add_child(card)

func _show_checkout_modal(pack: Dictionary) -> void:
	if active_checkout_modal:
		active_checkout_modal.queue_free()
		active_checkout_modal = null
		
	var layer = CanvasLayer.new()
	layer.layer = 160
	add_child(layer)
	active_checkout_modal = layer
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.02, 0.05, 0.92)
	layer.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 310)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.13, 0.98)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.96, 0.66, 0.16)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "[ PASARELA DE PAGO // REVENUECAT ]" if GameManager.current_language == "es" else "[ REVENUECAT CHECKOUT GATEWAY ]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.modulate = Color(0.96, 0.66, 0.16)
	vbox.add_child(title)
	
	var prod_name = Label.new()
	prod_name.text = pack["name"]
	prod_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prod_name.add_theme_font_size_override("font_size", 16)
	prod_name.modulate = Color.WHITE
	vbox.add_child(prod_name)
	
	var prod_desc = Label.new()
	prod_desc.text = pack["desc"]
	prod_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prod_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prod_desc.add_theme_font_size_override("font_size", 11)
	prod_desc.modulate = Color(0.7, 0.78, 0.88)
	vbox.add_child(prod_desc)
	
	var price_box = PanelContainer.new()
	var psb = StyleBoxFlat.new()
	psb.bg_color = Color(0.02, 0.04, 0.08, 0.8)
	psb.border_width_left = 1
	psb.border_width_top = 1
	psb.border_width_right = 1
	psb.border_width_bottom = 1
	psb.border_color = Color(0.2, 0.75, 1.0, 0.4)
	psb.corner_radius_top_left = 4
	psb.corner_radius_top_right = 4
	psb.corner_radius_bottom_right = 4
	psb.corner_radius_bottom_left = 4
	psb.content_margin_top = 8
	psb.content_margin_bottom = 8
	price_box.add_theme_stylebox_override("panel", psb)
	vbox.add_child(price_box)
	
	var price_lbl = Label.new()
	price_lbl.text = ("TOTAL A PAGAR: %s
Tarjeta Sandbox: •••• •••• •••• 4242 (Aprobación Real)" if GameManager.current_language == "es" else "TOTAL DUE: %s
Sandbox Card: •••• •••• •••• 4242 (Live Simulation)") % pack["cost_label"]
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_font_size_override("font_size", 12)
	price_lbl.modulate = Color(0.3, 0.95, 0.5)
	price_box.add_child(price_lbl)
	
	var status_msg = Label.new()
	status_msg.text = ""
	status_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_msg.add_theme_font_size_override("font_size", 11)
	status_msg.modulate = Color(0.96, 0.75, 0.2)
	vbox.add_child(status_msg)
	
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "CANCELAR" if GameManager.current_language == "es" else "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(110, 36)
	_style_menu_button(cancel_btn, Color(0.7, 0.3, 0.3), Color(0.12, 0.05, 0.05))
	btn_row.add_child(cancel_btn)
	
	var pay_btn = Button.new()
	pay_btn.text = ("PAGAR " + pack["cost_label"]) if GameManager.current_language == "es" else ("PAY " + pack["cost_label"])
	pay_btn.custom_minimum_size = Vector2(170, 36)
	_style_menu_button(pay_btn, Color(0.2, 0.85, 0.4), Color(0.04, 0.16, 0.08))
	btn_row.add_child(pay_btn)
	
	cancel_btn.pressed.connect(func():
		AudioManager.play("click")
		if active_checkout_modal:
			active_checkout_modal.queue_free()
			active_checkout_modal = null
	)
	
	pay_btn.pressed.connect(func():
		AudioManager.play("click")
		pay_btn.disabled = true
		cancel_btn.disabled = true
		status_msg.text = "PROCESANDO TRANSACCIÓN CON REVENUECAT..." if GameManager.current_language == "es" else "PROCESSING REVENUECAT TRANSACTION..."
		
		# 1.2s delay simulating secure cloud payment processing
		var tw = create_tween()
		tw.tween_interval(1.2)
		tw.finished.connect(func():
			if pack.get("no_ads", false):
				RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_NO_ADS)
			elif pack.get("unlock_all", false):
				RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_FULL_GAME)
			elif pack.get("id") == "pack_editor":
				RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_PLANET_EDITOR)
				
			GameManager.add_luna_coins(pack["reward_coins"])
			_update_luna_points_ui()
			_update_direct_iap_buttons()
			_render_store_items()
			
			if active_checkout_modal:
				active_checkout_modal.queue_free()
				active_checkout_modal = null
				
			if store_status_label:
				store_status_label.visible = true
				store_status_label.text = ("✓ COMPRA APROBADA: +%d LUNA COINS (RECIBO #RC-%d)" if GameManager.current_language == "es" else "✓ PAYMENT APPROVED: +%d LUNA COINS (RECEIPT #RC-%d)") % [pack["reward_coins"], randi_range(10000, 99999)]
				store_status_label.modulate = Color(0.3, 0.95, 0.5)
		)
	)

func open_store_modal(title: String = "", desc: String = "", _highlight_editor: bool = false) -> void:
	# Store title must always be LUNA STORE in EN, TIENDA LUNA in ES (never Sector Pro Bloqueado)
	store_title.text = GameManager.loc("store_title")
	
	# If opened because of a locked sector or editor, show clean gold badge in store info
	if sector_notice_badge:
		if _highlight_editor:
			sector_notice_badge.visible = true
			sector_notice_badge.text = GameManager.loc("store_badge_locked_editor")
		elif not title.is_empty() and title != "TIENDA LUNA" and title != "LUNA STORE":
			sector_notice_badge.visible = true
			sector_notice_badge.text = GameManager.loc("store_badge_locked_sector")
		else:
			sector_notice_badge.visible = false
			
	_update_luna_points_ui()
	_update_direct_iap_buttons()
	_switch_store_tab("packs" if _highlight_editor else current_store_tab)
	if store_dimmer:
		store_dimmer.visible = true
	store_modal.visible = true
	_set_modal_open_state(true)
	if store_status_label:
		store_status_label.visible = false

func _on_close_store_pressed() -> void:
	AudioManager.play("click")
	if store_dimmer:
		store_dimmer.visible = false
	store_modal.visible = false
	_set_modal_open_state(false)

func _on_buy_no_ads_pressed() -> void:
	AudioManager.play("click")
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_NO_ADS)
	if store_dimmer:
		store_dimmer.visible = false
	store_modal.visible = false
	_set_modal_open_state(false)
	_update_launch_button_text()

func _on_buy_full_game_pressed() -> void:
	AudioManager.play("click")
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_FULL_GAME)
	if store_dimmer:
		store_dimmer.visible = false
	store_modal.visible = false
	_set_modal_open_state(false)
	_update_launch_button_text()

func _on_buy_editor_pressed() -> void:
	AudioManager.play("click")
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_PLANET_EDITOR)
	if store_dimmer:
		store_dimmer.visible = false
	store_modal.visible = false
	_set_modal_open_state(false)
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
	_update_direct_iap_buttons()

func _update_direct_iap_buttons() -> void:
	var is_es = (GameManager.current_language == "es")
	
	if buy_no_ads_btn:
		if RevenueCatManager.has_no_ads():
			buy_no_ads_btn.text = "[ ACTIVO ✓ ] " + ("SIN ANUNCIOS DE POR VIDA" if is_es else "NO ADS LIFETIME")
			buy_no_ads_btn.disabled = true
			_style_menu_button(buy_no_ads_btn, Color(0.2, 0.85, 0.4), Color(0.04, 0.14, 0.08))
		else:
			buy_no_ads_btn.text = "⚡ " + ("QUITAR ANUNCIOS - $0.99" if is_es else "REMOVE ADS - $0.99")
			buy_no_ads_btn.disabled = false
			_style_menu_button(buy_no_ads_btn, Color(0.2, 0.75, 1.0), Color(0.04, 0.11, 0.18))
			
	if buy_full_game_btn:
		if RevenueCatManager.has_full_game():
			buy_full_game_btn.text = "[ ADQUIRIDO ✓ ] CIVITUS FOUNDER FULL GAME"
			buy_full_game_btn.disabled = true
			_style_menu_button(buy_full_game_btn, Color(0.96, 0.75, 0.2), Color(0.18, 0.14, 0.04))
		else:
			buy_full_game_btn.text = "★ " + ("CIVITUS FULL GAME (TODO INCLUIDO) - $2.99" if is_es else "CIVITUS FULL GAME (ALL INCLUDED) - $2.99")
			buy_full_game_btn.disabled = false
			_style_menu_button(buy_full_game_btn, Color(0.96, 0.66, 0.16), Color(0.14, 0.09, 0.03))
			
	if buy_editor_btn:
		if RevenueCatManager.has_planet_editor():
			buy_editor_btn.text = "[ ADQUIRIDO ✓ ] " + ("EDITOR DE PLANETAS HABILITADO" if is_es else "PLANET EDITOR UNLOCKED")
			buy_editor_btn.disabled = true
			_style_menu_button(buy_editor_btn, Color(0.2, 0.85, 0.4), Color(0.04, 0.14, 0.08))
		else:
			buy_editor_btn.text = "✦ " + ("DESBLOQUEAR EDITOR DE PLANETAS - $1.99" if is_es else "UNLOCK PLANET EDITOR - $1.99")
			buy_editor_btn.disabled = false
			_style_menu_button(buy_editor_btn, Color(0.3, 0.85, 0.6), Color(0.04, 0.14, 0.10))

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
