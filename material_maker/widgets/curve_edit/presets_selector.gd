extends MenuButton


func _enter_tree() -> void:
	get_popup().connect("id_pressed", self, "_menu_item_selected")
	var current_theme : Theme = get_node("/root/MainWindow").theme
	var path = "res://material_maker/theme/"
	if "light" in current_theme.resource_path:
		path += "light/"
	else:
		path += "dark/"
	
	get_popup().set_item_icon(0, load(path + "curve_preset_linear.png"))
	get_popup().set_item_icon(1, load(path + "curve_preset_easeout.png"))
	get_popup().set_item_icon(2, load(path + "curve_preset_easeinout.png"))
	get_popup().set_item_icon(3, load(path + "curve_preset_easein.png"))
	get_popup().set_item_icon(4, load(path + "curve_preset_sawtooth.png"))
	get_popup().set_item_icon(5, load(path + "curve_preset_bounce.png"))
	get_popup().set_item_icon(6, load(path + "curve_preset_bevel.png"))

func _exit_tree() -> void:
	get_popup().disconnect("id_pressed", self, "_menu_item_selected")

func _menu_item_selected(index : int) -> void:
	match(index):
		0:
			var new_curve = MMCurve.new()
			new_curve.clear()
			new_curve.add_point(0.0, 0.0, 0.0, 1.0)
			new_curve.add_point(1.0, 1.0, 1.0, 0.0)
			get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(new_curve)
		1:
			var new_curve = MMCurve.new()
			new_curve.clear()
			new_curve.add_point(0.0, 0.0, 0.0, 4.0)
			new_curve.add_point(0.292893, 0.707107, 1.0, 1.0)
			new_curve.add_point(1.0, 1.0, 0.0, 0.0)
			get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(new_curve)
		2:
			var new_curve = MMCurve.new()
			new_curve.clear()
			new_curve.add_point(0.0, 0.0, 0.0, 0.0)
			new_curve.add_point(0.5, 0.5, 3.0, 3.0)
			new_curve.add_point(1.0, 1.0, 0.0, 0.0)
			get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(new_curve)
		3:
			var new_curve = MMCurve.new()
			new_curve.clear()
			new_curve.add_point(0.0, 0.0, 0.0, 0.0)
			new_curve.add_point(0.707107, 0.292893, 1.0, 1.0)
			new_curve.add_point(1.0, 1.0, 4.0, 0.0)
			get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(new_curve)
		4:
			var new_curve = MMCurve.new()
			new_curve.clear()
			new_curve.add_point(0.0, 0.0, 0.0, 2.0)
			new_curve.add_point(0.5, 1.0, 2.0, -2.0)
			new_curve.add_point(1.0, 0.0, -2.0, 0.0)
			get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(new_curve)
		5:
			var new_curve = MMCurve.new()
			new_curve.clear()
			new_curve.add_point(0.0, 0.0, 0.0, 5.0)
			new_curve.add_point(0.15, 0.65, 2.45201, 2.45201)
			new_curve.add_point(0.5, 1.0, 0.0, 0.0)
			new_curve.add_point(0.85, 0.65, -2.45201, -2.45201)
			new_curve.add_point(1.0, 0.0, -5.0, 0.0)
			get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(new_curve)
		6:
			var new_curve = MMCurve.new()
			new_curve.clear()
			new_curve.add_point(0.0, 0.0, 0.0, 2.38507)
			new_curve.add_point(0.292893, 0.707107, 2.34362, 0.428147)
			new_curve.add_point(1.0, 1.0, 0.410866, 0.0)
			get_parent().get_parent().get_node("EditorContainer/CurveEditor").set_curve(new_curve)
