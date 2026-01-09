extends GraphFrame
class_name MMGraphComment


@onready var editor := %Text
var title_label : Label
var title_edit : LineEdit

var close_button : TextureButton
var autoshrink_button : TextureButton

var disable_undoredo_for_offset : bool = false

var undo_action : Dictionary
var redo_action : Dictionary

var is_resizing : bool = false

const CHANGE_COLOR_ICON = preload("res://material_maker/icons/color_palette.png")
const CLOSE_BUTTON_ICON = preload("res://material_maker/icons/close.tres")

var generator : MMGenComment:
	set(g):
		generator = g
		title = generator.title
		editor.text = generator.text
		position_offset = generator.position
		size = generator.size
		autoshrink_enabled = generator.autoshrink

		generator.attached = g.attached.duplicate()
		attach_from_generator.call_deferred()

		if mm_globals.get_config("auto_size_comment"):
			resize_to_selection()
		update_theme()
		update_autoshrink_button_tooltip()

var palette_colors := [
	Color("F8B8B3"),
	Color("F7FDAF"),
	Color("AAF3A2"),
	Color("92DEFC"),
	Color("AEC5F1"),
	Color("B1A7F0"),
]


func _ready() -> void:
	setup_titlebar_controls()

func attach_from_generator() -> void:
	# attach nodes from generator attachments
	var graph : MMGraphEdit = get_parent()
	if graph and generator.attached.size():
		for node in generator.attached:
			if not graph.has_node(node):
				return
			if graph.get_element_frame(node) == null:
				graph.attach_graph_element_to_frame(node, name)

func setup_titlebar_controls() -> void:
	title_label = get_titlebar_hbox().get_child(0)
	get_titlebar_hbox().remove_child(title_label)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.custom_minimum_size.y = 25

	title_edit = LineEdit.new()
	title_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_edit.hide()
	title_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_edit.text_submitted.connect(_on_title_edit_focus_exited.unbind(1))
	title_edit.focus_exited.connect(_on_title_edit_focus_exited)

	var change_color_button := TextureButton.new()
	change_color_button.texture_normal = CHANGE_COLOR_ICON
	change_color_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	change_color_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	change_color_button.pressed.connect(_on_change_color_pressed)

	close_button = TextureButton.new()
	close_button.texture_normal = CLOSE_BUTTON_ICON
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	close_button.pressed.connect(_on_close_pressed)

	autoshrink_button = TextureButton.new()
	autoshrink_button.texture_normal = get_theme_icon("shrink", "MM_Icons")
	autoshrink_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	autoshrink_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	autoshrink_button.gui_input.connect(_on_autoshrink_gui_input)

	var hbox_spacer := Control.new()
	hbox_spacer.custom_minimum_size.x = 0.5
	hbox_spacer.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	get_titlebar_hbox().add_child(hbox_spacer)
	get_titlebar_hbox().add_child(title_label)
	get_titlebar_hbox().add_child(title_edit)
	get_titlebar_hbox().add_child(autoshrink_button)
	get_titlebar_hbox().add_child(change_color_button)
	get_titlebar_hbox().add_child(close_button)
	get_titlebar_hbox().add_child(hbox_spacer.duplicate())

func do_set_position(o : Vector2) -> void:
	disable_undoredo_for_offset = true
	position_offset = o
	generator.position = o
	disable_undoredo_for_offset = false

func resize_to_selection() -> void:
	var graph : MMGraphEdit = get_parent()
	var selected_nodes : PackedStringArray 
	selected_nodes = graph.get_selected_nodes().map(func(n): return n.name)
	if selected_nodes.is_empty():
		return
	graph._on_graph_elements_linked_to_frame_request(selected_nodes, name)
	autoshrink_enabled = true
	autoshrink_enabled = false
	generator.position = position_offset

# Title / Text edit

func _on_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		if title_label.get_rect().has_point(get_local_mouse_position()):
			title_edit.text = title
			title_edit.mouse_filter = MOUSE_FILTER_STOP
			title_label.hide()
			title_edit.show()
			title_edit.select_all()
			title_edit.grab_focus()
			accept_event()
		elif editor.get_rect().has_point(get_local_mouse_position()):
			editor.editable = true
			editor.mouse_filter = MOUSE_FILTER_STOP
			editor.select_all()
			editor.grab_focus()
			# show caret immediately on double click
			editor.caret_blink = false
			editor.caret_blink = true
			accept_event()
	elif event is InputEventMouseMotion:
		if Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
			mouse_default_cursor_shape = Control.CURSOR_MOVE
		else:
			mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_title_edit_focus_exited() -> void:
	title = title_edit.text
	generator.title = title
	title_label.show()
	title_edit.hide()

func _on_node_selected() -> void:
	%Text.placeholder_text = tr("Double click to add comment")

func _on_node_deselected() -> void:
	%Text.placeholder_text = ""

func _on_text_focus_exited() -> void:
	editor.editable = false
	editor.mouse_filter = MOUSE_FILTER_IGNORE
	generator.text = editor.text

# Comment color

