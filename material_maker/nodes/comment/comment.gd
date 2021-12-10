extends MMGraphNodeMinimal

onready var label = $VBox/Label
onready var editor = $VBox/TextEdit

var pallette_colors = [
	Color("F8B8B3"),
	Color("F7FDAF"),
	Color("AAF3A2"),
	Color("92DEFC"),
	Color("AEC5F1"),
	Color("B1A7F0")
]

func _draw() -> void:
	var icon = preload("res://material_maker/icons/color_picker.png")
	draw_texture_rect(icon, Rect2(rect_size.x-40, 4, 16, 16), false)
	if !is_connected("gui_input", self, "_on_gui_input"):
		connect("gui_input", self, "_on_gui_input")

func set_generator(g) -> void:
	generator = g
	label.text = generator.text
	rect_size = generator.size
	title = generator.title
	set_color(generator.color)

func _on_resize_request(new_size : Vector2) -> void:
	var parent : GraphEdit = get_parent()
	if parent.use_snap:
		new_size = parent.snap_distance*Vector2(round(new_size.x/parent.snap_distance), round(new_size.y/parent.snap_distance))
	rect_size = new_size
	generator.size = new_size

func _on_Label_gui_input(ev) -> void:
	if ev is InputEventMouseButton and ev.doubleclick and ev.button_index == BUTTON_LEFT:
		editor.rect_min_size = label.rect_size + Vector2(0, rect_size.y - get_minimum_size().y)
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
	yield(get_tree(), "idle_frame")
	if focus_lost:
		label.text = editor.text
		generator.text = editor.text
		label.visible = true
		editor.visible = false

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if Rect2(rect_size.x-40, 4, 16, 16).has_point(event.position):
			var light_theme = "light" in get_node("/root/MainWindow").theme.resource_path
			accept_event()
			$Popup.rect_position = event.global_position
			$Popup.popup()
			var corrected_color = pallette_colors.duplicate(true)
			if !light_theme:
				for i in corrected_color.size():
					corrected_color[i] = corrected_color[i].darkened(0.5)
			corrected_color.insert(3, Color.webgray)
			corrected_color.push_front(Color.white if light_theme else Color.black)
			var palette_rects = $Popup/PanelContainer/VBoxContainer/GridContainer.get_children()
			for i in palette_rects.size():
				palette_rects[i].color = corrected_color[i]
				if !palette_rects[i].is_connected("pressed", self, "set_color"):
					palette_rects[i].connect("pressed", self, "set_color")
		elif event.doubleclick:
			name_change_popup()


func name_change_popup() -> void:
	accept_event()
	var dialog = preload("res://material_maker/windows/line_dialog/line_dialog.tscn").instance()
	add_child(dialog)
	var status = dialog.enter_text("Comment", "Enter the comment node title", generator.title)
	while status is GDScriptFunctionState:
		status = yield(status, "completed")
	if status.ok:
		title = status.text
		generator.title = status.text
		get_parent().send_changed_signal()

func set_color(c):
	$Popup.hide()
	generator.color = c
	var color = c
	color.a = 0.3
	get_stylebox("comment").bg_color = color
	get_stylebox("commentfocus").bg_color = color
	get_parent().send_changed_signal()

func _on_ColorChooser_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		accept_event()
		$Popup.hide()
		$PopupSelector.popup()
		$PopupSelector.rect_position = event.global_position
		$PopupSelector/PanelContainer/ColorPicker.color = generator.color
		if !$PopupSelector/PanelContainer/ColorPicker.is_connected("color_changed", self, "set_color"):
			$PopupSelector/PanelContainer/ColorPicker.connect("color_changed", self, "set_color")
