extends Node

signal entitlement_updated(entitlement_name: String, is_active: bool)
signal purchase_completed(product_id: String)
signal purchase_failed(error_message: String)
signal purchases_restored(success: bool)

# Entitlement identifiers matching RevenueCat Dashboard
const ENTITLEMENT_NO_ADS = "no_ads"
const ENTITLEMENT_FULL_GAME = "full_game"
const ENTITLEMENT_PLANET_EDITOR = "planet_editor"
const ENTITLEMENT_DEEP_SPACE = "deep_space_license"

# Product IDs
const PRODUCT_NO_ADS = "civitus_no_ads"                 # $0.99 -> grants no_ads
const PRODUCT_FULL_GAME = "civitus_full_game"           # $2.99 -> grants full_game, no_ads, deep_space_license, planet_editor
const PRODUCT_PLANET_EDITOR = "civitus_planet_editor"   # $1.99 -> grants planet_editor

# Backwards compatibility aliases
const PRODUCT_MONTHLY_PASS = "astro_deepspace_monthly"
const PRODUCT_LIFETIME = "astro_deepspace_lifetime"

var has_no_ads_license: bool = false
var has_full_game_license: bool = false
var has_planet_editor_license: bool = false
var has_deep_space_license: bool = false
var is_dev_mode: bool = false

const REVENUECAT_PUBLIC_API_KEY = "test_HMpYIEhyCGifYHUCJfwbYiuBcsK"
# Secret key is optionally read from local environment variable for headless CI/testing, never hardcoded in public repository
var REVENUECAT_SECRET_API_KEY: String = OS.get_environment("REVENUECAT_SECRET_API_KEY")

var http_client_node: HTTPRequest = null
var current_app_user_id: String = "civitus_player_desktop"

func _ready() -> void:
	load_local_status()
	http_client_node = HTTPRequest.new()
	add_child(http_client_node)
	http_client_node.request_completed.connect(_on_http_request_completed)

	# Check if RevenueCat native bridge/SDK is present
	if Engine.has_singleton("Purchases"):
		init_native_revenuecat()
	else:
		print("[RevenueCatManager] Standalone Desktop Mode - Cloud Sync with Live RevenueCat Server...")
		sync_with_revenuecat_server()

func has_no_ads() -> bool:
	return has_no_ads_license or has_full_game_license

func has_full_game() -> bool:
	return has_full_game_license

func has_planet_editor() -> bool:
	return has_planet_editor_license or has_full_game_license or is_dev_mode

func has_premium_access() -> bool:
	return has_full_game_license or has_deep_space_license or is_dev_mode

func init_native_revenuecat() -> void:
	var purchases = Engine.get_singleton("Purchases")
	print("[RevenueCatManager] Initializing native Purchases singleton...")
	if purchases.has_method("init_revenuecat"):
		purchases.init_revenuecat(REVENUECAT_PUBLIC_API_KEY)
	if purchases.has_signal("purchases_restored"):
		purchases.connect("purchases_restored", Callable(self, "_on_native_purchases_restored"))
	if purchases.has_signal("customer_info_updated"):
		purchases.connect("customer_info_updated", Callable(self, "_on_native_customer_info_updated"))
	if purchases.has_signal("purchase_completed"):
		purchases.connect("purchase_completed", Callable(self, "_on_native_purchase_completed"))
	if purchases.has_signal("purchase_failed"):
		purchases.connect("purchase_failed", Callable(self, "_on_native_purchase_failed"))

func purchase_product(product_id: String) -> void:
	print("[RevenueCatManager] Requesting purchase: ", product_id)
	if not Engine.has_singleton("Purchases"):
		_apply_purchase(product_id)
		return
	
	var purchases = Engine.get_singleton("Purchases")
	if purchases.has_method("purchaseProduct"):
		purchases.purchaseProduct(product_id)
	elif purchases.has_method("purchase_product"):
		purchases.purchase_product(product_id)
	elif purchases.has_method("purchasePackage"):
		purchases.purchasePackage(product_id)
	else:
		push_warning("[RevenueCatManager] Native purchase method not found, applying in dev mode.")
		_apply_purchase(product_id)