func _on_change_color_pressed() -> void:
	var light_theme : bool = mm_globals.is_theme_light()
	accept_event()
	var content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	$Popup.get_window().content_scale_factor = content_scale_factor
	$Popup.get_window().size = $Popup.get_window().get_contents_minimum_size() * content_scale_factor
	$Popup.position = get_screen_transform() * get_local_mouse_position()
	$Popup.popup()
	var corrected_color = palette_colors.duplicate(true)
	if !light_theme:
		for i in corrected_color.size():
			corrected_color[i] = corrected_color[i].darkened(0.5)
	corrected_color.push_front(Color.WEB_GRAY)
	corrected_color.push_front(Color.WHITE if light_theme else Color.BLACK)
	var palette_rects := $Popup/GridContainer.get_children()
	palette_rects.pop_back()
	for i in palette_rects.size():
		palette_rects[i].color = corrected_color[i]
		if not palette_rects[i].pressed.is_connected(set_color):
			palette_rects[i].pressed.connect(set_color)

func update_node() -> void:
	size = generator.size
	update_theme()

func set_color(c : Color) -> void:
	$Popup.hide()
	if c == generator.color:
		return
	undo_action = { type="comment_color_change", node=generator.get_hier_name(), color=generator.color }
	redo_action = { type="comment_color_change", node=generator.get_hier_name(), color=c }
	get_parent().undoredo.add("Change comment color", [undo_action], [redo_action], true)
	generator.color = c
	tint_color = c
	update_theme()
	get_parent().send_changed_signal()

func update_theme() -> void:
	var c : Color = generator.color
	c.a = 0.5
	tint_color = c
	_on_theme_changed()

func _on_ColorChooser_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		$Popup.hide()
		var csf := get_tree().root.content_scale_factor
		$PopupSelector.get_window().content_scale_factor = csf
		$PopupSelector.get_window().min_size = $PopupSelector.get_window().get_contents_minimum_size() * csf
		$PopupSelector.get_window().position = $Popup.position
		var color_picker : ColorPicker = $PopupSelector/PanelContainer/ColorPicker
		$PopupSelector.about_to_popup.connect(func():
			if mm_globals.has_config("color_picker_color_mode"):
				color_picker.color_mode = mm_globals.get_config("color_picker_color_mode")
			if mm_globals.has_config("color_picker_shape"):
				color_picker.picker_shape = mm_globals.get_config("color_picker_shape"))
		$PopupSelector.popup_hide.connect(func():
			mm_globals.set_config("color_picker_color_mode", color_picker.color_mode)
			mm_globals.set_config("color_picker_shape", color_picker.picker_shape))
		$PopupSelector.popup()
		color_picker.color = generator.color
		if not color_picker.color_changed.is_connected(set_color):
			color_picker.color_changed.connect(set_color)

func _on_autoshrink_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.shift_pressed:
			autoshrink_enabled = not autoshrink_enabled
			generator.autoshrink = autoshrink_enabled
			_on_theme_changed()
			update_autoshrink_button_tooltip()
		else:
			if autoshrink_enabled:
				return
			else:
				autoshrink_enabled = true
				autoshrink_enabled = false

func _on_close_pressed() -> void:
	get_parent().remove_node(self)

func _on_dragged(_from : Vector2, to : Vector2) -> void:
	generator.position = to

func _on_position_offset_changed() -> void:
	if ! disable_undoredo_for_offset:
		get_parent().undoredo_move_node(generator.name, generator.position, position_offset)
		generator.set_position(position_offset)

func _on_theme_changed() -> void:
	if not is_node_ready():
		await ready
	if autoshrink_enabled:
		autoshrink_button.modulate = Color.HOT_PINK
	elif mm_globals.is_theme_light():
		autoshrink_button.modulate = Color.BLACK
		close_button.modulate = Color.BLACK
	else:
		autoshrink_button.modulate = Color.WHITE
		close_button.modulate = Color.WHITE
	editor.add_theme_color_override("font_placeholder_color",
			mm_globals.main_window.get_theme_color(
			"editor_placeholder_color", "GraphFrame"))
	title_label.add_theme_font_override("font",
			mm_globals.main_window.get_theme_font(
			"title_font", "GraphFrame"))

func _on_resize_request(_new_size : Vector2) -> void:
	if is_resizing:
		return
	is_resizing = true
	await get_tree().process_frame
	undo_action = { type="resize_comment", node=generator.get_hier_name(), size=size }

func _on_resize_end(new_size : Vector2) -> void:
	is_resizing = false
	redo_action = { type="resize_comment", node=generator.get_hier_name(), size=size }
	get_parent().undoredo.add("Resize comment", [undo_action], [redo_action], true)
	generator.size = new_size

func update_autoshrink_button_tooltip() -> void:
	if autoshrink_enabled:
		autoshrink_button.tooltip_text = "Shift-LMB: Toggle Autoshrink"
	else:
		autoshrink_button.tooltip_text = "LMB: Shrink to fit\nShift-LMB: Toggle Autoshrink"
