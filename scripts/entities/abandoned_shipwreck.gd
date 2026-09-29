extends StaticBody3D
class_name AbandonedShipwreck

signal scavenged(loot_dict: Dictionary)

@export var wreck_type: int = 0 # 0: Scout Miner, 1: Heavy Cargo, 2: Transport Pod
@export var is_looted: bool = false
var is_scavenged: bool:
	get: return is_looted
	set(val): is_looted = val

@onready var beacon_light: OmniLight3D = get_node_or_null("BeaconLight")
@onready var smoke_particles: CPUParticles3D = get_node_or_null("SmokeParticles")
@onready var spark_particles: CPUParticles3D = get_node_or_null("SparkParticles")
@onready var label_3d: Label3D = get_node_or_null("Label3D")
@onready var mesh_root: Node3D = get_node_or_null("MeshRoot")

var pulse_time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("abandoned_ships")
	add_to_group("abandoned_shipwrecks")
	add_to_group("interactable")
	add_to_group("structures")
	
	rng.randomize()
	_setup_visuals()
	_update_beacon_state()

func _process(delta: float) -> void:
	if not is_looted and is_instance_valid(beacon_light):
		pulse_time += delta
		# SOS distress beacon pulse pattern (3 short, 3 long, 3 short)
		var t_mod = fmod(pulse_time, 3.2)
		var is_flash = (t_mod < 0.2) or (t_mod > 0.4 and t_mod < 0.6) or (t_mod > 0.8 and t_mod < 1.0) or (t_mod > 1.4 and t_mod < 2.0)
		beacon_light.light_energy = 2.8 if is_flash else 0.4

func _setup_visuals() -> void:
	if not mesh_root:
		mesh_root = get_node_or_null("MeshRoot")
	if not mesh_root:
		return
		
	# Select 3D model asset if not already populated
	if mesh_root.get_child_count() == 0:
		var model_paths = [
			"res://assets/models/craft_miner.glb",
			"res://assets/models/craft_cargoA.glb",
			"res://assets/models/craft_cargoB.glb"
		]
		var path = model_paths[clamp(wreck_type, 0, model_paths.size() - 1)]
		var scene_res = load(path)
		if scene_res:
			var inst = scene_res.instantiate()
			inst.name = "ShipModel"
			mesh_root.add_child(inst)
			_apply_weathered_materials(inst)

func _apply_weathered_materials(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			for surface_idx in range(child.get_surface_override_material_count()):
				var mat = child.get_surface_override_material(surface_idx)
				if not mat:
					mat = child.mesh.surface_get_material(surface_idx) if child.mesh else null
				if mat is StandardMaterial3D:
					var weathered = mat.duplicate()
					# Weathered / scorched hull patina
					weathered.albedo_color = weathered.albedo_color.lerp(Color(0.25, 0.22, 0.20), 0.55)
					weathered.roughness = clampf(weathered.roughness + 0.35, 0.5, 0.95)
					weathered.metallic = clampf(weathered.metallic * 0.7, 0.1, 0.8)
					child.set_surface_override_material(surface_idx, weathered)
		_apply_weathered_materials(child)

func _update_beacon_state() -> void:
	if is_looted:
		if beacon_light:
			beacon_light.light_color = Color(0.2, 0.85, 0.35) # Stable standby green
			beacon_light.light_energy = 0.8
		if smoke_particles:
			smoke_particles.emitting = false
		if spark_particles:
			spark_particles.emitting = false
		if label_3d:
			label_3d.text = "[ NAVE EXPLORADA // SALVAMENTO COMPLETADO ]"
			label_3d.modulate = Color(0.5, 0.6, 0.7, 0.6)
	else:
		if beacon_light:
			beacon_light.light_color = Color(1.0, 0.72, 0.18) # Amber distress emergency
		if smoke_particles:
			smoke_particles.emitting = true
		if spark_particles:
			spark_particles.emitting = true
		if label_3d:
			label_3d.text = "[ RESTOS ESPACIALES // EXPLORAR CARGA ]"
			label_3d.modulate = Color(1.0, 0.75, 0.2, 0.9)

func get_interaction_type() -> String:
	return "" if is_looted else "scavenge"

func scavenge(player: Node3D = null) -> Dictionary:
	if is_looted:
		return {}
		
	is_looted = true
	_update_beacon_state()
	
	var loot = {}
	var roll = rng.randf()
	var toast_msg = ""
	
	if roll < 0.70:
		# 70% Common: Oxygen supply canister
		var count = 1 if rng.randf() < 0.65 else 2
		loot["item"] = "o2_canister"
		loot["count"] = count
		if is_instance_valid(GameManager) and GameManager.crafting:
			GameManager.crafting.add_item("o2_canister", count)
		toast_msg = "[ RESTOS RECUPERADOS: +%d BOTELLA DE O₂ ]" % count if count == 1 else "[ RESTOS RECUPERADOS: +%d BOTELLAS DE O₂ ]" % count
	else:
		# 30% Rare: Valuable tech resources or tools
		var rare_roll = rng.randf()
		if rare_roll < 0.35:
			var amt = rng.randi_range(3, 5)
			loot["resource"] = "silicon"
			loot["count"] = amt
			if is_instance_valid(GameManager) and GameManager.crafting:
				GameManager.crafting.add_resource("silicon", amt)
			toast_msg = "[ COMPONENTES RECUPERADOS: +%d SILICIO ]" % amt
		elif rare_roll < 0.65:
			var amt = rng.randi_range(2, 4)
			loot["resource"] = "uranium"
			loot["count"] = amt
			if is_instance_valid(GameManager) and GameManager.crafting:
				GameManager.crafting.add_resource("uranium", amt)
			toast_msg = "[ COMBUSTIBLE CUÁNTICO: +%d URANIO ]" % amt
		elif rare_roll < 0.85:
			var amt = rng.randi_range(4, 7)
			loot["resource"] = "iron"
			loot["count"] = amt
			if is_instance_valid(GameManager) and GameManager.crafting:
				GameManager.crafting.add_resource("iron", amt)
			toast_msg = "[ ALEACIÓN ESTRUCTURAL: +%d HIERRO ]" % amt
		else:
			loot["item"] = "repair_kit_basic"
			loot["count"] = 1
			if is_instance_valid(GameManager) and GameManager.crafting:
				GameManager.crafting.add_item("repair_kit_basic", 1)
			toast_msg = "[ HERRAMIENTA RECUPERADA: +1 KIT DE REPARACIÓN ]"
			
	if is_instance_valid(AudioManager):
		AudioManager.play("collect")
		
	# Display notification on HUD
	if is_instance_valid(GameManager):
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_status_toast"):
			hud.show_status_toast(toast_msg)
		elif hud and hud.has_method("show_toast"):
			hud.show_toast(toast_msg)
			
	scavenged.emit(loot)
	return loot

func get_scanner_data() -> Dictionary:
	return {
		"name": "TRANSPORTE VARADO [S-09]",
		"purity": "CARGA DISPONIBLE" if not is_looted else "DESVALIJADO",
		"density": "INTEGRIDAD 18%",
		"desc": "Cápsula de exploración estrellada en la superficie."
	}
