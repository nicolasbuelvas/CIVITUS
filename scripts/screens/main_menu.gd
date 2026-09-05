extends Control

@onready var planet_pivot: Node3D = $SubViewportContainer/SubViewport/World3D/PlanetPivot
@onready var difficulty_selector: OptionButton = $MenuLayer/MainPanel/VBox/DiffContainer/DifficultyOption
@onready var planet_name_label: Label = $MenuLayer/MainPanel/VBox/InfoCard/VBox/PlanetName
@onready var planet_details_label: Label = $MenuLayer/MainPanel/VBox/InfoCard/VBox/PlanetDetails
@onready var coords_badge: Label = $MenuLayer/MainPanel/VBox/InfoCard/VBox/CoordsBadge

@onready var start_button: Button = $MenuLayer/MainPanel/VBox/Buttons/StartBtn
@onready var sandbox_button: Button = $MenuLayer/MainPanel/VBox/Buttons/SandboxBtn
@onready var store_button: Button = $MenuLayer/MainPanel/VBox/Buttons/StoreBtn

# Modals
@onready var paywall_modal: Panel = $MenuLayer/PaywallModal
@onready var paywall_title: Label = $MenuLayer/PaywallModal/VBox/Title
@onready var paywall_desc: Label = $MenuLayer/PaywallModal/VBox/Desc
@onready var sandbox_modal: Panel = $MenuLayer/SandboxModal

@onready var grav_slider: HSlider = $MenuLayer/SandboxModal/VBox/GravBox/HSlider
@onready var temp_slider: HSlider = $MenuLayer/SandboxModal/VBox/TempBox/HSlider
@onready var grav_val_label: Label = $MenuLayer/SandboxModal/VBox/GravBox/ValLabel
@onready var temp_val_label: Label = $MenuLayer/SandboxModal/VBox/TempBox/ValLabel

func _ready() -> void:
	paywall_modal.visible = false
	sandbox_modal.visible = false
	
	setup_difficulty_dropdown()
	update_planet_preview()
	
	difficulty_selector.item_selected.connect(_on_difficulty_selected)
	start_button.pressed.connect(_on_start_pressed)
	sandbox_button.pressed.connect(_on_sandbox_pressed)
	store_button.pressed.connect(_on_store_pressed)

func _process(delta: float) -> void:
	# Cinematic slow planetary rotation (KSP / Waste of Space menu style)
	if planet_pivot:
		planet_pivot.rotation.y += delta * 0.15
		planet_pivot.rotation.x = sin(Time.get_ticks_msec() / 4000.0) * 0.08

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
		difficulty_selector.selected = GameManager.current_difficulty
		open_paywall("Sectores Extremos 4 y 5 Bloqueados", "Desbloquea el abismo estelar y los desafíos mortales con la Licencia de Espacio Profundo.")
		return
		
	GameManager.set_difficulty(idx as GameManager.Difficulty)
	update_planet_preview()
	AudioManager.play("click")

func update_planet_preview() -> void:
	var p = GameManager.current_planet
	planet_name_label.text = str(p.name)
	coords_badge.text = str(p.get("coords_str", ""))
	planet_details_label.text = "Gravedad: %.1f m/s² | Temp: %.0f°C | Atmósfera: %.1f atm\nRadiación: %.2f rad/s | Órbita: %.2f AU" % [
		p.gravity, p.temperature, p.atmosphere, p.radiation, p.get("orbit_au", 1.0)
	]

func _on_start_pressed() -> void:
	AudioManager.play("click")
	GameManager.start_expedition()

func _on_sandbox_pressed() -> void:
	if not RevenueCatManager.has_premium_access():
		open_paywall("Modo Arquitecto / Editor Bloqueado", "Personaliza la física, gravedad de 0.1G a 25G, temperaturas extremas y biomas procedurales.")
		return
	sandbox_modal.visible = true
	AudioManager.play("click")

func _on_store_pressed() -> void:
	open_paywall("Tienda Estelar (RevenueCat)", "Apoya el desarrollo de CIVITUS y desbloquea el Modo Arquitecto y Niveles 4-5.")
	AudioManager.play("click")

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
	AudioManager.play("click")
