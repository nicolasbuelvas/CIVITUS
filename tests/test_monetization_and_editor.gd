extends SceneTree

func _init() -> void:
	print("\n=======================================================")
	print("   RUNNING MONETIZATION, STORE & EDITOR TEST SUITE     ")
	print("=======================================================\n")
	
	var RevenueCatManager = root.get_node_or_null("RevenueCatManager")
	if not RevenueCatManager:
		RevenueCatManager = load("res://scripts/autoloads/revenuecat_manager.gd").new()
		RevenueCatManager.name = "RevenueCatManager"
		root.add_child(RevenueCatManager)
		
	var GameManager = root.get_node_or_null("GameManager")
	if not GameManager:
		GameManager = load("res://scripts/autoloads/game_manager.gd").new()
		GameManager.name = "GameManager"
		root.add_child(GameManager)
		
	var passed: int = 0
	var failed: int = 0
	
	# 1. Test Default Settings
	GameManager.master_volume = 0.2
	GameManager.music_volume = 0.3
	GameManager.sfx_volume = 0.4
	GameManager.current_language = "es"
	GameManager.reset_settings_to_default()
	
	if GameManager.current_language == "en" and abs(GameManager.master_volume - 0.85) < 0.01 and abs(GameManager.music_volume - 0.70) < 0.01 and abs(GameManager.sfx_volume - 0.90) < 0.01:
		passed += 1
		print("[PASS] Setting 'Volver a Default' correctly restores 85%, 70%, 90% and 'en'")
	else:
		failed += 1
		print("[FAIL] Setting 'Volver a Default' failed to restore default values")
		
	# 2. Test RevenueCat IAPs & Entitlements
	RevenueCatManager.has_no_ads_license = false
	RevenueCatManager.has_full_game_license = false
	RevenueCatManager.has_planet_editor_license = false
	RevenueCatManager.has_deep_space_license = false
	RevenueCatManager.is_dev_mode = false
	
	# Purchase No Ads
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_NO_ADS)
	if RevenueCatManager.has_no_ads() and not RevenueCatManager.has_full_game() and not RevenueCatManager.has_planet_editor():
		passed += 1
		print("[PASS] IAP civitus_no_ads unlocks no_ads entitlement without VIP or editor")
	else:
		failed += 1
		print("[FAIL] IAP civitus_no_ads failed")
		
	# Purchase Planet Editor
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_PLANET_EDITOR)
	if RevenueCatManager.has_planet_editor() and not RevenueCatManager.has_full_game():
		passed += 1
		print("[PASS] IAP civitus_planet_editor unlocks planet_editor entitlement")
	else:
		failed += 1
		print("[FAIL] IAP civitus_planet_editor failed")
		
	# Purchase Full Game
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_FULL_GAME)
	if RevenueCatManager.has_full_game() and RevenueCatManager.has_no_ads() and RevenueCatManager.has_planet_editor() and RevenueCatManager.has_premium_access():
		passed += 1
		print("[PASS] IAP civitus_full_game unlocks all entitlements (Full Game, No Ads, Planet Editor, Deep Space)")
	else:
		failed += 1
		print("[FAIL] IAP civitus_full_game failed")
		
	# 3. Test Restore Purchases
	RevenueCatManager.has_no_ads_license = false
	RevenueCatManager.restore_purchases()
	if RevenueCatManager.has_no_ads():
		passed += 1
		print("[PASS] Restore Purchases successfully re-synchronizes saved licenses")
	else:
		failed += 1
		print("[FAIL] Restore Purchases failed")
		
	# 4. Test Ads System & VIP Unlocking
	GameManager.expeditions_completed = 0
	RevenueCatManager.has_no_ads_license = false
	RevenueCatManager.has_full_game_license = false
	
	var ad_1 = GameManager.record_expedition_completed() # 1
	var ad_2 = GameManager.record_expedition_completed() # 2 -> should trigger ad
	if not ad_1 and ad_2:
		passed += 1
		print("[PASS] Interstitial ad triggers exactly every 2 completed worlds")
	else:
		failed += 1
		print("[FAIL] Interstitial ad trigger timing failed")
		
	# Suppress ad with No Ads license
	RevenueCatManager.has_no_ads_license = true
	var ad_3 = GameManager.record_expedition_completed() # 3
	var ad_4 = GameManager.record_expedition_completed() # 4 -> suppressed
	if not ad_3 and not ad_4:
		passed += 1
		print("[PASS] Interstitial ads are 100% suppressed when player owns No Ads license")
	else:
		failed += 1
		print("[FAIL] Interstitial ads suppression failed")
		
	# VIP Unlocking via Rewarded Ad
	GameManager.temp_unlocked_vip_levels.clear()
	RevenueCatManager.has_full_game_license = false
	RevenueCatManager.has_deep_space_license = false
	RevenueCatManager.is_dev_mode = false
	
	var is_initially_locked = not GameManager.is_vip_unlocked(4)
	GameManager.unlock_vip_temporarily(4)
	var is_now_unlocked = GameManager.is_vip_unlocked(4)
	if is_initially_locked and is_now_unlocked:
		passed += 1
		print("[PASS] Rewarded ad successfully grants temporary access to VIP sector 4")
	else:
		failed += 1
		print("[FAIL] Rewarded ad VIP unlock failed")
		
	# 5. Test Planet Editor / Modo Arquitecto Custom Planet
	var custom_planet = {
		"name": "Custom Kepler Prime",
		"level": 2,
		"type_label": "Mundo Terraformado",
		"gravity": 12.5,
		"temperature": 18.0,
		"atmosphere": 1.15,
		"has_atmosphere": true,
		"has_rings": true,
		"is_locked": false,
		"telemetry_graph": {
			"habitability": 0.90,
			"atmosphere": 0.65,
			"temperature": 0.55,
			"gravity": 0.60
		}
	}
	GameManager.select_planet(custom_planet)
	if GameManager.current_planet.get("name") == "Custom Kepler Prime" and GameManager.current_difficulty == 2:
		passed += 1
		print("[PASS] Planet Editor custom world generates and registers in GameManager correctly")
	else:
		failed += 1
		print("[FAIL] Planet Editor custom world registration failed")
		
	print("\n=======================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("=======================================================\n")
	
	quit(0 if failed == 0 else 1)
