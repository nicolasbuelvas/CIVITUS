extends Control
class_name VectorLander2D

# Visual representation of the Apollo-style escape capsule from the 3D spawn
var thrust_active: bool = false
var rcs_left_active: bool = false
var rcs_right_active: bool = false
var is_exploded: bool = false

var flame_time: float = 0.0
var beacon_time: float = 0.0

func _process(delta: float) -> void:
	flame_time += delta * 24.0
	beacon_time += delta * 4.0
	queue_redraw()

func set_thrust(active: bool) -> void:
	thrust_active = active

func set_rcs(left: bool, right: bool) -> void:
	rcs_left_active = left
	rcs_right_active = right

func _draw() -> void:
	if is_exploded:
		return
		
	var center = size * 0.5
	var w = 44.0
	var h = 48.0
	
	# Draw main thruster plume if active
	if thrust_active:
		var flicker = sin(flame_time) * 4.0 + randf_range(-2.0, 2.0)
		var flame_h = 32.0 + flicker
		
		# Outer orange/yellow fire
		var flame_poly = PackedVector2Array([
			center + Vector2(-9.0, h * 0.45),
			center + Vector2(9.0, h * 0.45),
			center + Vector2(0.0, h * 0.45 + flame_h)
		])
		draw_colored_polygon(flame_poly, Color(1.0, 0.45, 0.1, 0.9))
		
		# Inner white/cyan core
		var core_poly = PackedVector2Array([
			center + Vector2(-4.0, h * 0.45),
			center + Vector2(4.0, h * 0.45),
			center + Vector2(0.0, h * 0.45 + flame_h * 0.55)
		])
		draw_colored_polygon(core_poly, Color(1.0, 0.95, 0.8, 1.0))
		
	# Draw RCS plumes
	if rcs_left_active:
		var rcs_p = PackedVector2Array([
			center + Vector2(-w * 0.45, -2.0),
			center + Vector2(-w * 0.45, 6.0),
			center + Vector2(-w * 0.45 - 14.0, 2.0)
		])
		draw_colored_polygon(rcs_p, Color(0.4, 0.85, 1.0, 0.85))
		
	if rcs_right_active:
		var rcs_p = PackedVector2Array([
			center + Vector2(w * 0.45, -2.0),
			center + Vector2(w * 0.45, 6.0),
			center + Vector2(w * 0.45 + 14.0, 2.0)
		])
		draw_colored_polygon(rcs_p, Color(0.4, 0.85, 1.0, 0.85))

	# Landing gear (Left & Right legs with footpads)
	var leg_color = Color(0.45, 0.52, 0.60)
	var footpad_color = Color(0.25, 0.30, 0.38)
	# Left leg
	draw_line(center + Vector2(-12.0, h * 0.35), center + Vector2(-22.0, h * 0.55), leg_color, 3.0)
	draw_line(center + Vector2(-27.0, h * 0.55), center + Vector2(-17.0, h * 0.55), footpad_color, 4.0)
	# Right leg
	draw_line(center + Vector2(12.0, h * 0.35), center + Vector2(22.0, h * 0.55), leg_color, 3.0)
	draw_line(center + Vector2(17.0, h * 0.55), center + Vector2(27.0, h * 0.55), footpad_color, 4.0)

	# Main Capsule Body (Apollo conical/curved command module style)
	var body_points = PackedVector2Array([
		center + Vector2(0.0, -h * 0.52),         # Apex top
		center + Vector2(w * 0.32, -h * 0.30),    # Upper slope right
		center + Vector2(w * 0.46, h * 0.25),     # Lower body right
		center + Vector2(w * 0.38, h * 0.42),     # Heat shield right
		center + Vector2(-w * 0.38, h * 0.42),    # Heat shield left
		center + Vector2(-w * 0.46, h * 0.25),    # Lower body left
		center + Vector2(-w * 0.32, -h * 0.30)    # Upper slope left
	])
	draw_colored_polygon(body_points, Color(0.92, 0.94, 0.98)) # Off-white aerospace ceramic
	draw_polyline(body_points, Color(0.25, 0.32, 0.42), 1.8)  # Clean comic-style outline

	# Heat shield bottom base
	var heat_shield = PackedVector2Array([
		center + Vector2(-w * 0.38, h * 0.42),
		center + Vector2(w * 0.38, h * 0.42),
		center + Vector2(w * 0.28, h * 0.48),
		center + Vector2(-w * 0.28, h * 0.48)
	])
	draw_colored_polygon(heat_shield, Color(0.18, 0.20, 0.24))

	# Main Rocket Nozzle
	var nozzle = PackedVector2Array([
		center + Vector2(-7.0, h * 0.44),
		center + Vector2(7.0, h * 0.44),
		center + Vector2(9.0, h * 0.52),
		center + Vector2(-9.0, h * 0.52)
	])
	draw_colored_polygon(nozzle, Color(0.35, 0.40, 0.48))
	draw_polyline(nozzle, Color(0.15, 0.18, 0.22), 1.2)

	# Capsule Hatch & Visor Window
	var hatch_center = center + Vector2(0.0, -4.0)
	draw_circle(hatch_center, 9.0, Color(0.25, 0.35, 0.48)) # Outer hatch ring
	draw_circle(hatch_center, 7.0, Color(0.10, 0.55, 0.92)) # Blue cockpit glass
	# Window specular glint
	draw_circle(hatch_center + Vector2(-2.5, -2.5), 2.2, Color(0.85, 0.95, 1.0, 0.9))

	# Aerospace panel accent stripes (Yellow & Dark Grey)
	draw_line(center + Vector2(-w * 0.38, 12.0), center + Vector2(-w * 0.20, 12.0), Color(0.95, 0.75, 0.2), 2.0)
	draw_line(center + Vector2(w * 0.20, 12.0), center + Vector2(w * 0.38, 12.0), Color(0.95, 0.75, 0.2), 2.0)

	# Flashing Navigation Beacons
	var beacon_alpha = (sin(beacon_time) + 1.0) * 0.5
	# Red port beacon
	draw_circle(center + Vector2(-w * 0.44, 4.0), 2.0, Color(1.0, 0.2, 0.2, 0.4 + 0.6 * beacon_alpha))
	# Green starboard beacon
	draw_circle(center + Vector2(w * 0.44, 4.0), 2.0, Color(0.2, 1.0, 0.4, 0.4 + 0.6 * beacon_alpha))
