extends Window

var previous_value

signal curve_changed(curve)
signal return_curve(curve)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_CurveDialog_popup_hide():
	emit_signal("return_curve", previous_value)

func _on_OK_pressed():
	emit_signal("return_curve", $VBoxContainer/EditorContainer/CurveEditor.curve)

func _on_Cancel_pressed():
	emit_signal("return_curve", previous_value)

func edit_curve(curve : MMCurve) -> Dictionary:
	previous_value = curve.duplicate()
	$VBoxContainer/EditorContainer/CurveEditor.set_curve(curve)
	popup_centered()
	var result = await self.return_curve
	queue_free()
	return { value=result, previous_value=previous_value }

func _on_CurveEditor_value_changed(value):
	emit_signal("curve_changed", value)

func _on_Invert_pressed() -> void:
	var old_curve = $VBoxContainer/EditorContainer/CurveEditor.curve
	var new_curve = MMCurve.new()
	new_curve.clear()
	for p in old_curve.points:
		new_curve.add_point(p.p.x, 1.0 - p.p.y, -p.ls, -p.rs)
	
	$VBoxContainer/EditorContainer/CurveEditor.set_curve(new_curve)
