extends Container


var flex_panel : Control
var updating : bool = false


func _ready():
	update()

func _notification(what):
	match what:
		NOTIFICATION_THEME_CHANGED:
			update()

func init(fp : Control):
	flex_panel = fp
	%Label.text = flex_panel.name

func get_flex_layout():
	var flex_tab = get_parent().get_parent().get_flex_tab()
	return flex_tab.flexible_layout

func update():
	%Close.texture_normal = get_theme_icon("close", "MM_FlexibleTab")
	%Close.modulate = get_theme_color("font_selected_color", "MM_FlexibleTab")
	%Undock.texture_normal = get_theme_icon("undock", "MM_FlexibleTab")
	%Undock.modulate = get_theme_color("font_selected_color", "MM_FlexibleTab")
	if not updating:
		updating = true
		var is_current: bool = (get_index() == get_parent().get_parent().current)
		add_theme_stylebox_override("panel", get_theme_stylebox("tab_selected" if is_current else "tab_unselected", "MM_FlexibleTab"))
		%Undock.visible = is_current and get_flex_layout().main_control.allow_undock
		%Close.visible = is_current
		%Label.add_theme_color_override("font_color", get_theme_color("font_selected_color" if is_current else "font_unselected_color", "MM_FlexibleTab") )
		updating = false

func _on_undock_pressed():
	get_flex_layout().undock(flex_panel)

func _on_close_pressed():
	var flex_tab = get_parent().get_parent().get_flex_tab()
	flex_tab.remove(flex_panel)
	flex_tab.flexible_layout.layout()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				get_parent().get_parent().set_current(get_index())
			MOUSE_BUTTON_MIDDLE:
				%Close.emit_signal("pressed")

func _get_drag_data(_position):
	return preload("res://addons/flexible_layout/flexible_layout.gd").PanelInfo.new(flex_panel)
