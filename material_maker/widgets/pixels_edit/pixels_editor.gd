@tool
extends "res://material_maker/widgets/pixels_edit/pixels_view.gd"

var current_color: int = -1:
	set(v):
		current_color = v
		colors.current_color = v
		colors.queue_redraw()

var last_mouse_pos : Vector2
var is_sampling_pixel : bool = false:
	set(v):
		is_sampling_pixel = v
		if is_sampling_pixel:
			Input.set_custom_mouse_cursor(
				preload("res://material_maker/icons/pixel_sample.svg"),
				Input.CURSOR_ARROW, Vector2(4.0, 19.8))
		else:
			Input.set_custom_mouse_cursor(null)

@onready var menu_bar : Control = $PixelMenu
@onready var colors : Control = %Colors

signal value_changed(value : MMPixels)
signal unhandled_event(event : InputEvent)

var achievement_submitted : bool = false

func _ready() -> void:
	super()
	%SettingsPanel.pixel_editor = self

	if get_parent().has_method("add_menu_bar"):
		menu_bar.get_parent().remove_child(menu_bar)
		get_parent().add_menu_bar(menu_bar, self)

func is_mouse_in_canvas() -> bool:
	return Rect2(draw_offset, draw_size).has_point(get_local_mouse_position())

func _draw() -> void:
	super._draw()
	var val : Vector2 = reverse_transform_point(get_local_mouse_position())
	var pixels_size : Vector2 = Vector2(pixels.size)
	val = snapped(val - (Vector2(0.5, 0.5) / pixels_size), Vector2.ONE / pixels_size)
	if is_mouse_in_canvas():
		# line preview
		if Input.is_key_pressed(KEY_SHIFT):
			for pixel : Vector2i in get_bresenham_line_pixels(
					last_mouse_pos, get_local_mouse_position()):
				var lr : Rect2 = Rect2(transform_point(Vector2(pixel)/pixels_size),
						draw_size / pixels_size) 
				draw_rect(lr, pixels.palette[current_color])

		# current pixel preview
		var rect = Rect2(transform_point(val), draw_size / pixels_size)
		draw_rect(rect.grow(-1.0), Color.BLACK, false, 1.0)
		draw_rect(rect, Color.WHITE, false, 1.0)

func set_pixels(p : MMPixels) -> void:
	pixels = p
	queue_redraw()
	update_color_buttons()

func update_color_buttons() -> void:
	var palette_size : int = pixels.palette.size()
	var button_count : int = colors.get_child_count()
	if palette_size < button_count:
		while button_count > palette_size:
			button_count -= 1
			var color_button : Node = colors.get_child(button_count)
			colors.remove_child(color_button)
			color_button.free()
	elif palette_size > colors.get_child_count():
		while colors.get_child_count() < palette_size:
			var color_button : ColorPickerButton = ColorPickerButton.new()
			color_button.ready.connect(func():
				var popup = color_button.get_popup()
				popup.content_scale_factor = mm_globals.ui_scale_factor()
				popup.min_size = popup.get_contents_minimum_size() * popup.content_scale_factor)
			color_button.custom_minimum_size = Vector2i(25, 25)
			color_button.theme_type_variation = "MM_PanelMenuButton"
			color_button.tooltip_text = "Click to select; Right click to change color"
			color_button.toggle_mode = true
			color_button.button_mask = MOUSE_BUTTON_MASK_RIGHT
			colors.add_child(color_button)
			color_button.focus_entered.connect(self.set_current_color.bind(button_count))
			color_button.color_changed.connect(self.set_palette_color.bind(button_count))
			button_count += 1
	for ci in palette_size:
		colors.get_child(ci).color = pixels.palette[ci]
	if current_color < 0 or current_color >= palette_size:
		current_color = 0

func set_current_color(c : int) -> void:
	current_color = c
	if is_sampling_pixel:
		var prev_focus : Control = get_viewport().gui_get_focus_owner()
		if prev_focus is ColorPickerButton:
			prev_focus.release_focus()

func set_palette_color(c : Color, i : int) -> void:
	pixels.palette[i] = c
	queue_redraw()
	self.value_changed.emit(pixels)

func sample_pixel() -> int:
	var click_position : Vector2 = reverse_transform_point(get_local_mouse_position())
	var pixel_position : Vector2i = Vector2i(Vector2(pixels.size)*click_position)
	return pixels.get_color_index(pixel_position.x, pixel_position.y)

func draw_pixel() -> void:
	var click_position : Vector2 = reverse_transform_point(get_local_mouse_position())
	var pixel_position : Vector2i = Vector2i(Vector2(pixels.size)*click_position)
	pixels.set_color_index(pixel_position.x, pixel_position.y, current_color)
	queue_redraw()
	self.value_changed.emit(pixels)
	if not achievement_submitted:
		mm_steam.unlock_achievement("ACH_MARGOTS_FAVORITE")
		achievement_submitted = true

func draw_pixel_line() -> void:
	for pixel in get_bresenham_line_pixels(last_mouse_pos, get_local_mouse_position()):
		pixels.set_color_index(pixel.x, pixel.y, current_color)
	queue_redraw()
	self.value_changed.emit(pixels)
	if not achievement_submitted:
		mm_steam.unlock_achievement("ACH_MARGOTS_FAVORITE")
		achievement_submitted = true

func get_bresenham_line_pixels(from : Vector2, to : Vector2) -> Array[Vector2i]:
	var start : Vector2 = reverse_transform_point(from)
	var end : Vector2 = reverse_transform_point(to)
	var pixel_from : Vector2i = Vector2i(Vector2(pixels.size) * start)
	var pixel_to : Vector2i = Vector2i(Vector2(pixels.size) * end)
	return Geometry2D.bresenham_line(pixel_from, pixel_to)

func _input(event : InputEvent) -> void:
	if is_mouse_in_canvas() and event is InputEventKey:
		match event.keycode:
			KEY_ALT:
				is_sampling_pixel = event.pressed
			KEY_SHIFT:
				queue_redraw()

func _on_PixelsEditor_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.shift_pressed and last_mouse_pos:
				draw_pixel_line()
			elif event.alt_pressed and is_mouse_in_canvas():
				set_current_color(sample_pixel())
				return
			last_mouse_pos = get_local_mouse_position()
			draw_pixel()
			return
	elif event is InputEventMouseMotion:
		queue_redraw()
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT and not event.alt_pressed:
			draw_pixel()
			return
		if is_mouse_in_canvas():
			var tip : String = "#LMB: Draw pixel,"
			tip += " Shift + #LMB: Draw line,"
			tip += " Alt + #LMB: Sample color"
			mm_globals.set_tip_text(tip, 2.0)
		else:
			is_sampling_pixel = false
			mm_globals.set_tip_text("")
	unhandled_event.emit(event)


var generator : MMGenBase = null
var parameter_name : String

func setup_control(g : MMGenBase, param_defs : Array) -> void:
	var need_hide : bool = true
	for p in param_defs:
		if p.type == "pixels":
			if g != generator or p.name != parameter_name:
				show()
				generator = g
				parameter_name = p.name
				value_changed.connect(self.control_update_parameter)
			set_pixels(MMType.deserialize_value(g.get_parameter(p.name)))
			need_hide = false
			break
	if need_hide:
		hide()
		if value_changed.is_connected(self.control_update_parameter):
			value_changed.disconnect(self.control_update_parameter)
		generator = null

func control_update_parameter(_value : MMPixels):
	generator.set_parameter(parameter_name, pixels.serialize())
