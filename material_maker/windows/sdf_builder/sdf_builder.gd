extends Window


#onready var shape_names = mm_sdf_builder.get_shape_names()

@onready var tree : Tree = $VBoxContainer/Main/Tree
@onready var preview_2d : ColorRect = $VBoxContainer/Main/Preview2D
@onready var preview_3d : SubViewportContainer = $VBoxContainer/Main/Preview3D
@onready var node_parameters_panel : GridContainer = $VBoxContainer/Main/ScrollContainer/Parameters/NodeParameters
@onready var item_parameters_panel : GridContainer = $VBoxContainer/Main/ScrollContainer/Parameters/ItemParameters

var node_parameter_mode : bool = true

var scene : Array = []
var controls : Dictionary = {}
var ignore_parameter_change : String = ""
var next_index : int = 0

const GENERIC = preload("res://material_maker/nodes/generic/generic.gd")

const MENU_RENAME : int = 1000
const MENU_CUT : int = 1001
const MENU_COPY : int = 1002
const MENU_PASTE : int = 1003
const MENU_DELETE : int = 1004
const MENU_DUMP : int = 1005

signal node_changed(model_data)
signal editor_window_closed


const BUTTON_SHOWN = preload("res://material_maker/icons/eye_open.tres")
const BUTTON_HIDDEN = preload("res://material_maker/icons/eye_closed.tres")


func _ready():
	tree.set_hide_root(true)
	if tree.get_root() == null:
		tree.create_item()
	set_node_parameter_mode(false)

func get_next_index() -> int:
	next_index += 1
	return next_index

func get_treeitem_by_index(index : int, parent : TreeItem = tree.get_root()) -> TreeItem:
	var meta = parent.get_meta("scene")
	if meta != null and meta is Dictionary and meta.has("index") and meta.index == index:
		return parent
	for i in parent.get_children():
		var item : TreeItem = get_treeitem_by_index(index, i)
		if item != null:
			return item
	return null

func set_preview(s : Array):
	if s.is_empty():
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

func select_first_item():

	if ! tree.get_root().get_children().is_empty():
		var top : TreeItem = tree.get_root().get_children()[0]
		top.select(0)
		_on_Tree_item_selected()

func set_node_parameter_mode(b : bool = true):
	if b == node_parameter_mode:
		return
	node_parameter_mode = b
	$VBoxContainer/Main/ScrollContainer/Parameters/NodeParams.button_pressed = b
	$VBoxContainer/Main/ScrollContainer/Parameters/ItemParams.button_pressed = not b
	$GenSDF.expressions = node_parameter_mode
	set_preview(scene)
	_on_Tree_item_selected()

func _on_NodeParams_toggled(button_pressed):
	set_node_parameter_mode(button_pressed)

func _on_ItemParams_toggled(button_pressed):
	set_node_parameter_mode(not button_pressed)

