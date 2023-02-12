extends ImageTexture

func _init():
	print("Initializing icons")
	var image : Image
	if FileAccess.file_exists("user://icons.svg"):
		print("Loading user icons")
		image = Image.load_from_file("user://icons.svg")
	else:
		print("loading default icons")
		image = Image.load_from_file("res://material_maker/icons/icons.svg")
	set_image(image)
	print("icon atlas initialized")
	print(self)
	print(get_size())
