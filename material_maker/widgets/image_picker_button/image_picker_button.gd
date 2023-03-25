extends TextureButton


var image_path = ""
var filetime : int = 0


signal on_file_selected(f)


func _ready():
	pass

func update_image() -> void:
	if texture_normal == null:
		texture_normal = ImageTexture.new()
	var image : Image = Image.new()
	image.load(image_path)
	texture_normal.create_from_image(image)
	queue_redraw()

func do_set_image_path(path) -> void:
	if path == null:
		return
	image_path = path
	update_image()
	tooltip_text = path
	filetime = get_filetime(image_path)

func set_image_path(path) -> void:
	do_set_image_path(path)
	emit_signal("on_file_selected", path)

func get_filetime(file_path : String) -> int:
	if FileAccess.file_exists(file_path):
		return FileAccess.get_modified_time(file_path)
	return 0

func _on_Timer_timeout():
	var new_filetime : int = get_filetime(image_path)
	if filetime != new_filetime:
		update_image()
		filetime = new_filetime

func _on_ImagePicker_pressed():
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	dialog.min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.bmp;BMP Image")
	dialog.add_filter("*.exr;EXR Image")
	dialog.add_filter("*.hdr;Radiance HDR Image")
	dialog.add_filter("*.jpg,*.jpeg;JPEG Image")
	dialog.add_filter("*.png;PNG Image")
	dialog.add_filter("*.svg;SVG Image")
	dialog.add_filter("*.tga;TGA Image")
	dialog.add_filter("*.webp;WebP Image")
	var files = await dialog.select_files()
	if files.size() > 0:
		set_image_path(files[0])

func on_drop_image_file(file_name : String) -> void:
	set_image_path(file_name)
