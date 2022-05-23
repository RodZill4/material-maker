extends WindowDialog


onready var shape_names = mm_sdf_builder.get_shape_names()

onready var tree : Tree = $VBoxContainer/Main/Tree
onready var preview_2d : ColorRect = $VBoxContainer/Main/Preview2D
onready var preview_3d : ViewportContainer = $VBoxContainer/Main/Preview3D
onready var parameters_panel : GridContainer = $VBoxContainer/Main/Parameters


var scene : Array = []
var controls : Dictionary = {}
var ignore_parameter_change : String = ""

const GENERIC = preload("res://material_maker/nodes/generic/generic.gd")

const MENU_COPY : int = 1000
const MENU_PASTE : int = 1001
const MENU_DELETE : int = 1002

signal node_changed(model_data)
signal editor_window_closed


const BUTTON_SHOWN = preload("res://material_maker/icons/eye_open.tres")
const BUTTON_HIDDEN = preload("res://material_maker/icons/eye_closed.tres")


func _ready():
	tree.set_hide_root(true)
	if tree.get_root() == null:
		tree.create_item()
	#popup_centered()

func set_preview(s : Array):
	if s.empty():
		return
	var item_type = mm_sdf_builder.item_types[mm_sdf_builder.item_ids[s[0].type]]
	$GenSDF.set_sdf_scene(s)
	match item_type.item_category:
		"SDF2D":
			preview_2d.visible = true
			preview_2d.set_generator($GenSDF, 0, true)
			preview_3d.visible = false
		"SDF3D":
			preview_2d.visible = false
			preview_3d.visible = true
			preview_3d.set_generator($GenSDF, 0, true)

func set_sdf_scene(s : Array, parent = null):
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
		add_sdf_item(i, parent_item)
	if parent == null:
		set_preview(scene)
	var top = tree.get_root().get_children()
	if top != null:
		tree.get_root().get_children().select(0)

func add_sdf_item(i : Dictionary, parent_item : TreeItem) -> TreeItem:
	var item = tree.create_item(parent_item)
	item.set_text(0, i.type)
	var item_type = mm_sdf_builder.item_types[mm_sdf_builder.item_ids[i.type]]
	var item_icon = item_type.get("icon")
	if item_icon != null:
		item.set_icon(0, item_icon)
	i.index = item.get_instance_id()
	item.add_button(1, BUTTON_HIDDEN if i.has("hidden") and i.hidden else BUTTON_SHOWN, 0)
	item.set_meta("scene", i)
	set_sdf_scene(i.children, item)
	return item

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

func show_menu(current_item : TreeItem):
	var menu : PopupMenu = PopupMenu.new()
	var filter : Array = tree.get_valid_children_types(current_item)
	var add_menu : PopupMenu = mm_sdf_builder.get_items_menu("", self, "_on_menu_add_shape", [ current_item ], filter)
	menu.add_child(add_menu)
	menu.add_submenu_item("Create", add_menu.name)
	if current_item != null:
		menu.add_separator()
		menu.add_item("Copy", MENU_COPY)
	var json = parse_json(OS.clipboard)
	if json is Dictionary and json.has("is_easysdf") and json.is_easysdf:
		if current_item == null:
			menu.add_separator()
		menu.add_item("Paste", MENU_PASTE)
	if current_item != null:
		menu.add_separator()
		menu.add_item("Delete", MENU_DELETE)
	menu.connect("id_pressed", self, "_on_menu", [ current_item ])
	add_child(menu)
	menu.popup(Rect2(get_global_mouse_position(), menu.get_minimum_size()))
	menu.connect("popup_hide", menu, "queue_free")

func _on_Tree_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			var current_item : TreeItem = tree.get_item_at_position(tree.get_local_mouse_position())
			show_menu(current_item)

func delete_item(item : TreeItem):
	item.get_parent().remove_child(item)
	tree.update()
	rebuild_scene()
	set_preview(scene)

func copy_item(item : TreeItem):
	var tmp_scene : Dictionary = item.get_meta("scene").duplicate()
	tmp_scene.is_easysdf = true
	OS.clipboard = JSON.print(tmp_scene)

func paste_item(parent : TreeItem):
	var json = parse_json(OS.clipboard)
	if json is Dictionary and json.has("is_easysdf") and json.is_easysdf:
		if parent == null:
			parent = tree.get_root()
		var new_item : TreeItem = add_sdf_item(json, parent)
		rebuild_scene()
		set_preview(scene)
		new_item.select(0)

func _on_menu(id : int, current_item : TreeItem):
	match id:
		MENU_COPY:
			copy_item(current_item)
		MENU_PASTE:
			paste_item(current_item)
		MENU_DELETE:
			current_item.get_parent().remove_child(current_item)
			tree.update()
			rebuild_scene()
			set_preview(scene)

