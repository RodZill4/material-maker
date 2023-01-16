extends LineEdit


var parent_dialog : Object


func _on_Button_pressed():
	var expression_editor : WindowDialog = load("res://material_maker/widgets/float_edit/expression_editor.tscn").instance()
	add_child(expression_editor)
	var expression = parent_dialog.get_expression_from_output(text)
	expression_editor.edit_parameter("Expression editor", expression, self, "set_value_from_expression_editor")
	accept_event()

func set_value_from_expression_editor(v : String):
	text = v
	emit_signal("text_entered")
