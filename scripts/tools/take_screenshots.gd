extends SceneTree

func _init() -> void:
	print("[Screenshot tool] Initializing...")
	_capture_scenes()

func _capture_scenes() -> void:
	# Load main menu
	var menu_scene = load("res://scenes/screens/main_menu.tscn").instantiate()
	root.add_child(menu_scene)
	
	# Wait 3 frames for rendering
	for i in range(5):
		await process_frame
		
	var img = root.get_texture().get_image()
	img.save_png("res://screenshot_menu.png")
	print("[Screenshot tool] Saved screenshot_menu.png")
	
	menu_scene.queue_free()
	await process_frame
	
	# Load world
	var world_scene = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world_scene)
	
	for i in range(10):
		await process_frame
		
	var img_world = root.get_texture().get_image()
	img_world.save_png("res://screenshot_gameplay.png")
	print("[Screenshot tool] Saved screenshot_gameplay.png")
	
	quit(0)
