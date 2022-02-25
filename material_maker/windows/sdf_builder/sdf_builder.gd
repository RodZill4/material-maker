extends WindowDialog


onready var shape_names = mm_sdf_builder.get_shape_names()

onready var tree : Tree = $VBoxContainer/Main/Tree


var scene : Array = []
var controls : Dictionary = {}
var ignore_parameter_change : String = ""

const GENERIC = preload("res://material_maker/nodes/generic/generic.gd")


signal node_changed(model_data)
signal editor_window_closed


func _ready():
	tree.set_hide_root(true)
	if tree.get_root() == null:
		tree.create_item()

func set_sdf_scene(s, parent = null):
	var parent_item
	if parent == null:
		scene = s.duplicate(true)
		s = scene
		tree.clear()
		tree.create_item()
		parent_item = tree.get_root()
	else:
		parent_item = parent
	for i in s:
		var item = tree.create_item(parent_item)
		item.set_text(0, i.type)
		i.index = item.get_instance_id()
		item.set_meta("scene", i)
		set_sdf_scene(i.children, item)
	if parent == null:
		$GenSDF.set_sdf_scene(scene)
		$VBoxContainer/Main/Preview2D.set_generator($GenSDF, 0, true)
	var top = tree.get_root().get_children()
	if top != null:
		tree.get_root().get_children().select(0)

var current_item : TreeItem
func _on_Tree_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			current_item = tree.get_item_at_position(tree.get_local_mouse_position())
			var menu : PopupMenu = PopupMenu.new()
			for shape_name in shape_names:
				menu.add_item(shape_name)
			add_child(menu)
			menu.popup(Rect2(get_global_mouse_position(), menu.get_minimum_size()))
			menu.connect("id_pressed", self, "_on_menu_add_shape")
			menu.connect("popup_hide", menu, "queue_free")

func _on_menu_add_shape(id : int):
	var shape_name = shape_names[id]
	var data : Dictionary = { type=shape_name, children=[] }
	var parameters : Dictionary = {}
	data.parameters = parameters
	for p in mm_sdf_builder.get_node(shape_name).get_parameter_defs():
		parameters[p.name] = p.default
	var item : TreeItem
	if current_item == null:
		item = tree.create_item()
		scene.push_back(data)
	else:
		item = tree.create_item(current_item)
		current_item.get_meta("scene").children.push_back(data)
	data.index = item.get_instance_id()
	item.set_text(0, shape_name)
	item.set_meta("scene", data)
	$GenSDF.set_sdf_scene(scene)
	$VBoxContainer/Main/Preview2D.set_generator($GenSDF, 0, true)
	item.select(0)

func get_item_transform(item : TreeItem) -> Transform2D:
	var item_transform : Transform2D = Transform2D(0, Vector2(0.0, 0.0))
	while item != null:
		if item.has_meta("scene"):
			var scene = item.get_meta("scene")
			if scene.has("parameters"):
				var parameters = scene.parameters
				var t : Transform2D = Transform2D(0, Vector2(0.0, 0.0))
				if parameters.has("angle"):
					t = t.rotated(deg2rad(parameters.angle))
				if parameters.has("scale"):
					t = t.scaled(Vector2(parameters.scale, parameters.scale))
				if parameters.has("position_x") and parameters.has("position_y"):
					t = Transform2D(0, Vector2(parameters.position_x, parameters.position_y))*t
				item_transform = t*item_transform
		item = item.get_parent()
	return item_transform

func update_center_transform():
	var center_transform : Transform2D = get_item_transform(tree.get_selected().get_parent())
	$VBoxContainer/Main/Preview2D.set_center_transform(center_transform)

func update_local_transform():
	var item : TreeItem = tree.get_selected()
	if item.has_meta("scene"):
		var scene = item.get_meta("scene")
		if scene.has("parameters"):
			var parameters = scene.parameters
			var r : float = 0.0
			if parameters.has("angle"):
				r = parameters.angle
			var s : float = 1.0
			if parameters.has("scale"):
				s = parameters.scale
			$VBoxContainer/Main/Preview2D.set_local_transform(r, s)

