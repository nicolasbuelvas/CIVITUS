@tool
extends BaseButton
class_name HyperdriveProgressWidget

@export var progress: float = 0.0: # 0.0 to 1.0
	set(val):
		progress = clamp(val, 0.0, 1.0)
		queue_redraw()

@export var text: String = "":
	set(val):
		text = val
		queue_redraw()

@export var ring_color: Color = Color(0.96, 0.66, 0.16, 1.0)
@export var bg_color: Color = Color(0.09, 0.08, 0.16, 0.95)

var pulse_time: float = 0.0
var is_hovered: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(176, 46)
	focus_mode = Control.FOCUS_NONE

func _ready() -> void:
	mouse_entered.connect(func(): is_hovered = true; queue_redraw())
	mouse_exited.connect(func(): is_hovered = false; queue_redraw())
	button_down.connect(func():
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08)
		pivot_offset = size * 0.5
	)
	button_up.connect(func():
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
		pivot_offset = size * 0.5
	)

func _process(delta: float) -> void:
	pulse_time += delta * 3.5
	if progress >= 1.0 or is_hovered:
		queue_redraw()

func _draw() -> void:
	var h = size.y
	var w = size.x
	var radius = h * 0.5 - 2.0
	var icon_center = Vector2(radius + 4.0, h * 0.5)
	var is_ready = progress >= 1.0
	
	# 1. Main Rounded Capsule Background (Stadium Shape)
	var capsule_rect = Rect2(Vector2(2, 2), Vector2(w - 4, h - 4))
	var capsule_bg = bg_color if not is_hovered else bg_color.lightened(0.12)
	var border_col = ring_color
	if is_ready:
		var pulse = (sin(pulse_time * 1.5) + 1.0) * 0.5
		border_col = border_col.lerp(Color(0.3, 1.0, 0.5, 1.0), pulse)
	elif is_hovered:
		border_col = border_col.lightened(0.2)
		
	var sb = StyleBoxFlat.new()
	sb.bg_color = capsule_bg
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(h * 0.5))
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 3
	draw_style_box(sb, capsule_rect)
	
	# 2. Left Icon Disc (Circular Badge)
	draw_circle(icon_center, radius, Color(0.06, 0.05, 0.12))
	draw_arc(icon_center, radius, 0, TAU, 32, ring_color, 2.2)
	
	# Draw the signature Rocket icon inside the circular badge
	_draw_rocket_icon(icon_center, radius / 22.0)
	
	# 3. Text: "HYPERDRIVE" (strictly untranslated, same in all languages)
	var font = ThemeDB.fallback_font
	var title_font_size = 11
	var title_text = "HYPERDRIVE"
	var title_pos = Vector2(icon_center.x + radius + 10.0, 16.0)
	draw_string(font, title_pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size, Color(0.95, 0.85, 0.45))
	
	# Percentage Text (e.g. "45%" or "READY")
	var pct_font_size = 11
	var pct_text = "%d%%" % int(progress * 100) if not is_ready else "READY"
	var pct_color = Color(0.3, 1.0, 0.5) if is_ready else Color(0.9, 0.95, 1.0)
	var pct_str_w = font.get_string_size(pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, pct_font_size).x
	var pct_pos = Vector2(w - pct_str_w - 24.0, 16.0)
	draw_string(font, pct_pos, pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, pct_font_size, pct_color)
	
	# 4. Progress Bar Track & Fill
	var bar_x = icon_center.x + radius + 8.0
	var bar_y = 23.0
	var bar_w = w - bar_x - 24.0
	var bar_h = 10.0
	var bar_rect = Rect2(bar_x, bar_y, bar_w, bar_h)
	
	# Track background (rounded)
	var track_sb = StyleBoxFlat.new()
	track_sb.bg_color = Color(0.04, 0.04, 0.08, 0.9)
	track_sb.border_color = Color(0.35, 0.28, 0.18, 0.85)
	track_sb.set_border_width_all(1)
	track_sb.set_corner_radius_all(5)
	draw_style_box(track_sb, bar_rect)
	
	# Fill Bar
	if progress > 0.001:
		var fill_w = maxf(6.0, bar_w * progress)
		var fill_rect = Rect2(bar_x + 1, bar_y + 1, fill_w - 2, bar_h - 2)
		var fill_col = Color(0.2, 0.85, 1.0).lerp(Color(1.0, 0.78, 0.2), progress)
		if is_ready:
			fill_col = Color(0.25, 1.0, 0.45)
		var fill_sb = StyleBoxFlat.new()
		fill_sb.bg_color = fill_col
		fill_sb.set_corner_radius_all(4)
		draw_style_box(fill_sb, fill_rect)
		
		# Glowing top highlight
		draw_line(Vector2(bar_x + 3, bar_y + 2), Vector2(bar_x + fill_w - 4, bar_y + 2), Color(1.0, 1.0, 1.0, 0.6), 1.2)

func _draw_rocket_icon(c: Vector2, s: float) -> void:
	var white = Color(0.96, 0.96, 1.0)
	var red = Color(0.91, 0.25, 0.21)
	var yellow = Color(0.98, 0.76, 0.16)
	
	# Red Diamond Cockpit
	var diamond = PackedVector2Array([
		c + Vector2(0.0, -12.0) * s,
		c + Vector2(2.5, -6.0) * s,
		c + Vector2(0.0, -2.0) * s,
		c + Vector2(-2.5, -6.0) * s
	])
	draw_colored_polygon(diamond, red)
	
	# White Fuselage
	var fuselage = PackedVector2Array([
		c + Vector2(0.0, -7.0) * s,
		c + Vector2(4.0, -1.0) * s,
		c + Vector2(3.0, 6.0) * s,
		c + Vector2(-3.0, 6.0) * s,
		c + Vector2(-4.0, -1.0) * s
	])
	draw_colored_polygon(fuselage, white)
	
	# Fins
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-3.5, 0.0) * s,
		c + Vector2(-9.0, 5.5) * s,
		c + Vector2(-3.0, 5.5) * s
	]), red)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(3.5, 0.0) * s,
		c + Vector2(9.0, 5.5) * s,
		c + Vector2(3.0, 5.5) * s
	]), red)
	
	# Yellow flame
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-2.5, 6.0) * s,
		c + Vector2(2.5, 6.0) * s,
		c + Vector2(0.0, 11.5) * s
	]), yellow)