func update_node_parameters_grid():
	for c in node_parameters_panel.get_children():
		node_parameters_panel.remove_child(c)
		c.free()
	var is_first : bool = true
	var button : Button
	for pi in range($GenSDF.node_parameters.size()):
		var p = $GenSDF.node_parameters[pi]
		var line_edit : LineEdit = LineEdit.new()
		line_edit.text = p.name
		line_edit.tooltip_text = p.name
		node_parameters_panel.add_child(line_edit)
		line_edit.connect("text_changed",Callable(self,"on_node_parameter_name_changed").bind( pi, line_edit ))
		line_edit.connect("text_submitted",Callable(self,"on_node_parameter_name_entered").bind( pi, line_edit ))
		line_edit.connect("focus_exited",Callable(self,"on_node_parameter_name_entered2").bind( pi, line_edit ))
		var description = preload("res://material_maker/widgets/desc_button/desc_button.tscn").instantiate()
		description.short_description = p.shortdesc if p.has("shortdesc") else ""
		description.long_description = p.longdesc if p.has("longdesc") else ""
		description.descriptions_changed.connect(self.on_node_parameter_descriptions_changed.bind( pi ))
		node_parameters_panel.add_child(description)
		var control = preload("res://material_maker/widgets/float_edit/float_edit.tscn").instantiate()
		control.min_value = p.min
		control.max_value = p.max
		control.step = p.step
		control.value = p.default
		node_parameters_panel.add_child(control)
		control.value_changed_undo.connect(self.on_node_parameter_value_changed.bind([ pi ].duplicate(true)))
		button = Button.new()
		button.icon = preload("res://material_maker/icons/edit.tres")
		node_parameters_panel.add_child(button)
		button.pressed.connect(self.edit_node_parameter.bind( pi ))
		button.tooltip_text = "Configure parameter "+p.name
		button = Button.new()
		button.icon = preload("res://material_maker/icons/remove.tres")
		button.tooltip_text = "Remove parameter"
		node_parameters_panel.add_child(button)
		button.connect("pressed",Callable(self,"remove_node_parameter").bind( pi ))
		button = Button.new()
		button.icon = preload("res://material_maker/icons/up.tres")
		button.tooltip_text = "Move parameter up"
		node_parameters_panel.add_child(button)
		if is_first:
			button.disabled = true
		else:
			button.connect("pressed",Callable(self,"move_node_parameter").bind( pi, -1 ))
		button = Button.new()
		button.icon = preload("res://material_maker/icons/down.tres")
		button.tooltip_text = "Move parameter down"
		node_parameters_panel.add_child(button)
		button.connect("pressed",Callable(self,"move_node_parameter").bind( pi, 1 ))
		is_first = false
	if button != null:
		button.disabled = true

func node_parameter_exists_already(name : String, param_index : int) -> bool:
	for pi in range($GenSDF.node_parameters.size()):
		if pi != param_index and $GenSDF.node_parameters[pi].name == name:
			return true
	return false

func create_node_parameter():
	var i : int = 1
	while node_parameter_exists_already("param"+str(i), -1):
		i += 1
	$GenSDF.node_parameters.push_back({name="param"+str(i), type="float", min=0, max=1, step=0.01, default=0.5})
	call_deferred("update_node_parameters_grid")

func on_node_parameter_name_changed(new_name : String, param_index : int, line_edit : LineEdit) -> void:
	if node_parameter_exists_already(new_name, param_index):
		line_edit.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	else:
		line_edit.add_theme_color_override("font_color", mm_globals.main_window.theme.get_color("font_color", "LineEdit"))

func on_node_parameter_name_entered(new_name : String, param_index : int, line_edit : LineEdit) -> void:
	if node_parameter_exists_already(new_name, param_index):
		line_edit.text = $GenSDF.node_parameters[param_index].name
		on_node_parameter_name_changed(line_edit.text, param_index, line_edit)
	else:
		$GenSDF.node_parameters[param_index].name = new_name
		line_edit.tooltip_text = new_name

func on_node_parameter_name_entered2(param_index : int, line_edit : LineEdit) -> void:
	on_node_parameter_name_entered(line_edit.text, param_index, line_edit)

func on_node_parameter_value_changed(new_value, _merge_undo : bool = false, param_index : int = 0) -> void:
	var variable = $GenSDF.node_parameters[param_index].name
	ignore_parameter_change = variable
	$GenSDF.set_parameter(variable, new_value)
	$GenSDF.node_parameters[param_index].default = new_value
	ignore_parameter_change = ""

func on_node_parameter_descriptions_changed(shortdesc, longdesc, param_index) -> void:
	var p : Dictionary = $GenSDF.node_parameters[param_index]
	if shortdesc == "":
		p.erase("shortdesc")
		p.erase("label")
	else:
		p.shortdesc = shortdesc
		p.label = shortdesc
	if longdesc == "":
		p.erase("longdesc")
	else:
		p.longdesc = longdesc

func edit_node_parameter(param_index) -> void:
	var p = $GenSDF.node_parameters[param_index]
	var dialog = preload("res://material_maker/nodes/remote/named_parameter_dialog.tscn").instantiate()
	add_child(dialog)
	var result = await dialog.configure_param(p.min, p.max, p.step, p.default)
	if result.keys().size() == 4:
		p.min = result.min
		p.max = result.max
		p.step = result.step
		p.default = result.default
		call_deferred("update_node_parameters_grid")

func remove_node_parameter(param_index) -> void:
	$GenSDF.node_parameters.remove_at(param_index)
	call_deferred("update_node_parameters_grid")

