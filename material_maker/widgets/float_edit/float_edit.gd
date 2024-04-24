extends LineEdit

var float_value : float = 0.5
@export var value : float = 0.5 :
	get:
		return float_value
	set(new_value):
		set_value(new_value)
@export var min_value : float = 0.0 : set = set_min_value
@export var max_value : float = 1.0 : set = set_max_value
@export var step : float = 0.0 : set = set_step
@export var float_only : bool = false

var sliding : bool = false
var start_position : float
var last_position : float
var start_value : float
var modifiers : int
var from_lower_bound : bool = false
var from_upper_bound : bool = false

@onready var slider = $Slider
@onready var cursor = $Slider/Cursor

signal value_changed(value)
signal value_changed_undo(value, merge_undo)

func _ready() -> void:
	do_update()

func get_value() -> String:
	return text
	
func set_value(v, notify = false) -> void:
	if v is int:
		v = float(v)
	if v is float:
		float_value = v
		text = str(v)
		do_update()
		$Slider.visible = true
		if notify:
			emit_signal("value_changed", float_value)
			emit_signal("value_changed_undo", float_value, false)
	elif v is String and !float_only:
		text = v
		$Slider.visible = false
		if notify:
			emit_signal("value_changed", v)
			emit_signal("value_changed_undo", v, false)

func set_value_from_expression_editor(v : String):
	if v.is_valid_float():
		set_value(float(v), true)
	else:
		set_value(v, true)

func set_min_value(v : float) -> void:
	min_value = v
	do_update()

func set_max_value(v : float) -> void:
	max_value = v
	do_update()

func set_step(v : float) -> void:
	step = v
	do_update()

func do_update(update_text : bool = true) -> void:
	if update_text and $Slider.visible:
		text = str(float_value)
		if cursor != null:
			if max_value != min_value:
				cursor.position.x = (clamp(float_value, min_value, max_value)-min_value)*(slider.size.x-cursor.size.x)/(max_value-min_value)
			else:
				cursor.position.x = 0

func get_modifiers(event):
	var new_modifiers = 0
	if event.shift_pressed:
		new_modifiers |= 1
	if event.is_command_or_control_pressed():
		new_modifiers |= 2
	if event.alt_pressed:
		new_modifiers |= 4
	return new_modifiers

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed() and !float_only:
		var expression_editor : Window = load("res://material_maker/widgets/float_edit/expression_editor.tscn").instantiate()
		add_child(expression_editor)
		expression_editor.edit_parameter("Expression editor - "+name, text, self, "set_value_from_expression_editor")
		accept_event()
	if !slider.visible or !sliding and !editable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if event.double_click:
				await get_tree().process_frame
				select_all()
				accept_event()
			else:
				last_position = event.position.x
				start_position = last_position
				start_value = float_value
				sliding = true
				from_lower_bound = float_value <= min_value
				from_upper_bound = float_value >= max_value
				modifiers = get_modifiers(event)
				emit_signal("value_changed_undo", float_value, false)
				editable = false
				selecting_enabled = false
		else:
			sliding = false
			editable = true
			selecting_enabled = true
	elif sliding and event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		var new_modifiers = get_modifiers(event)
		if new_modifiers != modifiers:
			start_position = last_position
			start_value = float_value
			modifiers = new_modifiers
		else:
			last_position = event.position.x
			var delta : float = last_position-start_position
			var current_step = step
			if event.is_command_or_control_pressed():
				delta *= 0.2
			elif event.shift_pressed:
				delta *= 5.0
			if event.alt_pressed:
				current_step *= 0.01
			var v : float = start_value+sign(delta)*pow(abs(delta)*0.005, 2)*abs(max_value - min_value)
			if current_step != 0:
				v = min_value+floor((v - min_value)/current_step)*current_step
			if !from_lower_bound and v < min_value:
				v = min_value
			if !from_upper_bound and v > max_value:
				v = max_value
			set_value(v)
			emit_signal("value_changed", float_value)
			emit_signal("value_changed_undo", float_value, true)
		accept_event()
	elif event is InputEventKey and !event.echo:
		match event.keycode:
			KEY_SHIFT, KEY_CTRL, KEY_ALT:
				start_position = last_position
				start_value = float_value
				modifiers = get_modifiers(event)

func _on_LineEdit_text_changed(_new_text : String) -> void:
	pass

func _on_LineEdit_text_entered(new_text : String, release = true) -> void:
	if new_text.is_valid_float():
		var new_value : float = new_text.to_float()
		if abs(float_value-new_value) > 0.00001:
			float_value = new_value
			do_update()
			emit_signal("value_changed", float_value)
			emit_signal("value_changed_undo", float_value, false)
			$Slider.visible = true
	elif float_only or new_text == "":
		do_update()
		emit_signal("value_changed", float_value)
		emit_signal("value_changed_undo", float_value, false)
		$Slider.visible = true
	else:
		emit_signal("value_changed", new_text)
		emit_signal("value_changed_undo", new_text, false)
		$Slider.visible = false
	if release:
		release_focus()

func _on_FloatEdit_focus_entered():
	select_all()

func _on_LineEdit_focus_exited() -> void:
	select(0, 0)
	_on_LineEdit_text_entered(text, false)
	select(0, 0)
