extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_model_item_selected(index: int) -> void:
	owner._on_Model_item_selected(index)


func _on_mesh_config_header_toggled(toggled_on: bool) -> void:
	%MeshConfigSection.visible = toggled_on
	size = Vector2()


func _on_rotation_item_selected(index: int) -> void:
	match index:
		0:
			owner.set_rotate_model_speed(0)
		1:
			owner.set_rotate_model_speed(0.01)
		2:
			owner.set_rotate_model_speed(0.05)
		3:
			owner.set_rotate_model_speed(0.1)


func _on_generate_map_header_toggled(toggled_on: bool) -> void:
	%GenerateMapSection.visible = toggled_on
	size = Vector2()
