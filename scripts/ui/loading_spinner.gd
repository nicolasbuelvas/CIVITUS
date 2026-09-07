extends Control
class_name LoadingSpinner

@export var radius: float = 38.0
@export var thickness: float = 4.0
@export var spin_speed: float = 4.5
@export var arc_color: Color = Color(0.25, 0.85, 1.0)
@export var track_color: Color = Color(0.12, 0.20, 0.32, 0.5)

var current_angle: float = 0.0

func _process(delta: float) -> void:
	current_angle += spin_speed * delta
	if current_angle > TAU:
		current_angle -= TAU
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	
	# Background track ring
	draw_arc(center, radius, 0.0, TAU, 48, track_color, thickness, true)
	
	# Spinning arc
	var arc_len = PI * 0.85
	var start_a = current_angle
	var end_a = current_angle + arc_len
	draw_arc(center, radius, start_a, end_a, 32, arc_color, thickness, true)
	
	# Glowing tip head
	var tip_pos = center + Vector2(cos(end_a), sin(end_a)) * radius
	draw_circle(tip_pos, thickness * 1.3, arc_color)
	draw_circle(tip_pos, thickness * 2.8, Color(arc_color.r, arc_color.g, arc_color.b, 0.25))
