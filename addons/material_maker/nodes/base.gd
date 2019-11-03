tool
extends GraphNode
class_name MMGraphNodeBase

var generator : MMGenBase = null setget set_generator
var fixed_seed = false

func _ready() -> void:
	connect("offset_changed", self, "_on_offset_changed")

func _draw():
	if generator.has_randomness():
		var icon = preload("res://addons/material_maker/icons/randomness_unlocked.tres") if fixed_seed else preload("res://addons/material_maker/icons/randomness_locked.tres")
		draw_texture_rect(icon, Rect2(rect_size.x-48, 4, 16, 16), false)

func set_generator(g) -> void:
	generator = g

func _on_offset_changed() -> void:
	generator.set_position(offset)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT and Rect2(rect_size.x-48, 4, 16, 16).has_point(event.position):
		fixed_seed = !fixed_seed
		update()
