extends GraphNode
class_name MMGraphNodeMinimal


var generator : MMGenBase = null : set = set_generator
var disable_undoredo_for_offset : bool = false


func _ready() -> void:
	connect("position_offset_changed",Callable(self,"_on_offset_changed"))
	add_to_group("generator_node")

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

func get_input_slot(pos : Vector2) -> int:
	var scale = get_global_transform().get_scale()
	if get_connection_input_count() > 0:
		var input_1 : Vector2 = get_connection_input_position(0)-5*scale
		var input_2 : Vector2 = get_connection_input_position(get_connection_input_count()-1)+5*scale
		var new_show_inputs : bool = Rect2(input_1, input_2-input_1).has_point(pos)
		if new_show_inputs:
			for i in range(get_connection_input_count()):
				if (get_connection_input_position(i)-pos).length() < 5*scale.x:
					return i
			return -1
	return -2

func get_output_slot(pos : Vector2) -> int:
	var scale = get_global_transform().get_scale()
	if get_connection_output_count() > 0:
		var output_1 : Vector2 = get_connection_output_position(0)-5*scale
		var output_2 : Vector2 = get_connection_output_position(get_connection_output_count()-1)+5*scale
		var new_show_outputs : bool = Rect2(output_1, output_2-output_1).has_point(pos)
		if new_show_outputs:
			for i in range(get_connection_output_count()):
				if (get_connection_output_position(i)-pos).length() < 5*scale.x:
					return i
			return -1
	return -2

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
