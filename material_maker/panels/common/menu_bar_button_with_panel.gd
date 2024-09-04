extends Button

@export var mm_icon := ""

@onready var panel := get_child(0)

var pinned := false
var theme_arrow_icon: Texture2D

func _ready() -> void:
	
	toggle_mode = true
	button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
	toggled.connect(_on_toggled)
	owner.resized.connect(position_panel)

	panel.hide()
	
	


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		if mm_icon:
			icon = get_theme_icon(mm_icon, "MM_Icons")
			
		theme_arrow_icon = get_theme_icon("arrow", "OptionButton")
		custom_minimum_size = Vector2(35, 25) * mm_globals.ui_scale
		queue_redraw()


func _draw() -> void:
	if pinned:
		draw_circle(Vector2(size.x-2, 2), 4 * mm_globals.ui_scale, get_theme_color("icon_pressed_color"))
	draw_texture(theme_arrow_icon, Vector2(18, 5) * mm_globals.ui_scale)


func _on_toggled(pressed:bool) -> void:
	panel.visible = pressed
	
	if panel.visible:
		position_panel()
		if panel.has_method("_open"):
			panel._open()
	else:
		pinned = false


func position_panel() -> void:
	var at_position := global_position
	at_position.x += size.x/2 - panel.size.x/2
	at_position.x = max(at_position.x, get_parent().get_child(0).global_position.x)
	at_position.y += size.y + 6
	panel.global_position = at_position
		

func _input(event:InputEvent) -> void:
	if not panel.visible:
		return
	
	if event is InputEventMouseButton:
		var node := get_viewport().gui_get_hovered_control()
		if node != self and not is_ancestor_of(node) and (not pinned or (node and node.script == self.script)):
			button_pressed = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if not pinned and button_pressed:
				get_viewport().set_input_as_handled()
			pinned = true
		grab_focus()
