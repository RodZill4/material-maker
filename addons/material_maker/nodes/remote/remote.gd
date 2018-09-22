tool
extends "res://addons/material_maker/node_base.gd"

const LinkedControl = preload("res://addons/material_maker/widgets/linked_widgets/linked_control.tscn")
const ConfigControl = preload("res://addons/material_maker/widgets/linked_widgets/config_control.tscn")

func _ready():
	pass

func _get_shader_code(uv):
	var rv = { defs="", code="" }
	rv.rgb = "vec3(1.0)"
	return rv

func add_control(widget):
	var controls = widget.get_associated_controls()
	$Controls.add_child(controls.label)
	$Controls.add_child(widget)
	$Controls.add_child(controls.buttons)


func _on_AddLink_pressed():
	var widget = LinkedControl.instance()
	add_control(widget)
	widget.pick_linked()

func _on_AddConfig_pressed():
	var widget = ConfigControl.instance()
	add_control(widget)
	widget.pick_linked()

func _on_Remote_resize_request(new_minsize):
	print("_on_Remote_resize_request")
	rect_size = new_minsize

func _on_HBoxContainer_minimum_size_changed():
	print("_on_HBoxContainer_minimum_size_changed "+str($HBoxContainer.rect_min_size))

func serialize():
	var widgets = []
	for i in range(1, $Controls.get_child_count(), 3):
		widgets.append($Controls.get_child(i).serialize())
	var data = { type="remote", node_position={x=offset.x,y=offset.y}, editable=true, widgets=widgets }
	return data 

func deserialize(data):
	if data.has("node_position"):
		offset.x = data.node_position.x
		offset.y = data.node_position.y
	call_deferred("do_deserialize", data)

func do_deserialize(data):
	if data.has("widgets"):
		for w in data.widgets:
			var widget
			if w.type == "linked_control":
				widget = LinkedControl.instance()
			elif w.type == "config_control":
				widget = ConfigControl.instance()
			else:
				continue
			add_control(widget)
			widget.deserialize(w)
