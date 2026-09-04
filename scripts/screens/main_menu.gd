extends Control

@onready var difficulty_selector: OptionButton = $MainPanel/VBox/DiffContainer/DifficultyOption
@onready var planet_preview_label: Label = $MainPanel/VBox/PreviewLabel
@onready var start_button: Button = $MainPanel/VBox/StartExpeditionBtn
@onready var editor_button: Button = $MainPanel/VBox/EditPlanetBtn
@onready var store_button: Button = $MainPanel/VBox/StoreBtn

# Modals
@onready var paywall_modal: Panel = $PaywallModal
@onready var paywall_title: Label = $PaywallModal/VBox/Title
@onready var paywall_desc: Label = $PaywallModal/VBox/Desc
@onready var sandbox_modal: Panel = $SandboxModal

# Sandbox inputs
@onready var grav_slider: HSlider = $SandboxModal/VBox/GravBox/HSlider
@onready var temp_slider: HSlider = $SandboxModal/VBox/TempBox/HSlider
@onready var grav_val_label: Label = $SandboxModal/VBox/GravBox/ValLabel
@onready var temp_val_label: Label = $SandboxModal/VBox/TempBox/ValLabel

func _ready() -> void:
	paywall_modal.visible = false
	sandbox_modal.visible = false
	
	setup_difficulty_dropdown()
	update_planet_preview()
	
	difficulty_selector.item_selected.connect(_on_difficulty_selected)
	start_button.pressed.connect(_on_start_pressed)
	editor_button.pressed.connect(_on_editor_pressed)
	store_button.pressed.connect(_on_store_pressed)

func setup_difficulty_dropdown() -> void:
	difficulty_selector.clear()
	difficulty_selector.add_item("Nivel 0: Terranova (Tierra - Muy Seguro)", 0)
	difficulty_selector.add_item("Nivel 1: Ares Prime (Marte - Moderado)", 1)
	difficulty_selector.add_item("Nivel 2: Vesper Acid (Venus - Inseguro)", 2)
	difficulty_selector.add_item("Nivel 3: Cryo-Void (Criogénico - Peligroso)", 3)
	difficulty_selector.add_item("⭐ Nivel 4: Abyssal Singularity (Extremo - PRO)", 4)
	difficulty_selector.add_item("💀 Nivel 5: Tartarus Hell-Star (Mortal - PRO)", 5)
	difficulty_selector.selected = GameManager.current_difficulty

func _on_difficulty_selected(idx: int) -> void:
	if idx >= 4 and not RevenueCatManager.has_premium_access():
		# Revert selection and trigger paywall
		difficulty_selector.selected = GameManager.current_difficulty
		open_paywall("Niveles Extremos 4 y 5 Bloqueados", "Desbloquea el abismo estelar y los desafíos mortales con la Licencia de Espacio Profundo.")
		return
		
	GameManager.set_difficulty(idx as GameManager.Difficulty)
	update_planet_preview()

func update_planet_preview() -> void:
	var p = GameManager.current_planet
	planet_preview_label.text = "Planeta: %s\nGravedad: %.1f m/s² | Temp: %.0f°C | Atmósfera: %.1f atm\nRadiación: %.2f rad/s | Cuota: %d Cristales" % [
		p.name, p.gravity, p.temperature, p.atmosphere, p.radiation, GameManager.player_stats.target_minerals
	]

func _on_start_pressed() -> void:
	GameManager.start_expedition()

func _on_editor_pressed() -> void:
	if not RevenueCatManager.has_premium_access():
		open_paywall("Modo Arquitecto / Editor Bloqueado", "Personaliza la física, gravedad de 0.1G a 25G, temperaturas extremas y biomas procedurales ilimitados.")
		return
	sandbox_modal.visible = true

func _on_store_pressed() -> void:
	open_paywall("Tienda de Expedición Estelar", "Apoya el desarrollo de AstroStranded y desbloquea contenido infinito.")

func open_paywall(title: String, desc: String) -> void:
	paywall_title.text = title
	paywall_desc.text = desc
	paywall_modal.visible = true

func _on_buy_monthly_pressed() -> void:
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_MONTHLY_PASS)
	paywall_modal.visible = false
	setup_difficulty_dropdown()

func _on_buy_lifetime_pressed() -> void:
	RevenueCatManager.purchase_product(RevenueCatManager.PRODUCT_LIFETIME)
	paywall_modal.visible = false
	setup_difficulty_dropdown()

func _on_close_paywall_pressed() -> void:
	paywall_modal.visible = false

func _on_grav_slider_value_changed(val: float) -> void:
	grav_val_label.text = "%.1f m/s²" % val
	GameManager.current_planet["gravity"] = val

func _on_temp_slider_value_changed(val: float) -> void:
	temp_val_label.text = "%.0f °C" % val
	GameManager.current_planet["temperature"] = val

func _on_apply_sandbox_pressed() -> void:
	GameManager.is_sandbox = true
	GameManager.current_planet["name"] = "Sector Personalizado (Sandbox)"
	update_planet_preview()
	sandbox_modal.visible = false
