extends GraphNode
class_name MMGraphNodeMinimal


var generator : MMGenBase = null : set = set_generator
var disable_undoredo_for_offset : bool = false

var buttons : HBoxContainer = null
var close_button : Button


const CLOSE_ICON := "Cross"


func _ready() -> void:
	position_offset_changed.connect(self._on_offset_changed)
	if buttons == null:
		buttons = HBoxContainer.new()
		var space : Control = Control.new()
		buttons.add_theme_constant_override("separation", 1)
		space.custom_minimum_size = Vector2(4, 0)
		buttons.add_child(space)
		get_titlebar_hbox().add_child(buttons)
		init_buttons()
	add_to_group("generator_node")


func update():
	queue_redraw()


func add_button(mm_icon : String, pressed_callback = null, popup_callback = null) -> Button:
	var button : Button = preload("res://material_maker/nodes/node_button.tscn").instantiate()
	button.mm_icon = mm_icon
	buttons.add_child(button)
	buttons.move_child(button, 0)
	if pressed_callback:
		if pressed_callback is Callable:
			button.pressed.connect(pressed_callback)
		else:
			print("unsupported callback")
	if popup_callback:
		if popup_callback is Callable:
			button.on_show_popup.connect(popup_callback)
		else:
			print("unsupported callback")
	return button

func init_buttons():
	close_button = add_button(CLOSE_ICON, self.on_close_pressed)

func on_close_pressed():
	delete_request.emit()

func _on_offset_changed() -> void:
	if ! disable_undoredo_for_offset:
		get_parent().undoredo_move_node(generator.name, generator.position, position_offset)
	generator.set_position(position_offset)
	# This is the old behavior
	#reroll_generator_seed()

func reroll_generator_seed() -> void:
	pass

func on_generator_changed(_g):
	pass

func update_node() -> void:
	pass

func set_generator(g) -> void:
	generator = g

func do_set_position(o : Vector2) -> void:
	disable_undoredo_for_offset = true
	position_offset = o
	disable_undoredo_for_offset = false

func get_slot_from_position(pos : Vector2) -> Dictionary:
	var rv : Dictionary = { type="none", index=-1, show_inputs = false, show_outputs=false }
	var global_scale = get_global_transform().get_scale()
	var rel_pos : Vector2 = (pos-global_position)/global_scale
	var margin := 8
	if get_input_port_count() > 0:
		var input_1 : Vector2 = get_input_port_position(0)-margin*global_scale
		var input_2 : Vector2 = get_input_port_position(get_input_port_count()-1)+margin*global_scale
		rv.show_inputs = Rect2(input_1, input_2-input_1).has_point(rel_pos)
		if rv.show_inputs:
			for i in range(get_input_port_count()):
				if (get_input_port_position(i)-rel_pos).length() < margin*global_scale.x:
					rv.type = "input"
					rv.index = i
	if get_output_port_count() > 0:
		var output_1 : Vector2 = get_output_port_position(0)-margin*global_scale
		var output_2 : Vector2 = get_output_port_position(get_output_port_count()-1)+margin*global_scale
		rv.show_outputs = Rect2(output_1, output_2-output_1).has_point(rel_pos)
		if rv.show_outputs:
			for i in range(get_output_port_count()):
				if (get_output_port_position(i)-rel_pos).length() < margin*global_scale.x:
					rv.type = "output"
					rv.index = i
	return rv

func on_clicked_input(index : int, with_shift : bool) -> bool:
	if ! with_shift:
		return false
	get_parent().add_reroute_to_input(self, index)
	return true

func on_clicked_output(index : int, with_shift : bool) -> bool:
	if ! with_shift:
		return false
	get_parent().add_reroute_to_output(self, index)
	return true
