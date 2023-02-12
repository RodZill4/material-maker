extends Button

var path : String

func todo_rename_set_name(name: String) -> void:
	$HBoxContainer/HBoxContainer/Name.text = name

func set_path(p: String) -> void:
	path = p
	if path == "":
		$HBoxContainer/Arrow.hide()
		$HBoxContainer/Path3D.hide()
	else:
		$HBoxContainer/Arrow.show()
		$HBoxContainer/Path3D.show()
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
		$HBoxContainer/Path3D.text = path
		var color = get_node("/root/MainWindow/NodeLibraryManager").get_section_color(section)
		if color != null:
			$HBoxContainer/Path3D.add_theme_color_override("font_color", color)

func set_icon(icon: Texture2D) -> void:
	$HBoxContainer/HBoxContainer/Icon.texture = icon

func _get_drag_data(_position):
	var texture_rect : TextureRect = TextureRect.new()
	texture_rect.texture = $HBoxContainer/HBoxContainer/Icon.texture
	texture_rect.scale = Vector2(0.35, 0.35)
	set_drag_preview(texture_rect)
	if path == "":
		return $HBoxContainer/HBoxContainer/Name.text
	else:
		return path+"/"+$HBoxContainer/HBoxContainer/Name.text
