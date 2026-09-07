extends Node

func _ready() -> void:
	print("[Showcase Capture] Starting visual captures...")
	_run_captures()

func _run_captures() -> void:
	# 1. Capture Root Menu
	var menu = load("res://scenes/screens/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().create_timer(1.0).timeout
	_save_viewport("screenshot_menu.png")
	
	# 2. Capture Planet Selector View
	if menu.has_method("_show_view"):
		menu._show_view(1) # ViewState.PLANET_SELECTOR
		await get_tree().create_timer(1.0).timeout
		_save_viewport("screenshot_selector.png")
	menu.queue_free()
	await get_tree().create_timer(0.3).timeout
	
	# 3. Capture Loading Screen (Spinner)
	var loading = load("res://scenes/screens/loading_screen.tscn").instantiate()
	add_child(loading)
	await get_tree().create_timer(0.8).timeout
	_save_viewport("screenshot_loading_spinner.png")
	
	# 4. Force reveal minigame & capture 2D procedural landscape
	if loading.has_method("_activate_minigame"):
		loading._activate_minigame()
	await get_tree().create_timer(0.8).timeout
	_save_viewport("screenshot_loading_minigame.png")
	loading.queue_free()
	await get_tree().create_timer(0.3).timeout

	# 5. Capture World 3D & Planet & Character
	var world = load("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	await get_tree().create_timer(1.5).timeout
	var player = world.get_node_or_null("Character3D")
	if player:
		var cam = player.get_node("CameraPivot/Camera3D")
		print("[Debug] Player global pos: ", player.global_position)
		print("[Debug] Camera global pos: ", cam.global_position)
	_save_viewport("screenshot_gameplay.png")
	
	# 6. Switch to Jarvis 1st person mode and capture
	if player and player.has_method("zoom_camera"):
		player.zoom_camera(-12.0)
	await get_tree().create_timer(1.0).timeout
	_save_viewport("screenshot_jarvis.png")
	
	print("[Showcase Capture] All showcase screenshots saved successfully!")
	get_tree().quit(0)

func _save_viewport(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://" + filename)
		print("[Showcase Capture] Saved " + filename)
