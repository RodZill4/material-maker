extends Window


@export var closed : bool = true: set = set_closed
var previous_value


signal lattice_changed(lattice)
signal return_lattice(lattice)


func _ready():
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	min_size = $VBoxContainer.get_combined_minimum_size() * content_scale_factor

func set_closed(c : bool = true):
	closed = c
	title = "Edit lattice" if closed else "Edit polyline"
	$VBoxContainer/EditorContainer/LatticeEditor.set_closed(closed)

func _on_CurveDialog_popup_hide():
	emit_signal("return_lattice", previous_value)

func _on_OK_pressed():
	emit_signal("return_lattice", $VBoxContainer/EditorContainer/LatticeEditor.lattice)

func _on_Cancel_pressed():
	emit_signal("return_lattice", previous_value)

func edit_lattice(lattice : MMLattice) -> Dictionary:
	previous_value = lattice.duplicate()
	$VBoxContainer/EditorContainer/LatticeEditor.set_lattice(lattice)
	hide()
	popup_centered()
	var result = await self.return_lattice
	queue_free()
	return { value=result, previous_value=previous_value }

func _on_LatticeEditor_value_changed(value):
	emit_signal("lattice_changed", value)
