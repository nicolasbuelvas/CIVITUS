extends Control

# View State
enum ViewState {
	ROOT_MENU,
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

# UI References - Root Menu
@onready var root_layer: Control = $MenuLayer/RootLayer
@onready var title_label: Label = $MenuLayer/RootLayer/BrandBox/Title
@onready var subtitle_label: Label = $MenuLayer/RootLayer/BrandBox/Subtitle

@onready var play_btn: Button = $MenuLayer/RootLayer/ActionButtons/PlayBtn
@onready var planet_editor_btn: Button = $MenuLayer/RootLayer/ActionButtons/PlanetEditorBtn
@onready var settings_btn: Button = $MenuLayer/RootLayer/ActionButtons/SettingsBtn
@onready var store_btn: Button = $MenuLayer/RootLayer/ActionButtons/StoreBtn
@onready var exit_btn: Button = $MenuLayer/RootLayer/ActionButtons/ExitBtn

# UI References - Planet Selector
@onready var selector_layer: Control = $MenuLayer/PlanetSelectorLayer
@onready var system_name_label: Label = $MenuLayer/PlanetSelectorLayer/TopBar/SystemBox/SystemName
@onready var system_coords_label: Label = $MenuLayer/PlanetSelectorLayer/TopBar/SystemBox/SystemCoords
@onready var new_system_btn: Button = $MenuLayer/PlanetSelectorLayer/TopBar/NewSystemBtn

@onready var prev_planet_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/PrevBtn
@onready var next_planet_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/NextBtn
@onready var planet_badge_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/CarouselRow/PlanetBadgeLabel

@onready var planet_tab_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/TabBar/PlanetTabBtn
@onready var system_tab_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/TabBar/SystemTabBtn

@onready var telemetry_card: PanelContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard
@onready var planet_info_box: VBoxContainer = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox
@onready var planet_name_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/HeaderRow/PlanetName
@onready var planet_type_label: Label = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/HeaderRow/PlanetType
@onready var toggle_details_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/TelemetryCard/PlanetInfoBox/HeaderRow/ToggleDetailsBtn

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

@onready var back_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/BackBtn
@onready var unlock_ad_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/UnlockAdBtn
@onready var launch_btn: Button = $MenuLayer/PlanetSelectorLayer/BottomDock/NavButtons/LaunchBtn

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
@onready var store_title: Label = $MenuLayer/StoreModal/VBox/Title
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

func _ready() -> void:
	# Hide modals
	settings_modal.visible = false
	store_modal.visible = false
	
	# Connect Root Menu buttons
	play_btn.pressed.connect(_on_play_pressed)
	if planet_editor_btn:
		planet_editor_btn.pressed.connect(_on_planet_editor_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	store_btn.pressed.connect(_on_store_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
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

func _apply_localization() -> void:
	# Root Menu
	play_btn.text = GameManager.loc("play")
	if planet_editor_btn:
		planet_editor_btn.text = GameManager.loc("planet_editor")
	settings_btn.text = GameManager.loc("settings")
	store_btn.text = GameManager.loc("store")
	exit_btn.text = GameManager.loc("exit")
	
	# Selector Navigation
	new_system_btn.text = GameManager.loc("new_system")
	back_btn.text = GameManager.loc("back_menu")
	planet_tab_btn.text = GameManager.loc("planet_info_tab")
	system_tab_btn.text = GameManager.loc("system_info_tab")
	
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
			selector_layer.visible = false
			target_camera_dist = 12.0
			target_focal_point = Vector3.ZERO
			planet_pivot.visible = true
			if star_pivot:
				star_pivot.visible = false
			if orbits_view:
				orbits_view.visible = false
		ViewState.PLANET_SELECTOR:
			root_layer.visible = false
			selector_layer.visible = true
			target_camera_dist = 11.5
			target_focal_point = Vector3.ZERO
			planet_pivot.visible = true
			if star_pivot:
				star_pivot.visible = true
			if orbits_view:
				orbits_view.visible = false
			_refresh_solar_system_ui()

func _process(delta: float) -> void:
	# Idle orbital camera drift when not dragging
	if not is_dragging:
		cam_yaw += cam_yaw_velocity * delta
		cam_pitch += cam_pitch_velocity * delta
		cam_pitch = clamp(cam_pitch, -1.25, 1.25)
		cam_yaw_velocity = lerp(cam_yaw_velocity, 0.025, delta * 1.5)
		cam_pitch_velocity = lerp(cam_pitch_velocity, 0.0, delta * 2.5)
		
	# Planet spins on its own polar axis
	if planet_mesh and planet_pivot and planet_pivot.visible:
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
	# Free 360° omnidirectional orbit drag & mobile tap detection
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
			is_dragging = true
			last_drag_pos = event.position
			drag_travel = 0.0
		else:
			is_dragging = false
			if drag_travel < 14.0 and active_info_tab == "system":
				_check_screen_tap_planet(event.position)
			
	elif event is InputEventScreenDrag and is_dragging:
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
	toggle_details_btn.text = "[ - INFO ]" if is_telemetry_expanded else "[ + INFO ]"

# ----------------- Navigation & Button Callbacks -----------------

func _on_play_pressed() -> void:
	AudioManager.play("click")
	_show_view(ViewState.PLANET_SELECTOR)

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
	planet_tab_btn.modulate = Color(1.0, 1.0, 1.0)
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
	planet_tab_btn.modulate = Color(0.65, 0.75, 0.85, 0.6)
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
		
	if AudioManager.has_method("play_gameplay_music"):
		AudioManager.play_gameplay_music()
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

func open_store_modal(title: String, desc: String, highlight_editor: bool = false) -> void:
	store_title.text = title
	store_desc.text = desc
	store_modal.visible = true
	if store_status_label:
		store_status_label.visible = false
	if highlight_editor and buy_editor_btn:
		buy_editor_btn.modulate = Color(1.0, 0.88, 0.25)
		if buy_full_game_btn:
			buy_full_game_btn.modulate = Color(0.35, 0.95, 1.0)
	else:
		if buy_editor_btn:
			buy_editor_btn.modulate = Color(1.0, 1.0, 1.0)
		if buy_full_game_btn:
			buy_full_game_btn.modulate = Color(1.0, 1.0, 1.0)

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
