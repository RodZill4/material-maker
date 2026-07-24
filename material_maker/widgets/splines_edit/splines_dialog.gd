extends Window


@export var closed : bool = true: set = set_closed
var previous_value


signal splines_changed(splines)
signal return_splines(splines)


func _ready():
	min_size = $VBoxContainer.get_combined_minimum_size()

func set_closed(c : bool = true):
	closed = c
	title = "Edit Splines" if closed else "Edit Polyline"
	$VBoxContainer/EditorContainer/SplinesEditor.set_closed(closed)

func _on_CurveDialog_popup_hide():
	emit_signal("return_splines", previous_value)

func _on_OK_pressed():
	emit_signal("return_splines", $VBoxContainer/EditorContainer/SplinesEditor.splines)

func _on_Cancel_pressed():
	emit_signal("return_splines", previous_value)

func edit_splines(splines : MMSplines) -> Dictionary:
	previous_value = splines.duplicate()
	$VBoxContainer/EditorContainer/SplinesEditor.set_splines(splines)
	popup_centered()
	var result = await self.return_splines
	queue_free()
	return { value=result, previous_value=previous_value }

func _on_SplinesEditor_value_changed(value):
	emit_signal("splines_changed", value)
