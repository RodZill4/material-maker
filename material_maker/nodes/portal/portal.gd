extends MMGraphNodeMinimal
class_name MMGraphPortal

const LABEL_FONT = preload("res://material_maker/theme/font_rubik/Rubik-416.ttf")

## Whether portal's link is being edited
## (i.e. its associated LineEdit is visible)
var is_editing := false

var syncing_io := false

var is_navigating_source : bool = false

func _ready() -> void:
	super._ready()
	get_titlebar_hbox().get_children().map(func(n): n.hide())
	on_connections_changed.call_deferred()
	size = Vector2.ZERO

func update_node() -> void:
	# handle ctrl/cmd-w editing
	if not is_editing and generator.editable:
		setup_portal_edit()

func _draw() -> void:
	const label_font_size : int = 16
	const label_y_offset : int = 40

	# in/out arc decoration
	var offset : float = PI if is_portal_out() else 0.0
	draw_rounded_arc(size * 0.5, 12.0, PI * 0.35 + offset, -PI * 0.35 + offset, get_slot_color_left(0), 5.0, true)

	# label
	var label_pos := size * 0.5
	var label_color : Color = generator.color

	var label_size = LABEL_FONT.get_string_size(get_link(), HORIZONTAL_ALIGNMENT_CENTER, -1, label_font_size)
	var label_draw_pos := label_pos - Vector2(label_size.x * 0.5, label_y_offset)
	if not is_editing:
		draw_string_outline(LABEL_FONT, label_draw_pos, get_link(), HORIZONTAL_ALIGNMENT_CENTER, -1, label_font_size, 5, Color.BLACK)
		draw_string(LABEL_FONT, label_draw_pos, get_link(), HORIZONTAL_ALIGNMENT_CENTER, -1, label_font_size, label_color)

	# label dragger
	%Dragger.mouse_filter = MOUSE_FILTER_IGNORE if is_editing else MOUSE_FILTER_PASS
	%Dragger.position = label_draw_pos - Vector2(0.0, label_font_size)
	%Dragger.size = label_size

func set_generator(g : MMGenBase) -> void:
	super.set_generator(g)
	generator.parameter_changed.connect(on_parameter_changed)
	generator.target_updated.connect(on_gen_target_updated)
	set_link_from_selection()
	set_unique_portal_link()
	reset_slot()
	sync_io_slots()
	notify_redraw()

func on_gen_target_updated(gen_name : String) -> void:
	var node_path := NodePath("node_" + gen_name)
	if get_parent() != null and get_parent().has_node(node_path):
		get_parent().get_node(node_path).on_connections_changed.call_deferred()

func on_parameter_changed(n : String, v : Variant) -> void:
	if n == "link":
		generator.set_parameter(n, v)
		sync_io_slots()
		notify_redraw()

func _draw_port(_slot_index : int, pos : Vector2i, _left : bool, color : Color) -> void:
	draw_circle(pos, 5, color, true, -1, true)

func _exit_tree() -> void:
	var source_node : MMGraphPortal = get_link_source(get_link(), get_parent())
	if source_node != null and source_node == self:
		for node in get_parent().get_children():
			if node is MMGraphPortal and node.is_portal_out() and node.get_link() == get_link():
				node.generator.notify_output_change(0)
				node.reset_slot()

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and not event.alt_pressed:
		setup_portal_edit()

func mouse_in_node_rect() -> bool:
	return Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())

func mouse_in_label_rect() -> bool:
	return %Dragger.get_rect().has_point(get_local_mouse_position())

func set_link_hint(enabled : bool) -> void:
	if is_portal_out():
		for node : Control in [self, %Dragger]:
			node.mouse_default_cursor_shape = CURSOR_POINTING_HAND if enabled else CURSOR_ARROW

