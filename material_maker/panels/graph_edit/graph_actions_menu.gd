extends PanelContainer

var graph : MMGraphEdit

func _ready() -> void:
	if OS.get_name() != "Android":
		hide()

func _on_knife_tool_toggled(toggled_on : bool) -> void:
	if not graph:
		graph = mm_globals.main_window.get_current_graph_edit()
	if toggled_on:
		if not graph.cut_drag_finished.is_connected(reset_knife_action_button):
			graph.cut_drag_finished.connect(reset_knife_action_button)
		should_hide_selection_rect(true)
		should_disable_graph_elements(true)
		graph.drag_cut_line.clear()
	else:
		reset_knife_action_button()
	graph.valid_drag_cut_entry = toggled_on

func reset_knife_action_button() -> void:
	$HBox/KnifeTool.hide()
	$HBox/KnifeTool.show.call_deferred()
	$HBox/KnifeTool.set_pressed_no_signal(false)
	should_disable_graph_elements(false)
	should_hide_selection_rect(false)

func should_hide_selection_rect(is_hide : bool) -> void:
	if is_hide:
		graph.add_theme_color_override("selection_fill", Color.TRANSPARENT)
		graph.add_theme_color_override("selection_stroke", Color.TRANSPARENT)
	else:
		graph.remove_theme_color_override("selection_fill")
		graph.remove_theme_color_override("selection_stroke")

func should_disable_graph_elements(disable : bool) -> void:
	for x in graph.get_children():
		if x is GraphElement:
			x.modulate.a = 0.5 if disable else 1.0
			x.selectable = not disable
