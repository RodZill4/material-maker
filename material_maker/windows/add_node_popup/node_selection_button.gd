extends Button


func set_name(name: String) -> void:
	$HBoxContainer/HBoxContainer/Name.text = name

func set_path(path: String) -> void:
	$HBoxContainer/Path.text = path
	$HBoxContainer/Path.text = path

	if path == "":
		$HBoxContainer/Arrow.hide()
	else:
		$HBoxContainer/Arrow.show()
		var slash_position = path.find("/")
		var section : String
		if slash_position == -1:
			section = path
		else:
			section = path.left(slash_position)
		var color = get_node("/root/MainWindow/NodeLibraryManager").get_section_color(section)
		if color != null:
			$HBoxContainer/Path.add_color_override("font_color", color)


func set_icon(icon: Texture) -> void:
	$HBoxContainer/HBoxContainer/Icon.texture = icon
