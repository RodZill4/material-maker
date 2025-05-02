extends GraphElement
class_name MMGraphCommentLine

# Single-lined comments to put in the graph

@onready var editor = %TextEditor
@onready var label = %TextLabel


var generator : MMGenCommentLine:
	set(g):
		generator = g
		label.text = generator.text.replace("\\n","\n")
		position_offset = generator.position


func do_set_position(o : Vector2) -> void:
	position_offset = o
	generator.position = o


func _on_node_selected() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property($PanelContainer, "self_modulate",
			Color(1.0,1.0,1.0,0.2), 0.4).set_trans(Tween.TRANS_CUBIC)
	_on_raise_request()


func _on_node_deselected() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property($PanelContainer, "self_modulate",
			Color(1.0,1.0,1.0,0.0),0.4).set_trans(Tween.TRANS_CUBIC)
	_on_raise_request()


func _on_text_focus_exited() -> void:
	if editor.text == "" or editor.text.strip_edges() == "":
		get_parent().remove_node(self)
		return
	editor.visible = false
	editor.mouse_filter = MOUSE_FILTER_STOP
	label.text = editor.text.replace("\\n","\n")
	label.visible = true
	generator.text = editor.text


func _on_dragged(from, to) -> void:
	_on_raise_request()
	generator.position = to


func _on_position_offset_changed() -> void:
	_on_raise_request()


func _on_raise_request() -> void:
	var parent = get_parent()
	for i in parent.get_child_count():
		var child = parent.get_child(i)
		if child == self:
			break
		if not child is MMGraphCommentLine:
			get_parent().move_child(self, i)
			break


func _on_text_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		editor.text = label.text.replace("\n","\\n")
		label.visible = false
		editor.visible = true
		editor.select_all()
		editor.grab_focus()
		accept_event()


func _on_text_text_submitted(new_text: String) -> void:
	_on_text_focus_exited()