func _apply_purchase(product_id: String) -> void:
	var effective_id = product_id
	if product_id == PRODUCT_LIFETIME or product_id == "astro_deepspace_lifetime":
		effective_id = PRODUCT_FULL_GAME
	
	match effective_id:
		PRODUCT_NO_ADS:
			has_no_ads_license = true
			save_local_status()
			purchase_completed.emit(product_id)
			entitlement_updated.emit(ENTITLEMENT_NO_ADS, true)
			_grant_promotional_entitlement_remote(ENTITLEMENT_NO_ADS)
		PRODUCT_PLANET_EDITOR:
			has_planet_editor_license = true
			save_local_status()
			purchase_completed.emit(product_id)
			entitlement_updated.emit(ENTITLEMENT_PLANET_EDITOR, true)
			_grant_promotional_entitlement_remote(ENTITLEMENT_PLANET_EDITOR)
		PRODUCT_FULL_GAME:
			has_full_game_license = true
			has_no_ads_license = true
			has_planet_editor_license = true
			has_deep_space_license = true
			save_local_status()
			purchase_completed.emit(product_id)
			entitlement_updated.emit(ENTITLEMENT_FULL_GAME, true)
			entitlement_updated.emit(ENTITLEMENT_NO_ADS, true)
			entitlement_updated.emit(ENTITLEMENT_DEEP_SPACE, true)
			entitlement_updated.emit(ENTITLEMENT_PLANET_EDITOR, true)
			_grant_promotional_entitlement_remote(ENTITLEMENT_FULL_GAME)
			_grant_promotional_entitlement_remote(ENTITLEMENT_NO_ADS)
			_grant_promotional_entitlement_remote(ENTITLEMENT_PLANET_EDITOR)
		PRODUCT_MONTHLY_PASS, "astro_deepspace_monthly":
			has_deep_space_license = true
			save_local_status()
			purchase_completed.emit(product_id)
			entitlement_updated.emit(ENTITLEMENT_DEEP_SPACE, true)
			_grant_promotional_entitlement_remote(ENTITLEMENT_DEEP_SPACE)
		_:
			purchase_completed.emit(product_id)

func restore_purchases() -> void:
	print("[RevenueCatManager] Restoring purchases...")
	if Engine.has_singleton("Purchases"):
		var purchases = Engine.get_singleton("Purchases")
		if purchases.has_method("restorePurchases"):
			purchases.restorePurchases()
		elif purchases.has_method("syncPurchases"):
			purchases.syncPurchases()
		elif purchases.has_method("restore_purchases"):
			purchases.restore_purchases()
		elif purchases.has_method("sync_purchases"):
			purchases.sync_purchases()
		else:
			var success = load_local_status()
			purchases_restored.emit(success)
	else:
		var success = load_local_status()
		purchases_restored.emit(success)

func update_from_customer_info(customer_info: Dictionary) -> void:
	var entitlements = customer_info.get("entitlements", {})
	var active = entitlements.get("active", {}) if entitlements is Dictionary else {}
	
	if active.has(ENTITLEMENT_FULL_GAME) or active.has("full_game"):
		has_full_game_license = true
		has_no_ads_license = true
		has_planet_editor_license = true
		has_deep_space_license = true
	if active.has(ENTITLEMENT_NO_ADS) or active.has("no_ads"):
		has_no_ads_license = true
	if active.has(ENTITLEMENT_PLANET_EDITOR) or active.has("planet_editor"):
		has_planet_editor_license = true
	if active.has(ENTITLEMENT_DEEP_SPACE) or active.has("deep_space_license"):
		has_deep_space_license = true
	
	save_local_status()
	entitlement_updated.emit(ENTITLEMENT_NO_ADS, has_no_ads())
	entitlement_updated.emit(ENTITLEMENT_FULL_GAME, has_full_game())
	entitlement_updated.emit(ENTITLEMENT_PLANET_EDITOR, has_planet_editor())
	entitlement_updated.emit(ENTITLEMENT_DEEP_SPACE, has_premium_access())

func _on_native_purchases_restored(result = null) -> void:
	print("[RevenueCatManager] Native purchases restored callback received.")
	if result is Dictionary:
		update_from_customer_info(result)
		purchases_restored.emit(true)
	elif result is bool:
		purchases_restored.emit(result)
	else:
		load_local_status()
		purchases_restored.emit(true)

