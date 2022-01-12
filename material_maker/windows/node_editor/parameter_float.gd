extends HBoxContainer

const CONTROLS = [
	"None",
	"P1.x",
	"P1.y",
	"P1.a",
	"P1.r",
	"P2.x",
	"P2.y",
	"P2.a",
	"P2.r",
	"P3.x",
	"P3.y",
	"Rect1.x",
	"Rect1.y",
	"Radius1.r",
	"Radius1.a",
	"Radius11.r",
	"Radius11.a",
	"Scale1.x",
	"Scale1.y",
	"Angle1.a",
	"Angle2.a"
]


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
		control = $Control.get_item_text($Control.selected)
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
				break


func _on_Min_value_changed(v: float) -> void:
	$Default.min_value = v


func _on_Max_value_changed(v: float) -> void:
	$Default.max_value = v


func _on_Step_value_changed(v: float) -> void:
	$Default.step = v
