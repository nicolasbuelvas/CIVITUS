extends Node

func _ready() -> void:
	print("\n==========================================")
	print("       RUNNING AUDIO MANAGER TESTS        ")
	print("==========================================\n")
	
	var passed = 0
	var failed = 0
	
	# Test 1: Check sound loading
	if AudioManager.sounds.has("music_menu_theme"):
		print("  [PASS] music_menu_theme sound loaded in AudioManager")
		passed += 1
	else:
		print("  [FAIL] music_menu_theme not found in AudioManager")
		failed += 1
		
	if AudioManager.sounds.has("ambient_music"):
		print("  [PASS] ambient_music sound loaded in AudioManager")
		passed += 1
	else:
		print("  [FAIL] ambient_music not found in AudioManager")
		failed += 1
		
	# Test 2: Check music player initialization
	if AudioManager.music_player != null and AudioManager.music_player.is_inside_tree():
		print("  [PASS] music_player created and in tree")
		passed += 1
	else:
		print("  [FAIL] music_player missing or not in tree")
		failed += 1
		
	# Test 3: Check initial menu track playback
	if AudioManager.get_current_music_track() == "menu":
		print("  [PASS] Initial music track is 'menu'")
		passed += 1
	else:
		print("  [FAIL] Initial music track is '%s', expected 'menu'" % AudioManager.get_current_music_track())
		failed += 1
		
	if AudioManager.music_player.stream == AudioManager.sounds["music_menu_theme"]:
		print("  [PASS] music_player stream matches music_menu_theme")
		passed += 1
	else:
		print("  [FAIL] music_player stream does not match music_menu_theme")
		failed += 1
		
	# Test 4: Check crossfade to gameplay music
	print("  Testing crossfade to gameplay music...")
	AudioManager.play_gameplay_music(0.1)
	if AudioManager.get_current_music_track() == "gameplay":
		print("  [PASS] Track switched to 'gameplay'")
		passed += 1
	else:
		print("  [FAIL] Track failed to switch to 'gameplay'")
		failed += 1
		
	if AudioManager.music_player.stream == AudioManager.sounds["ambient_music"]:
		print("  [PASS] music_player stream updated to ambient_music")
		passed += 1
	else:
		print("  [FAIL] music_player stream not updated")
		failed += 1
		
	# Wait for tween to complete
	await get_tree().create_timer(0.2).timeout
	
	# Test 5: Check crossfade back to menu music
	print("  Testing crossfade back to menu music...")
	AudioManager.play_menu_music(0.1)
	if AudioManager.get_current_music_track() == "menu":
		print("  [PASS] Track switched back to 'menu'")
		passed += 1
	else:
		print("  [FAIL] Track failed to switch back to 'menu'")
		failed += 1
		
	await get_tree().create_timer(0.2).timeout
	
	if AudioManager.music_player.stream == AudioManager.sounds["music_menu_theme"]:
		print("  [PASS] music_player stream restored to music_menu_theme")
		passed += 1
	else:
		print("  [FAIL] music_player stream not restored")
		failed += 1
		
	print("\n==========================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("==========================================\n")
	
	get_tree().quit(0 if failed == 0 else 1)
