extends MMGraphNodeMinimal

@onready var label = $VBox/Label
@onready var editor = $VBox/TextEdit

var pallette_colors = [
	Color("F8B8B3"),
	Color("F7FDAF"),
	Color("AAF3A2"),
	Color("92DEFC"),
	Color("AEC5F1"),
	Color("B1A7F0")
]

const AUTO_SIZE_PADDING : int = 22

func _ready():
	super._ready()
	for s in [ "comment", "comment_focus" ]:
		var frame : StyleBoxFlat = mm_globals.main_window.theme.get_stylebox(s, "GraphNode").duplicate(true) as StyleBoxFlat
		add_theme_stylebox_override(s, frame);

func _draw() -> void:
	var icon = preload("res://material_maker/icons/color_palette.png")
	draw_texture_rect(icon, Rect2(size.x-40, 4, 16, 16), false)
	if !is_connected("gui_input",Callable(self,"_on_gui_input")):
		connect("gui_input",Callable(self,"_on_gui_input"))

func set_generator(g) -> void:
	generator = g
	label.text = generator.text
	size = generator.size
	title = generator.title

	set_stylebox_color(generator.color)
	
	if mm_globals.get_config("auto_size_comment"):
		resize_to_selection()

func _on_resize_request(new_size : Vector2) -> void:
	var parent : GraphEdit = get_parent()
	if parent.use_snap:
		new_size = parent.snap_distance*Vector2(round(new_size.x/parent.snap_distance), round(new_size.y/parent.snap_distance))
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
	
	if not selected_nodes.is_empty():
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
				
		position_offset = Vector2(min_bounds.x - AUTO_SIZE_PADDING, min_bounds.y - AUTO_SIZE_PADDING)
		
		# Size needs to account for offset padding as well (Padding * 2)
		var new_size : Vector2 = Vector2(max_bounds.x - min_bounds.x + AUTO_SIZE_PADDING * 2,
											max_bounds.y - min_bounds.y + AUTO_SIZE_PADDING * 2)
		
		size = new_size
		generator.size = new_size

func _on_Label_gui_input(ev) -> void:
	if ev is InputEventMouseButton and ev.double_click and ev.button_index == MOUSE_BUTTON_LEFT:
		editor.custom_minimum_size = label.size + Vector2(0, size.y - get_minimum_size().y)
		editor.text = label.text
		label.visible = false
		editor.visible = true
		editor.select_all()
		editor.grab_focus()

var focus_lost = false

func _on_TextEdit_focus_entered():
	focus_lost = false

func _on_TextEdit_focus_exited() -> void:
	focus_lost = true
	await get_tree().process_frame
	if focus_lost:
		label.text = editor.text
		generator.text = editor.text
		label.visible = true
		editor.visible = false

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(size.x-40, 4, 16, 16).has_point(event.position):
			var light_theme = "light" in mm_globals.main_window.theme.resource_path
			accept_event()
			$Popup.position = event.global_position
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
				if !palette_rects[i].is_connected("pressed",Callable(self,"set_color")):
					palette_rects[i].connect("pressed",Callable(self,"set_color"))
		elif event.double_click:
			name_change_popup()

func update_node() -> void:
	size = generator.size
	set_stylebox_color(generator.color)

func name_change_popup() -> void:
	accept_event()
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instantiate()
	add_child(dialog)
	var status = await dialog.enter_text("Comment", "Enter the comment node title", generator.title)
	if status.ok:
		title = status.text
		generator.title = status.text
		get_parent().send_changed_signal()

func set_color(c):
	$Popup.hide()
	if c == generator.color:
		return
	var undo_action = { type="comment_color_change", node=generator.get_hier_name(), color=generator.color }
	var redo_action = { type="comment_color_change", node=generator.get_hier_name(), color=c }
	get_parent().undoredo.add("Change comment color", [undo_action], [redo_action], true)
	generator.color = c
	set_stylebox_color(c)
	get_parent().send_changed_signal()

func set_stylebox_color(c):
	c.a = 0.3
	get_theme_stylebox("comment").bg_color = c
	get_theme_stylebox("comment_focus").bg_color = c

func _on_ColorChooser_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		$Popup.hide()
		$PopupSelector.popup(Rect2(event.global_position, $PopupSelector.get_minimum_size()))
		$PopupSelector/PanelContainer/ColorPicker.color = generator.color
		if !$PopupSelector/PanelContainer/ColorPicker.is_connected("color_changed",Callable(self,"set_color")):
			$PopupSelector/PanelContainer/ColorPicker.connect("color_changed",Callable(self,"set_color"))
