extends "res://material_maker/preview/preview_2d.gd"

var shader_margin : float = 0

func _ready():
	update_shader_options()
	$ContextMenu.add_submenu_item("Export", "Export")

func set_generator(g : MMGenBase, o : int = 0) -> void:
	.set_generator(g, o)
	setup_controls()
	update_shader_options()

func setup_controls() -> void:
	var param_defs = generator.get_parameter_defs() if is_instance_valid(generator) else []
	for c in get_children():
		if c.has_method("setup_control"):
			c.setup_control(generator, param_defs)

func value_to_pos(value : Vector2) -> Vector2:
	return rect_size*0.5+value*min(rect_size.x, rect_size.y)/(1+shader_margin)

func value_to_offset(value : Vector2) -> Vector2:
	return value*min(rect_size.x, rect_size.y)/(1+shader_margin)

func pos_to_value(pos : Vector2) -> Vector2:
	return (pos - rect_size*0.5)*(1+shader_margin)/min(rect_size.x, rect_size.y)

func update_shader_options() -> void:
	if $ContextMenu == null:
		return
	if $ContextMenu.is_item_checked(0):
		shader_margin = 0.2
		material.set_shader_param("show_tiling", true)
		material.set_shader_param("margin", 0.2)
	else:
		shader_margin = 0
		material.set_shader_param("show_tiling", false)
		material.set_shader_param("margin", 0)
	setup_controls()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT:
			$ContextMenu.popup(Rect2(get_global_mouse_position(), $ContextMenu.get_minimum_size()))

func _on_ContextMenu_id_pressed(id) -> void:
	if $ContextMenu.is_item_checkable(id):
		$ContextMenu.toggle_item_checked(id)
	match id:
		0:
			update_shader_options()
		_:
			print("unsupported id "+str(id))
