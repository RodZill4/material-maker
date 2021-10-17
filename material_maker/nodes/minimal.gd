extends GraphNode
class_name MMGraphNodeMinimal

var generator : MMGenBase = null setget set_generator

func _ready() -> void:
	add_to_group("generator_node")

func _exit_tree() -> void:
	get_parent().call_deferred("check_last_selected")

func on_generator_changed(g):
	pass

func update_node() -> void:
	pass

func set_generator(g) -> void:
	generator = g
