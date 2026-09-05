extends StaticBody3D

enum OreType { IRON, COPPER, SILICON, URANIUM }

@export var ore_type: OreType = OreType.IRON
@export var yield_amount: int = 3
@export var max_health: float = 2.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var current_health: float = 2.0

func _ready() -> void:
	collision_layer = 2 # Mining layer
	collision_mask = 0
	current_health = max_health
	_setup_material()

func _setup_material() -> void:
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.8
	var tex_name = "ore_iron"
	match ore_type:
		OreType.IRON:
			tex_name = "ore_iron"
		OreType.COPPER:
			tex_name = "ore_copper"
		OreType.SILICON:
			tex_name = "ore_silicon"
		OreType.URANIUM:
			tex_name = "ore_uranium"
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.9, 0.4)
			mat.emission_energy_multiplier = 0.6
			
	var tex_path = "res://assets/textures/%s.png" % tex_name
	if ResourceLoader.exists(tex_path):
		mat.albedo_texture = load(tex_path)
	mesh_instance.material_override = mat

func mine_tick(delta: float) -> bool:
	current_health -= delta
	# Slight shake
	mesh_instance.position.x = randf_range(-0.06, 0.06)
	mesh_instance.position.z = randf_range(-0.06, 0.06)
	
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
	AudioManager.play("collect", 1.1)
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.15)
	tween.tween_callback(queue_free)
