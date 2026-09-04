extends StaticBody3D

@export var mineral_value: int = 5
@export var is_rare_gold: bool = false

@onready var sprite: Sprite3D = $Sprite3D
var base_y: float = 0.0
var time_offset: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	base_y = position.y
	time_offset = randf() * 10.0
	if is_rare_gold:
		mineral_value = 15
		sprite.texture = load("res://assets/sprites/crystal_gold.png")

func _process(delta: float) -> void:
	# Subtle floating bobbing animation
	var t = Time.get_ticks_msec() / 1000.0 + time_offset
	sprite.position.y = 0.6 + sin(t * 3.0) * 0.08
	# Subtle paper tilt
	sprite.rotation.z = sin(t * 2.0) * 0.05

func mine() -> void:
	# Shrink & pop effect
	collision_layer = 0
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", Vector3.ZERO, 0.18)
	tween.tween_callback(queue_free)
