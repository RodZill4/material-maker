extends "res://material_maker/panels/preview_2d/preview_2d.gd"

var config_cache : ConfigFile

var shader_margin : float = 0
var center : Vector2 = Vector2(0.5, 0.5)
var scale : float = 1.2

func _ready():
	if config_cache.has_section_key("preview_2d", "show_tiling"):
		$ContextMenu.set_item_checked(0, config_cache.get_value("preview_2d", "show_tiling"))
	update_shader_options()
	update_export_menu()
 
func set_generator(g : MMGenBase, o : int = 0) -> void:
	center = Vector2(0.5, 0.5)
	scale = 1.2
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
	if $ContextMenu == null:
		return
	if $ContextMenu.is_item_checked(0):
		material.set_shader_param("center", center)
		$Lines.visible = true
		$Lines.update()
	else:
		material.set_shader_param("center", center)
		$Lines.visible = false
	on_resized()

func on_resized() -> void:
	.on_resized()
	setup_controls()
	$Lines.update()

var dragging : bool = false

func _on_gui_input(event):
	var m : ShaderMaterial = material
	var canvas_size : Vector2 = rect_size
	var new_center : Vector2 = center
	var ratio : Vector2 = canvas_size
	var multiplier : float = min(ratio.x, ratio.y)
	var image_rect : Rect2 = get_global_rect()
	var offset_from_center : Vector2 = get_global_mouse_position()-(image_rect.position+0.5*image_rect.size)
	if event is InputEventMouseButton:
		if event.pressed:
			var new_scale : float = scale
			if event.button_index == BUTTON_WHEEL_DOWN:
				new_scale = min(new_scale*1.05, 5)
			elif event.button_index == BUTTON_WHEEL_UP:
				new_scale = max(new_scale*0.95, 0.005)
			elif event.button_index == BUTTON_MIDDLE:
				dragging = true
			if new_scale != scale:
				new_center = center+offset_from_center*(scale-new_scale)/multiplier
				scale = new_scale
				m.set_shader_param("scale", scale)
				on_resized()
		elif event.button_index == BUTTON_MIDDLE:
			dragging = false
	elif event is InputEventMouseMotion:
		if dragging:
			new_center = m.get_shader_param("center")-event.relative*scale/multiplier
	if new_center != center:
		center.x = clamp(new_center.x, 0.0, 1.0)
		center.y = clamp(new_center.y, 0.0, 1.0)
		m.set_shader_param("center", center)
		on_resized()
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			$ContextMenu.popup(Rect2(get_global_mouse_position(), $ContextMenu.get_minimum_size()))

func _on_ContextMenu_id_pressed(id) -> void:
	if $ContextMenu.is_item_checkable(id):
		$ContextMenu.toggle_item_checked(id)
		config_cache.set_value("preview_2d", "show_tiling", $ContextMenu.is_item_checked(0))
	match id:
		0:
			update_shader_options()
		_:
			print("unsupported id "+str(id))

