extends HBoxContainer

const CONTROLS = [ "None", "P1.x", "P1.y", "P1.a", "P1.r", "P2.x", "P2.y", "P2.a", "P2.r", "P3.x", "P3.y", "P4.x", "P4.y", "Rect1.x", "Rect1.y", "Radius1.r", "Radius1.a", "Radius11.r", "Radius11.a", "Scale1.x", "Scale1.y", "Angle1.a", "Angle2.a" ]

const CONTROLS_PXY : Array[String] = ["P1.x", "P2.x", "P3.x", "P4.x", "P1.y", "P2.y", "P3.y", "P4.y"]

func _ready() -> void:
	$Control.clear()
	for c in CONTROLS:
		$Control.add_item(c)

func get_model_data() -> Dictionary:
	var data = {
		min = $Min.value,
		max = $Max.value,
		step = $Step.value,
		default = $Default.value,
		control = $Control.get_item_text($Control.selected),
		control_size = int($ControlSize/ControlLarge.visible),
	}
	return data

func set_model_data(data) -> void:
	if data.has("min"):
		$Min.value = data.min
		$Default.min_value = data.min
	if data.has("max"):
		$Max.value = data.max
		$Default.max_value = data.max
	if data.has("step"):
		$Step.value = data.step
		$Default.step = data.step
	if data.has("default"):
		$Default.value = data.default
	if data.has("control"):
		$Control.selected = 0
		for i in range($Control.get_item_count()):
			if data.control == $Control.get_item_text(i):
				$Control.selected = i
				_on_control_item_selected(i)
				break
		if data.control in CONTROLS_PXY:
			if "control_size" not in data:
				data.control_size = ControlPoint.DEFAULT_GIZMO_SIZES[data.control.split(".")[0]]
			$ControlSize/ControlSmall.visible = data.control_size == ControlPoint.GizmoSize.SMALL
			$ControlSize/ControlLarge.visible = data.control_size == ControlPoint.GizmoSize.LARGE
		else:
			$ControlSize.hide()

func _on_Min_value_changed(v : float) -> void:
	$Default.min_value = v

func _on_Max_value_changed(v : float) -> void:
	$Default.max_value = v

func _on_Step_value_changed(v : float) -> void:
	$Default.step = v

func _on_control_small_pressed() -> void:
	$ControlSize/ControlSmall.hide()
	$ControlSize/ControlLarge.show()

func _on_control_large_pressed() -> void:
	$ControlSize/ControlSmall.show()
	$ControlSize/ControlLarge.hide()

func _on_control_item_selected(index: int) -> void:
	$ControlSize.visible = CONTROLS_PXY.any(func(g: String):
		return CONTROLS[index] == g)