func move_node_parameter(param_index, offset) -> void:
	var p = $GenSDF.node_parameters[param_index]
	$GenSDF.node_parameters.remove_at(param_index)
	$GenSDF.node_parameters.insert(param_index+offset, p)
	call_deferred("update_node_parameters_grid")

func set_node_parameter_defs(np : Array):
	$GenSDF.node_parameters = np.duplicate()
	update_node_parameters_grid()

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
	select_first_item()

func add_sdf_item(i : Dictionary, parent_item : TreeItem) -> TreeItem:
	var item = tree.create_item(parent_item)
	item.set_text(0, i.name if i.has("name") else i.type)
	item.set_editable(0, true)
	var item_type = mm_sdf_builder.item_types[mm_sdf_builder.item_ids[i.type]]
	var item_icon = item_type.get("icon")
	if item_icon != null:
		item.set_icon(0, item_icon)
	i.index = get_next_index()
	item.add_button(2, BUTTON_HIDDEN if i.has("hidden") and i.hidden else BUTTON_SHOWN, 0)
	item.set_meta("scene", i)
	set_sdf_scene(i.children, item)
	if i.has("collapsed") and i.collapsed:
		item.collapsed = true
	return item

func rebuild_scene(item : TreeItem = tree.get_root()) -> Dictionary:
	var scene_list : Array = []
	for child in item.get_children():
		scene_list.push_back(rebuild_scene(child))
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
	var add_menu : PopupMenu = mm_sdf_builder.get_items_menu("", self._on_menu_add_shape.bind(current_item), filter)
	menu.add_child(add_menu)
	menu.add_submenu_item("Create", add_menu.name)
	if current_item != null:
		menu.add_separator()
		menu.add_item("Rename", MENU_RENAME)
		menu.add_item("Cut", MENU_CUT)
		menu.add_item("Copy", MENU_COPY)
	var test_json_conv = JSON.new()
	test_json_conv.parse(DisplayServer.clipboard_get())
	var json = test_json_conv.get_data()
	if json is Dictionary and json.has("is_easysdf") and json.is_easysdf:
		if current_item == null:
			menu.add_separator()
		menu.add_item("Paste", MENU_PASTE)
	if current_item != null:
		menu.add_separator()
		menu.add_item("Delete", MENU_DELETE)
		#menu.add_item("Dump", MENU_DUMP)
	add_child(menu)
	menu.id_pressed.connect(self._on_menu.bind(current_item))
	menu.popup_hide.connect(menu.queue_free)
	menu.popup(Rect2($VBoxContainer.get_local_mouse_position()+$VBoxContainer.get_screen_position(), Vector2(0, 0)))

func _on_Tree_gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var current_item : TreeItem = tree.get_item_at_position(tree.get_local_mouse_position())
			show_menu(current_item)

func delete_item(item : TreeItem):
	item.get_parent().remove_child(item)
	tree.queue_redraw()
	rebuild_scene()
	set_preview(scene)
	select_first_item()

func copy_item(item : TreeItem):
	var tmp_scene : Dictionary = mm_sdf_builder.serialize_scene([item.get_meta("scene")])[0]
	tmp_scene.is_easysdf = true
	DisplayServer.clipboard_set(JSON.stringify(tmp_scene))

func paste_item(parent : TreeItem):
	var test_json_conv = JSON.new()
	test_json_conv.parse(DisplayServer.clipboard_get())
	var json = test_json_conv.get_data()
	if json is Dictionary and json.has("is_easysdf") and json.is_easysdf:
		if parent == null:
			parent = tree.get_root()
		var new_item : TreeItem = add_sdf_item(mm_sdf_builder.deserialize_scene([json])[0], parent)
		rebuild_scene()
		set_preview(scene)
		new_item.select(0)

