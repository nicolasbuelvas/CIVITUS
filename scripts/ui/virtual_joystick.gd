extends Control

signal joystick_vector(vec: Vector2)

@export var max_distance: float = 60.0
@export var deadzone: float = 0.15

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var touch_id: int = -1
var center_pos: Vector2 = Vector2.ZERO
var current_output: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Center knob inside base
	center_knob()

func center_knob() -> void:
	if base and knob:
		var base_size = base.size
		var knob_size = knob.size
		center_pos = (base_size - knob_size) * 0.5
		knob.position = center_pos

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			_update_knob(event.position)
		elif not event.pressed and event.index == touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var base_center = base.global_position + base.size * 0.5
	var diff = touch_pos - base_center
	var dist = diff.length()
	var dir = diff.normalized() if dist > 0.0 else Vector2.ZERO
	
	var clamped_dist = min(dist, max_distance)
	var knob_center = base.size * 0.5 - knob.size * 0.5
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
	joystick_vector.emit(Vector2.ZERO)
	_apply_input_actions(Vector2.ZERO)

func _apply_input_actions(vec: Vector2) -> void:
	# Emulate keyboard actions for engine compatibility
	if vec.x > 0.25:
		Input.action_press("move_right", vec.x)
		Input.action_release("move_left")
	elif vec.x < -0.25:
		Input.action_press("move_left", abs(vec.x))
		Input.action_release("move_right")
	else:
		Input.action_release("move_right")
		Input.action_release("move_left")

	if vec.y > 0.25:
		Input.action_press("move_backward", vec.y)
		Input.action_release("move_forward")
	elif vec.y < -0.25:
		Input.action_press("move_forward", abs(vec.y))
		Input.action_release("move_backward")
	else:
		Input.action_release("move_backward")
		Input.action_release("move_forward")
