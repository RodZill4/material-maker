class_name FloatEdit
extends Container

var float_value: float = 0.5
@export var value: float = 0.5 :
	get:
		return float_value
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

# For display. Will always show at least this many decimal places as step.
var _step_decimals := 2

@export var float_only: bool = false

var start_position: float
var last_position: float
var start_value: float
var from_lower_bound: bool = false
var from_upper_bound: bool = false
var actually_dragging: bool = false

signal value_changed(value)
signal value_changed_undo(value, merge_undo)

enum Modes {IDLE, SLIDING, EDITING, UNEDITABLE}
var mode := Modes.IDLE:
	set(m):
		mode = m
		if mode == Modes.EDITING:
			$Edit.editable = true
			$Edit.mouse_filter = MOUSE_FILTER_STOP
			$Edit.grab_focus()
			$Edit.select_all()
			$Edit.caret_column = len($Edit.text)
			$Edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
			$Slider.value = min_value
		else:
			$Edit.editable = false
			$Edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			$Edit.mouse_filter = MOUSE_FILTER_IGNORE
		update()

var editable := true:
	set(val):
		if val:
			mode = Modes.IDLE
		else:
			mode = Modes.UNEDITABLE
	get:
		return mode != Modes.UNEDITABLE


func get_value() -> Variant:
	if $Edit.text.is_valid_float():
		return float($Edit.text)
	elif float_only:
		return 0
	else:
		return $Edit.text


func set_value(v: Variant, notify := false, merge_undos := false) -> void:
	if v is int or (v is String and v.is_valid_float()):
		v = float(v)

	if v is String and float_only:
		v = min_value

	if v is float:
		float_value = v
		if get_decimal_places(v) < _step_decimals:
			$Edit.text = str(v).pad_decimals(_step_decimals)
		else:
			$Edit.text = str(v)
		if mode != Modes.EDITING:
			$Slider.value = v
		else:
			$Slider.value = min_value
		if notify:
			emit_signal("value_changed", float_value)
			emit_signal("value_changed_undo", float_value, merge_undos)

	elif v is String:
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


func _input(event:InputEvent) -> void:
	if not Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		return
	if mode == Modes.IDLE:
		if event is InputEventKey and event.is_command_or_control_pressed() and event.pressed:
			if event.keycode == KEY_C:
				DisplayServer.clipboard_set(str(float_value))
				accept_event()
			if event.keycode == KEY_V:
				set_value(DisplayServer.clipboard_get(), true)
				accept_event()


func _gui_input(event: InputEvent) -> void:
	if mode == Modes.IDLE:

		# Handle Drag-Start
		if event is InputEventMouseMotion and event.relative.length() > 0.0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if $Edit.text.is_valid_float():
				mode = Modes.SLIDING
				start_position = event.position.x
				start_value = float_value
				from_lower_bound = float_value <= min_value
				from_upper_bound = float_value >= max_value
				actually_dragging = false

		if event.is_action("ui_accept") and event.pressed:
			mode = Modes.EDITING
			accept_event()
			return

		if event is InputEventMouseButton:
			# Handle Edit-Click (on button up!)
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not event.pressed:
					mode = Modes.EDITING
					accept_event()

	if mode == Modes.SLIDING:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if actually_dragging:
				mode = Modes.IDLE
				set_value(float_value, true)
			else:
				mode = Modes.EDITING
			accept_event()

		if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_LEFT:
			last_position = event.position.x

			last_position = event.position.x

			var delta: float = last_position-start_position
			# By only setting [actually_dragging] to true after at least a 2 pixel movement,
			# we can more reliably differentiate intential mouse movements from unintentional ones.
			if abs(delta) > 2:
				actually_dragging = true
			if actually_dragging:
				var current_step := step

				if event.is_command_or_control_pressed():
					if step == 1:
						current_step *= 5
					if step < 1:
						if max_value-min_value > 50:
							current_step = 5
						elif max_value-min_value > 1:
							current_step = 1
						else:
							current_step = 0.1
				elif event.shift_pressed:
					delta *= 0.2
				elif event.alt_pressed:
					current_step *= 0.01
					delta *= 0.1


				var v: float = start_value + delta / (size.x / abs(max_value - min_value))

				if current_step != 0:
					v = snappedf(v, current_step)

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

	if mode == Modes.EDITING or mode == Modes.IDLE:
		if event is InputEventMouseButton:
			# Handle Right Click (Expression Editor)
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not float_only:
				var expression_editor: Window = load("res://material_maker/widgets/float_edit/expression_editor.tscn").instantiate()
				add_child(expression_editor)
				expression_editor.edit_parameter(
					"Expression editor - " + name,
					$Edit.text, self,
					"set_value_from_expression_editor")
				accept_event()

			# Handle CTRL+Scrolling
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



func _on_edit_focus_entered() -> void:
	$Edit.queue_redraw()
	if mode == Modes.IDLE:
		mode = Modes.EDITING


func _on_edit_focus_exited() -> void:
	$Edit.queue_redraw()
	if mode == Modes.EDITING:
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


func _notification(what):
	match what:
		NOTIFICATION_THEME_CHANGED:
			if get_theme_stylebox("clip") != get_theme_stylebox("panel"):
				add_theme_stylebox_override("panel", get_theme_stylebox("clip"))
			update()
		NOTIFICATION_DRAG_BEGIN:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		NOTIFICATION_DRAG_END:
			mouse_filter = Control.MOUSE_FILTER_STOP


func update() -> void:
	var is_hovered := Rect2(Vector2(), size).has_point(get_local_mouse_position()) or mode == Modes.SLIDING
	$Slider.add_theme_stylebox_override("fill", get_theme_stylebox("fill_hover" if is_hovered else "fill_normal"))
	$Slider.add_theme_stylebox_override("background", get_theme_stylebox("hover" if is_hovered else "normal"))

	if editable:
		$Edit.add_theme_color_override("font_uneditable_color", get_theme_color("font_color"))
	else:
		$Edit.remove_theme_color_override("font_uneditable_color")
	$Edit.queue_redraw()


func _ready() -> void:
	update()
	min_value = min_value
	max_value = max_value



func _on_mouse_entered() -> void:
	update()

func _on_mouse_exited() -> void:
	update()


func _on_edit_draw() -> void:
	var is_focused = get_viewport().gui_get_focus_owner() == self or get_viewport().gui_get_focus_owner() == $Edit
	var is_dragging = mode == Modes.SLIDING

	if is_focused or is_dragging:
		$Edit.draw_style_box(get_theme_stylebox("focus"), Rect2(Vector2(), size))
