extends MMGraphNodeBase

onready var label = $VBox/Label
onready var editor = $VBox/TextEdit

func _draw() -> void:
	var icon = preload("res://material_maker/icons/edit.tres")
	draw_texture_rect(icon, Rect2(rect_size.x-56, 4, 16, 16), false)
	draw_rect(Rect2(rect_size.x-40, 4, 16, 16), generator.color)
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
			accept_event()
			$Popup/ColorPicker.color = generator.color
			$Popup/ColorPicker.connect("color_changed", self, "set_color")
			$Popup.rect_position = event.global_position
			$Popup.popup()
		elif Rect2(rect_size.x-56, 4, 16, 16).has_point(event.position):
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
	generator.color = c
	var color = c
	color.a = 0.3
	get_stylebox("comment").bg_color = color
	get_parent().send_changed_signal()
