class_name PortalCompletionPanel
extends Panel

var selected_item : int = -1
const HEIGHT_MAX_ITEMS : int = 8

@onready var portal_edit : LineEdit = get_parent()
@export_multiline var slot_svg : String

## Emitted when selected item changes(i.e. via up/down key presses)
signal selection_updated

func _ready() -> void:
	theme = mm_globals.main_window.theme
	hide_panel()
	setup_scrollbar_theme()
	position = Vector2(portal_edit.size.x * 0.5 - size.x * 0.5,
			portal_edit.size.y + 10)

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_WHEEL_UP
			or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		accept_event()

func _input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and visible:
		match event.get_keycode_with_modifiers():
			KEY_UP:
				update_current_selection(KEY_UP)
				accept_event()
			KEY_DOWN:
				update_current_selection(KEY_DOWN)
				accept_event()
			KEY_ESCAPE:
				hide_panel()
				accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if not Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()) or not visible:
				hide_panel()
			else:
				if visible:
					handle_click_completion()
					accept_event()

func setup_scrollbar_theme() -> void:
	$ItemList.add_theme_constant_override("scrollbar_h_separation", 1)

	var vscroll : VScrollBar = $ItemList.get_v_scroll_bar()
	vscroll.add_theme_constant_override("padding_left", 2)
	vscroll.add_theme_constant_override("padding_right", 1)

	var sb : StyleBoxFlat = StyleBoxFlat.new()
	sb.draw_center = true
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = sb.bg_color
	sb.set_border_width_all(2)
	vscroll.add_theme_stylebox_override("scroll", sb)

func show_panel() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	show()

func hide_panel() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func request_completion(filter : String, graph : MMGraphEdit) -> void:
	if filter.is_empty():
		hide_panel()
		return
	show_panel()
	selected_item = -1
	$ItemList.clear()

	if not filter.is_empty():
		for node in graph.get_children():
			if node is MMGraphPortal and node.is_portal_in():
				var link : String = node.get_link()
				if link.begins_with(filter.to_lower()) or link.contains(filter.to_lower()):
					var port_color : Color = node.get_input_port_color(0)
					var icon : Image = Image.new()
					icon.load_svg_from_buffer(slot_svg.replace("#FFF",
							"#" + port_color.to_html(false)).to_utf8_buffer())
					var index : int = $ItemList.add_icon_item(ImageTexture.create_from_image(icon))
					$ItemList.set_item_text(index, link)
					$ItemList.set_item_tooltip_enabled(index, false)

	# approx height adjustment, min 2 items, max 7
	size.y = clampf(4 + $ItemList.item_count * 25, 50, HEIGHT_MAX_ITEMS * 25)
	custom_minimum_size = size
	if $ItemList.item_count == 0:
		hide_panel()

func update_current_selection(input : Key) -> void:
	selected_item = wrapi(selected_item +
			(1 if input == KEY_DOWN else -1), 0, $ItemList.item_count)
	if $ItemList.item_count != 0:
		$ItemList.select(selected_item)
		$ItemList.ensure_current_is_visible()
		set_portal_edit_text($ItemList.get_item_text(selected_item))
		portal_edit.size.x = 0
		selection_updated.emit()

func handle_click_completion() -> void:
	var item : int = $ItemList.get_item_at_position(get_local_mouse_position(), true)
	if item != -1:
		$ItemList.select(item)
		set_portal_edit_text($ItemList.get_item_text(item))
		portal_edit.focus_exited.emit()
		hide_panel()

func set_portal_edit_text(new_text : String) -> void:
	portal_edit.text = new_text
	portal_edit.caret_column = new_text.length()
