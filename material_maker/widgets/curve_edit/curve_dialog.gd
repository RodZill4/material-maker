extends WindowDialog

var previous_value

signal curve_changed(curve)
signal return_curve(curve)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_CurveDialog_popup_hide():
	emit_signal("return_curve", null)

func _on_OK_pressed():
	emit_signal("return_curve", $VBoxContainer/EditorContainer/CurveEditor.curve)

func _on_Cancel_pressed():
	emit_signal("return_curve", previous_value)

func edit_curve(curve : MMCurve) -> Array:
	previous_value = curve.duplicate()
	$VBoxContainer/EditorContainer/CurveEditor.set_curve(curve)
	popup_centered()
	var result = yield(self, "return_curve")
	queue_free()
	return result

func _on_CurveEditor_value_changed(value):
	emit_signal("curve_changed", value)