func _on_native_customer_info_updated(customer_info) -> void:
	print("[RevenueCatManager] Native customer info updated.")
	if customer_info is Dictionary:
		update_from_customer_info(customer_info)

func _on_native_purchase_completed(product_id: String, customer_info = null) -> void:
	print("[RevenueCatManager] Native purchase completed: ", product_id)
	if customer_info is Dictionary:
		update_from_customer_info(customer_info)
	else:
		_apply_purchase(product_id)
	purchase_completed.emit(product_id)

func _on_native_purchase_failed(error_message: String) -> void:
	print("[RevenueCatManager] Native purchase failed: ", error_message)
	purchase_failed.emit(error_message)

func save_local_status() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("auth", "no_ads", has_no_ads_license)
	cfg.set_value("auth", "full_game", has_full_game_license)
	cfg.set_value("auth", "planet_editor", has_planet_editor_license)
	cfg.set_value("auth", "deep_space_license", has_deep_space_license)
	var err = cfg.save("user://license.cfg")
	if err != OK:
		push_error("[RevenueCatManager] Failed to save license.cfg: %s" % err)

func load_local_status() -> bool:
	var cfg = ConfigFile.new()
	if cfg.load("user://license.cfg") == OK:
		has_no_ads_license = cfg.get_value("auth", "no_ads", false)
		has_full_game_license = cfg.get_value("auth", "full_game", false)
		has_planet_editor_license = cfg.get_value("auth", "planet_editor", false)
		has_deep_space_license = cfg.get_value("auth", "deep_space_license", false)
		return true
	return false

# ----------------- Live RevenueCat REST API Sync -----------------

func sync_with_revenuecat_server() -> void:
	if not http_client_node or not is_inside_tree():
		return
	var url = "https://api.revenuecat.com/v1/subscribers/%s" % current_app_user_id
	var headers = [
		"Authorization: Bearer " + REVENUECAT_SECRET_API_KEY
	]
	print("[RevenueCatManager] Requesting live customer info from RevenueCat cloud...")
	http_client_node.request(url, headers, HTTPClient.METHOD_GET)

func _grant_promotional_entitlement_remote(ent_name: String) -> void:
	if not is_inside_tree() or REVENUECAT_SECRET_API_KEY.is_empty():
		return
	var hr = HTTPRequest.new()
	add_child(hr)
	hr.request_completed.connect(func(_res, code, _hdrs, body):
		if code == 200 or code == 201:
			var json_str = body.get_string_from_utf8()
			var parse_res = JSON.parse_string(json_str)
			if parse_res is Dictionary and parse_res.has("subscriber"):
				print("[RevenueCatManager] Cloud promotional grant confirmed for: ", ent_name)
		hr.queue_free()
	)
	var url = "https://api.revenuecat.com/v1/subscribers/%s/entitlements/%s/promotional" % [current_app_user_id, ent_name]
	var headers = [
		"Authorization: *** " + REVENUECAT_SECRET_API_KEY,
		"Content-Type: application/json"
	]
	var body = JSON.stringify({"duration": "lifetime"})
	print("[RevenueCatManager] Syncing entitlement '%s' to RevenueCat cloud..." % ent_name)
	hr.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_http_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200 and response_code != 201:
		print("[RevenueCatManager] HTTP response code: %d (Offline or dev sandbox)" % response_code)
		return
	
	var json_str = body.get_string_from_utf8()
	var parse_res = JSON.parse_string(json_str)
	if parse_res is Dictionary and parse_res.has("subscriber"):
		var sub = parse_res["subscriber"]
		var ents = sub.get("entitlements", {})
		print("[RevenueCatManager] RevenueCat Cloud Sync OK! Remote Entitlements: ", ents.keys())
		if ents.has("full_game"):
			has_full_game_license = true
			has_no_ads_license = true
			has_planet_editor_license = true
			has_deep_space_license = true
		if ents.has("no_ads"):
			has_no_ads_license = true
		if ents.has("planet_editor"):
			has_planet_editor_license = true
		if ents.has("deep_space_license"):
			has_deep_space_license = true
		save_local_status()
		purchases_restored.emit(true)
