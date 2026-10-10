class_name MMTouch
extends Node

## basic touch handling and android utilities

var _display_corner_radii : PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var _dispalay_cutout_margins : PackedInt32Array = PackedInt32Array([0, 0, 0, 0])

var android_runtime : JNISingleton

# workaround for godot issue #123454 for Android 16
var last_go_back_request : int = 0

## Emitted when back button is pressed on Android.
signal back_pressed()

func _ready() -> void:
	if OS.get_name() != "Android":
		set_process_input(false)
	else:
		android_runtime = Engine.get_singleton("AndroidRuntime")
		_display_corner_radii = _get_corner_radius()
		_dispalay_cutout_margins = _get_cutout_margins()

var _touch_start : int = -1

## Duration between touch down/up events in milliseconds.
var last_touch_duration_msec : int = -1

## Time since last touch down event in milliseconds.
var time_since_touch_down : int = -1:
	get: return Time.get_ticks_msec() - _touch_start

func _input(event : InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = Time.get_ticks_msec()
		elif not event.pressed:
			last_touch_duration_msec = Time.get_ticks_msec() - _touch_start

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			mm_globals.config.save("user://mm_config.ini")
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if _get_android_version() >= 36:
				if Time.get_ticks_msec() - last_go_back_request < 125:
					return
				last_go_back_request = Time.get_ticks_msec()

			back_pressed.emit()

			var main_window : MainWindow = get_node("/root/MainWindow")
			var exclude : PackedStringArray = PackedStringArray(["AddNodePopup"])
			var windows : Array[Window]

			if main_window:
				windows.append(_first_window_child(main_window, exclude))
				windows.append(_first_window_child(main_window.get_current_graph_edit(), exclude))

				# ask window to quit
				for window in windows:
					if window:
						window.close_requested.emit()
						return

				# exit app when no other dialogs are shown
				main_window.quit()

## Get display corner radius per corner.
func corner_radius(corner : Corner, scale : float = mm_globals.get_ui_scale()) -> int:
	return ceili(_display_corner_radii[corner] / scale)

## Get cutout margins per side.
func cutout_margins(side : Side, scale : float = mm_globals.get_ui_scale()) -> int:
	return ceili(_dispalay_cutout_margins[side] / scale)

func make_dialog_fullscreen(window : Window, show : bool = false) -> void:
	window.borderless = true
	window.size = mm_globals.main_window.size
	window.min_size = Vector2.ZERO
	window.position = Vector2.ZERO
	# offset by MM_MainBackground stylebox content margins
	window.position.x += maxi(0, calc_margins(Side.SIDE_LEFT) - 10)
	window.size.x -= (window.position.x + calc_margins(Side.SIDE_RIGHT))
	if show:
		window.show()

## Get display safe margins accounting for cutouts and corner radii.
## [param side] can be either Side.SIDE_LEFT or Side.SIDE_RIGHT
func calc_margins(side : Side, scale : float = mm_globals.get_ui_scale()) -> int:
	var top : int = cutout_margins(SIDE_TOP, scale)
	var bottom : int = cutout_margins(SIDE_BOTTOM, scale)
	match side:
		Side.SIDE_LEFT:
			var top_left : int = _inset(corner_radius(CORNER_TOP_LEFT, scale), top)
			var bottom_left : int = _inset(corner_radius(CORNER_BOTTOM_LEFT, scale), bottom)
			return maxi(maxi(top_left, bottom_left),  cutout_margins(SIDE_LEFT, scale))
		Side.SIDE_RIGHT:
			var top_right : int = _inset(corner_radius(CORNER_TOP_RIGHT, scale), top)
			var bottom_right : int = _inset(corner_radius(CORNER_BOTTOM_RIGHT, scale), bottom)
			return maxi(maxi(top_right, bottom_right), cutout_margins(SIDE_RIGHT, scale))
	return 0

func setup_margins(container : MarginContainer, margin_offset_left : int,
		margin_ofset_right : int = margin_offset_left) -> void:
	container.add_theme_constant_override("margin_left",
			maxi(0, calc_margins(Side.SIDE_LEFT) + margin_offset_left))
	container.add_theme_constant_override("margin_right",
			maxi(0, calc_margins(Side.SIDE_RIGHT) + margin_ofset_right))

## Allows a control to show its tooltip when tapped.
func handle_tap_show_tooltip(c : Control) -> void:
	if not c.gui_input.is_connected(_control_tap_show_tooltip.bind(c)):
		c.gui_input.connect(_control_tap_show_tooltip.bind(c))

func _first_window_child(node : Node, exclude_list : PackedStringArray) -> Window:
	if node != null:
		for w in node.get_children():
			if w is Window and w.name not in exclude_list:
				return w
	return null

func _inset(radius : int, y : int) -> int:
	return ceili(radius - sqrt(radius ** 2 - (y - radius) ** 2)) if y < radius else 0

func _get_corner_radius() -> PackedInt32Array:
	# github.com/godotengine/godot-proposals/issues/14056#issuecomment-3816832522
	var result : PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
	if not android_runtime:
		return result
	var version : JavaClass = JavaClassWrapper.wrap("android.os.Build$VERSION")

	# Available only on Android 12 and later
	if version.SDK_INT < 31:
		return result

	var insets : JavaObject = android_runtime.getActivity().getWindow().getDecorView().getRootWindowInsets()
	var RoundedCorner : JavaClass = JavaClassWrapper.wrap("android.view.RoundedCorner")

	var topLeft : JavaObject = insets.getRoundedCorner(RoundedCorner.POSITION_TOP_LEFT)
	var topRight : JavaObject  = insets.getRoundedCorner(RoundedCorner.POSITION_TOP_RIGHT)
	var bottomRight : JavaObject  = insets.getRoundedCorner(RoundedCorner.POSITION_BOTTOM_RIGHT)
	var bottomLeft : JavaObject  = insets.getRoundedCorner(RoundedCorner.POSITION_BOTTOM_LEFT)

	if is_instance_valid(topLeft):
		result[Corner.CORNER_TOP_LEFT] = topLeft.getRadius()
	if is_instance_valid(topRight):
		result[Corner.CORNER_TOP_RIGHT] = topRight.getRadius()
	if is_instance_valid(bottomRight):
		result[Corner.CORNER_BOTTOM_RIGHT] = bottomRight.getRadius()
	if is_instance_valid(bottomLeft):
		result[Corner.CORNER_BOTTOM_LEFT] = bottomLeft.getRadius()
	return result

func _get_cutout_margins() -> PackedInt32Array:
	var result : PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
	var safe_area : Rect2i = DisplayServer.get_display_safe_area()
	var screen_size : Vector2i = DisplayServer.screen_get_size()
	result[SIDE_LEFT] = safe_area.position.x
	result[SIDE_TOP] = safe_area.position.y
	result[SIDE_RIGHT] = screen_size.x - safe_area.end.x
	result[SIDE_BOTTOM] = screen_size.y - safe_area.end.y
	return result

func _get_android_version() -> int:
	if not android_runtime:
		return -1
	return JavaClassWrapper.wrap("android.os.Build$VERSION").SDK_INT

func _control_tap_show_tooltip(e : InputEvent, c : Control) -> void:
	if e is InputEventScreenTouch and e.pressed and e.index == 0:
		_show_tooltip(c.get_global_mouse_position(), c.tooltip_text)

func _show_tooltip(at : Vector2, text : String) -> void:
	if get_tree().root.has_node("TouchTooltipPanel"):
		get_tree().root.get_node("TouchTooltipPanel").queue_free()
	const margin : Vector2i = Vector2i(24, 24)
	var main_window : MainWindow = get_node("/root/MainWindow")

	var tool_tip_panel : PopupPanel = PopupPanel.new()
	tool_tip_panel.name = "TouchTooltipPanel"
	tool_tip_panel.theme = main_window.theme
	tool_tip_panel.theme_type_variation = "TooltipPanel"

	var label : Label = Label.new()
	label.text = text

	tool_tip_panel.add_child(label)
	tool_tip_panel.size = Vector2.ZERO
	get_tree().root.add_child(tool_tip_panel)
	var tsize : Vector2i = tool_tip_panel.get_contents_minimum_size()
	var vsize : Vector2i = get_viewport().get_visible_rect().size
	tool_tip_panel.position = at.clamp(margin, vsize - tsize - margin)
	tool_tip_panel.popup()
	tool_tip_panel.popup_hide.connect(tool_tip_panel.queue_free)
