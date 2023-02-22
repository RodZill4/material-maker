extends Control

var value = null : set = set_value


signal updated(curve, old_value)


func _ready():
	set_value(MMCurve.new())

func set_value(v) -> void:
	value = v.duplicate()
	$CurveView.curve = value
	$CurveView.queue_redraw()

func _on_CurveEdit_pressed():
	var dialog = preload("res://material_maker/widgets/curve_edit/curve_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.connect("curve_changed",Callable(self,"on_value_changed"))
	var new_curve = await dialog.edit_curve(value)
	if new_curve != null:
		set_value(new_curve.value)
		emit_signal("updated", new_curve.value.duplicate(), null if new_curve.value.compare(new_curve.previous_value) else new_curve.previous_value)

func on_value_changed(v) -> void:
	set_value(v)
	emit_signal("updated", v.duplicate(), null)
