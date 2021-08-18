extends Panel

onready var selected_slot : Control = null

var images : Array = []
var current_image = -1

var dragging = false
var gradient = null
var gradient_length : float = 0.0

func _ready():
	$VBoxContainer/Image.material.set_shader_param("image_size", Vector2(1.0, 1.0))
	select_slot($VBoxContainer/Colors/ColorSlot1)
	change_image(0)

func on_drop_image_file(file_name : String) -> void:
	var t : ImageTexture = ImageTexture.new()
	t.load(file_name)
	add_reference(t)

func add_reference(t : Texture) -> void:
	images.insert(current_image+1, { texture=t, scale=1.0, center=Vector2(0.5, 0.5) })
	change_image(1)

func get_color_under_cursor() -> Color:
	var image : Image = get_viewport().get_texture().get_data()
	var pos = get_global_mouse_position()
	pos.y = image.get_height() - pos.y
	image.lock()
	var c = image.get_pixelv(pos)
	image.unlock()
	return c

func _on_Image_gui_input(event) -> void:
	var m : ShaderMaterial = $VBoxContainer/Image.material
	var canvas_size : Vector2 = $VBoxContainer/Image.get_size()
	var image_size : Vector2 = m.get_shader_param("image_size")
	var scale : float = m.get_shader_param("scale")
	var center : Vector2 = m.get_shader_param("center")
	var new_center : Vector2 = center
	var new_scale : float = scale
	var ratio : Vector2 = canvas_size/image_size
	var multiplier : Vector2 = image_size*min(ratio.x, ratio.y)
	var image_rect : Rect2 = $VBoxContainer/Image.get_global_rect()
	var offset_from_center : Vector2 = get_global_mouse_position()-(image_rect.position+0.5*image_rect.size)
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT and selected_slot != null:
				if selected_slot.get_parent() == $VBoxContainer/Colors:
					selected_slot.set_color(get_color_under_cursor())
				else:
					gradient = selected_slot.gradient
					gradient.clear()
					gradient.add_point(0.0, get_color_under_cursor())
					selected_slot.set_gradient(gradient)
					gradient_length = 0.0
			elif event.button_index == BUTTON_WHEEL_DOWN:
				new_scale = min(new_scale+0.05, 1.0)
			elif event.button_index == BUTTON_WHEEL_UP:
				new_scale = max(new_scale-0.05, 0.05)
			elif event.button_index == BUTTON_MIDDLE:
				dragging = true
			elif event.button_index == BUTTON_RIGHT:
				$ContextMenu.popup(Rect2(get_global_mouse_position(), $ContextMenu.get_minimum_size()))
		elif event.button_index == BUTTON_MIDDLE:
			dragging = false
		elif event.button_index == BUTTON_LEFT:
			gradient = null
	elif event is InputEventMouseMotion:
		if dragging:
			new_center = m.get_shader_param("center")-event.relative*scale/multiplier
		elif gradient != null:
			var new_gradient_length = gradient_length + event.relative.length()
			if gradient_length > 0.0:
				for i in range(gradient.get_point_count()):
					gradient.set_point_position(i, gradient.get_point_position(i)*gradient_length/new_gradient_length)
			gradient.add_point(1.0, get_color_under_cursor())
			selected_slot.set_gradient(gradient)
			gradient_length = new_gradient_length
	if new_scale != scale:
		m.set_shader_param("scale", new_scale)
		new_center = center+offset_from_center*(scale-new_scale)/multiplier
		if current_image >= 0:
			images[current_image].scale = new_scale
	if new_center != center:
		new_center.x = clamp(new_center.x, 0.0, 1.0)
		new_center.y = clamp(new_center.y, 0.0, 1.0)
		m.set_shader_param("center", new_center)
		if current_image >= 0:
			images[current_image].center = new_center

func select_slot(s) -> void:
	if selected_slot != null:
		selected_slot.select(false)
	selected_slot = s
	selected_slot.select(true)

func _on_Image_resized():
	$VBoxContainer/Image.material.set_shader_param("canvas_size", $VBoxContainer/Image.get_size())

func change_image(offset = 0):
	current_image += offset
	if current_image < 0:
		current_image = 0
	if current_image >= images.size():
		current_image = images.size()-1
	$VBoxContainer/Image/HBoxContainer/Prev.disabled = current_image <= 0
	$VBoxContainer/Image/HBoxContainer/Next.disabled = current_image >= images.size()-1
	var m : ShaderMaterial = $VBoxContainer/Image.material
	if current_image < 0:
		m.set_shader_param("image", null)
		m.set_shader_param("image_size", Vector2(0, 0))
		m.set_shader_param("scale", 1)
		m.set_shader_param("center", Vector2(0, 0))
		return
	var i = images[current_image]
	var t = i.texture
	m.set_shader_param("image", t)
	m.set_shader_param("image_size", t.get_data().get_size())
	m.set_shader_param("scale", i.scale)
	m.set_shader_param("center", i.center)


func _on_ContextMenu_about_to_show():
	$ContextMenu.set_item_disabled(1, images.empty())

func _on_ContextMenu_index_pressed(index):
	match index:
		0:
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
			if files.size() == 1:
				on_drop_image_file(files[0])
		1:
			images.remove(current_image)
			change_image(0)
