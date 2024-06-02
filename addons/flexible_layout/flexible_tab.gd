extends Container


var flex_panel : Control


func _ready():
	$Container/Close.texture_normal = get_theme_icon("close", "TabBar")
	update()

func init(fp : Control):
	flex_panel = fp
	$Container/Label.text = flex_panel.name

func get_flex_layout():
	var flex_tab = get_parent().get_parent().get_flex_tab()
	return flex_tab.flexible_layout

func update():
	var is_current: bool = (get_index() == get_parent().get_parent().current)
	add_theme_stylebox_override("panel", get_theme_stylebox("tab_selected" if is_current else "tab_unselected", "MM_FlexibleTab"))
	$Container/Undock.visible = is_current and get_flex_layout().main_control.allow_undock
	$Container/Close.visible = is_current

func _on_undock_pressed():
	get_flex_layout().undock(flex_panel)

func _on_close_pressed():
	var flex_tab = get_parent().get_parent().get_flex_tab()
	flex_tab.remove(flex_panel)
	flex_tab.flexible_layout.layout()

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_parent().get_parent().set_current(get_index())

func _get_drag_data(_position):
	return preload("res://addons/flexible_layout/flexible_layout.gd").PanelInfo.new(flex_panel)
