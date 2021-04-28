extends "res://material_maker/windows/node_editor/node_editor.gd"

onready var preview_editor : TextEdit = $"Sizer/Tabs/Preview"

func _ready():
	preview_editor.add_color_region("//", "", Color(0, 0.5, 0), true)

func set_model_data(data) -> void:
	.set_model_data(data)
	if data.has("preview_shader"):
		$Sizer/Tabs/Preview.text = data.preview_shader

func get_model_data() -> Dictionary:
	var data = .get_model_data()
	data.preview_shader = $Sizer/Tabs/Preview.text
	return data
