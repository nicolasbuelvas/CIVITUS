extends Node

signal rewarded_ad_completed(reward_type: String, amount: int)
signal rewarded_ad_failed()
signal interstitial_completed()

var is_native_ads_available: bool = false
var native_ads = null

func _ready() -> void:
	if Engine.has_singleton("GodotAds"):
		native_ads = Engine.get_singleton("GodotAds")
		is_native_ads_available = true
		print("[AdManager] Native GodotAds singleton detected.")
		_connect_signals()
		if native_ads.has_method("init_ads"):
			native_ads.init_ads()
	else:
		print("[AdManager] Running in Standalone / Diegetic Mode.")

func _connect_signals() -> void:
	if not native_ads:
		return
	if native_ads.has_signal("rewarded_completed"):
		native_ads.connect("rewarded_completed", Callable(self, "_on_native_rewarded_completed"))
	if native_ads.has_signal("rewarded_failed_to_load"):
		native_ads.connect("rewarded_failed_to_load", Callable(self, "_on_native_rewarded_failed"))
	if native_ads.has_signal("interstitial_dismissed"):
		native_ads.connect("interstitial_dismissed", Callable(self, "_on_native_interstitial_dismissed"))

var active_ad_overlay: CanvasLayer = null

func show_rewarded_ad(fallback_callable: Callable = Callable()) -> void:
	if is_native_ads_available and native_ads and native_ads.has_method("is_rewarded_ready") and native_ads.is_rewarded_ready():
		print("[AdManager] Showing native rewarded ad...")
		native_ads.show_rewarded()
	else:
		print("[AdManager] Displaying in-game diegetic rewarded transmission overlay.")
		_show_diegetic_ad_overlay(true, fallback_callable)

func show_interstitial_ad(fallback_callable: Callable = Callable()) -> void:
	var rcm = get_node_or_null("/root/RevenueCatManager")
	if rcm and rcm.has_no_ads():
		print("[AdManager] Interstitial suppressed: Player owns No Ads.")
		interstitial_completed.emit()
		return

	if is_native_ads_available and native_ads and native_ads.has_method("is_interstitial_ready") and native_ads.is_interstitial_ready():
		print("[AdManager] Showing native interstitial...")
		native_ads.show_interstitial()
	else:
		print("[AdManager] Displaying in-game diegetic interstitial transmission overlay.")
		_show_diegetic_ad_overlay(false, fallback_callable)

func _show_diegetic_ad_overlay(is_rewarded: bool, fallback_callable: Callable = Callable()) -> void:
	if active_ad_overlay:
		active_ad_overlay.queue_free()
		active_ad_overlay = null

	var layer = CanvasLayer.new()
	layer.layer = 150
	active_ad_overlay = layer

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.08, 0.94)
	layer.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 260)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.14, 0.98)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.2, 0.85, 1.0) if is_rewarded else Color(0.96, 0.66, 0.16)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var top_badge = Label.new()
	top_badge.text = "[ RED DE TELEMETRÍA ORBITAL CIVITUS ]"
	top_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_badge.add_theme_font_size_override("font_size", 11)
	top_badge.modulate = Color(0.2, 0.85, 1.0) if is_rewarded else Color(0.96, 0.66, 0.16)
	vbox.add_child(top_badge)

	var title = Label.new()
	title.text = "TRANSMISIÓN PATROCINADA EN CURSO" if is_rewarded else "TRANSMISIÓN COMERCIAL DE SECTOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color.WHITE
	vbox.add_child(title)

	var body_desc = Label.new()
	if is_rewarded:
		body_desc.text = "Patrocinador: CIVITUS FOUNDER EDITION\nDesbloquea el salto hiperespacial, el editor de planetas y elimina todos los anuncios. Recompensa por sintonizar: +50 Luna Coins."
	else:
		body_desc.text = "Transmisión comercial de sector profundo.\n(Nota: Adquirir la licencia 'Sin Anuncios' en la Tienda suprime todas las transmisiones publicitarias de por vida)."
	body_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_desc.add_theme_font_size_override("font_size", 12)
	body_desc.modulate = Color(0.75, 0.82, 0.90)
	vbox.add_child(body_desc)

	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 10)
	progress_bar.show_percentage = false
	progress_bar.value = 100.0
	vbox.add_child(progress_bar)

	var action_btn = Button.new()
	action_btn.custom_minimum_size = Vector2(220, 38)
	action_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_btn.text = "RECLAMAR RECOMPENSA (+50 COINS)" if is_rewarded else "CONTINUAR EXPEDICIÓN"
	action_btn.add_theme_font_size_override("font_size", 12)
	
	var btn_sb = StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.08, 0.22, 0.14) if is_rewarded else Color(0.12, 0.18, 0.25)
	btn_sb.border_width_left = 1
	btn_sb.border_width_top = 1
	btn_sb.border_width_right = 1
	btn_sb.border_width_bottom = 1
	btn_sb.border_color = Color(0.2, 0.85, 0.4) if is_rewarded else Color(0.2, 0.75, 1.0)
	btn_sb.corner_radius_top_left = 6
	btn_sb.corner_radius_top_right = 6
	btn_sb.corner_radius_bottom_right = 6
	btn_sb.corner_radius_bottom_left = 6
	action_btn.add_theme_stylebox_override("normal", btn_sb)
	action_btn.add_theme_stylebox_override("hover", btn_sb)
	action_btn.add_theme_stylebox_override("pressed", btn_sb)
	action_btn.modulate = Color(0.3, 0.95, 0.5) if is_rewarded else Color(0.7, 0.9, 1.0)
	vbox.add_child(action_btn)

	action_btn.pressed.connect(func():
		var am = Engine.get_main_loop().root.get_node_or_null("AudioManager") if Engine.get_main_loop() else null
		if am: am.play("click")
		if active_ad_overlay:
			active_ad_overlay.queue_free()
			active_ad_overlay = null
		if is_rewarded:
			if fallback_callable.is_valid():
				fallback_callable.call()
			else:
				rewarded_ad_completed.emit("luna_coins", 50)
		else:
			if fallback_callable.is_valid():
				fallback_callable.call()
			else:
				interstitial_completed.emit()
	)

	add_child(layer)

func _on_native_rewarded_completed(type: String, amount: int) -> void:
	print("[AdManager] Native reward earned: ", amount, " ", type)
	rewarded_ad_completed.emit(type, amount)

func _on_native_rewarded_failed(err: String) -> void:
	print("[AdManager] Native reward failed: ", err)
	rewarded_ad_failed.emit()

func _on_native_interstitial_dismissed() -> void:
	print("[AdManager] Native interstitial dismissed.")
	interstitial_completed.emit()
