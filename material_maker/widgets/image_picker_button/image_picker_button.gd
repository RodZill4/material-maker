extends TextureButton


var image_path = ""


signal on_file_selected(f)


func _ready():
	texture_normal = ImageTexture.new()

func do_set_image_path(path) -> void:
	if path == null:
		return
	image_path = path
	texture_normal.load(image_path)

func set_image_path(path) -> void:
	do_set_image_path(path)
	emit_signal("on_file_selected", path)

func _on_ImagePicker_pressed():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.bmp;BMP Image")
	dialog.add_filter("*.exr;EXR Image")
	dialog.add_filter("*.hdr;Radiance HDR Image")
	dialog.add_filter("*.jpg,*.jpeg;JPEG Image")
	dialog.add_filter("*.png;PNG Image")
	dialog.add_filter("*.svg;SVG Image")
	dialog.add_filter("*.tga;TGA Image")
	dialog.add_filter("*.webp;WebP Image")
	dialog.connect("file_selected", self, "set_image_path")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()

func on_drop_image_file(file_name : String) -> void:
	set_image_path(file_name)
