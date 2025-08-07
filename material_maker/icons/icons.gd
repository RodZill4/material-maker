extends ImageTexture

func _init():
	var img : Image
	if FileAccess.file_exists("user://icons.svg"):
		img = Image.load_from_file("user://icons.svg")
	else:
		var texture : Texture2D = ResourceLoader.load("res://material_maker/icons/icons.svg")
		img = texture.get_image()
	set_image(img)
