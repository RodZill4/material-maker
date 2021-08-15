extends "res://material_maker/panels/preview_2d/preview_2d.gd"

var center : Vector2 = Vector2(0.5, 0.5)
var scale : float = 1.2

func _ready():
	update_shader_options()
	update_axes_menu()
	update_export_menu()

func update_axes_menu() -> void:
	$ContextMenu/Axes.clear()
	for s in $Axes.STYLES:
		$ContextMenu/Axes.add_item(s)
	$ContextMenu/Axes.add_separator()
	$ContextMenu/Axes.add_item("Change color", 1000)
	$ContextMenu.add_submenu_item("Axes", "Axes")

func set_generator(g : MMGenBase, o : int = 0) -> void:
	#center = Vector2(0.5, 0.5)
	#scale = 1.2
	.set_generator(g, o)
	setup_controls()
	update_shader_options()

func setup_controls() -> void:
	var param_defs = generator.get_parameter_defs() if is_instance_valid(generator) else []
	for c in get_children():
		if c.has_method("setup_control"):
			c.setup_control(generator, param_defs)

func value_to_pos(value : Vector2) -> Vector2:
	return (value-center+Vector2(0.5, 0.5))*min(rect_size.x, rect_size.y)/scale+0.5*rect_size

func value_to_offset(value : Vector2) -> Vector2:
	return value*min(rect_size.x, rect_size.y)/scale

func pos_to_value(pos : Vector2) -> Vector2:
	return (pos-0.5*rect_size)*scale/min(rect_size.x, rect_size.y)+center-Vector2(0.5, 0.5)

func update_shader_options() -> void:
	on_resized()

func on_resized() -> void:
	.on_resized()
	material.set_shader_param("preview_2d_center", center)
	material.set_shader_param("preview_2d_scale", scale)
	setup_controls()
	$Axes.update()

var dragging : bool = false
var zooming : bool = false

func _on_gui_input(event):
	var need_update : bool = false
	var new_center : Vector2 = center
	var multiplier : float = min(rect_size.x, rect_size.y)
	var image_rect : Rect2 = get_global_rect()
	var offset_from_center : Vector2 = get_global_mouse_position()-(image_rect.position+0.5*image_rect.size)
	var new_scale : float = scale
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_DOWN:
				new_scale = min(new_scale*1.05, 5.0)
			elif event.button_index == BUTTON_WHEEL_UP:
				new_scale = max(new_scale*0.95, 0.005)
			elif event.button_index == BUTTON_MIDDLE:
				dragging = true
			elif event.button_index == BUTTON_LEFT:
				if event.shift:
					dragging = true
				elif event.command:
					zooming = true
		else:
			dragging = false
			zooming = false
	elif event is InputEventMouseMotion:
		if dragging:
			new_center = center-event.relative*scale/multiplier
		elif zooming:
			new_scale = clamp(new_scale*(1.0+0.01*event.relative.y), 0.005, 5.0)
	if new_scale != scale:
		new_center = center+offset_from_center*(scale-new_scale)/multiplier
		scale = new_scale
		need_update = true
	if new_center != center:
		center.x = clamp(new_center.x, 0.0, 1.0)
		center.y = clamp(new_center.y, 0.0, 1.0)
		need_update = true
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			$ContextMenu.popup(Rect2(get_global_mouse_position(), $ContextMenu.get_minimum_size()))
	if need_update:
		on_resized()

func _on_ContextMenu_id_pressed(id) -> void:
	match id:
		0:
			center = Vector2(0.5, 0.5)
			scale = 1.2
			update_shader_options()
		MENU_EXPORT_AGAIN:
			export_again()
		_:
			print("unsupported id "+str(id))

func _on_Axes_id_pressed(id):
	if id == 1000:
		var color_picker_popup = preload("res://material_maker/widgets/color_picker_popup/color_picker_popup.tscn").instance()
		add_child(color_picker_popup)
		var color_picker = color_picker_popup.get_node("ColorPicker")
		color_picker.color = $Axes.color
		color_picker.connect("color_changed", $Axes, "set_color")
		color_picker_popup.rect_position = get_global_mouse_position()
		color_picker_popup.connect("popup_hide", color_picker_popup, "queue_free")
		color_picker_popup.popup()
	else:
		$Axes.style = id