func show_parameters(prefix : String):
	controls = {}
	for c in $VBoxContainer/Main/Parameters.get_children():
		$VBoxContainer/Main/Parameters.remove_child(c)
		c.free()
	for p in $GenSDF.get_filtered_parameter_defs(prefix):
		if p.has("label"):
			var label : Label = Label.new()
			label.text = p.label if p.has("label") else ""
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			$VBoxContainer/Main/Parameters.add_child(label)
		else:
			$VBoxContainer/Main/Parameters.add_child(Control.new())
		var control = GENERIC.create_parameter_control(p, false)
		control.name = p.name
		control.size_flags_horizontal = SIZE_FILL
		$VBoxContainer/Main/Parameters.add_child(control)
		controls[p.name] = control
	GENERIC.initialize_controls_from_generator(controls, $GenSDF, self)

func _on_float_value_changed(new_value, merge_undo : bool = false, variable : String = "") -> void:
	ignore_parameter_change = variable
	$GenSDF.set_parameter(variable, new_value)
	set_node_parameters($GenSDF, { variable:new_value })
	ignore_parameter_change = ""

func on_parameter_changed(p : String, v) -> void:
	if ignore_parameter_change == p:
		return
	else:
		GENERIC.update_control_from_parameter(controls, p, v)

func _on_Tree_cell_selected():
	$VBoxContainer/Main/Preview2D.set_generator($GenSDF)
	update_local_transform()
	update_center_transform()
	var index : int = tree.get_selected().get_meta("scene").index
	$VBoxContainer/Main/Preview2D.setup_controls("n%d" % index)
	show_parameters("n%d" % index)
	$GenSDF.set_parameter("index", float(index))

func set_node_parameters(generator, parameters):
	print(parameters)
	for p in parameters.keys():
		var value = MMType.deserialize_value(parameters[p])
		generator.set_parameter(p, MMType.deserialize_value(parameters[p]))
		var item : TreeItem = instance_from_id(p.right(1).to_int())
		var parameter_name : String = p.right(p.find("_")+1)
		item.get_meta("scene").parameters[parameter_name] = value
		print(item.get_meta("scene"))
	update_local_transform()
	$VBoxContainer/Main/Preview2D.setup_controls("n%d" % tree.get_selected().get_meta("scene").index)

func copy_item(item : TreeItem, parent : TreeItem, index : int = -1):
	var new_item : TreeItem = tree.create_item(parent, index)
	new_item.set_text(0, item.get_text(0))
	new_item.set_meta("scene", item.get_meta("scene"))
	var c : TreeItem = item.get_children()
	while c != null:
		copy_item(c, new_item)
		c = c.get_next()
	return new_item

func rebuild_scene(item : TreeItem = tree.get_root()) -> Dictionary:
	var scene_list : Array = []
	var child : TreeItem = item.get_children()
	while child != null:
		scene_list.push_back(rebuild_scene(child))
		child = child.get_next()
	if item == tree.get_root():
		scene = scene_list
		return {}
	else:
		var item_scene : Dictionary = item.get_meta("scene")
		item_scene.children = scene_list
		return item_scene

func _on_Tree_drop_item(item, dest, position):
	var source_transform = get_item_transform(item)
	var dest_transform = get_item_transform(dest)
	var new_transform : Transform2D = dest_transform.affine_inverse()*source_transform
	var new_item : TreeItem = copy_item(item, dest, position)
	item.get_parent().remove_child(item)
	# update copy's transform parameters
	rebuild_scene()
	$GenSDF.set_sdf_scene(scene)
	$VBoxContainer/Main/Preview2D.set_generator($GenSDF, 0, true)
	new_item.select(0)
	var index = new_item.get_meta("scene").index
	var parameters : Dictionary = {}
	parameters["n%d_angle" % index] = rad2deg(new_transform.get_rotation())
	parameters["n%d_scale" % index] = new_transform.get_scale().x
	parameters["n%d_position_x" % index] = new_transform.get_origin().x
	parameters["n%d_position_y" % index] = new_transform.get_origin().y
	set_node_parameters($GenSDF, parameters)

# OK/Apply/Cancel buttons

func _on_Apply_pressed() -> void:
	emit_signal("node_changed", scene)

func _on_OK_pressed() -> void:
	emit_signal("node_changed", scene)
	_on_Cancel_pressed()

func _on_Cancel_pressed() -> void:
	emit_signal("editor_window_closed")
	queue_free()
