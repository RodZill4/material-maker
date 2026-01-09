extends GraphFrame
class_name MMGraphComment


@onready var editor := %Text
var title_label : Label
var title_edit : LineEdit

var close_button : TextureButton
var autoshrink_button : TextureButton

var disable_undoredo_for_offset : bool = false

const CHANGE_COLOR_ICON = preload("res://material_maker/icons/color_palette.png")
const CLOSE_BUTTON_ICON = preload("res://material_maker/icons/close.tres")

var generator : MMGenComment:
	set(g):
		generator = g
		title = generator.title
		editor.text = generator.text
		position_offset = generator.position
		size = generator.size

		if mm_globals.get_config("auto_size_comment"):
			resize_to_selection()
		autoshrink_enabled = generator.autoshrink
		update_theme()

var pallette_colors := [
	Color("F8B8B3"),
	Color("F7FDAF"),
	Color("AAF3A2"),
	Color("92DEFC"),
	Color("AEC5F1"),
	Color("B1A7F0"),
]


func _ready() -> void:
	title_label = get_titlebar_hbox().get_child(0)
	get_titlebar_hbox().remove_child(title_label)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.custom_minimum_size.y = 25
	title_label.add_theme_font_override("font", get_theme_font("title_font"))

	title_edit = LineEdit.new()
	title_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_edit.hide()
	title_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_edit.text_submitted.connect(_on_title_edit_text_submitted)
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
	autoshrink_button.tooltip_text = "LMB: Shrink to fit\nShift-LMB: Toggle Autoshrink"

	var hbox_spacer_start := Control.new()
	hbox_spacer_start.custom_minimum_size.x = 0.5
	hbox_spacer_start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var hbox_spacer_end := Control.new()
	hbox_spacer_end.custom_minimum_size.x = 0.5
	hbox_spacer_end.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	get_titlebar_hbox().add_child(hbox_spacer_start)
	get_titlebar_hbox().add_child(title_label)
	get_titlebar_hbox().add_child(title_edit)
	get_titlebar_hbox().add_child(autoshrink_button)
	get_titlebar_hbox().add_child(change_color_button)
	get_titlebar_hbox().add_child(close_button)
	get_titlebar_hbox().add_child(hbox_spacer_end)

func do_set_position(o : Vector2) -> void:
	disable_undoredo_for_offset = true
	position_offset = o
	generator.position = o
	disable_undoredo_for_offset = false

func _on_resize_request(new_size : Vector2) -> void:
	if size == new_size:
		return
	var undo_action = { type="resize_comment", node=generator.get_hier_name(), size=size }
	var redo_action = { type="resize_comment", node=generator.get_hier_name(), size=new_size }
	get_parent().undoredo.add("Resize comment", [undo_action], [redo_action], true)
	size = new_size
	generator.size = new_size

func resize_to_selection() -> void:
	var graph : MMGraphEdit = get_parent()
	var selected_nodes : Array = graph.get_selected_nodes()
	if selected_nodes.is_empty():
		return
	for el in selected_nodes:
		graph.attach_graph_element_to_frame(el.name, name)
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
			accept_event()

func _on_title_edit_focus_exited() -> void:
	title = title_edit.text
	generator.title = title
	title_label.show()
	title_edit.hide()

func _on_title_edit_text_submitted(_new_text) -> void:
	_on_title_edit_focus_exited()

func _on_node_selected() -> void:
	%Text.placeholder_text = tr("Double click to add your comment here")

func _on_node_deselected() -> void:
	%Text.placeholder_text = ""

func _on_text_focus_exited() -> void:
	editor.editable = false
	editor.mouse_filter = MOUSE_FILTER_IGNORE
	generator.text = editor.text

# Comment color

func _on_change_color_pressed() -> void:
	var light_theme = "light" in mm_globals.main_window.theme.resource_path
	accept_event()
	var content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	$Popup.get_window().content_scale_factor = content_scale_factor
	$Popup.get_window().size = $Popup.get_window().get_contents_minimum_size() * content_scale_factor
	$Popup.position = get_screen_transform() * get_local_mouse_position()
	$Popup.popup()
	var corrected_color = pallette_colors.duplicate(true)
	if !light_theme:
		for i in corrected_color.size():
			corrected_color[i] = corrected_color[i].darkened(0.5)
	corrected_color.push_front(Color.WEB_GRAY)
	corrected_color.push_front(Color.WHITE if light_theme else Color.BLACK)
	var palette_rects = $Popup/GridContainer.get_children()
	palette_rects.pop_back()
	for i in palette_rects.size():
		palette_rects[i].color = corrected_color[i]
		if not palette_rects[i].is_connected("pressed",Callable(self,"set_color")):
			palette_rects[i].connect("pressed",Callable(self,"set_color"))

func update_node() -> void:
	size = generator.size
	update_theme()

func set_color(c) -> void:
	$Popup.hide()
	if c == generator.color:
		return
	var undo_action = { type="comment_color_change", node=generator.get_hier_name(), color=generator.color }
	var redo_action = { type="comment_color_change", node=generator.get_hier_name(), color=c }
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
		var content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
		$PopupSelector.get_window().content_scale_factor = content_scale_factor
		$PopupSelector.get_window().min_size = $PopupSelector.get_window().get_contents_minimum_size() * content_scale_factor
		$PopupSelector.get_window().position = get_screen_transform() * get_local_mouse_position()
		$PopupSelector.popup()
		$PopupSelector/PanelContainer/ColorPicker.color = generator.color
		if not $PopupSelector/PanelContainer/ColorPicker.color_changed.is_connected(self.set_color):
			$PopupSelector/PanelContainer/ColorPicker.color_changed.connect(self.set_color)

func _on_autoshrink_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.shift_pressed:
			autoshrink_enabled = not autoshrink_enabled
			generator.autoshrink = autoshrink_enabled
			_on_theme_changed()
		else:
			if autoshrink_enabled:
				return
			else:
				autoshrink_enabled = true
				autoshrink_enabled = false

func _on_close_pressed() -> void:
	get_parent().remove_node(self)

func _on_dragged(_from, to) -> void:
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
	elif "light" in mm_globals.main_window.theme.resource_path:
		autoshrink_button.modulate = Color.BLACK
		close_button.modulate = Color.BLACK
	else:
		autoshrink_button.modulate = Color.WHITE
		close_button.modulate = Color.WHITE