func jump_to_source() -> void:
	if is_navigating_source or is_portal_in():
		return
	is_navigating_source = true
	set_link_hint(false)
	var graph : MMGraphEdit = get_parent()
	if not graph:
		return
	var source_portal : MMGraphPortal = get_link_source(get_link(), graph)
	if source_portal != null:
		graph.scroll_offset = (source_portal.position_offset
			+ 0.5 * source_portal.size) * graph.zoom - 0.5 * graph.size

	var tween : Tween = get_tree().create_tween()
	tween.tween_property(source_portal, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(source_portal, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_CUBIC).set_delay(0.5)
	source_portal.set_deferred("selected", true)
	await tween.finished
	is_navigating_source = false

func set_portal_tip_text() -> void:
	const editing_tip : String = "Enter: Rename, Ctrl/Cmd+Enter: Batch rename"
	var normal_tip = "%s#LMB: Select node, #LMB#LMB/F2/Enter: Rename"
	normal_tip = normal_tip % ["Alt + #LMB: Jump to source, " if is_portal_out() else ""]
	if mouse_in_node_rect():
		mm_globals.set_tip_text(tr(normal_tip), 1.0, 2)
	elif mouse_in_label_rect():
		mm_globals.set_tip_text(tr(editing_tip if is_editing else normal_tip), 1.0, 2)

func _input(event : InputEvent) -> void:
	if event is InputEventKey:
		match event.get_keycode_with_modifiers():
			KEY_F2, KEY_ENTER:
				if event.pressed and selected and not is_editing:
					setup_portal_edit()
			KEY_ALT:
				set_link_hint(event.pressed)
	elif event is InputEventMouseMotion:
		set_portal_tip_text()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.alt_pressed and (mouse_in_node_rect() or mouse_in_label_rect()):
			accept_event()
			jump_to_source()

func _on_dragger_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		set_deferred("selected", true)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		position_offset += event.relative
		selected = true
		accept_event()

func _on_node_selected() -> void:
	notify_redraw()

func _on_node_deselected() -> void:
	notify_redraw()

func is_portal_in() -> bool:
	return generator.io == MMGenPortal.Portal.IN

func is_portal_out() -> bool:
	return not is_portal_in()

func reset_slot() -> void:
	generator.port_type = "any"
	set_slot(0, is_portal_in(), 42, Color.WHITE, is_portal_out(), 42, Color.WHITE)

func add_link_undoredo(old_link : String, new_link : String) -> void:
	if old_link != new_link and get_parent().get("undoredo") != null:
		var node_hier_name : String = generator.get_hier_name()
		var undo_command = { type="setparams", node=node_hier_name, params={ link=old_link } }
		var redo_command = { type="setparams", node=node_hier_name, params={ link=new_link } }
		get_parent().undoredo.add("Set link parameter", [ undo_command ], [ redo_command ], false)

func get_link() -> String:
	return generator.get_parameter("link")

func sync_io_slots() -> void:
	var graph_edit : MMGraphEdit = get_parent()
	if syncing_io or graph_edit == null:
		return
	syncing_io = true
	await get_tree().process_frame
	var color := Color.WHITE
	var type := 42
	var port_type := "any"
	if is_portal_in():
		var source_node : MMGraphPortal = get_link_source(get_link(), graph_edit)
		for w in graph_edit.get_children():
			if w is MMGraphPortal and w.is_portal_out():
				if w.get_link() == get_link() and source_node and source_node == self:
					color = get_slot_color_left(0)
					type = get_slot_type_left(0)
					w.set_slot(0, false, type, color, true, type, color)
					w.generator.port_type = generator.port_type
					w.generator.notify_output_change(0)
				elif get_link_source(w.get_link(), graph_edit) == null:
					w.reset_slot()
					w.generator.notify_output_change(0)
	else:
		for w in graph_edit.get_children():
			if w is MMGraphPortal and w.is_portal_in() and w.get_link() == get_link():
				color = w.get_slot_color_left(0)
				type = w.get_slot_type_left(0)
				port_type = w.generator.port_type
				break
		set_slot(0, false, type, color, true, type, color)
		generator.port_type = port_type
	syncing_io = false

func on_connections_changed() -> void:
	if is_portal_in():
		var graph_edit : MMGraphEdit = get_parent()
		if graph_edit == null:
			return
		var color := Color.WHITE
		var type := 42
		var port_type := "any"
		for c in graph_edit.get_connection_list():
			if c.to_node == name and is_portal_in():
				var node : MMGraphNodeMinimal = graph_edit.get_node(NodePath(c.from_node))
				color = node.get_slot_color_right(c.from_port)
				type = node.get_slot_type_right(c.from_port)
				port_type = node.generator.get_output_defs()[c.from_port].type
				break
		set_slot(0, true, type, color, false, type, color)
		generator.port_type = port_type
	sync_io_slots()

func draw_rounded_arc(center : Vector2, radius : float, start : float, end : float,
		color : Color, width : float, aa : bool, point_count : int = 12) -> void:
	draw_arc(center, radius, start, end, point_count, color, width, aa)
	draw_circle(center + Vector2(cos(start), sin(start)) * radius, width * 0.5, color, true, -1.0, aa)
	draw_circle(center + Vector2(cos(end), sin(end)) * radius, width * 0.5, color, true, -1.0, aa)

static func graph_node_center(n : GraphNode, g : MMGraphEdit) -> Vector2:
	return (n.position_offset + n.size * 0.5) * g.zoom - g.scroll_offset

## Returns first input portal node with matching [param link] name.
static func get_link_source(link : String, g : MMGraphEdit) -> MMGraphPortal:
	for n in g.get_children():
		if n is MMGraphPortal and n.is_portal_in() and n.get_link() == link:
			return n
	return null

## Returns [code]true[/code] if portal(input) link is unique in the current graph.
func is_link_unique(link : String = get_link()) -> bool:
	if is_portal_in():
		for n in get_parent().get_children():
			if n is MMGraphPortal and n.is_portal_in() and n.get_link() == link and n != self:
				return false
	return true

## Sets next available unique link in the current graph
func set_unique_portal_link() -> void:
	if is_portal_in() and not is_link_unique():
		if name == "node_" + generator.get_type():
			generator.set_parameter("link", "aperture_1")
		else:
			var next_available_id := 2
			var graph : GraphEdit = get_parent()
			var portal_input_links : PackedStringArray = graph.get_children().filter(
					func(w) -> bool: return w is MMGraphPortal and w.is_portal_in() and w != self).map(
					func(w) -> String: return w.get_link())
			while ("aperture_%s" % next_available_id) in portal_input_links:
				next_available_id += 1
			generator.set_parameter("link", "aperture_%s" % next_available_id)

func link_collision_warning_color(link : String = get_link()) -> Color:
	return Color.WHITE if is_link_unique(link) else Color.RED.lightened(0.4)

func set_link_from_selection() -> void:
	# Copy selected input portal's link for newly added output portal nodes
	var selected_nodes : Array = get_parent().get_selected_nodes()
	if selected_nodes.size() == 1 and selected_nodes[0] is MMGraphPortal:
		var source_portal : MMGraphPortal = selected_nodes[0]
		if source_portal.is_portal_in():
			generator.set_parameter("link", source_portal.get_link())

func set_color(c : Color) -> void:
	if c == generator.color:
		return
	var _undo_action = { type="node_color_change", node=generator.get_hier_name(), color=generator.color }
	var _redo_action = { type="node_color_change", node=generator.get_hier_name(), color=c }
	get_parent().undoredo.add("Change portal color", [_undo_action], [_redo_action], false)
	generator.color = c
	queue_redraw()
	get_parent().send_changed_signal()

#region portal link edit

## Replaces all links from [param from_link] to [param new_link].
## If an input link collision is found, only outputs will be updated.
func replace_links(new_link : String, from_link : String) -> void:
	var g : MMGraphEdit = get_parent()
	if g == null:
		return
	var existing_input := get_link_source(new_link, g) != null
	for p in g.get_children():
		if p is MMGraphPortal and p != self and p.get_link() == from_link:
			p.add_link_undoredo(p.get_link(), new_link)
			if p.is_portal_in() and existing_input:
				continue
			else:
				p.on_parameter_changed("link", new_link)

func edit_box_set_position(edit : LineEdit) -> void:
	const y_offset : int = 61
	var g : MMGraphEdit = get_parent()
	if g == null:
		edit.queue_free()
		return
	edit.scale = Vector2.ONE * g.zoom
	edit.position = graph_node_center(self, g)
	edit.position -= Vector2(edit.size.x * 0.5 - 0.5, y_offset) * g.zoom

func setup_portal_edit() -> void:
	if is_editing:
		return
	is_editing = true

	var old_link := get_link()
	var graph : MMGraphEdit = get_parent()
	var edit := LineEdit.new()
	edit.add_theme_font_override("font", LABEL_FONT)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.max_length = 64
	edit.expand_to_text_length = true
	edit.text = old_link
	edit.select_all()

	edit_box_set_position(edit)
	position_offset_changed.connect(edit_box_set_position.bind(edit))
	graph.draw.connect(edit_box_set_position.bind(edit))

	edit.modulate = link_collision_warning_color(get_link())
	edit.text_submitted.connect(
		func(new_text : String) -> void:
			if not is_editing:
				return
			var new_link := new_text.strip_edges()
			if not new_link.is_empty():
				if is_link_unique(new_link):
					graph.undoredo.start_group()
					on_parameter_changed("link", new_link)
					add_link_undoredo(old_link, new_link)
					if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
						replace_links(new_link, old_link)
					graph.undoredo.end_group()
				else:
					on_parameter_changed("link", old_link)
			is_editing = false
			generator.editable = false
			edit.reset_size()
			edit.queue_free())
	edit.text_changed.connect(
		func(new_text : String) -> void:
			var new_link := new_text.strip_edges()
			if not new_link.is_empty():
				on_parameter_changed("link", new_link)
				edit.modulate = link_collision_warning_color(new_link)
			edit_box_set_position(edit))
	edit.focus_exited.connect(func(): edit.text_submitted.emit(edit.text))
	edit.tree_exiting.connect(
		func() -> void:
			position_offset_changed.disconnect(edit_box_set_position)
			graph.draw.disconnect(edit_box_set_position))

	graph.add_child(edit)
	edit.grab_focus.call_deferred()

#endregion portal link edit

#region links drawing

func notify_redraw() -> void:
	if get_parent() != null:
		get_parent().queue_redraw()

static func draw_links(g : MMGraphEdit) -> void:
	const circle_r : int = 24
	const circle_outline_width : int = 6
	const dash_length : float = 5.0
	const link_width : float = 5.0

	var zoom : float = g.zoom
	var in_color := g.get_theme_color("in_color", "MM_Portal")
	var out_color := g.get_theme_color("out_color", "MM_Portal")
	var link_color := g.get_theme_color("link", "MM_Portal")

	for node in g.get_children():
		if node is not MMGraphPortal:
			continue
		var wo : MMGraphPortal = node

		# portal link and circular highlight
		if wo.is_portal_out():
			var wi := get_link_source(wo.get_link(), g)
			if wi == null:
				continue
			var from : Vector2 = graph_node_center(wi, g)
			var to : Vector2 = graph_node_center(wo, g)
			if wo.selected or wi.selected:
				# link / io highlight
				g.draw_dashed_line(from, to, link_color, link_width, dash_length, true, true)
				g.draw_circle(from, circle_r * zoom, in_color, false, circle_outline_width * zoom, true)
				g.draw_circle(to, circle_r * zoom, out_color, false, circle_outline_width * zoom, true)

				# arrow
				var mid := (from + to) * 0.5
				var dir_a := (from - to).normalized().rotated(-PI * 0.25)
				var dir_b := (from - to).normalized().rotated(PI * 0.25)
				var aw := maxf(20.0 * zoom, 15.0)
				g.draw_multiline(PackedVector2Array([
					mid, mid + dir_a * aw,
					mid, mid + dir_b * aw]), link_color, link_width*0.8, true)

#endregion
