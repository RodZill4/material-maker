class_name TouchDragger
extends Control

var is_pressed : bool = false

static var sb_normal : StyleBoxFlat
static var sb_pressed : StyleBoxFlat

func _ready() -> void:
	set_notify_transform(true)
	gui_input.connect(get_parent()._on_gui_input.bind(true))

	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_level = true

	init_styleboxes()

func _draw() -> void:
	if sb_pressed and sb_normal:
		draw_style_box(sb_pressed if is_pressed else sb_normal, Rect2(Vector2.ZERO, size))

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_pressed = event.pressed
		queue_redraw()

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			update_theme_colors()
		NOTIFICATION_TRANSFORM_CHANGED:
			update_dragger_global_pos()

func update_stylebox_colors(base_color : Color, border : Color,
		normal_opacity : float, pressed_opacity : float) -> void:
	sb_normal.bg_color = base_color
	sb_normal.bg_color.a = normal_opacity
	sb_normal.border_color = border

	sb_pressed.bg_color = base_color
	sb_pressed.bg_color.a = pressed_opacity
	sb_pressed.border_color = border

func init_styleboxes() -> void:
	if not sb_normal:
		sb_normal = StyleBoxFlat.new()
		sb_normal.set_border_width_all(2)
		sb_normal.set_corner_radius_all(5)
		sb_normal.border_blend = true
		sb_normal.corner_detail = 4

	if not sb_pressed:
		sb_pressed = sb_normal.duplicate(true)

func setup() -> void:
	show()
	if get_parent().vertical:
		mouse_default_cursor_shape = Control.CURSOR_VSPLIT
		custom_minimum_size = Vector2(52, 24)
	else:
		mouse_default_cursor_shape = Control.CURSOR_HSPLIT
		custom_minimum_size = Vector2(24, 52)
	update_theme_colors()
	update_dragger_global_pos.call_deferred()

func update_dragger_global_pos() -> void:
	global_position =  get_parent().global_position + (get_parent().size - size) * 0.5

func update_position(v : float) -> void:
	if get_parent().vertical:
		position.y = v
	else:
		position.x = v
	queue_redraw()

func get_drag_offset() -> int:
	return mini(custom_minimum_size.x, custom_minimum_size.y) / 2

func update_theme_colors() -> void:
	if not sb_normal or not sb_pressed:
		init_styleboxes()
	match mm_globals.current_theme():
		mm_globals.DEFAULT_DARK:
			update_stylebox_colors(Color.WHITE, Color.BLACK, 0.25, 0.8)
		mm_globals.DEFAULT_LIGHT:
			update_stylebox_colors(Color.BLACK, Color.WHITE, 0.6, 0.25)
		mm_globals.CLASSIC:
			update_stylebox_colors(Color("506396ff"), Color("768ac2ff"), .25, .8)
	queue_redraw()