func _on_menu(id : int, current_item : TreeItem):
	match id:
		MENU_RENAME:
			current_item.select(0)
			tree.edit_selected()
		MENU_CUT:
			copy_item(current_item)
			delete_item(current_item)
		MENU_COPY:
			copy_item(current_item)
		MENU_PASTE:
			paste_item(current_item)
		MENU_DELETE:
			delete_item(current_item)
		MENU_DUMP:
			print(current_item.get_meta("scene"))

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
			parameters[p.name] = MMType.deserialize_value(p.default)
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
	data.index = get_next_index()
	item.set_text(0, shape_name)
	item.set_meta("scene", data)
	item.add_button(2, BUTTON_SHOWN, 0)
	set_preview(scene)
	item.select(0)

func _on_Tree_item_edited():
	var item : TreeItem = tree.get_selected()
	var item_scene : Dictionary = item.get_meta("scene")
	var name : String = item.get_text(0)
	if name == "" or name == item_scene.type:
		item_scene.erase("name")
		item.set_text(0, item_scene.type)
	else:
		item_scene.name = name

func _on_Tree_item_collapsed(item):
	var item_scene : Dictionary = item.get_meta("scene")
	if item.collapsed:
		item_scene.collapsed = true
	else:
		item_scene.erase("collapsed")

func get_local_item_transform_2d(item : TreeItem) -> Transform2D:
	if item.has_meta("scene"):
		var item_scene = item.get_meta("scene")
		if item_scene.has("parameters"):
			var parameters = item_scene.parameters
			var t : Transform2D = Transform2D(0, Vector2(0.0, 0.0))
			if parameters.has("angle"):
				t = t.rotated(deg_to_rad(parameters.angle))
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

func update_2d_orientation(root_2d : TreeItem):
	var euler : Vector3
	if root_2d != null:
		euler = get_item_transform_3d(root_2d).basis.get_euler()
	else:
		euler = Vector3(0, 0, 0)
	preview_3d.set_2d_orientation(euler)

func get_local_item_transform_3d(item : TreeItem) -> Transform3D:
	if item.has_meta("scene"):
		var item_scene = item.get_meta("scene")
		if item_scene.has("parameters"):
			var parameters = item_scene.parameters
			var t : Transform3D = Transform3D()
			if parameters.has("angle_x") and parameters.has("angle_y") and parameters.has("angle_z"):
				t = Transform3D(Basis.from_euler(Vector3(deg_to_rad(parameters.angle_x), deg_to_rad(parameters.angle_y), deg_to_rad(parameters.angle_z))))
			elif parameters.has("angle"):
				t = Transform3D(Basis.from_euler(Vector3(0, 0, deg_to_rad(parameters.angle))))
			if parameters.has("scale"):
				t = t.scaled(Vector3(parameters.scale, parameters.scale, parameters.scale))
			if parameters.has("position_x") and parameters.has("position_y"):
				var origin = Vector3(parameters.position_x, parameters.position_y, 0.0)
				if parameters.has("position_z"):
					origin.z = parameters.position_z
				t = Transform3D(Basis(), origin)*t
			return t
	return Transform3D()

func get_item_transform_3d(item : TreeItem) -> Transform3D:
	var item_transform : Transform3D = Transform3D()
	while item != null:
		item_transform = get_local_item_transform_3d(item)*item_transform
		item = item.get_parent()
	return item_transform

func update_center_transform_3d():
	var parent_transform : Transform3D = get_item_transform_3d(tree.get_selected().get_parent())
	preview_3d.set_parent_transform(parent_transform)

func update_local_transform_3d():
	var local_transform : Transform3D = get_local_item_transform_3d(tree.get_selected())
	preview_3d.set_local_transform(local_transform)

func show_node_parameters(_prefix : String):
	for c in node_parameters_panel.get_children():
		node_parameters_panel.remove_child(c)
		c.free()
	var plus_button = TextureButton.new()
	plus_button.texture_normal = preload("res://material_maker/icons/add.tres")
	node_parameters_panel.add_child(plus_button)

