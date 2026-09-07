extends Control

signal joystick_vector(vec: Vector2)

@export var max_distance: float = 85.0
@export var deadzone: float = 0.12
@export var is_dynamic: bool = true

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var touch_id: int = -1
var default_base_pos: Vector2 = Vector2(80, -220)
var current_output: Vector2 = Vector2.ZERO

func _ready() -> void:
	if base:
		base.modulate.a = 0.45
		center_knob()

func center_knob() -> void:
	if base and knob:
		var base_size = base.size
		var knob_size = knob.size
		knob.position = (base_size - knob_size) * 0.5

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			if is_dynamic:
				# Reposition base center directly to the touch location
				base.global_position = event.position - base.size * 0.5
				base.modulate.a = 0.95
			center_knob()
			_update_knob(event.position)
		elif not event.pressed and event.index == touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			_update_knob(event.position)
	elif event is InputEventMouseButton:
		# Mouse debugging support for PC
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_id == -1:
				touch_id = 999
				if is_dynamic:
					base.global_position = event.position - base.size * 0.5
					base.modulate.a = 0.95
				center_knob()
				_update_knob(event.position)
			elif not event.pressed and touch_id == 999:
				_reset_joystick()
	elif event is InputEventMouseMotion and touch_id == 999:
		_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var base_center = base.global_position + base.size * 0.5
	var diff = touch_pos - base_center
	var dist = diff.length()
	var dir = diff.normalized() if dist > 0.0 else Vector2.ZERO
	
	var clamped_dist = min(dist, max_distance)
	var knob_center = (base.size - knob.size) * 0.5
	knob.position = knob_center + dir * clamped_dist
	
	var strength = clamped_dist / max_distance
	if strength < deadzone:
		current_output = Vector2.ZERO
	else:
		var remapped_strength = (strength - deadzone) / (1.0 - deadzone)
		current_output = dir * remapped_strength
	
	joystick_vector.emit(current_output)
	_apply_input_actions(current_output)

func _reset_joystick() -> void:
	touch_id = -1
	current_output = Vector2.ZERO
	center_knob()
	if base:
		base.modulate.a = 0.45
	joystick_vector.emit(Vector2.ZERO)
	_apply_input_actions(Vector2.ZERO)

func _apply_input_actions(vec: Vector2) -> void:
	# Continuous analog strength input actions
	if vec.x > 0.15:
		Input.action_press("move_right", vec.x)
		Input.action_release("move_left")
	elif vec.x < -0.15:
		Input.action_press("move_left", abs(vec.x))
		Input.action_release("move_right")
	else:
		Input.action_release("move_right")
		Input.action_release("move_left")

	# Y Axis: vec.y < -0.15 means dragged UP (Forward)
	if vec.y < -0.15:
		Input.action_press("move_forward", abs(vec.y))
		Input.action_release("move_backward")
	elif vec.y > 0.15:
		Input.action_press("move_backward", vec.y)
		Input.action_release("move_forward")
	else:
		Input.action_release("move_backward")
		Input.action_release("move_forward")
