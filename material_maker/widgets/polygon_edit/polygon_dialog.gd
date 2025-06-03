extends Window


@export var closed : bool = true: set = set_closed
var previous_value


signal polygon_changed(polygon)
signal return_polygon(polygon)


func _ready():
	min_size = $VBoxContainer.get_combined_minimum_size()

func set_closed(c : bool = true):
	closed = c
	title = "Edit polygon" if closed else "Edit polyline"
	$VBoxContainer/EditorContainer/PolygonEditor.set_closed(closed)

func _on_CurveDialog_popup_hide():
	emit_signal("return_polygon", previous_value)

func _on_OK_pressed():
	emit_signal("return_polygon", $VBoxContainer/EditorContainer/PolygonEditor.polygon)

func _on_Cancel_pressed():
	emit_signal("return_polygon", previous_value)

func edit_polygon(polygon : MMPolygon) -> Dictionary:
	previous_value = polygon.duplicate()
	$VBoxContainer/EditorContainer/PolygonEditor.set_polygon(polygon)
	hide()
	popup_centered()
	var result = await self.return_polygon
	queue_free()
	return { value=result, previous_value=previous_value }

func _on_PolygonEditor_value_changed(value):
	emit_signal("polygon_changed", value)
