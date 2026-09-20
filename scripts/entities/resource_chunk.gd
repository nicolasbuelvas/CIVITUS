extends StaticBody3D

enum OreType { IRON, COPPER, SILICON, URANIUM }

@export var ore_type: OreType = OreType.IRON
@export var yield_amount: int = 3
@export var max_health: float = 1.2

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = get_node_or_null("Label3D")

var current_health: float = 1.2
var ore_color: Color = Color(0.85, 0.55, 0.25)
var ore_label_text: String = "HIERRO"

func _ready() -> void:
	collision_layer = 2 # Mining layer
	collision_mask = 0
	current_health = max_health
	_setup_material()

func _setup_material() -> void:
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.55
	mat.metallic = 0.65
	
	match ore_type:
		OreType.IRON:
			ore_label_text = "HIERRO" if GameManager.current_language == "es" else "IRON"
			ore_color = Color(0.82, 0.85, 0.92)
			mat.metallic = 0.85
			mat.roughness = 0.4
		OreType.COPPER:
			ore_label_text = "COBRE" if GameManager.current_language == "es" else "COPPER"
			ore_color = Color(0.95, 0.52, 0.22)
			mat.metallic = 0.80
			mat.roughness = 0.35
		OreType.SILICON:
			ore_label_text = "SILICIO" if GameManager.current_language == "es" else "SILICON"
			ore_color = Color(0.35, 0.85, 1.0)
			mat.metallic = 0.3
			mat.roughness = 0.2
			mat.emission_enabled = true
			mat.emission = ore_color * 0.4
		OreType.URANIUM:
			ore_label_text = "URANIO" if GameManager.current_language == "es" else "URANIUM"
			ore_color = Color(0.25, 0.95, 0.40)
			mat.emission_enabled = true
			mat.emission = ore_color * 0.8
			mat.roughness = 0.3
			
	mat.albedo_color = ore_color
	if mesh_instance:
		mesh_instance.material_override = mat
		
	if label_3d:
		label_3d.text = "[ %s ]" % ore_label_text
		label_3d.modulate = ore_color

func mine_tick(delta: float) -> bool:
	current_health -= delta
	
	# Responsive mineral fracture shake
	if mesh_instance:
		mesh_instance.position.x = randf_range(-0.08, 0.08)
		mesh_instance.position.z = randf_range(-0.08, 0.08)
		
	if label_3d:
		var pct = int(clampf(current_health / max_health, 0.0, 1.0) * 100.0)
		label_3d.text = "[ %s %d%% ]" % [ore_label_text, pct]
	
	if current_health <= 0.0:
		break_and_harvest()
		return true
	return false

func break_and_harvest() -> void:
	collision_layer = 0
	var res_key = "iron"
	match ore_type:
		OreType.IRON: res_key = "iron"
		OreType.COPPER: res_key = "copper"
		OreType.SILICON: res_key = "silicon"
		OreType.URANIUM: res_key = "uranium"
		
	GameManager.crafting.add_resource(res_key, yield_amount)
	AudioManager.play("collect", 1.2, 2.0)
	
	if label_3d:
		label_3d.text = "+%d %s!" % [yield_amount, ore_label_text]
		label_3d.modulate = Color(1.0, 1.0, 0.4)
		var tw_l = create_tween()
		tw_l.tween_property(label_3d, "position:y", 2.2, 0.6)
		tw_l.parallel().tween_property(label_3d, "modulate:a", 0.0, 0.6)
	
	if mesh_instance:
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.2)
		tw.tween_callback(queue_free)
	else:
		queue_free()
