extends Control

var highlight : StyleBoxFlat

var t : Tween

func _ready() -> void:
	if not OS.get_name() == "Android":
		queue_free()
		return
	show()

	var panel_sb : StyleBoxFlat = get_theme_stylebox("panel")
	panel_sb.set_corner_radius_all(3)
	panel_sb.corner_detail = 3
	add_theme_stylebox_override("panel", panel_sb)

	highlight = StyleBoxFlat.new()
	highlight.set_corner_radius_all(4)
	highlight.corner_detail = 3
	highlight.bg_color = Color.WEB_GRAY
	highlight.bg_color.a = 0.1
	highlight.set_expand_margin_all(4.0)

	var prefs : TabContainer = get_node("../TabContainer")
	for tab in prefs.get_children():
		for container in tab.get_child(0).get_children():
			if container is not Container:
				continue
			for control : Control in container.get_children():
				if control.get_script() in [BoolOption, EnumOption, FloatOption]:
					control.mouse_entered.connect(_item_mouse_entered.bind(container, control.tooltip_text))
					control.mouse_exited.connect(_item_mouse_exited.bind(container))
					container.mouse_entered.connect(_item_mouse_entered.bind(container, control.tooltip_text))
					container.mouse_exited.connect(_item_mouse_exited.bind(container))
					break

func setup_tween() -> void:
	var vs : VScrollBar = $MarginContainer/ScrollContainer.get_v_scroll_bar()
	if t:
		t.kill()

	# do not animate scroll if the text still fits
	if abs(vs.max_value -  $MarginContainer/ScrollContainer.size.y) > 5.0:
		t = create_tween().set_loops()
		t.tween_interval(1.5)
		t.tween_property(vs, "ratio", 1.0, 1.5)
		t.tween_interval(1.5)
		t.tween_property(vs, "ratio", 0.0, 1.5)

func _item_mouse_entered(c : Container, hint : String) -> void:
	var hint_lb : Label = $MarginContainer/ScrollContainer/TouchHintLabel
	highlight.draw.call_deferred(c.get_parent().get_canvas_item(), c.get_rect())
	hint_lb.text = hint.replacen("\n", " ")
	setup_tween.call_deferred()

func _item_mouse_exited(c : Container) -> void:
	c.get_parent().queue_redraw()
	var hint_lb : Label = $MarginContainer/ScrollContainer/TouchHintLabel
	hint_lb.text = ""
	if t:
		t.kill.call_deferred()
