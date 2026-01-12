extends Panel

## Panel that allows loading reference images
## and picking colors and gradients from them.


var opened_images: Array[Dictionary] = []
var current_image_index := 0

## Some state flags

var is_picking := false
var is_dragging := false
var is_zooming := false
var is_drag_zooming := false

var selected_slot: Button = null

## Picking variables
var color : Color
var color_count : int = 0
var gradient = null
var gradient_length : float = 0.0

func _ready():
	%Image.material.set_shader_parameter("image_size", Vector2(1.0, 1.0))

	%AddImageButton.icon = get_theme_icon("add_image", "MM_Icons")
	%PasteImageButton.icon = get_theme_icon("paste_image", "MM_Icons")
	%RemoveImageButton.icon = get_theme_icon("delete", "MM_Icons")

	%PrevImageButton.icon = get_theme_icon("arrow_left", "MM_Icons")
	%NextImageButton.icon = get_theme_icon("arrow_right", "MM_Icons")

	go_to_image(0)

	for slot in %ColorSlots.get_children():
		slot.toggled.connect(_on_slot_toggled.bind(slot))

	%GradientSlot.toggled.connect(_on_slot_toggled.bind(%GradientSlot))


## This is magically called by the main window :)
func on_drop_image_file(file_name: String) -> void:
	add_reference(file_name)


func add_reference(from:Variant) -> void:
	var texture: Texture2D

	if typeof(from) == TYPE_STRING:
		var image: Image = Image.new()
		if from.get_extension() == "dds":
			image.load_dds_from_buffer(FileAccess.get_file_as_bytes(from))
		else:
			image = Image.load_from_file(from)

		if image != null:
			texture = ImageTexture.create_from_image(image)
		else:
			print("[ReferencePanel] Error loading %s" % from)
			return

	elif typeof(from) == TYPE_OBJECT and from is Texture2D:
		texture = from

	else:
		print("[ReferencePanel] Error loading reference.")
		return

	if opened_images.is_empty():
		current_image_index = -1

	opened_images.insert(
		current_image_index+1,
		{"texture":texture, "scale":1.1, "center":Vector2(0.5, 0.47)}
		)

	go_to_image(current_image_index+1)


func go_to_image(index:int) -> void:
	index = wrapi(index, 0, len(opened_images))
	current_image_index = index

	%RemoveImageButton.disabled = opened_images.is_empty()
	%Empty.visible = opened_images.is_empty()

	%NavigationMenu.visible = len(opened_images) > 1
	%PrevImageButton.disabled = current_image_index == 0
	%NextImageButton.disabled = current_image_index == len(opened_images)-1

	%ImageIndexLabel.text = str(current_image_index+1)+"/"+str(len(opened_images))

	%PickerMenu.visible = not opened_images.is_empty()

	var m : ShaderMaterial = %Image.material
	if len(opened_images) == 0:
		m.set_shader_parameter("image", null)
		return

	var i := opened_images[current_image_index]
	var t: Texture2D = i.texture
	m.set_shader_parameter("image", t)
	m.set_shader_parameter("image_size", t.get_image().get_size())
	m.set_shader_parameter("scale", i.scale)
	m.set_shader_parameter("center", i.center)


func _on_add_image_button_pressed() -> void:
	var dialog := preload("res://material_maker/windows/file_dialog/file_dialog.tscn").instantiate()
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
	dialog.add_filter("*.dds;DirectDraw Surface Image")
	var files = await dialog.select_files()
	if files.size() == 1:
		add_reference(files[0])


func _on_remove_image_button_pressed() -> void:
	opened_images.remove_at(current_image_index)
	go_to_image(current_image_index-1)


func _on_prev_image_button_pressed() -> void:
	go_to_image(current_image_index-1)


func _on_next_image_button_pressed() -> void:
	go_to_image(current_image_index+1)


func _on_slot_toggled(toggled_on: bool, slot: Button) -> void:
	if toggled_on:
		selected_slot = slot
	elif selected_slot == slot:
		selected_slot = null

	is_picking = selected_slot != null


func get_color_under_cursor() -> Color:
	var image: Image = get_viewport().get_texture().get_image()
	var pos: Vector2 = get_global_mouse_position()
	pos *= Vector2(image.get_size())
	pos /= get_viewport_rect().size
	var c := image.get_pixelv(pos)
	return c


