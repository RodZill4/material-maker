extends GraphElement
class_name MMGraphCommentLine

# Single-lined comments to put in the graph

@onready var editor = %TextEditor
@onready var label = %TextLabel

var disable_undoredo_for_offset : bool = false

var generator : MMGenCommentLine:
	set(g):
		generator = g
		label.text = generator.text.replace("\\n", "\n")
		position_offset = generator.position


func do_set_position(o : Vector2) -> void:
	disable_undoredo_for_offset = true
	position_offset = o
	generator.position = o
	disable_undoredo_for_offset = false


func _on_node_selected() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property($PanelContainer, "self_modulate",
			Color(1.0, 1.0, 1.0, 0.2), 0.4).set_trans(Tween.TRANS_CUBIC)


func _on_node_deselected() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property($PanelContainer, "self_modulate",
			Color(1.0, 1.0, 1.0, 0.0), 0.4).set_trans(Tween.TRANS_CUBIC)


func _on_text_focus_exited() -> void:
	if editor.text == "" or editor.text.strip_edges() == "":
		get_parent().remove_node(self)
		return
	editor.visible = false
	label.text = editor.text.replace("\\n", "\n")
	label.visible = true
	generator.text = editor.text


func _on_dragged(_from, to) -> void:
	generator.position = to


func _on_position_offset_changed() -> void:
	if ! disable_undoredo_for_offset:
		get_parent().undoredo_move_node(generator.name, generator.position, position_offset)
		generator.set_position(position_offset)


func _on_text_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		editor.text = label.text.replace("\n", "\\n")
		label.visible = false
		editor.visible = true
		editor.select_all()
		editor.grab_focus()
		accept_event()


func _on_text_text_submitted(_new_text: String) -> void:
	_on_text_focus_exited()


func _on_minimum_size_changed() -> void:
	size = get_combined_minimum_size()
