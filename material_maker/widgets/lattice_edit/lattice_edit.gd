extends Control

@export var closed : bool = true: set = set_closed
var value = null: set = set_value


signal updated(lattice, old_value)


func _ready():
	set_value(MMLattice.new())

func set_closed(c : bool = true):
	closed = c
	$LatticeView.set_closed(c)

func set_value(v) -> void:
	value = v.duplicate()
	$LatticeView.lattice = value
	$LatticeView.queue_redraw()

func _on_LatticeEdit_pressed():
	var dialog = preload("res://material_maker/widgets/lattice_edit/lattice_dialog.tscn").instantiate()
	dialog.set_closed(closed)
	mm_globals.main_window.add_dialog(dialog)
	dialog.lattice_changed.connect(self.on_value_changed)
	var new_lattice = await dialog.edit_lattice(value)
	if new_lattice != null:
		set_value(new_lattice.value)
		emit_signal("updated", new_lattice.value.duplicate(), null if new_lattice.value.compare(new_lattice.previous_value) else new_lattice.previous_value)

func on_value_changed(v) -> void:
	set_value(v)
	emit_signal("updated", v.duplicate(), null)

func _get_drag_data(_position):
	var duplicated_value = value.duplicate()
	var view = LatticeView.new(duplicated_value)
	view.size = $LatticeView.size
	view.position -= Vector2(15,15)
	var button = Button.new()
	button.size = size
	button.add_child(view)
	set_drag_preview(button)
	return duplicated_value

func _can_drop_data(_position, data) -> bool:
	return data is MMLattice

func _drop_data(_position, data) -> void:
	var old_lattice : MMLattice = value
	value = data
	emit_signal("updated", value, old_lattice)
