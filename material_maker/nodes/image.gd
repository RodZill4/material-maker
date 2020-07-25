extends MMGraphNodeBase

func _ready() -> void:
	set_slot(0, false, 0, Color(0.5, 0.5, 1), true, 0, Color(0.5, 0.5, 1))

func set_generator(g) -> void:
	.set_generator(g)
	generator.connect("parameter_changed", self, "on_parameter_changed")
	$TextureButton.texture_normal = generator.texture

func set_texture(path) -> void:
	if path == null:
		return
	if generator != null:
		generator.set_parameter("image", path)
	$TextureButton.texture_normal = generator.texture

func get_textures() -> Dictionary:
	var list = {}
	list[name] = $TextureButton.texture_normal
	return list

func on_parameter_changed(p, v) -> void:
	$TextureButton.texture_normal = generator.texture

func _on_TextureButton_pressed() -> void:
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.bmp;BMP Image")
	dialog.add_filter("*.hdr;Radiance HDR Image")
	dialog.add_filter("*.jpg,*.jpeg;JPEG Image")
	dialog.add_filter("*.png;PNG Image")
	dialog.add_filter("*.svg;SVG Image")
	dialog.add_filter("*.tga;TGA Image")
	dialog.add_filter("*.webp;WebP Image")
	dialog.connect("file_selected", self, "set_texture")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func on_drop_image_file(file_name : String) -> void:
	set_texture(file_name)
