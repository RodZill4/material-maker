extends TextureButton


var image_path = ""


signal on_file_selected(f)


func _ready():
	pass

func do_set_image_path(path) -> void:
	if path == null:
		return
	image_path = path
	if texture_normal == null:
		texture_normal = ImageTexture.new()
	texture_normal.load(image_path)
	hint_tooltip = path

func set_image_path(path) -> void:
	do_set_image_path(path)
	emit_signal("on_file_selected", path)

func _on_ImagePicker_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instance()
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
	var files = dialog.select_files()
	while files is GDScriptFunctionState:
		files = yield(files, "completed")
	if files.size() > 0:
		set_image_path(files[0])

func on_drop_image_file(file_name : String) -> void:
	set_image_path(file_name)