func _on_menu_add_shape(id : int, current_item : TreeItem):
	var shape = mm_sdf_builder.item_types[id]
	var shape_name = shape.item_type
	var data : Dictionary = { type=shape_name, children=[] }
	var parameters : Dictionary = {}
	data.parameters = parameters
	for p in shape.get_parameter_defs():
		if p.type == "float" and p.default is int:
			parameters[p.name] = float(p.default)
		else:
			parameters[p.name] = p.default
	var item : TreeItem
	if current_item == null:
		item = tree.create_item()
		scene.push_back(data)
	else:
		item = tree.create_item(current_item)
		current_item.get_meta("scene").children.push_back(data)
	var item_icon = shape.get("icon")
	if item_icon != null:
		item.set_icon(0, item_icon)
	data.index = item.get_instance_id()
	item.set_text(0, shape_name)
	item.set_meta("scene", data)
	item.add_button(1, BUTTON_SHOWN, 0)
	set_preview(scene)
	item.select(0)


func get_local_item_transform_2d(item : TreeItem) -> Transform2D:
	var item_transform : Transform2D = Transform2D(0, Vector2(0.0, 0.0))
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
			return t
	return Transform2D(0, Vector2(0.0, 0.0))

func get_item_transform_2d(item : TreeItem) -> Transform2D:
	var item_transform : Transform2D = Transform2D(0, Vector2(0.0, 0.0))
	while item != null:
		item_transform = get_local_item_transform_2d(item)*item_transform
		item = item.get_parent()
	return item_transform

func update_center_transform_2d():
	var center_transform : Transform2D = get_item_transform_2d(tree.get_selected().get_parent())
	preview_2d.set_center_transform(center_transform)

func update_local_transform_2d():
	var item : TreeItem = tree.get_selected()
	if item.has_meta("scene"):
		var item_scene = item.get_meta("scene")
		if item_scene.has("parameters"):
			var parameters = item_scene.parameters
			var r : float = 0.0
			if parameters.has("angle"):
				r = parameters.angle
			var s : float = 1.0
			if parameters.has("scale"):
				s = parameters.scale
			preview_2d.set_local_transform(r, s)


func get_local_item_transform_3d(item : TreeItem) -> Transform:
	if item.has_meta("scene"):
		var scene = item.get_meta("scene")
		if scene.has("parameters"):
			var parameters = scene.parameters
			var t : Transform = Transform()
			if parameters.has("angle_x") and parameters.has("angle_y") and parameters.has("angle_z"):
				t = Transform(Basis(Vector3(deg2rad(parameters.angle_x), deg2rad(parameters.angle_y), deg2rad(parameters.angle_z))))
			if parameters.has("scale"):
				t = t.scaled(Vector3(parameters.scale, parameters.scale, parameters.scale))
			if parameters.has("position_x") and parameters.has("position_y"):
				var origin = Vector3(parameters.position_x, parameters.position_y, 0.0)
				if parameters.has("position_z"):
					origin.z = parameters.position_z
				t = Transform(Basis(), origin)*t
			return t
	return Transform()

func get_item_transform_3d(item : TreeItem) -> Transform:
	var item_transform : Transform = Transform()
	while item != null:
		item_transform = get_local_item_transform_3d(item)*item_transform
		item = item.get_parent()
	return item_transform

func update_center_transform_3d():
	var parent_transform : Transform = get_item_transform_3d(tree.get_selected().get_parent())
	preview_3d.set_parent_transform(parent_transform)

func update_local_transform_3d():
	var local_transform : Transform = get_local_item_transform_3d(tree.get_selected())
	preview_3d.set_local_transform(local_transform)


func show_parameters(prefix : String):
	controls = {}
	for c in parameters_panel.get_children():
		parameters_panel.remove_child(c)
		c.free()
	for p in $GenSDF.get_filtered_parameter_defs(prefix):
		if p.has("label"):
			var label : Label = Label.new()
			label.text = p.label if p.has("label") else ""
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			parameters_panel.add_child(label)
		else:
			parameters_panel.add_child(Control.new())
		var control = GENERIC.create_parameter_control(p, false)
		control.name = p.name
		control.size_flags_horizontal = SIZE_FILL
		parameters_panel.add_child(control)
		controls[p.name] = control
	GENERIC.initialize_controls_from_generator(controls, $GenSDF, self)
	for p in $GenSDF.get_filtered_parameter_defs(prefix):
		GENERIC.update_control_from_parameter(controls, p.name, $GenSDF.get_parameter(p.name))

func _on_value_changed(new_value, variable : String) -> void:
	var value = MMType.deserialize_value(new_value)
	var item : TreeItem = instance_from_id(variable.right(1).to_int())
	var parameter_name : String = variable.right(variable.find("_")+1)
	item.get_meta("scene").parameters[parameter_name] = value
	set_preview(scene)

