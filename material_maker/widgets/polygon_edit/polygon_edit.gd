extends Control

@export var closed : bool = true: set = set_closed
var value = null: set = set_value


signal updated(polygon, old_value)


func _ready():
	set_value(MMPolygon.new())

func set_closed(c : bool = true):
	closed = c
	$PolygonView.set_closed(c)

func set_value(v) -> void:
	value = v.duplicate()
	$PolygonView.polygon = value
	$PolygonView.queue_redraw()

func _on_PolygonEdit_pressed():
	var dialog = preload("res://material_maker/widgets/polygon_edit/polygon_dialog.tscn").instantiate()
	dialog.content_scale_factor = mm_globals.ui_scale_factor()
	dialog.min_size = Vector2(500, 500) * dialog.content_scale_factor
	dialog.set_closed(closed)
	mm_globals.main_window.add_dialog(dialog)
	dialog.polygon_changed.connect(self.on_value_changed)
	var new_polygon = await dialog.edit_polygon(value)
	if new_polygon != null:
		set_value(new_polygon.value)
		emit_signal("updated", new_polygon.value.duplicate(), null if new_polygon.value.compare(new_polygon.previous_value) else new_polygon.previous_value)

func on_value_changed(v) -> void:
	set_value(v)
	emit_signal("updated", v.duplicate(), null)

func _get_drag_data(_position):
	var duplicated_value = value.duplicate()
	var view = PolygonView.new(duplicated_value)
	view.set_closed($PolygonView.closed)
	view.size = $PolygonView.size
	view.position -= Vector2(15,15)
	var button = Button.new()
	button.size = size
	button.add_child(view)
	set_drag_preview(button)
	return duplicated_value

func _can_drop_data(_position, data) -> bool:
	return data is MMPolygon

func _drop_data(_position, data) -> void:
	var old_polygon : MMPolygon = value
	value = data
	emit_signal("updated", value, old_polygon)
