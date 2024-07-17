extends Container

var float_value: float = 0.5
@export var value: float = 0.5 :
	set(new_value):
		set_value(new_value)

@export var min_value: float = 0.0 :
	set(v):
		min_value = v
		$Slider.min_value = v

@export var max_value: float = 1.0 :
	set(v):
		max_value = v
		$Slider.max_value = v

@export var step: float = 0.0 :
	set(v):
		step = v
		_step_decimals = get_decimal_places(v)
		$Slider.step = v

# For display. Will always show at least as many decimal places as step.
var _step_decimals := 2

@export var float_only: bool = false

var start_position: float
var last_position: float
var start_value: float
var modifiers: int
var from_lower_bound: bool = false
var from_upper_bound: bool = false

@onready var slider = $Slider
@onready var cursor = $Slider/Cursor

signal value_changed(value)
signal value_changed_undo(value, merge_undo)

enum Modes {IDLE, SLIDING, EDITING}
var mode := Modes.IDLE:
	set(m):
		mode = m
		if mode == Modes.EDITING:
			$Edit.mouse_filter = MOUSE_FILTER_STOP
			$Edit.grab_focus()
			$Edit.select_all()
			$Edit.caret_column = len($Edit.text)
			$Edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
			$Slider.value = min_value
		else:
			$Edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			$Edit.mouse_filter = MOUSE_FILTER_IGNORE
			grab_focus()


func get_value() -> String:
	return $Edit.text


func set_value(v: Variant, notify := false, merge_undos := false) -> void:
	if v is int:
		v = float(v)
	
	if v is float:
		float_value = v
		if get_decimal_places(v) < _step_decimals:
			$Edit.text = str(v).pad_decimals(_step_decimals)
		else:
			$Edit.text = str(v)
		$Slider.value = v
		if notify:
			emit_signal("value_changed", float_value)
			emit_signal("value_changed_undo", float_value, merge_undos)

	elif v is String and not float_only:
		if v.is_valid_float():
			if get_decimal_places(float(v)) < _step_decimals:
				v = v.pad_decimals(_step_decimals)
			$Slider.value = float(v)
		else:
			$Slider.value = min_value
		$Edit.text = v
		if notify:
			emit_signal("value_changed", v)
			emit_signal("value_changed_undo", v, merge_undos)


func set_value_from_expression_editor(v: String) -> void:
	if v.is_valid_float():
		set_value(float(v), true)
	else:
		set_value(v, true)


func get_modifiers(event:InputEvent) -> int:
	var new_modifiers = 0
	if event.shift_pressed:
		new_modifiers |= 1
	if event.is_command_or_control_pressed():
		new_modifiers |= 2
	if event.alt_pressed:
		new_modifiers |= 4
	return new_modifiers


func _gui_input(event: InputEvent) -> void:
	if mode == Modes.IDLE:
		# Handle Drag-Start
		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if $Edit.text.is_valid_float():
				mode = Modes.SLIDING
				start_position = event.position.x
				start_value = float_value
				from_lower_bound = float_value <= min_value
				from_upper_bound = float_value >= max_value
				modifiers = get_modifiers(event)

		if event is InputEventMouseButton:
			# Handle Edit-Click (on button up!)
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not event.pressed:
					mode = Modes.EDITING
					accept_event()
		
			if event.is_command_or_control_pressed() and $Edit.text.is_valid_float() and event.pressed:
				var amount := step
				if is_equal_approx(step, 0.01):
					if event.shift_pressed:
						amount = 0.01
					else:
						amount = 0.1
					
				if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					set_value(max(float($Edit.text)-amount, min_value), true, true)
					accept_event()
				elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
					set_value(min(float($Edit.text)+amount, max_value), true, true)
					accept_event()
					


	if mode == Modes.SLIDING:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			mode = Modes.IDLE
			set_value(float_value, true)
			accept_event()

		if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_LEFT:
			last_position = event.position.x

			last_position = event.position.x

			var delta: float = last_position-start_position
			var current_step := step

			if event.is_command_or_control_pressed():
				delta *= 2
			elif event.shift_pressed:
				delta *= 0.2
			if event.alt_pressed:
				current_step *= 0.01

			var v: float = start_value + delta / (size.x / abs(max_value - min_value))

			if current_step != 0:
				v = min_value + floor((v - min_value)/current_step) * current_step

			if from_lower_bound and v > min_value:
				from_lower_bound = false

			if from_upper_bound and v < max_value:
				from_upper_bound = false

			if not from_lower_bound and v < min_value:
				v = min_value

			if not from_upper_bound and v > max_value:
				v = max_value

			set_value(v, true, true)
			accept_event()
	
	if mode == Modes.EDITING:
		if event.is_action("ui_accept"):
			set_value($Edit.text)
			mode = Modes.IDLE

	if mode == Modes.EDITING or mode == Modes.IDLE:
		if event is InputEventMouseButton:
			# Handle Right Click (Expression Editor)
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and !float_only:
				var expression_editor: Window = load("res://material_maker/widgets/float_edit/expression_editor.tscn").instantiate()
				add_child(expression_editor)
				expression_editor.edit_parameter(
					"Expression editor - " + name,
					$Edit.text, self,
					"set_value_from_expression_editor")
				accept_event()



func _on_edit_focus_exited() -> void:
	_on_edit_text_submitted($Edit.text)


func _on_edit_text_submitted(new_text: String) -> void:
	if not mode == Modes.EDITING:
		return

	mode = Modes.IDLE

	if new_text.is_valid_float():
		var new_value: float = new_text.to_float()
		if abs(float_value-new_value) > 0.00001:
			float_value = new_value
			set_value(float_value, true)
		else:
			set_value(float_value)
	elif float_only or new_text == "":
		set_value(float_value, true)
	else:
		set_value(new_text, true)


func get_decimal_places(v: float) -> int:
	return (str(v)+".").split(".")[1].length()
