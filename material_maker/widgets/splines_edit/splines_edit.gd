extends Control


var value = null : set = set_value


signal updated(splines, old_value)


func _ready():
	set_value(MMSplines.new())

func set_value(v) -> void:
	value = v.duplicate()
	$SplinesView.splines = value
	$SplinesView.queue_redraw()

func _on_SplinesEdit_pressed():
	var dialog = preload("res://material_maker/widgets/splines_edit/splines_dialog.tscn").instantiate()
	mm_globals.main_window.add_dialog(dialog)
	dialog.splines_changed.connect(self.on_value_changed)
	var new_splines = await dialog.edit_splines(value)
	if new_splines != null:
		set_value(new_splines.value)
		emit_signal("updated", new_splines.value.duplicate(), null if new_splines.value.compare(new_splines.previous_value) else new_splines.previous_value)

func on_value_changed(v) -> void:
	set_value(v)
	emit_signal("updated", v.duplicate(), null)

func _get_drag_data(_position):
	var duplicated_value = value.duplicate()
	var view = SplinesView.new(duplicated_value)
	view.size = $SplinesView.size
	view.position -= Vector2(15,15)
	var button = Button.new()
	button.size = size
	button.add_child(view)
	set_drag_preview(button)
	return duplicated_value

func _can_drop_data(_position, data) -> bool:
	return data is MMSplines

func _drop_data(_position, data) -> void:
	var old_splines : MMSplines = value
	value = data
	emit_signal("updated", value, old_splines)
