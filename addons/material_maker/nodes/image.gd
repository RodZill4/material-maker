tool
extends GraphNode

var generator = null

func _ready():
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))

func set_texture(path):
	if path == null:
		return
	if generator != null:
		generator.set_parameter("image", path)
	$TextureButton.texture_normal = generator.texture

func get_textures():
	var list = {}
	list[name] = $TextureButton.texture_normal
	return list

func _on_TextureButton_pressed():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.png;PNG image")
	dialog.add_filter("*.jpg;JPG image")
	dialog.connect("file_selected", self, "set_texture")
	dialog.popup_centered()