func show_item_parameters(prefix : String):
	var item : TreeItem = get_treeitem_by_index(prefix.right(-1).to_int())
	if item == null:
		return
	var item_scene : Dictionary = item.get_meta("scene")
	controls = {}
	for c in item_parameters_panel.get_children():
		item_parameters_panel.remove_child(c)
		c.free()
	for p in $GenSDF.get_filtered_parameter_defs(prefix):
		if p.has("label"):
			var label : Label = Label.new()
			label.text = p.label if p.has("label") else ""
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_parameters_panel.add_child(label)
		else:
			item_parameters_panel.add_child(Control.new())
		var control : Control = GENERIC.create_parameter_control(p, false)
		control.name = p.name
		control.size_flags_horizontal = Control.SIZE_FILL
		item_parameters_panel.add_child(control)
		controls[p.name] = control
		if p.type == "float":
			var button : Button = Button.new()
			button.text = "f(x)"
			item_parameters_panel.add_child(button)
			button.flat = not ( item_scene.has("parmexprs") and item_scene.parmexprs.has(p.name.right(-(p.name.find("_")+1))) )
			button.connect("pressed",Callable(self,"on_parameter_expression_button").bind( p.name ))
			if node_parameter_mode:
				control.editable = false
		else:
			item_parameters_panel.add_child(Control.new())
	GENERIC.initialize_controls_from_generator(controls, $GenSDF, self)
	for p in $GenSDF.get_filtered_parameter_defs(prefix):
		GENERIC.update_control_from_parameter(controls, p.name, $GenSDF.get_parameter(p.name))

func on_parameter_expression_button(param_full_name : String):
	var item_id : int = param_full_name.left(param_full_name.find("_")).right(-1).to_int()
	var item : TreeItem = get_treeitem_by_index(item_id)
	if item != null:
		var item_scene : Dictionary = item.get_meta("scene")
		var param_name = param_full_name.right(-(param_full_name.find("_")+1))
		var expression_editor : Window = load("res://material_maker/widgets/float_edit/expression_editor.tscn").instantiate()
		add_child(expression_editor)
		var param_value : String = item_scene.parmexprs[param_name] if ( item_scene.has("parmexprs") and item_scene.parmexprs.has(param_name) ) else ""
		expression_editor.edit_parameter("Expression editor - "+param_name, param_value, self, "set_parameter_expression", [ item_scene, param_name ], true)

func set_parameter_expression(value : String, item_scene : Dictionary, param_name : String):
	if not item_scene.has("parmexprs"):
		item_scene.parmexprs = {}
	if value == "":
		item_scene.parmexprs.erase(param_name)
	else:
		item_scene.parmexprs[param_name] = value
	if node_parameter_mode:
		set_preview(scene)
	_on_Tree_item_selected()

func _on_value_changed(new_value, variable : String) -> void:
	var value = MMType.deserialize_value(new_value)
	$GenSDF.set_parameter(variable, new_value)
	var item : TreeItem = get_treeitem_by_index(variable.right(-1).to_int())
	var parameter_name : String = variable.right(-(variable.find("_")+1))
	item.get_meta("scene").parameters[parameter_name] = value
	set_preview(scene)
	call_deferred("_on_Tree_item_selected")

func _on_float_value_changed(new_value, _merge_undo : bool = false, variable : String = "") -> void:
	ignore_parameter_change = variable
	$GenSDF.set_parameter(variable, new_value)
	set_node_parameters($GenSDF, { variable:new_value })
	ignore_parameter_change = ""

func _on_color_changed(new_color, _old_value, variable : String) -> void:
	ignore_parameter_change = variable
	$GenSDF.set_parameter(variable, MMType.serialize_value(new_color))
	set_node_parameters($GenSDF, { variable:MMType.serialize_value(new_color) })
	ignore_parameter_change = ""

func _on_polygon_changed(new_polygon, _old_value, variable : String) -> void:
	ignore_parameter_change = variable
	$GenSDF.set_parameter(variable, new_polygon)
	set_node_parameters($GenSDF, { variable:MMType.serialize_value(new_polygon) })
	ignore_parameter_change = ""

func on_parameter_changed(p : String, v) -> void:
	if ignore_parameter_change == p:
		return
	else:
		GENERIC.update_control_from_parameter(controls, p, v)

