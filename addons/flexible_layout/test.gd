extends Control

func _ready():
	get_window().borderless = false
	get_window().size = Vector2i(1024, 768)
	var file : FileAccess = FileAccess.open("res://addons/flexible_layout/layout.json", FileAccess.READ)
	if file:
		var layout : Dictionary = JSON.parse_string(file.get_as_text())
		$FlexibleLayout.layout(layout)

func _on_tree_exiting():
	var file : FileAccess = FileAccess.open("res://addons/flexible_layout/layout.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify($FlexibleLayout.serialize()))
		
