tool
extends LineEdit
class_name MMFloatEdit

export var value : float = 0.5 setget set_value
export var min_value : float = 0.0 setget set_min_value
export var max_value : float = 1.0 setget set_max_value
export var step : float = 0.0 setget set_step

var sliding : bool = false
var start_position : float
var start_value : float
var from_lower_bound : bool = false
var from_upper_bound : bool = false

onready var slider = $Slider
onready var cursor = $Slider/Cursor

signal value_changed

func _ready() -> void:
	do_update()

func set_value(v : float) -> void:
	value = v
	do_update()

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
	if update_text:
		text = str(value)
	if cursor != null:
		cursor.rect_position.x = (clamp(value, min_value, max_value)-min_value)*(slider.rect_size.x-cursor.rect_size.x)/(max_value-min_value)

func _on_LineEdit_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.is_pressed():
			start_position = event.position.x
			start_value = value
			sliding = true
			from_lower_bound = value <= min_value
			from_upper_bound = value >= max_value
		else:
			sliding = false
	elif sliding and event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_LEFT:
		var delta : float = event.position.x-start_position
		var v : float = start_value+sign(delta)*pow(abs(delta)*0.005, 2)*abs(max_value - min_value)
		if step != 0:
			v = min_value+floor((v - min_value)/step)*step
		if !from_lower_bound and v < min_value:
			v = min_value
		if !from_upper_bound and v > max_value:
			v = max_value
		set_value(v)
		select(0, 0)
		emit_signal("value_changed", value)

func _on_LineEdit_text_changed(new_text : String) -> void:
	if new_text.is_valid_float():
		value = new_text.to_float()
		do_update(false)

func _on_LineEdit_text_entered(new_text : String) -> void:
	if new_text.is_valid_float():
		value = new_text.to_float()
	do_update()
	emit_signal("value_changed", value)

func _on_LineEdit_focus_exited() -> void:
	do_update()
	emit_signal("value_changed", value)
