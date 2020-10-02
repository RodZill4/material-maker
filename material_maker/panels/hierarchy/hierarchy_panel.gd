extends VBoxContainer

export(int, 0, 3) var preview : int = 0

onready var tree = $Tree

var config_cache : ConfigFile

var default_texture : ImageTexture = null
var current_graph_edit = null
var current_generator = null
var item_from_gen : Dictionary = {}
var update_index = 0

var pending_updates = {}

signal group_selected

func _ready() -> void:
	if config_cache.has_section_key("hierarchy", "previews"):
		preview = config_cache.get_value("hierarchy", "previews")
	var default_image = Image.new()
	default_image.create(24, 24, false, Image.FORMAT_RGBA8)
	default_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	default_texture = ImageTexture.new()
	default_texture.create_from_image(default_image)
	
	$HBoxContainer/PreviewMenu.get_popup().connect("id_pressed", self, "_on_PreviewMenu_id_pressed")

func update_from_graph_edit(graph_edit) -> void:
	$Delay.stop()
	pending_updates = {}
	update_index += 1
	for g in item_from_gen.keys():
		if is_instance_valid(g):
			g.disconnect("parameter_changed", self, "on_gen_parameter_changed")
	item_from_gen = {}
	tree.set_column_expand(0, true)
	tree.columns = preview+1
	for i in range(1, tree.columns):
		tree.set_column_expand(i, false)
		tree.set_column_min_width(i, 28)
	tree.clear()
	pending_updates = {}
	if current_graph_edit != null and is_instance_valid(current_graph_edit):
		current_graph_edit.disconnect("view_updated", self, "on_view_updated")
	if current_generator != null and is_instance_valid(current_generator):
		current_generator.disconnect("hierarchy_changed", self, "on_hierarchy_changed")
	if graph_edit == null or graph_edit.top_generator == null or graph_edit.generator == null:
		current_graph_edit = null
		current_generator = null
		return
	current_graph_edit = graph_edit
	current_graph_edit.connect("view_updated", self, "on_view_updated")
	current_generator = graph_edit.generator
	current_generator.connect("hierarchy_changed", self, "on_hierarchy_changed")
	var file_name = "PTex"
	if graph_edit.save_path != null:
		file_name = graph_edit.save_path.get_file()
	fill_item(tree.create_item(null), graph_edit.top_generator, graph_edit.generator, file_name)

func set_icon(item : TreeItem, generator : MMGenGraph, output : int) -> void:
	var index = update_index
	if output >= preview:
		return
	if mm_renderer.render_queue_size > 0:
		yield(mm_renderer, "render_queue_empty")
	var result = generator.render(self, output, 24, true)
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	if index == update_index:
		var tex = ImageTexture.new()
		result.copy_to_texture(tex)
		result.release(self)
# warning-ignore:narrowing_conversion
		item.set_icon(1-min(generator.get_output_defs().size()-preview, 0)+output, tex)
	else:
		result.release(self)

func fill_item(item : TreeItem, generator : MMGenGraph, selected : MMGenGraph, name = null) -> void:
	item.set_text(0, name if name != null else generator.get_type_name())
	if generator == selected:
		item.set_custom_color(0, Color(0.5, 0.5, 1))
	else:
		item.clear_custom_color(0)
	item.set_metadata(0, generator)
	item_from_gen[generator] = item
	generator.connect("parameter_changed", self, "on_gen_parameter_changed", [ generator ])
	if preview > 0 and generator.get_output_defs().size() > 0:
		for i in range(min(preview, generator.get_output_defs().size())):
			item.set_icon(i+1, default_texture)
		var output_count = min(generator.get_output_defs().size(), preview)
		for output in range(output_count):
			on_gen_output_changed(output, generator)
	for c in generator.get_children():
		if c is MMGenGraph:
			if c.is_template():
				continue
			fill_item(tree.create_item(item), c, selected)

func _on_Hierarchy_item_double_clicked() -> void:
	emit_signal("group_selected", tree.get_selected().get_metadata(0))

func on_view_updated(generator) -> void:
	assert(generator is MMGenGraph)
	if item_from_gen.has(current_generator):
		item_from_gen[current_generator].clear_custom_color(0)
	current_generator = generator
	if item_from_gen.has(current_generator):
		item_from_gen[current_generator].set_custom_color(0, Color(0.5, 0.5, 1))

func on_gen_parameter_changed(param_name : String, _value, generator) -> void:
	if param_name == "__output_changed__":
		for index in range(preview):
			on_gen_output_changed(index, generator)

func on_gen_output_changed(index : int, generator) -> void:
	if item_from_gen.has(generator) and index < preview:
		if !pending_updates.has(generator):
			pending_updates[generator] = [index]
		elif pending_updates[generator].find(index) == -1:
			pending_updates[generator].push_back(index)
		$Delay.stop()
		$Delay.start()

func on_hierarchy_changed() -> void:
	update_from_graph_edit(current_graph_edit)

func _on_Delay_timeout() -> void:
	for generator in pending_updates.keys():
		var item = item_from_gen[generator]
		for index in pending_updates[generator]:
			set_icon(item, generator, index)


func _on_PreviewMenu_id_pressed(id):
	preview = id
	config_cache.set_value("hierarchy", "previews", preview)
	update_from_graph_edit(current_graph_edit)


func expand_all(item : TreeItem, expand : bool) -> void:
	item = item.get_children()
	while item != null:
		item.collapsed = !expand
		item = item.get_next()

func _on_Expand_pressed():
	expand_all(tree.get_root(), true)

func _on_Collapse_pressed():
	expand_all(tree.get_root(), false)
