extends GraphElement
class_name MMGraphComment


@onready var title = %Title
@onready var title_edit = %TitleEdit
@onready var editor = %Text


var generator : MMGenComment:
	set(g):
		generator = g
		title.text = generator.title
		editor.text = generator.text
		position_offset = generator.position
		size = generator.size
		update_stylebox()
		
		if mm_globals.get_config("auto_size_comment"):
			resize_to_selection()

var pallette_colors = [
	Color("F8B8B3"),
	Color("F7FDAF"),
	Color("AAF3A2"),
	Color("92DEFC"),
	Color("AEC5F1"),
	Color("B1A7F0")
]

const AUTO_SIZE_PADDING : int = 22
const AUTO_SIZE_TOP_PADDING : int = 72


func do_set_position(o : Vector2) -> void:
	position_offset = o
	generator.position = o

func _on_resize_request(new_size : Vector2) -> void:
	var parent : GraphEdit = get_parent()
	if parent.snapping_enabled:
		new_size = parent.snapping_distance*Vector2(round(new_size.x/parent.snapping_distance), round(new_size.y/parent.snapping_distance))
	if size == new_size:
		return
	var undo_action = { type="resize_comment", node=generator.get_hier_name(), size=size }
	var redo_action = { type="resize_comment", node=generator.get_hier_name(), size=new_size }
	get_parent().undoredo.add("Resize comment", [undo_action], [redo_action], true)
	size = new_size
	generator.size = new_size

func resize_to_selection() -> void:
	# If any nodes are selected on initialization automatically adjust size to match
	var parent : GraphEdit = get_parent()
	var selected_nodes : Array = parent.get_selected_nodes()
	
	if selected_nodes.is_empty():
		return
	var min_bounds : Vector2 = Vector2(INF, INF)
	var max_bounds : Vector2 = Vector2(-INF, -INF)
	for node in selected_nodes:
		var node_pos : Vector2 = node.position_offset
		var node_size : Vector2 = node.get_size()
		
		# Top-left corner
		if node_pos.x < min_bounds.x:
			min_bounds.x = node_pos.x
		if node_pos.y < min_bounds.y:
			min_bounds.y = node_pos.y
			
		# Bottom-right corner
		var bottom_right : Vector2 = Vector2(node_pos.x + node_size.x, node_pos.y + node_size.y)
		if bottom_right.x > max_bounds.x:
			max_bounds.x = bottom_right.x
		if bottom_right.y > max_bounds.y:
			max_bounds.y = bottom_right.y
	
	position_offset = Vector2(min_bounds.x - AUTO_SIZE_PADDING, min_bounds.y - AUTO_SIZE_TOP_PADDING)
	generator.position = position_offset

	# Size needs to account for offset padding as well (Padding * 2)
	var new_size : Vector2 = Vector2(max_bounds.x - min_bounds.x, max_bounds.y - min_bounds.y)
	new_size += Vector2(AUTO_SIZE_PADDING * 2, AUTO_SIZE_TOP_PADDING + AUTO_SIZE_PADDING)
	
	size = new_size
	generator.size = new_size

# Title edit

func _on_gui_input(event):
	if event is InputEventMouseMotion:
		if event.position.x > size.x-10 and event.position.y > size.y-10:
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		else:
			mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_Title_gui_input(event):
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		title_edit.text = title.text
		title.visible = false
		title_edit.visible = true
		title_edit.select_all()
		title_edit.grab_focus()
		accept_event()

func _on_title_edit_focus_exited():
	title.text = title_edit.text
	generator.title = title.text
	title.visible = true
	title_edit.visible = false

func _on_title_edit_text_submitted(new_text):
	_on_title_edit_focus_exited()

# Text edit

func _on_text_gui_input(event):
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		editor.editable = true
		editor.mouse_filter = MOUSE_FILTER_STOP
		editor.select_all()
		editor.grab_focus()
		accept_event()

func _on_text_focus_exited():
	editor.editable = false
	editor.mouse_filter = MOUSE_FILTER_PASS
	generator.text = editor.text

# Comment color

func _on_change_color_pressed():
	var light_theme = "light" in mm_globals.main_window.theme.resource_path
	accept_event()
	var content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	$Popup.get_window().content_scale_factor = content_scale_factor
	$Popup.get_window().min_size = $Popup.get_window().get_contents_minimum_size() * content_scale_factor
	$Popup.position = get_global_mouse_position() * content_scale_factor
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
	update_stylebox()

func set_color(c):
	$Popup.hide()
	if c == generator.color:
		return
	var undo_action = { type="comment_color_change", node=generator.get_hier_name(), color=generator.color }
	var redo_action = { type="comment_color_change", node=generator.get_hier_name(), color=c }
	get_parent().undoredo.add("Change comment color", [undo_action], [redo_action], true)
	generator.color = c
	update_stylebox()
	get_parent().send_changed_signal()

func update_stylebox():
	var c : Color = generator.color
	c.a = 0.5
	var stylebox : StyleBoxFlat = get_theme_stylebox("selected" if selected else "default", "MM_CommentNode").duplicate()
	stylebox.bg_color = c
	$PanelContainer.add_theme_stylebox_override("panel", stylebox)
	$PanelContainer/ResizerIcon.texture = get_theme_icon("resizer", "MM_CommentNode")

func _on_ColorChooser_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		$Popup.hide()
		var content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
		$PopupSelector.get_window().content_scale_factor = content_scale_factor
		$PopupSelector.get_window().min_size = $PopupSelector.get_window().get_contents_minimum_size() * content_scale_factor
		$PopupSelector.get_window().position = get_global_mouse_position() * content_scale_factor
		$PopupSelector.popup()
		$PopupSelector/PanelContainer/ColorPicker.color = generator.color
		if not $PopupSelector/PanelContainer/ColorPicker.color_changed.is_connected(self.set_color):
			$PopupSelector/PanelContainer/ColorPicker.color_changed.connect(self.set_color)

func _on_close_pressed():
	get_parent().remove_node(self)

func _on_dragged(from, to):
	_on_raise_request()
	generator.position = to

func _on_position_offset_changed():
	_on_raise_request()

func _on_node_selected():
	_on_raise_request()
	update_stylebox()

func _on_node_deselected():
	_on_raise_request()
	update_stylebox()

func _on_raise_request():
	var parent = get_parent()
	for i in parent.get_child_count():
		var child = parent.get_child(i)
		if child == self:
			break
		if not child is MMGraphComment:
			get_parent().move_child(self, i)
			break
