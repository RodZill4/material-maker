class_name PreferenceTouchHint
extends PanelContainer

var highlight : StyleBoxFlat
var t : Tween
@onready var hint_label : Label = $MarginContainer/ScrollContainer/TouchHintLabel

func _ready() -> void:
	_update_visibility()
	_setup_hints()
	_setup_highlight()

func _setup_tween() -> void:
	var sc : ScrollContainer = $MarginContainer/ScrollContainer
	var vs : VScrollBar = sc.get_v_scroll_bar()
	if t:
		t.kill()

	var dist : float = abs(vs.max_value -  vs.page)

	# do not animate scroll if the text still fits
	if dist <= 5.0:
		return

	t = create_tween().set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(1.75)
	t.tween_property(vs, "value", vs.min_value + dist, 1.75)
	t.tween_interval(2.0)
	t.tween_property(vs, "value", vs.min_value, 1.75)

func _item_mouse_entered(c : Container, hint : String) -> void:
	hint_label.text = hint.replacen("\n", " ")
	await get_tree().process_frame
	await get_tree().process_frame
	highlight.draw(c.get_parent().get_canvas_item(), c.get_rect())
	_setup_tween()

func _item_mouse_exited(c : Container) -> void:
	hint_label.text = ""
	c.get_parent().queue_redraw()
	if t:
		t.kill.call_deferred()

func _update_visibility() -> void:
	if not mm_globals.get_config("touch_optimization"):
		queue_free()
		return
	show()

func _setup_hints() -> void:
	var prefs : TabContainer = get_node("../TabContainer")
	for tab in prefs.get_children():
		for container in tab.get_child(0).get_children():
			if container is not Container:
				continue
			for control : Control in container.get_children():
				if control.get_script() in [ BoolOption,
						EnumOption, FloatOption, ColorOption, EnumChecklist]:
					control.mouse_entered.connect(
							_item_mouse_entered.bind(container, control.tooltip_text))
					container.mouse_entered.connect(
							_item_mouse_entered.bind(container, control.tooltip_text))
					control.mouse_exited.connect(_item_mouse_exited.bind(container))
					container.mouse_exited.connect(_item_mouse_exited.bind(container))
					break

func _setup_highlight() -> void:
	highlight = StyleBoxFlat.new()
	highlight.set_corner_radius_all(4)
	highlight.corner_detail = 3
	highlight.bg_color = Color.WEB_GRAY
	highlight.bg_color.a = 0.1
	highlight.set_expand_margin_all(4.0)
