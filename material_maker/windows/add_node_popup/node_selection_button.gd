extends Button


func set_name(name: String) -> void:
	$HBoxContainer/Name.text = name


func set_path(path: String) -> void:
	$HBoxContainer/Path.text = path

	if path == "":
		$HBoxContainer/Arrow.hide()
	else:
		$HBoxContainer/Arrow.show()


func set_icon(icon: Texture) -> void:
	$HBoxContainer/Icon.texture = icon

