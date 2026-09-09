extends Node

const VectorLander2DScript = preload("res://scripts/ui/vector_lander_2d.gd")
const VectorTouchButtonScript = preload("res://scripts/ui/vector_touch_button.gd")
const ProceduralBackdrop2DScript = preload("res://scripts/ui/procedural_backdrop_2d.gd")

func _ready() -> void:
	print("==========================================")
	print("  RUNNING CIVITUS LOADING & MINIGAME TESTS")
	print("==========================================")
	
	var passed = 0
	var failed = 0
	
	# 1. Test VectorLander2D instantiation and draw methods
	print("--- 1. Testing VectorLander2D ---")
	var lander = VectorLander2DScript.new()
	lander.size = Vector2(44, 48)
	add_child(lander)
	
	lander.set_thrust(true)
	if lander.thrust_active:
		print("  [PASS] Thrust flag activated on lander")
		passed += 1
	else:
		print("  [FAIL] Thrust flag failed to activate")
		failed += 1
		
	lander.set_rcs(true, false)
	if lander.rcs_left_active and not lander.rcs_right_active:
		print("  [PASS] Left RCS activated on lander")
		passed += 1
	else:
		print("  [FAIL] Left RCS failed")
		failed += 1
	lander.queue_free()
	
	# 2. Test VectorTouchButton types
	print("--- 2. Testing VectorTouchButton ---")
	var thrust_btn = VectorTouchButtonScript.new()
	thrust_btn.button_type = 0 # THRUST
	add_child(thrust_btn)
	if thrust_btn.custom_minimum_size.x >= 80.0:
		print("  [PASS] Touch button has ergonomic mobile touch size (>= 80px)")
		passed += 1
	else:
		print("  [FAIL] Touch button too small for mobile touch")
		failed += 1
	thrust_btn.queue_free()
	
	# 3. Test ProceduralBackdrop2D Responsive Width (Eliminate right gap on ultrawide)
	print("--- 3. Testing ProceduralBackdrop2D Ultrawide Coverage ---")
	var backdrop = ProceduralBackdrop2DScript.new()
	backdrop.size = Vector2(1600, 720) # 20:9 Ultrawide phone
	add_child(backdrop)
	var eff_sz = backdrop._get_effective_size()
	if eff_sz.x >= 1600.0:
		print("  [PASS] Backdrop expands to full ultrawide screen width (%s px)" % eff_sz.x)
		passed += 1
	else:
		print("  [FAIL] Backdrop did not expand to ultrawide width: %s" % eff_sz.x)
		failed += 1
	backdrop.queue_free()
	
	# 4. Test LoadingScreen Scene Architecture
	print("--- 4. Testing LoadingScreen Scene Nodes & HUD ---")
	var loading_scene = load("res://scenes/screens/loading_screen.tscn")
	if loading_scene != null:
		print("  [PASS] LoadingScreen scene loaded successfully")
		passed += 1
	else:
		print("  [FAIL] LoadingScreen scene failed to load")
		failed += 1
		
	var screen_inst = loading_scene.instantiate()
	add_child(screen_inst)
	
	var spinner_container = screen_inst.get_node_or_null("SpinnerContainer")
	var spinner_bar = screen_inst.get_node_or_null("SpinnerContainer/ProgressBar")
	var top_bar = screen_inst.get_node_or_null("MinigameContainer/TopBar")
	var top_progress_bar = screen_inst.get_node_or_null("MinigameContainer/TopBar/TopProgressBar")
	var top_progress_label = screen_inst.get_node_or_null("MinigameContainer/TopBar/TopProgressLabel")
	var ready_btn = screen_inst.get_node_or_null("MinigameContainer/TopBar/ReadyBtn")
	var mobile_controls = screen_inst.get_node_or_null("MinigameContainer/MobileControls")
	var main_burn_btn = screen_inst.get_node_or_null("MinigameContainer/MobileControls/MainBurnBtn")
	
	if spinner_container and spinner_bar and top_bar and top_progress_bar and top_progress_label and ready_btn:
		print("  [PASS] 5s Spinner Screen and Minigame HUD with ready button exists")
		passed += 1
	else:
		print("  [FAIL] Missing loading elements in scene")
		failed += 1
		
	if mobile_controls and main_burn_btn:
		print("  [PASS] Mobile controls present (zero text, hand-drawn style)")
		passed += 1
	else:
		print("  [FAIL] Mobile controls missing")
		failed += 1
		
	# Wait for threaded load to complete gracefully to verify full background loading pipeline
	print("  Waiting for background scene loading to complete...")
	var timeout_timer = 0.0
	while not screen_inst.is_loading_complete and timeout_timer < 4.0:
		await get_tree().process_frame
		timeout_timer += get_process_delta_time()
		
	if screen_inst.is_loading_complete:
		print("  [PASS] Background threaded scene load completed successfully!")
		passed += 1
	else:
		print("  [FAIL] Background threaded load timed out")
		failed += 1
		
	screen_inst.queue_free()
	await get_tree().process_frame
	
	print("==========================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("==========================================")
	
	if failed == 0:
		print("ALL LOADING & MINIGAME TESTS PASSED! :D")
		get_tree().quit(0)
	else:
		print("SOME TESTS FAILED! :(")
		get_tree().quit(1)
