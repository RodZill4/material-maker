class_name NodeActionsPanel
extends PanelContainer

## floating panel for node titlebar actions, mainly for touch.

static var sb_selection : StyleBoxFlat

const BUTTON_SIZE : Vector2 = Vector2(16, 16)
const H_PAD : int = 16
const AREA_PAD : int = 24
const PADDING : Vector2 = Vector2(AREA_PAD + H_PAD, -AREA_PAD)
const AVOID_PAD : int = 12

var parent : MMGraphEdit
var selection_area : Rect2

var is_updating : bool = false
var is_theme_updating : bool = false

var selected_nodes : Array

var container : VBoxContainer
var buttons : Dictionary[String, ActionButton]

func _init(graph : MMGraphEdit) -> void:
	name = "NodeActionsPanel"
	parent = graph
	parent.add_child(self)
	scale = Vector2(2.5, 2.5)
	top_level = true

func _ready() -> void:
	hide()
	init_stylebox()
	setup_signals()

	container = VBoxContainer.new()
	add_child(container)
	create_buttons()

	theme_type_variation = "MM_PanelMenuSubPanel"

func _notification(what : int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		if not is_node_ready():
			await ready
		update_button_icons()
		update_stylebox()

func _input(event : InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventPanGesture and event.delta.length():
		hide_panel()

func viewport_focus_changed(c : Control) -> void:
	if visible and c.owner and c.owner.get_script() in [GradientPopup, GradientEdit]:
		hide_panel()

func setup_signals() -> void:
	get_viewport().gui_focus_changed.connect(viewport_focus_changed)
	parent.node_selected.connect(should_panel_update.unbind(1))
	parent.scroll_offset_changed.connect(should_panel_update.unbind(1))
	parent.node_deselected.connect(hide_panel.unbind(1))
	parent.begin_node_move.connect(hide_panel)
	parent.connection_drag_started.connect(hide_panel.unbind(3))
	parent.draw.connect(draw_selection_area)

class ActionButton extends Button:
	## Emitted when button is right clicked (long pressed for touch)
	signal on_show_popup

	func _gui_input(event : InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				on_show_popup.emit()

	func disconnect_actions() -> void:
		for s in [ pressed, on_show_popup ]:
			for connection in s.get_connections():
				if s.is_connected(connection.callable):
					s.disconnect(connection.callable)

	func connect_actions(pressed_callback : Callable = Callable(),
			popup_callback : Callable = Callable()) -> void:
		disconnect_actions()
		if visible:
			if pressed_callback != Callable() and not pressed.is_connected(pressed_callback):
				pressed.connect(pressed_callback)
			if  popup_callback != Callable() and not on_show_popup.is_connected(popup_callback):
				on_show_popup.connect(popup_callback)

#region panel creation/update

func input_released() -> void:
	while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if visible and Input.is_key_pressed(KEY_SHIFT):
			hide()
		await get_tree().process_frame
	await get_tree().process_frame

func create_panel() -> void:
	if not is_node_ready():
		return
	await input_released()

	selected_nodes = parent.get_selected_nodes()
	if selected_nodes.is_empty():
		return hide_panel()

	for button : ActionButton in container.get_children():
		button.show()

	var nodes_rect : Rect2 = Rect2(0, 0, -1, -1)
	for n in selected_nodes:
		if nodes_rect.size == Vector2(-1, -1):
			nodes_rect = calc_node_rect(n)
		else:
			nodes_rect = nodes_rect.merge(calc_node_rect(n))

		if not n.tree_exiting.is_connected(should_panel_update):
			n.tree_exiting.connect(should_panel_update)

	global_position = nodes_rect.get_support(Vector2(1, -1)) + parent.global_position

	if selected_nodes.size() == 1:
		selection_area = Rect2()
		global_position.x += AREA_PAD

		var node : GraphElement = selected_nodes[0]
		var gen : MMGenBase = node.generator

		if is_node_simple(node):
			buttons.minimize.hide()
			buttons.randomize.hide()
			buttons.generic.hide()
			buttons.custom.hide()

			if node is MMGraphSwitch:
				buttons.custom.show()
				buttons.custom.connect_actions(node_switch_edit.bind(node))

			if should_node_panel_center(node):
				var local_p : Vector2 = node.position
				local_p.x += node.size.x * 0.5 * parent.zoom - size.x - 6.0
				local_p.y += (node.size.y + H_PAD) * parent.zoom
				global_position = parent.global_position + local_p
		else:
			buttons.close.visible = should_close_visible(gen)
			buttons.randomize.visible = should_random_visible(gen)
			buttons.generic.visible = should_generic_visible(gen)
			buttons.custom.visible = should_custom_visible(gen)

			buttons.randomize.connect_actions(node.on_randomness_pressed, node.randomness_button_create_popup)
			buttons.generic.connect_actions(node.on_generic_pressed, node.generic_button_create_popup)
			buttons.custom.connect_actions(node.edit_generator, node.custom_button_create_popup)

	elif selected_nodes.size() > 1:
		selection_area = nodes_rect
		global_position += PADDING

		buttons.close.visible = node_selection_can_be_deleted()
		buttons.randomize.visible = node_selection_has_randomness()
		buttons.generic.visible = false
		buttons.custom.visible = false

		buttons.randomize.connect_actions(randomize_selected_nodes)

	size = get_combined_minimum_size()

	avoid_intersecting_popups()
	set_top_level()
	show_panel()

func is_node_simple(node : GraphElement) -> bool:
	return node.get_script() in [ MMGraphPortal, MMGraphReroute,
			MMGraphCommentLine, MMGraphSwitch, MMGraphComment,
			MMGraphDebug, MMGraphNodeRemote ]

func should_node_panel_center(node : GraphElement) -> bool:
	return node.get_script() in [ MMGraphPortal, MMGraphReroute,
			MMGraphCommentLine ]

func set_top_level() -> void:
	# have panel visible only within graph bounds
	var prev : Vector2 = global_position
	var graph_rect : Rect2 = parent.get_global_rect()
	var panel_rect : Rect2 = get_global_rect()

	# account for graph scrollbars width/height
	var wh : int = -get_theme_stylebox("scroll").border_width_left * 2.0 - 6.0
	graph_rect = graph_rect.grow_individual(0.0, 0.0, wh, wh)

	# avoid covering subgraph menu and graph menubar
	var graph_menu : ScrollContainer = mm_globals.main_window.projects_panel.get_node("MenuBar")
	var intersect_subgraph_ui : bool = parent.subgraph_ui.get_global_rect().intersects(panel_rect)
	var intersect_graph_menu : bool = graph_menu.get_global_rect().intersects(panel_rect)

	top_level = graph_rect.encloses(panel_rect) and not (intersect_subgraph_ui or intersect_graph_menu)
	global_position = prev

var _gradient_edits : Array[Node]

func avoid_intersecting_popups() -> void:
	# avoid intersecting with GradientEdit's popup
	if selected_nodes.size() != 1 or not selected_nodes[0]:
		return
	var node : GraphElement = selected_nodes[0]
	var popup : GradientPopup

	var edits : Array[Node] = node.find_children("*", "GradientEdit", true, false)
	if edits.hash() != _gradient_edits.hash():
		_gradient_edits = edits

	for edit in _gradient_edits:
		if edit and is_instance_valid(edit.popup):
			popup = edit.popup
			break

	if not popup:
		return
	var panel_r : Rect2 = get_global_rect()
	var popup_r : Rect2 = popup.get_global_rect()
	if panel_r.intersects(popup_r):
		global_position.y = popup_r.position.y - panel_r.size.y - AVOID_PAD

func should_panel_update() -> void:
	if is_updating:
		return
	is_updating = true
	create_panel.call_deferred()

func show_panel() -> void:
	show()
	move_to_front()
	parent.queue_redraw()
	is_updating = false

func hide_panel() -> void:
	hide()
	selection_area = Rect2()
	parent.queue_redraw()
	is_updating = false

func calc_node_rect(n : GraphElement) -> Rect2:
	if n is MMGraphPortal:
		var r : Rect2 = n.get_rect_with_link()
		return Rect2(r.position * parent.zoom + n.position,
				r.size * parent.zoom)
	return Rect2(n.position, n.size * parent.zoom)

#endregion

#region generator conditionals/functions

func node_switch_edit(node : MMGraphSwitch) -> void:
	node.generator.toggle_editable()
	node.update_node()

func node_selection_has_generic() -> bool:
	for node in selected_nodes:
		if should_generic_visible(node.generator):
			return true
	return false

func node_selection_has_randomness() -> bool:
	for node in selected_nodes:
		if should_random_visible(node.generator):
			return true
	return false

func node_selection_can_be_deleted() -> bool:
	for node in selected_nodes:
		if should_close_visible(node.generator):
			return true
	return false

func randomize_selected_nodes() -> void:
	parent.undoredo.start_group()
	for node in selected_nodes:
		if should_random_visible(node.generator):
			node.on_randomness_pressed()
	parent.undoredo.end_group()

func should_close_visible(g : MMGenBase) -> bool:
	return g and g.can_be_deleted()

func should_random_visible(g : MMGenBase) -> bool:
	return g and g.has_randomness()

func should_generic_visible(g : MMGenBase) -> bool:
	return g and g.has_method("is_generic") and g.is_generic()

func should_custom_visible(g : MMGenBase) -> bool:
	return g and g.model == null and (g is MMGenShader or g is MMGenGraph)

#endregion

#region area stylebox draw/update

func init_stylebox() -> void:
	if not sb_selection:
		sb_selection = StyleBoxFlat.new()
		sb_selection.set_border_width_all(2)
		sb_selection.set_corner_radius_all(4)
		sb_selection.corner_detail = 4

func update_stylebox() -> void:
	if not sb_selection:
		init_stylebox()

	match mm_globals.current_theme():
		mm_globals.CLASSIC:
			sb_selection.bg_color = Color(0.22, 0.255, 0.36, 1.0)
			sb_selection.border_color = Color(0.377, 0.482, 0.65, 1.0)
		mm_globals.DEFAULT_DARK:
			sb_selection.bg_color = Color(0.14, 0.14, 0.14, 1.0)
			sb_selection.border_color = Color(0.355, 0.355, 0.355, 1.0)
		mm_globals.DEFAULT_LIGHT:
			sb_selection.bg_color = Color(0.62, 0.62, 0.62, 1.0)
			sb_selection.border_color = Color(0.33, 0.33, 0.33, 1.0)

func draw_selection_area() -> void:
	if selection_area.size != Vector2.ZERO and sb_selection and visible:
		var ci : RID = parent.get_canvas_item()
		sb_selection.draw(ci, selection_area.grow(AREA_PAD))

#endregion

#region button init/setup

func create_buttons() -> void:
	buttons.close = create_button(parent.remove_selection)
	buttons.minimize = create_button(parent.minimize_selection)
	buttons.randomize = create_button()
	buttons.generic = create_button()
	buttons.custom = create_button()

func update_button_icons() -> void:
	buttons.close.icon = get_theme_icon("delete_2x", "MM_Icons")
	buttons.minimize.icon = get_theme_icon("minimize", "MM_Icons")
	buttons.randomize.icon = get_theme_icon("randomize", "MM_Icons")
	buttons.generic.icon = get_theme_icon("generic_size", "MM_Icons")
	buttons.custom.icon = get_theme_icon("draw_2x", "MM_Icons")

	buttons.randomize.add_theme_color_override("icon_normal_color", Color.WHITE)

func create_button(pressed_callback : Callable = Callable()) -> ActionButton:
	var button : ActionButton = ActionButton.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.flat = true
	button.expand_icon = true
	button.add_theme_color_override("icon_hover_color", Color.WHITE)
	if pressed_callback != Callable():
		button.pressed.connect(pressed_callback)
	container.add_child(button)
	return button

#endregion
