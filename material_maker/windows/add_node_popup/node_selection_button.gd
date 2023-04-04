extends Button

var path : String

func set_node(node_name: String, node_path: String, node_icon: Texture2D) -> void:
	$HBoxContainer/HBoxContainer/Name.text = node_name
	
	path = node_path
	if path == "":
		$HBoxContainer/Arrow.hide()
		$HBoxContainer/Path.hide()
	else:
		$HBoxContainer/Arrow.show()
		$HBoxContainer/Path.show()
		var slash_position = path.find("/")
		var section : String
		if slash_position == -1:
			section = path
		else:
			section = path.left(slash_position)
			var path_elements = path.split("/")
			for i in path_elements.size():
				path_elements[i] = String(TranslationServer.translate(path_elements[i]))
			path = "/".join(path_elements)
		$HBoxContainer/Path.text = path
		var color = get_node("/root/MainWindow/NodeLibraryManager").get_section_color(section)
		if color != null:
			$HBoxContainer/Path.add_theme_color_override("font_color", color)
	
	$HBoxContainer/HBoxContainer/Icon.texture = node_icon

func _get_drag_data(_position):
	var texture_rect : TextureRect = TextureRect.new()
	texture_rect.texture = $HBoxContainer/HBoxContainer/Icon.texture
	texture_rect.scale = Vector2(0.35, 0.35)
	set_drag_preview(texture_rect)
	if path == "":
		return $HBoxContainer/HBoxContainer/Name.text
	else:
		return path+"/"+$HBoxContainer/HBoxContainer/Name.text
