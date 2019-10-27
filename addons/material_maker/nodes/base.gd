tool
extends GraphNode
class_name MMGraphNodeBase

var generator : MMGenBase = null setget set_generator

func _ready() -> void:
	connect("offset_changed", self, "_on_offset_changed")

func set_generator(g) -> void:
	generator = g

func _on_offset_changed() -> void:
	generator.set_position(offset)
