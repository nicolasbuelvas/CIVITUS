extends Node

signal entitlement_updated(entitlement_name: String, is_active: bool)
signal purchase_completed(product_id: String)
signal purchase_failed(error_message: String)

# Entitlement identifier matching RevenueCat Dashboard
const ENTITLEMENT_DEEP_SPACE = "deep_space_license"

# Product IDs
const PRODUCT_MONTHLY_PASS = "astro_deepspace_monthly"
const PRODUCT_LIFETIME = "astro_deepspace_lifetime"

var has_deep_space_license: bool = false

func _ready() -> void:
	load_local_status()
	# Check if RevenueCat native bridge/SDK is present
	if Engine.has_singleton("Purchases"):
		init_native_revenuecat()
	else:
		print("[RevenueCatManager] Running in Standalone / Dev Mode.")

func has_premium_access() -> bool:
	return has_deep_space_license

func init_native_revenuecat() -> void:
	var purchases = Engine.get_singleton("Purchases")
	# Configured with public API key in dashboard
	print("[RevenueCatManager] Initializing native Purchases singleton...")
	# Setup listeners...

func purchase_product(product_id: String) -> void:
	print("[RevenueCatManager] Requesting purchase: ", product_id)
	# In development/editor, allow unlock testing:
	if not Engine.has_singleton("Purchases"):
		has_deep_space_license = true
		save_local_status()
		purchase_completed.emit(product_id)
		entitlement_updated.emit(ENTITLEMENT_DEEP_SPACE, true)
		return

func restore_purchases() -> void:
	print("[RevenueCatManager] Restoring purchases...")
	# Restore logic for Google Play / App Store

func save_local_status() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("auth", "deep_space_license", has_deep_space_license)
	cfg.save("user://license.cfg")

func load_local_status() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://license.cfg") == OK:
		has_deep_space_license = cfg.get_value("auth", "deep_space_license", false)
