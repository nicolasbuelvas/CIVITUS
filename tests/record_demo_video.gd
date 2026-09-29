extends Node3D

# =============================================================================
# CIVITUS: DEMO OFICIAL PARA REVENUECAT SHIPATON 2026
# Duración exacta: < 2 minutos (aprox 110s)
# Muestra:
#   1. Paywall IAP de RevenueCat ($0.99, $1.99, $2.99)
#   2. Compra y desbloqueo de Licencia Founder vía RevenueCat
#   3. Transmisión patrocinada diegética (+50 Luna Coins) con cierre limpio
#   4. Cartografía orbital con mapa de Kepler y navegación multi-planeta
#   5. Reentrada balística, retrocohetes y aterrizaje con despliegue de rampa
#   6. Exploración EVA en 3ª persona con gravedad radial y salto lunar
#   7. Interacción dócil con fauna alienígena (agarre y liberación)
#   8. Visor diegético 1P con azimut, barómetro y faros duales
#   9. Extracción de minerales con multi-herramienta láser
#  10. Retorno a cabina, recarga O2, fabricación e hiperimpulso a deep space
# =============================================================================

var hud_overlay: CanvasLayer = null
var telemetry_label: Label = null
var status_pill: PanelContainer = null

func _ready() -> void:
	print("[Demo] Iniciando grabación oficial para RevenueCat Shipaton 2026...")
	RenderingServer.set_default_clear_color(Color(0.01, 0.02, 0.04, 1.0))
	_setup_telemetry_hud()
	_execute_gameplay_flow()

func _setup_telemetry_hud() -> void:
	hud_overlay = CanvasLayer.new()
	hud_overlay.layer = 120
	add_child(hud_overlay)
	
	status_pill = PanelContainer.new()
	status_pill.set_anchors_preset(Control.PRESET_TOP_WIDE)
	status_pill.custom_minimum_size = Vector2(0, 36)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.07, 0.88)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.2, 0.85, 1.0, 0.6)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	status_pill.add_theme_stylebox_override("panel", sb)
	hud_overlay.add_child(status_pill)
	
	telemetry_label = Label.new()
	telemetry_label.text = "[ ⬡ CIVITUS // REVENUECAT SHIPATON 2026 ]"
	telemetry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	telemetry_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	telemetry_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	telemetry_label.add_theme_font_size_override("font_size", 14)
	status_pill.add_child(telemetry_label)

func _log_telemetry(msg: String) -> void:
	print("[Demo Telemetry] ", msg)
	if telemetry_label:
		telemetry_label.text = msg

