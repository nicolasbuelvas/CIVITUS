extends Node3D

# CIVITUS - Official 2-Minute Gameplay & RevenueCat Showcase
# Minimalist Aerospace Symbology - Zero AI Slop

var hud_overlay: CanvasLayer = null
var status_label: Label = null

func _ready() -> void:
	_setup_telemetry_hud()
	_execute_gameplay_flow()

func _setup_telemetry_hud() -> void:
	hud_overlay = CanvasLayer.new()
	hud_overlay.layer = 200
	add_child(hud_overlay)
	
	var box = PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.custom_minimum_size = Vector2(0, 36)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.07, 0.90)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.2, 0.85, 1.0, 0.7)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", sb)
	hud_overlay.add_child(box)
	
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.modulate = Color(0.85, 0.92, 1.0)
	box.add_child(status_label)

func _log_telemetry(symbolic_tag: String) -> void:
	if status_label:
		status_label.text = symbolic_tag
	print(symbolic_tag)

func _execute_gameplay_flow() -> void:
	# =========================================================================
	# FASE 1: MENÚ PRINCIPAL & TIENDA LUNA (REVENUECAT) [0s - 28s]
	# =========================================================================
	_log_telemetry("[ ⬡ CIVITUS // R=160m • NAVEGACIÓN Y ECONOMÍA LUNA ]")
	var menu_scene = load("res://scenes/screens/main_menu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	
	await get_tree().create_timer(3.5).timeout
	
	_log_telemetry("[ ⬡ 01 // TIENDA LUNA • IAP REVENUECAT & COSMÉTICOS ]")
	if menu.has_method("open_store_modal"):
		menu.open_store_modal("TIENDA LUNA", "Protocolos de Suministro y Trajes EVA")
	await get_tree().create_timer(3.5).timeout
	
	# Tab de Toberas de Propulsión
	if menu.has_method("_switch_store_tab"):
		menu._switch_store_tab("paints")
	await get_tree().create_timer(3.0).timeout
	
	# Tab de Paquetes RevenueCat
	_log_telemetry("[ ⬡ 02 // REVENUECAT IAP • SIN ADS / EDITOR / FULL GAME ]")
	if menu.has_method("_switch_store_tab"):
		menu._switch_store_tab("packs")
	await get_tree().create_timer(4.0).timeout
	
	# Transmisión patrocinada (Rewarded Ad)
	_log_telemetry("[ ⬡ 03 // TRANSMISIÓN ORBITAL • ANUNCIO RECOMPENSADO (+50 ☾) ]")
	AdManager.show_rewarded_ad(func():
		GameManager.add_luna_coins(50)
		if menu.has_method("_update_luna_points_ui"):
			menu._update_luna_points_ui()
	)
	await get_tree().create_timer(4.5).timeout
	
	# Cerrar tienda
	if menu.has_method("_on_close_store_pressed"):
		menu._on_close_store_pressed()
	await get_tree().create_timer(1.5).timeout
	
	# =========================================================================
	# FASE 2: CARTOGRAFÍA Y SELECCIÓN DE PLANETAS [28s - 45s]
	# =========================================================================
	_log_telemetry("[ ⬡ 04 // CARTOGRAFÍA ORBITAL • SISTEMA ESTELAR ◄ / ► ]")
	if menu.has_method("_on_play_pressed"):
		menu._on_play_pressed()
	await get_tree().create_timer(2.0).timeout
	
	if menu.has_method("_on_continue_pressed"):
		menu._on_continue_pressed()
	await get_tree().create_timer(3.5).timeout
	
	if menu.has_method("_on_next_planet_pressed"):
		menu._on_next_planet_pressed()
	await get_tree().create_timer(3.0).timeout
	
	if menu.has_method("_on_next_planet_pressed"):
		menu._on_next_planet_pressed()
	await get_tree().create_timer(3.0).timeout
	
	# Limpieza de menú para descender al mundo
	menu.queue_free()
	await get_tree().process_frame
	
	# =========================================================================
	# FASE 3: REENTRADA Y ATERRIZAJE SUBORBITAL [45s - 72s]
	# =========================================================================
	_log_telemetry("[ ⬡ 05 // REENTRADA BALÍSTICA • ESCALADO KSP & RETROCOHETES ]")
	GameManager.start_new_game(1)
	
	var world_scene = load("res://scenes/world/world.tscn")
	var world = world_scene.instantiate()
	add_child(world)
	
	var planet = world.get_node_or_null("SphericalPlanet")
	if planet and planet.is_generating:
		await planet.planet_ready
		
	await get_tree().create_timer(0.5).timeout
	
	if planet and planet.has_method("start_landing_cinematic"):
		planet.start_landing_cinematic()
		
	var ship = planet.spaceship_instance if planet and "spaceship_instance" in planet else null
	if not ship:
		ship = world.find_child("Spaceship3D", true, false)
		
	if ship and ship.has_signal("landing_completed"):
		await ship.landing_completed
		
	_log_telemetry("[ ⬡ 06 // CONTACTO NOMINAL • RAMPA DE EMBARQUE & ESCOTILLA ]")
	await get_tree().create_timer(3.5).timeout
	
	# =========================================================================
	# FASE 4: EXPLORACIÓN SUPERFICIAL, SALTO LUNAR Y FAUNA [72s - 98s]
	# =========================================================================
	var player = planet.player_instance if planet and "player_instance" in planet else null
	if not player:
		player = world.find_child("Character3D", true, false)
		
	if player:
		player.is_action_locked = false
		if player.is_first_person:
			player.toggle_first_person()
			
	_log_telemetry("[ ⬡ 07 // LOCOMOCIÓN • GRAVEDAD RADIAL Y SALTO APOLO ]")
	
	# Criatura dócil procedural
	var alien_scene = load("res://scenes/entities/alien_creature.tscn")
	var creature = alien_scene.instantiate()
	world.add_child(creature)
	creature.setup_creature(GameManager.current_planet, false)
	creature.global_position = Vector3(1.6, 161.0, 3.2)
	
	if player:
		player.input_dir = Vector2(0.0, -1.0)
	await get_tree().create_timer(2.2).timeout
	if player:
		player.input_dir = Vector2.ZERO
		
	_log_telemetry("[ ⬡ 08 // ECOLOGÍA REACTIVA • AGARRE, TRANSPORTE Y RESCATE ]")
	if player and player.has_method("pick_up_creature"):
		player.pick_up_creature(creature)
	await get_tree().create_timer(3.5).timeout
	
	if player and player.has_method("drop_carried_creature"):
		player.drop_carried_creature()
	await get_tree().create_timer(2.0).timeout
	
	# =========================================================================
	# FASE 5: VISOR HUD 1P, FAROS Y MINADO [98s - 116s]
	# =========================================================================
	_log_telemetry("[ ⬡ 09 // VISOR TÉCNICO 1P • AZIMUT, BARÓMETRO & FAROS DUALES ]")
	if player and not player.is_first_person:
		player.toggle_first_person()
		
	if player and player.has_method("toggle_headlamp"):
		player.toggle_headlamp()
	await get_tree().create_timer(3.0).timeout
	
	_log_telemetry("[ ⬡ 10 // MULTI-HERRAMIENTA • MINADO DE VETA ANGULAR ]")
	var chunk_scene = load("res://scenes/entities/resource_chunk.tscn")
	var chunk = chunk_scene.instantiate()
	world.add_child(chunk)
	chunk.setup_resource("iron", GameManager.current_planet)
	chunk.global_position = Vector3(0.0, 161.0, 2.4)
	
	await get_tree().create_timer(2.5).timeout
	chunk.mine_tick(100.0)
	GameManager.crafting.add_resource("iron", 4)
	GameManager.crafting.add_resource("copper", 2)
	await get_tree().create_timer(2.5).timeout
	
	# =========================================================================
	# FASE 6: CABINA, SOPORTE VITAL Y PREPARACIÓN DE VUELO [116s - 135s]
	# =========================================================================
	_log_telemetry("[ ⬡ 11 // CABINA INTERIOR • SOPORTE VITAL O2 Y BANCO FABRICADOR ]")
	if player and player.is_first_person:
		player.toggle_first_person()
		
	if player and ship:
		player.global_position = ship.to_global(Vector3(0, 0.8, 1.8))
		ship.is_player_in_cabin = true
		
	await get_tree().create_timer(3.5).timeout
	
	_log_telemetry("[ ⬡ 12 // HIPERIMPULSO RESTAURADO • SALTO AL ESPACIO PROFUNDO ]")
	GameManager.crafting.craft("wrench")
	GameManager.crafting.install_part("wrench")
	GameManager.crafting.install_part("wire")
	GameManager.crafting.install_part("uranium")
	
	if ship and ship.has_method("sit_in_pilot_seat"):
		ship.sit_in_pilot_seat(player)
		
	await get_tree().create_timer(3.5).timeout
	
	_log_telemetry("[ ⬡ CIVITUS // PARTICIPACIÓN: NEXT GEN AWARD • REVENUECAT SHIPATON 2026 ]")
	await get_tree().create_timer(4.5).timeout
	
	print("\n=======================================================")
	print("   RECORDING COMPLETED CLEANLY! (EXIT CODE 0)          ")
	print("=======================================================\n")
	get_tree().quit(0)
