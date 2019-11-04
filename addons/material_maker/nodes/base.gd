tool
extends GraphNode
class_name MMGraphNodeBase

var generator : MMGenBase = null setget set_generator

func _ready() -> void:
	connect("offset_changed", self, "_on_offset_changed")

func _draw():
	if generator != null and generator.has_randomness():
		var icon = preload("res://addons/material_maker/icons/randomness_locked.tres") if generator.is_seed_locked() else preload("res://addons/material_maker/icons/randomness_unlocked.tres")
		draw_texture_rect(icon, Rect2(rect_size.x-48, 4, 16, 16), false)
		if !is_connected("gui_input", self, "_on_gui_input"):
			connect("gui_input", self, "_on_gui_input")
	else:
		if is_connected("gui_input", self, "_on_gui_input"):
			disconnect("gui_input", self, "_on_gui_input")

func set_generator(g) -> void:
	generator = g

func _on_offset_changed() -> void:
	generator.set_position(offset)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT and Rect2(rect_size.x-48, 4, 16, 16).has_point(event.position):
		generator.toggle_lock_seed()
		update()
