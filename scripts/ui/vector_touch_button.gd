extends BaseButton
class_name VectorTouchButton

enum ButtonType {
	THRUST,
	ROTATE_LEFT,
	ROTATE_RIGHT
}

@export var button_type: ButtonType = ButtonType.THRUST

var pulse_time: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(84, 84)

func _process(delta: float) -> void:
	pulse_time += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	var radius = min(size.x, size.y) * 0.46
	var is_down = button_pressed
	
	# Outer background circle
	var bg_color = Color(0.06, 0.12, 0.20, 0.75)
	var border_color = Color(0.30, 0.65, 0.95, 0.70)
	var icon_color = Color(0.90, 0.95, 1.0, 0.95)
	
	if button_type == ButtonType.THRUST:
		bg_color = Color(0.25, 0.08, 0.04, 0.85) if not is_down else Color(0.60, 0.20, 0.05, 0.95)
		border_color = Color(1.0, 0.55, 0.18, 0.90)
		icon_color = Color(1.0, 0.90, 0.70)
	else:
		if is_down:
			bg_color = Color(0.12, 0.25, 0.42, 0.90)
			border_color = Color(0.50, 0.85, 1.0, 1.0)
			
	# Draw circular plate
	draw_circle(center, radius, bg_color)
	draw_arc(center, radius, 0, TAU, 32, border_color, 2.4)
	
	# Draw inner iconic symbols
	match button_type:
		ButtonType.THRUST:
			_draw_rocket_icon(center, is_down, icon_color)
		ButtonType.ROTATE_LEFT:
			_draw_curved_arrow(center, -1.0, is_down, icon_color)
		ButtonType.ROTATE_RIGHT:
			_draw_curved_arrow(center, 1.0, is_down, icon_color)

func _draw_rocket_icon(center: Vector2, is_down: bool, col: Color) -> void:
	var offset_y = 1.0 if is_down else 0.0
	var c = center + Vector2(0, offset_y)
	
	# Rocket body / nozzle cone
	var body = PackedVector2Array([
		c + Vector2(0.0, -18.0),   # Nose
		c + Vector2(9.0, -2.0),    # Right shoulder
		c + Vector2(6.0, 10.0),    # Right base
		c + Vector2(-6.0, 10.0),   # Left base
		c + Vector2(-9.0, -2.0)    # Left shoulder
	])
	draw_colored_polygon(body, col)
	
	# Fins
	var left_fin = PackedVector2Array([
		c + Vector2(-6.0, 2.0),
		c + Vector2(-15.0, 12.0),
		c + Vector2(-6.0, 10.0)
	])
	draw_colored_polygon(left_fin, col.darkened(0.15))
	
	var right_fin = PackedVector2Array([
		c + Vector2(6.0, 2.0),
		c + Vector2(15.0, 12.0),
		c + Vector2(6.0, 10.0)
	])
	draw_colored_polygon(right_fin, col.darkened(0.15))

	# Flame jet beneath rocket
	var flame_scale = 1.3 if is_down else 1.0
	var flame = PackedVector2Array([
		c + Vector2(-4.5, 11.0),
		c + Vector2(4.5, 11.0),
		c + Vector2(0.0, 11.0 + 13.0 * flame_scale)
	])
	draw_colored_polygon(flame, Color(1.0, 0.40, 0.05))
	
	# Inner flame core
	var core = PackedVector2Array([
		c + Vector2(-2.0, 11.0),
		c + Vector2(2.0, 11.0),
		c + Vector2(0.0, 11.0 + 7.0 * flame_scale)
	])
	draw_colored_polygon(core, Color(1.0, 0.95, 0.4))

func _draw_curved_arrow(center: Vector2, dir: float, is_down: bool, col: Color) -> void:
	var offset_y = 1.0 if is_down else 0.0
	var c = center + Vector2(0, offset_y)
	
	# Clean arc line
	var arc_radius = 18.0
	var start_angle = -PI * 0.70 if dir > 0 else -PI * 0.30
	var end_angle = 0.15 if dir > 0 else PI - 0.15
	draw_arc(c, arc_radius, start_angle, end_angle, 20, col, 3.5)
	
	# Arrowhead at arc endpoint
	var tip = c + Vector2(cos(end_angle), sin(end_angle)) * arc_radius
	var tangent = Vector2(-sin(end_angle), cos(end_angle)) * dir
	var normal = Vector2(cos(end_angle), sin(end_angle))
	
	var head = PackedVector2Array([
		tip + tangent * 6.0,
		tip - tangent * 8.0 + normal * 7.0,
		tip - tangent * 8.0 - normal * 7.0
	])
	draw_colored_polygon(head, col)