func _on_float_value_changed(new_value, _merge_undo : bool = false, variable : String = "") -> void:
	ignore_parameter_change = variable
	$GenSDF.set_parameter(variable, new_value)
	set_node_parameters($GenSDF, { variable:new_value })
	ignore_parameter_change = ""

func on_parameter_changed(p : String, v) -> void:
	if ignore_parameter_change == p:
		return
	else:
		GENERIC.update_control_from_parameter(controls, p, v)

func _on_Tree_item_selected():
	var scene = tree.get_selected().get_meta("scene")
	var index : int = scene.index
	show_parameters("n%d" % index)
	match $GenSDF.get_scene_type():
		"SDF2D":
			preview_2d.set_generator($GenSDF)
			update_local_transform_2d()
			update_center_transform_2d()
			preview_2d.setup_controls("n%d" % index)
			$GenSDF.set_parameter("index", float(index))
		"SDF3D":
			preview_3d.set_generator($GenSDF)
			preview_3d.mode = 1 if mm_sdf_builder.scene_get_type(scene).item_category == "SDF3D" else 0
			update_local_transform_3d()
			update_center_transform_3d()
			preview_3d.setup_controls("n%d" % index)
			$GenSDF.set_parameter("index", float(index))

func _on_Tree_button_pressed(item, column, _id):
	var item_scene : Dictionary = item.get_meta("scene")
	if item_scene.has("hidden") and item_scene.hidden:
		item_scene.erase("hidden")
		item.set_button(1, 0, BUTTON_SHOWN)
	else:
		item_scene.hidden = true
		item.set_button(1, 0, BUTTON_HIDDEN)
	set_preview(scene)

func set_node_parameters(generator, parameters):
	var parameters_changed : bool = false
	for p in parameters.keys():
		var value = MMType.deserialize_value(parameters[p])
		generator.set_parameter(p, value)
		var item : TreeItem = instance_from_id(p.right(1).to_int())
		if item != null:
			var parameter_name : String = p.right(p.find("_")+1)
			item.get_meta("scene").parameters[parameter_name] = value
			parameters_changed = true
	if parameters_changed:
		update_local_transform_2d()
		preview_2d.setup_controls("n%d" % tree.get_selected().get_meta("scene").index)
		update_local_transform_3d()

func duplicate_item(item : TreeItem, parent : TreeItem, index : int = -1):
	var new_item : TreeItem = tree.create_item(parent, index)
	new_item.set_text(0, item.get_text(0))
	new_item.set_icon(0, item.get_icon(0))
	new_item.add_button(1, item.get_button(1, 0), 0)
	new_item.set_meta("scene", item.get_meta("scene"))
	var c : TreeItem = item.get_children()
	while c != null:
		duplicate_item(c, new_item)
		c = c.get_next()
	return new_item

func move_item_2d(item, dest, position):
	var source_transform = get_item_transform_2d(item)
	var dest_transform = get_item_transform_2d(dest)
	var new_transform : Transform2D = dest_transform.affine_inverse()*source_transform
	var new_item : TreeItem = duplicate_item(item, dest, position)
	item.get_parent().remove_child(item)
	# update copy's transform parameters
	rebuild_scene()
	set_preview(scene)
	new_item.select(0)
	var index = new_item.get_meta("scene").index
	var parameters : Dictionary = {}
	parameters["n%d_angle" % index] = rad2deg(new_transform.get_rotation())
	parameters["n%d_scale" % index] = new_transform.get_scale().x
	parameters["n%d_position_x" % index] = new_transform.get_origin().x
	parameters["n%d_position_y" % index] = new_transform.get_origin().y
	set_node_parameters($GenSDF, parameters)

func _on_Tree_drop_item(item, dest, position):
	move_item_2d(item, dest, position)


# OK/Apply/Cancel buttons

func _on_Apply_pressed() -> void:
	emit_signal("node_changed", scene)

func _on_OK_pressed() -> void:
	emit_signal("node_changed", scene)
	_on_Cancel_pressed()

func _on_Cancel_pressed() -> void:
	emit_signal("editor_window_closed")
	queue_free()

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_DELETE:
					var item : TreeItem = tree.get_selected()
					if item != null:
						delete_item(item)
				KEY_X:
					if event.control:
						var item : TreeItem = tree.get_selected()
						if item != null:
							copy_item(item)
							delete_item(item)
					else:
						return
				KEY_C:
					if event.control:
						var item : TreeItem = tree.get_selected()
						if item != null:
							copy_item(item)
					else:
						return
				KEY_V:
					if event.control:
						var item : TreeItem = tree.get_selected()
						if item != null:
							paste_item(item)
					else:
						return
				KEY_Z:
					if event.control:
						pass
					else:
						return
				_:
					return
		accept_event()


