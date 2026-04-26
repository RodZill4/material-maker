class_name MMGraphCommentLine
extends GraphElement

# Single-lined comments to put in the graph

@onready var editor : LineEdit = %TextEditor
@onready var label : Label = %TextLabel

const LABEL_SIZES : Array[int] = [16, 48, 96]

var disable_undoredo_for_offset : bool = false

var generator : MMGenCommentLine:
	set(g):
		generator = g
		label.text = generator.text.replace("\\n", "\n")
		position_offset = generator.position
		generator.parameter_changed.connect(on_parameter_changed)
		set_label_size(generator.get_parameter("label"))

func do_set_position(o : Vector2) -> void:
	disable_undoredo_for_offset = true
	position_offset = o
	generator.position = o
	disable_undoredo_for_offset = false

func _on_node_selected() -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property($PanelContainer, "self_modulate",
			Color(1.0, 1.0, 1.0, 0.2), 0.4).set_trans(Tween.TRANS_CUBIC)

func _on_node_deselected() -> void:
	var tween : Tween = get_tree().create_tween()
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

func _input(event : InputEvent) -> void:
	if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		mm_globals.set_tip_text("#LMB#LMB: Edit label, #RMB: Set label size", 1.0, 2)
		if (event is InputEventMouseButton and event.pressed
				and event.button_index == MOUSE_BUTTON_RIGHT
				and label.visible and is_visible_in_tree()):
			accept_event()
			var menu : PopupMenu = PopupMenu.new()
			menu.add_check_item("Small label")
			menu.add_check_item("Large label")
			menu.add_check_item("Huge label")
			menu.set_item_checked(generator.get_parameter("label"), true)
			add_child(menu)
			menu.position = get_screen_transform() * get_local_mouse_position()
			menu.id_pressed.connect(on_label_context_menu)
			menu.popup_hide.connect(menu.queue_free)
			menu.popup()

func on_label_context_menu(id : int) -> void:
	var old_value = generator.get_parameter("label")
	if old_value != id and get_parent().get("undoredo") != null:
		var node_hier_name = generator.get_hier_name()
		var undo_command = { type="setparams", node=node_hier_name, params={ "label"=old_value } }
		var redo_command = { type="setparams", node=node_hier_name, params={ "label"=id } }
		get_parent().undoredo.add("Set parameter value", [ undo_command ], [ redo_command ])
	generator.set_parameter("label", id)

func on_parameter_changed(n : String, v : Variant) -> void:
	if n == "label":
		set_label_size(v)

func set_label_size(id : int) -> void:
	var new_size : int = LABEL_SIZES[id]
	label.add_theme_font_size_override("font_size", new_size)
	editor.add_theme_font_size_override("font_size", new_size)

func _on_text_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		editor.text = label.text.replace("\n", "\\n")
		label.visible = false
		editor.visible = true
		editor.select_all()
		editor.grab_focus()
		accept_event()

func _on_text_text_submitted(_new_text : String) -> void:
	_on_text_focus_exited()

func _on_minimum_size_changed() -> void:
	size = get_combined_minimum_size()
