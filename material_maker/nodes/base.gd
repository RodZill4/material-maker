extends GraphNode
class_name MMGraphNodeBase

var generator : MMGenBase = null setget set_generator

func _ready() -> void:
	connect("offset_changed", self, "_on_offset_changed")
	connect("gui_input", self, "_on_gui_input")

func _exit_tree() -> void:
	get_parent().call_deferred("check_last_selected")

func _draw() -> void:
	if generator != null and generator.has_randomness():
		var icon = preload("res://material_maker/icons/randomness_locked.tres") if generator.is_seed_locked() else preload("res://material_maker/icons/randomness_unlocked.tres")
		draw_texture_rect(icon, Rect2(rect_size.x-48, 4, 16, 16), false)

func set_generator(g) -> void:
	generator = g

func _on_offset_changed() -> void:
	generator.set_position(offset)

func _input(event) -> void:
	_on_gui_input(event)

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT and Rect2(rect_size.x-48, 4, 16, 16).has_point(event.position):
		generator.toggle_lock_seed()
		update()
		get_parent().send_changed_signal()
	elif event is InputEventMouseMotion:
		var epos = event.position
		if Rect2(0, 0, 16, 16).has_point(epos):
			if generator.model:
				hint_tooltip = generator.model
			return
		elif Rect2(rect_size.x-48, 4, 16, 16).has_point(epos) and generator.has_randomness():
			if generator.is_seed_locked():
				hint_tooltip = "Unlock the random seed, so it can be modified by moving the node"
			else:
				hint_tooltip = "Lock the random seed to its current value"
			return
		hint_tooltip = ""

func get_slot_tooltip(pos : Vector2):
	for i in range(get_connection_input_count()):
		if is_slot_enabled_left(i) and (get_connection_input_position(i)-pos).length() < 5:
			return "input "+str(i)
	for i in range(get_connection_output_count()):
		if is_slot_enabled_right(i) and (get_connection_output_position(i)-pos).length() < 5:
			return "output "+str(i)
	return ""
