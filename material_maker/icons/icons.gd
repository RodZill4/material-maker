extends ImageTexture

func _init():
	var image : Image
	if FileAccess.file_exists("user://icons.svg"):
		image = Image.load_from_file("user://icons.svg")
	else:
		var texture : Texture2D = ResourceLoader.load("res://material_maker/icons/icons.svg")
		image = texture.get_image()
	set_image(image)