func _on_image_resized() -> void:
	%Image.material.set_shader_parameter("canvas_size", %Image.get_size())


func _on_image_gui_input(event: InputEvent) -> void:
	if opened_images.is_empty():
		return

	if is_picking:
		handle_picking(event)
	else:
		handle_movement(event)


func handle_movement(event: InputEvent) -> void:
	var m: ShaderMaterial = %Image.material

	var canvas_size : Vector2 = %Image.get_size()
	var image_size : Vector2 = m.get_shader_parameter("image_size")
	var image_scale : float = m.get_shader_parameter("scale")
	var center : Vector2 = m.get_shader_parameter("center")

	var new_center := center
	var new_scale := image_scale
	var ratio : Vector2 = canvas_size/image_size
	var multiplier : Vector2 = image_size*min(ratio.x, ratio.y)

	var image_rect : Rect2 = %Image.get_global_rect()
	var offset_from_center : Vector2 = get_global_mouse_position()-(image_rect.position+0.5*image_rect.size)

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				is_dragging = event.pressed

			MOUSE_BUTTON_LEFT:
				is_dragging = event.pressed and event.shift_pressed

				is_zooming = event.pressed and event.is_command_or_control_pressed() and not is_dragging
				is_drag_zooming = false
			MOUSE_BUTTON_WHEEL_DOWN:
				new_scale = min(new_scale+0.05, 3)

			MOUSE_BUTTON_WHEEL_UP:
				new_scale = max(new_scale-0.05, 0.05)

	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0 and (
				event.ctrl_pressed or event.meta_pressed):
			is_drag_zooming = true
			var sca : Array[float] = [new_scale]
			mm_globals.handle_warped_drag_zoom(self,
				(func(): sca[0] *= 1.0 + 0.005 * event.relative.y),0, get_rect().size.y)
			new_scale = clamp(sca[0], 0.005, 3.0)
		else:
			if is_dragging:
				new_center = m.get_shader_parameter("center")-event.relative*image_scale/multiplier

			elif is_zooming:
				new_scale = clamp(new_scale*(1.0+0.01*event.relative.y), 0.005, 3)

	if new_scale != image_scale:
		m.set_shader_parameter("scale", new_scale)
		if not is_drag_zooming:
			new_center = center+offset_from_center*(image_scale-new_scale)/multiplier
		opened_images[current_image_index].scale = new_scale

	if new_center != center:
		new_center.x = clamp(new_center.x, 0.0, 1.0)
		new_center.y = clamp(new_center.y, 0.0, 1.0)
		m.set_shader_parameter("center", new_center)
		opened_images[current_image_index].center = new_center


func handle_picking(event: InputEvent) -> void:
	var picking_color := selected_slot.get_parent() == %ColorSlots

	if event is InputEventMouseButton:
		if event.pressed:
			if picking_color:
				color_count = 1
				color = get_color_under_cursor()
				selected_slot.set_slot_color(color)
			else:
				gradient = selected_slot.gradient
				gradient.clear()
				gradient.add_point(0.0, get_color_under_cursor())
				selected_slot.set_gradient(gradient)
				gradient_length = 0.0

		else:
			is_picking = false
			selected_slot.button_pressed = false
			color_count = 0
			gradient = 0

	elif event is InputEventMouseMotion:
		if picking_color and color_count > 0:
			color_count += 1
			color += get_color_under_cursor()
			selected_slot.set_slot_color(color/color_count)
		elif gradient:
			var new_gradient_length: float = gradient_length + event.relative.length()
			if gradient_length > 0.0:
				for i in range(gradient.get_point_count()):
					gradient.set_point_position(i, gradient.get_point_position(i)*gradient_length/new_gradient_length)
			gradient.add_point(1.0, get_color_under_cursor())
			selected_slot.set_gradient(gradient)
			gradient_length = new_gradient_length


func _on_paste_image_button_pressed() -> void:
	if DisplayServer.clipboard_has_image():
		var img : Texture2D = ImageTexture.create_from_image(
				DisplayServer.clipboard_get_image())
		add_reference(img)


func _on_check_clipboard_image_timeout() -> void:
	$%PasteImageButton.disabled = not DisplayServer.clipboard_has_image()
