extends WindowDialog


onready var shape_names = mm_sdf_builder.get_shape_names()

onready var tree : Tree = $VBoxContainer/Main/Tree

var scene : Array = []

func _ready():
	tree.set_hide_root(true)
	if tree.get_root() == null:
		tree.create_item()
	popup_centered()

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
	$GenSDF.set_scene(scene)
	$VBoxContainer/Main/Preview2D.set_generator($GenSDF, 0, true)
	item.select(0)

func update_center_transform():
	var center_transform : Transform2D = Transform2D(0, Vector2(0.0, 0.0))
	var parent_item : TreeItem = tree.get_selected().get_parent()
	while parent_item != null:
		if parent_item.has_meta("scene"):
			var scene = parent_item.get_meta("scene")
			if scene.has("parameters"):
				var parameters = scene.parameters
				var t : Transform2D = Transform2D(0, Vector2(0.0, 0.0))
				if parameters.has("angle"):
					t = t.rotated(deg2rad(parameters.angle))
				if parameters.has("scale"):
					t = t.scaled(Vector2(parameters.scale, parameters.scale))
				if parameters.has("position_x") and parameters.has("position_y"):
					t = Transform2D(0, Vector2(parameters.position_x, parameters.position_y))*t
				center_transform = t*center_transform
		parent_item = parent_item.get_parent()
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

func _on_Tree_cell_selected():
	$VBoxContainer/Main/Preview2D.set_generator($GenSDF)
	update_local_transform()
	update_center_transform()
	var index : int = tree.get_selected().get_meta("scene").index
	$VBoxContainer/Main/Preview2D.setup_controls("n%d" % index)
	$GenSDF.set_parameter("index", float(index))

func set_node_parameters(generator, parameters):
	for p in parameters.keys():
		var value = MMType.deserialize_value(parameters[p])
		generator.set_parameter(p, MMType.deserialize_value(parameters[p]))
		var item : TreeItem = instance_from_id(p.right(1).to_int())
		var parameter_name : String = p.right(p.find("_")+1)
		item.get_meta("scene").parameters[parameter_name] = value
	update_local_transform()
	$VBoxContainer/Main/Preview2D.setup_controls("n%d" % tree.get_selected().get_meta("scene").index)
