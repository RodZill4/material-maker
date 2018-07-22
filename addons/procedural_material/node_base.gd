tool
extends GraphNode

var generated = false

func _ready():
	pass

func initialize_properties(object_list):
	for o in object_list:
		if o is LineEdit:
			set(o.name, float(o.text))
			o.connect("text_changed", self, "_on_text_changed", [ o.name ])

func _on_text_changed(new_text, variable):
	set(variable, float(new_text))
	get_parent().get_parent().generate_shader()

func get_source(index = 0):
	for c in get_parent().get_children():
		if c != self && c is GraphNode:
			if get_parent().is_node_connected(c.name, 0, name, index):
				return c
	return null

func queue_free():
	get_parent().remove_node(self.name)
	.queue_free()
