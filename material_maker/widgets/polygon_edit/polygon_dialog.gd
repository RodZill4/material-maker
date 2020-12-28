extends WindowDialog

var previous_value

signal polygon_changed(polygon)
signal return_polygon(polygon)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_CurveDialog_popup_hide():
	emit_signal("return_polygon", null)

func _on_OK_pressed():
	emit_signal("return_polygon", $VBoxContainer/EditorContainer/PolygonEditor.polygon)

func _on_Cancel_pressed():
	emit_signal("return_polygon", previous_value)

func edit_polygon(polygon : MMPolygon) -> Array:
	previous_value = polygon.duplicate()
	$VBoxContainer/EditorContainer/PolygonEditor.set_polygon(polygon)
	popup_centered()
	var result = yield(self, "return_polygon")
	queue_free()
	return result

func _on_PolygonEditor_value_changed(value):
	emit_signal("polygon_changed", value)
