extends Control

var value = null: set = set_value


signal updated(curve, old_value)

func _ready():
	set_value(MMCurve.new())

func set_value(v) -> void:
	value = v.duplicate()
	$CurveView.curve = value
	$CurveView.queue_redraw()

func _on_CurveEdit_pressed():
	var dialog = preload("res://material_maker/widgets/curve_edit/curve_dialog.tscn").instantiate()
	mm_globals.main_window.add_dialog(dialog)
	dialog.connect("curve_changed",Callable(self,"on_value_changed"))
	var new_curve = await dialog.edit_curve(value)
	if new_curve != null:
		set_value(new_curve.value)
		emit_signal("updated", new_curve.value.duplicate(), null if new_curve.value.compare(new_curve.previous_value) else new_curve.previous_value)

func on_value_changed(v) -> void:
	set_value(v)
	emit_signal("updated", v.duplicate(), null)

func _get_drag_data(_position) -> MMCurve:
	var duplicated_value = value.duplicate()
	var view = CurveView.new(duplicated_value)
	view.size = $CurveView.size
	var button = Button.new()
	button.size = size
	button.add_child(view)
	set_drag_preview(button)
	return duplicated_value

func _can_drop_data(_position, data) -> bool:
	return data is MMCurve
	

func _drop_data(_position, data) -> void:
	var old_curve : MMCurve = value
	value = data
	emit_signal("updated", value, old_curve)