func _on_Tree_item_selected():
	var selected_item = tree.get_selected()
	if selected_item == null:
		return
	var item_scene = selected_item.get_meta("scene")
	var index : int = item_scene.index
	if index != selected_item.get_index():
		print("index don't match")
	show_item_parameters("n%d" % index)
	match $GenSDF.get_scene_type():
		"SDF2D":
			preview_2d.set_generator($GenSDF)
			if ! node_parameter_mode:
				update_local_transform_2d()
				update_center_transform_2d()
				preview_2d.setup_controls("n%d" % index)
			else:
				preview_2d.setup_controls("no_control")
			$GenSDF.set_parameter("index", float(index))
		"SDF3D":
			preview_3d.set_generator($GenSDF)
			var scene_type = mm_sdf_builder.scene_get_type(item_scene)
			if ! node_parameter_mode:
				match scene_type.item_category:
					"SDF3D":
						preview_3d.mode = 2
					"SDF2D":
						preview_3d.mode = 1
					_:
						preview_3d.mode = 0
			else:
				preview_3d.mode = 0
			update_local_transform_3d()
			update_center_transform_3d()
			var parent_3d = null
			if tree.get_sdf_item_type_name(selected_item) == "SDF2D":
				parent_3d = tree.get_nearest_parent(selected_item, "SDF3D")
			update_2d_orientation(parent_3d)
			preview_3d.setup_controls("n%d" % index)
			$GenSDF.set_parameter("index", float(index))

func _on_Tree_button_pressed(item, _column, _id):
	var item_scene : Dictionary = item.get_meta("scene")
	if item_scene.has("hidden") and item_scene.hidden:
		item_scene.erase("hidden")
		item.set_button(2, 0, BUTTON_SHOWN)
	else:
		item_scene.hidden = true
		item.set_button(2, 0, BUTTON_HIDDEN)
	set_preview(scene)
	_on_Tree_item_selected()

func set_node_parameters(generator, parameters):
	var parameters_changed : bool = false
	for p in parameters.keys():
		var value = MMType.deserialize_value(parameters[p])
		generator.set_parameter(p, value)
		var item_id : int = p.left(p.find("_")).right(-1).to_int()
		var item : TreeItem = get_treeitem_by_index(item_id)
		if item != null:
			var parameter_name : String = p.right(-(p.find("_")+1))
			if item.get_meta("scene").parameters.has(parameter_name):
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
	new_item.add_button(2, item.get_button(2, 0), 0)
	new_item.set_meta("scene", item.get_meta("scene"))
	for c in item.get_children():
		duplicate_item(c, new_item)
	return new_item

func move_item(item, dest, position):
	var source_transform : Transform3D = get_item_transform_3d(item)
	var dest_transform : Transform3D = get_item_transform_3d(dest)
	var new_transform : Transform3D = dest_transform.affine_inverse()*source_transform
	var new_item : TreeItem = duplicate_item(item, dest, position)
	item.get_parent().remove_child(item)
	# update copy's transform parameters
	rebuild_scene()
	set_preview(scene)
	new_item.select(0)
	var index = new_item.get_meta("scene").index
	var parameters : Dictionary = {}
	var angle_euler : Vector3 = new_transform.basis.get_euler()
	parameters["n%d_angle" % index] = rad_to_deg(angle_euler.z)
	parameters["n%d_angle_x" % index] = rad_to_deg(angle_euler.x)
	parameters["n%d_angle_y" % index] = rad_to_deg(angle_euler.y)
	parameters["n%d_angle_z" % index] = rad_to_deg(angle_euler.z)
	parameters["n%d_scale" % index] = new_transform.basis.get_scale().x
	parameters["n%d_position_x" % index] = new_transform.origin.x
	parameters["n%d_position_y" % index] = new_transform.origin.y
	parameters["n%d_position_z" % index] = new_transform.origin.z
	set_node_parameters($GenSDF, parameters)

func _on_Tree_drop_item(item, dest, position):
	move_item(item, dest, position)


# OK/Apply/Cancel buttons

func _on_Apply_pressed() -> void:
	emit_signal("node_changed", { parameters=$GenSDF.node_parameters, scene=scene })

func _on_OK_pressed() -> void:
	_on_Apply_pressed()
	_on_Cancel_pressed()

func _on_Cancel_pressed() -> void:
	emit_signal("editor_window_closed")
	queue_free()

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
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
		$VBoxContainer.accept_event()

func _on_VBoxContainer_minimum_size_changed():
	min_size = $VBoxContainer.get_minimum_size()+Vector2(4, 4)
