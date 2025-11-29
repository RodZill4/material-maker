extends PanelContainer


var image_path := ""
var filetime: int = 0

signal on_file_selected(f)


func _ready() -> void:
	%Image.custom_minimum_size = Vector2(64, 64)
	_on_mouse_exited()


func update_image() -> void:
	if %Image.texture == null:
		%Image.texture = ImageTexture.new()
	
	if FileAccess.file_exists(image_path):
		var image: Image = Image.load_from_file(image_path)
		%Image.texture.set_image(image)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		open_image_dialog()


func do_set_image_path(path:String) -> void:
	if path == null:
		return
	image_path = path
	update_image()
	tooltip_text = path
	filetime = get_filetime(image_path)


func set_image_path(path:String) -> void:
	do_set_image_path(path)
	emit_signal("on_file_selected", path)


func get_filetime(file_path: String) -> int:
	if FileAccess.file_exists(file_path):
		return FileAccess.get_modified_time(file_path)
	return 0


func open_image_dialog() -> void:
	var dialog = preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
	if image_path:
		dialog.current_dir = image_path.get_base_dir()
		if FileAccess.file_exists(image_path):
			dialog.current_file = image_path.get_file()
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


func _on_timer_timeout() -> void:
	var new_filetime : int = get_filetime(image_path)
	if filetime != new_filetime:
		update_image()
		filetime = new_filetime


func _on_mouse_entered() -> void:
	add_theme_stylebox_override("panel", get_theme_stylebox("hover"))


func _on_mouse_exited() -> void:
	add_theme_stylebox_override("panel", get_theme_stylebox("normal"))