func _execute_gameplay_flow() -> void:
	# =========================================================================
	# FASE 1: MENÚ PRINCIPAL & SHOWCASE REVENUECAT (0s - 30s)
	# =========================================================================
	_log_telemetry("[ ⬡ CIVITUS // REVENUECAT SHIPATON 2026 • DIORAMA ESPACIAL 3D ]")
	var menu_scene = load("res://scenes/screens/main_menu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	
	await get_tree().create_timer(4.0).timeout
	
	# Abrir Tienda Luna
	_log_telemetry("[ ⬡ 01 // TIENDA LUNA • PROTOCOLOS EVA & MONETIZACIÓN ÉTICA ]")
	if menu.has_method("open_store_modal"):
		menu.open_store_modal("TIENDA LUNA", "Protocolos de Suministro y Trajes EVA")
	await get_tree().create_timer(3.5).timeout
	
	# Cambiar a la pestaña de Paquetes IAP (Paywall RevenueCat)
	_log_telemetry("[ ⬡ 02 // PAYWALL REVENUECAT • SIN ANUNCIOS / EDITOR 3D / FOUNDER ]")
	if menu.has_method("_switch_store_tab"):
		menu._switch_store_tab("packs")
	await get_tree().create_timer(4.0).timeout
	
	# Simular compra exitosa con RevenueCat
	_log_telemetry("[ ✓ REVENUECAT // PAGO PROCESADO ($2.99 USD) • LICENCIA FOUNDER ACTIVADA ]")
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_FULL_GAME)
	await get_tree().create_timer(3.0).timeout
	
	# Demostración del Anuncio Recompensado Diegético
	_log_telemetry("[ ⬡ 03 // TRANSMISIÓN ORBITAL • ANUNCIO RECOMPENSADO (+50 ☾) ]")
	AdManager.show_rewarded_ad(func():
		GameManager.add_luna_coins(50)
		if is_instance_valid(menu) and menu.has_method("_update_luna_points_ui"):
			menu._update_luna_points_ui()
	)
	
	# Esperar a que el contador de 5s termine y el botón de reclamar se active
	await get_tree().create_timer(5.4).timeout
	if is_instance_valid(AdManager.active_ad_overlay):
		var btns = AdManager.active_ad_overlay.find_children("", "Button", true, false)
		for b in btns:
			if "RECLAMAR" in b.text and not b.disabled:
				b.pressed.emit()
				break
	await get_tree().create_timer(1.2).timeout
	
	# Asegurar que el overlay del ad quede completamente cerrado
	if is_instance_valid(AdManager.active_ad_overlay):
		AdManager.active_ad_overlay.queue_free()
		AdManager.active_ad_overlay = null
	
	# Cerrar tienda Luna
	if is_instance_valid(menu) and menu.has_method("_on_close_store_pressed"):
		menu._on_close_store_pressed()
	await get_tree().create_timer(2.0).timeout
	
	# =========================================================================
	# FASE 2: CARTOGRAFÍA Y SELECCIÓN DE PLANETAS (30s - 45s)
	# =========================================================================
	_log_telemetry("[ ⬡ 04 // CARTOGRAFÍA ORBITAL • SISTEMA SOLAR MULTI-CUERPO ]")
	if menu.has_method("_on_play_pressed"):
		menu._on_play_pressed()
	await get_tree().create_timer(1.5).timeout
	
	if menu.has_method("_on_new_game_pressed"):
		menu._on_new_game_pressed()
	await get_tree().create_timer(2.0).timeout
	
	# Mostrar mapa de órbitas de Kepler del sistema estelar
	if menu.has_method("_on_system_tab_pressed"):
		menu._on_system_tab_pressed()
	await get_tree().create_timer(3.5).timeout
	
	# Volver a vista de planeta y seleccionar mundo habitable
	if menu.has_method("_on_planet_tab_pressed"):
		menu._on_planet_tab_pressed()
	await get_tree().create_timer(1.5).timeout
	
	var planets = GameManager.current_solar_system.get("planets", [])
	for i in range(planets.size()):
		if planets[i].get("category", -1) == 0 or planets[i].get("is_habitable", false):
			if menu.has_method("_select_planet"):
				menu._select_planet(i)
			break
	await get_tree().create_timer(3.0).timeout
	
	# Limpieza de menú para descender al mundo
	menu.queue_free()
	await get_tree().process_frame
	
	# =========================================================================
	# FASE 3: REENTRADA Y ATERRIZAJE SUBORBITAL (45s - 65s)
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
		
	_log_telemetry("[ ⬡ 06 // CONTACTO NOMINAL • APERTURA DE ESCOTILLA Y RAMPA ]")
	if ship and ship.has_method("open_hatch"):
		ship.open_hatch()
	await get_tree().create_timer(5.0).timeout
	
	# =========================================================================
	# FASE 4: EXPLORACIÓN SUPERFICIAL, SALTO LUNAR Y FAUNA (65s - 85s)
	# =========================================================================
	print("[Phase 4] Iniciando exploración superficial...")
	var player = planet.player_instance if planet and "player_instance" in planet else null
	if not player:
		player = world.find_child("Character3D", true, false)
		
	if player:
		player.is_action_locked = false
		if player.is_first_person:
			player.toggle_first_person()
			
	_log_telemetry("[ ⬡ 07 // EXPLORACIÓN EVA • GRAVEDAD RADIAL Y SALTO APOLO ]")
	
	# Astronauta camina hacia adelante bajando de la plataforma
	Input.action_press("move_forward")
	await get_tree().create_timer(2.5).timeout
	Input.action_release("move_forward")
	
	# Salto en baja gravedad
	Input.action_press("jump_thrust")
	await get_tree().create_timer(0.4).timeout
	Input.action_release("jump_thrust")
	await get_tree().create_timer(2.0).timeout
	
	# Criatura dócil alienígena
	print("[Phase 4] Spawneando criatura alienígena...")
	_log_telemetry("[ ⬡ 08 // ECOLOGÍA REACTIVA • INTERACCIÓN Y TRANSPORTE DE FAUNA ]")
	var alien_scene = load("res://scenes/entities/alien_creature.tscn")
	var creature = alien_scene.instantiate()
	planet.add_child(creature)
	creature.setup_creature(GameManager.current_planet, false)
	
	if player:
		var p_fwd = -player.global_transform.basis.z.normalized()
		var p_up = player.global_transform.basis.y.normalized()
		creature.global_position = player.global_position + p_fwd * 2.8 + p_up * 0.2
			
	await get_tree().create_timer(1.5).timeout
	
	if player and player.has_method("pick_up_creature"):
		player.pick_up_creature(creature)
	await get_tree().create_timer(2.5).timeout
	
	if player and player.has_method("drop_carried_creature"):
		player.drop_carried_creature()
	await get_tree().create_timer(2.0).timeout
	
	# =========================================================================
	# FASE 5: VISOR HUD 1P, FAROS Y MINADO (85s - 100s)
	# =========================================================================
	print("[Phase 5] Iniciando Visor HUD 1P y minado...")
	# Ocultamos la barra de telemetría de demo para que el visor diegético se aprecie al 100%
	if status_pill:
		status_pill.visible = false
		
	if player and not player.is_first_person:
		player.toggle_first_person()
		
	if player and player.has_method("toggle_headlamp"):
		player.toggle_headlamp()
	await get_tree().create_timer(3.0).timeout
	
	# Spawner de veta mineral para minado
	var chunk_scene = load("res://scenes/entities/resource_chunk.tscn")
	var chunk = chunk_scene.instantiate()
	chunk.ore_type = ResourceChunk.OreType.IRON
	planet.add_child(chunk)
	if player:
		var p_fwd = -player.global_transform.basis.z.normalized()
		var p_up = player.global_transform.basis.y.normalized()
		chunk.global_position = player.global_position + p_fwd * 2.2 + p_up * 0.25
		
	await get_tree().create_timer(1.2).timeout
	if player and player.has_method("_draw_laser"):
		player._draw_laser(chunk.global_position)
	await get_tree().create_timer(1.5).timeout
	chunk.mine_tick(100.0)
	GameManager.crafting.add_resource("iron", 4)
	GameManager.crafting.add_resource("copper", 2)
	await get_tree().create_timer(1.2).timeout
	if player and "laser_mesh" in player and is_instance_valid(player.laser_mesh):
		player.laser_mesh.visible = false
		
	# Salvamento de nave espacial abandonada procedural
	var wreck_scene = load("res://scenes/entities/abandoned_shipwreck.tscn")
	var wreck = wreck_scene.instantiate()
	planet.add_child(wreck)
	if player:
		var p_right = player.global_transform.basis.x.normalized()
		var p_fwd = -player.global_transform.basis.z.normalized()
		wreck.global_position = player.global_position + p_right * 3.8 + p_fwd * 1.5
	await get_tree().create_timer(1.2).timeout
	if player and is_instance_valid(wreck):
		wreck.scavenge(player)
	await get_tree().create_timer(1.5).timeout
	
	# =========================================================================
	# FASE 6: CABINA, SOPORTE VITAL Y SALTO HIPERESPACIAL (100s - 115s)
	# =========================================================================
	print("[Phase 6] Retornando a cabina y despegue...")
	if status_pill:
		status_pill.visible = true
	_log_telemetry("[ ⬡ 09 // MÓDULO DE MANDO • RECARGA O2 Y MESA FABRICADORA ]")
	
	if player and player.is_first_person:
		player.toggle_first_person()
		
	if player and ship:
		player.global_position = ship.to_global(Vector3(0, 0.8, 1.8))
		ship.is_player_in_cabin = true
		
	await get_tree().create_timer(3.0).timeout
	
	_log_telemetry("[ ⬡ 10 // HIPERIMPULSO RESTAURADO • SALTO AL ESPACIO PROFUNDO ]")
	GameManager.crafting.craft("wrench")
	GameManager.crafting.install_part("wrench")
	GameManager.crafting.install_part("wire")
	GameManager.crafting.install_part("uranium")
	
	if ship and ship.has_method("sit_in_pilot_seat"):
		ship.sit_in_pilot_seat(player)
		
	await get_tree().create_timer(3.5).timeout
	
	_log_telemetry("[ ⬡ CIVITUS // PARTICIPACIÓN: NEXT GEN AWARD • REVENUECAT SHIPATON 2026 ]")
	await get_tree().create_timer(4.0).timeout
	
	print("\n=======================================================")
	print("   DEMO RECORDING COMPLETED CLEANLY! (EXIT CODE 0)     ")
	print("=======================================================\n")
	get_tree().quit(0)
