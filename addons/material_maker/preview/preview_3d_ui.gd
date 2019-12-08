tool
extends HBoxContainer

signal model_selected(id)
signal environment_selected(id)
signal rotate_toggled(b)
signal background_toggled(b)

func set_models(model_list : Array) -> void:
	$Model.clear()
	for m in model_list:
		$Model.add_item(m)
	call_deferred("_on_Model_item_selected", 0)

func set_environments(environment_list : Array) -> void:
	$Environment.clear()
	for e in environment_list:
		$Environment.add_item(e)
	call_deferred("_on_Environment_item_selected", 0)

func rotation_cancelled() -> void:
	$Rotate.pressed = false

func _on_Model_item_selected(ID) -> void:
	emit_signal("model_selected", ID)

func _on_Environment_item_selected(ID) -> void:
	emit_signal("environment_selected", ID)

func _on_Rotate_toggled(button_pressed) -> void:
	emit_signal("rotate_toggled", button_pressed)

func _on_Background_toggled(button_pressed) -> void:
	emit_signal("background_toggled", button_pressed)
