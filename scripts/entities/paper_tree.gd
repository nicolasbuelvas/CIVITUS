extends StaticBody3D

@onready var trunk: MeshInstance3D = $Trunk
@onready var foliage: MeshInstance3D = $Foliage

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	# Subtle wind wobble
	var t_offset = randf() * 10.0
	var tween = create_tween().set_loops()
	tween.tween_property(foliage, "rotation:z", 0.05, 1.8 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(foliage, "rotation:z", -0.05, 1.8 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
