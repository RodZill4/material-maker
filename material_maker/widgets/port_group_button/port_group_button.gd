extends TextureButton
class_name PortGroupButton

export var group_parent : int = 2

var state : int = 0
# warning-ignore:unused_class_variable
var group_size : int = 0
const TEXTURES = [
	preload("res://material_maker/icons/port_group_0.tres"),
	preload("res://material_maker/icons/port_group_1.tres"),
	preload("res://material_maker/icons/port_group_2.tres"),
	preload("res://material_maker/icons/port_group_3.tres")
]


# warning-ignore:unused_signal
signal group_size_changed(s)
signal groups_updated(g)


func _ready() -> void:
	pass

func set_state(s) -> void:
	state = s
	texture_normal = TEXTURES[state]

func get_group_parent() -> Dictionary:
	var rv = self
	for _i in range(group_parent):
		rv = rv.get_parent()
	return { parent=rv, index=rv.get_index() }

class MyCustomSorter:
	static func sort(a, b):
		if a.index < b.index:
			return true
		return false

static func update_groups(parent : Control):
	var buttons : Array = []
	for b in parent.get_tree().get_nodes_in_group("port_group_button"):
		var p = b.get_group_parent()
		if p.parent == parent:
			p.button = b
			p.erase("parent")
			buttons.append(p)
	buttons.sort_custom(MyCustomSorter, "sort")
	var in_group : bool = false
	var current_group : int = -1
	var group_sizes = {}
	for i in range(buttons.size()):
		var b = buttons[i].button
		if in_group:
			b.set_state(b.state | 2)
		else:
			b.set_state(b.state & 1)
		if b.state & 1 != 0:
			in_group = !in_group
			if in_group:
				current_group = i
				continue
			else:
				group_sizes[current_group] = i + 1 - current_group
				current_group = -1
		b.group_size = 0
		b.emit_signal("group_size_changed", 0)
	if current_group != -1:
		group_sizes[current_group] = buttons.size() - current_group
	return group_sizes

func _on_pressed() -> void:
	set_state(state ^ 1)
	emit_signal("groups_updated", update_groups(get_group_parent().parent))
