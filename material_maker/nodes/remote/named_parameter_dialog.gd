extends WindowDialog

signal return_values(values)


func _ready():
	pass  # Replace with function body.


func _on_OK_pressed() -> void:
	emit_signal(
		"return_values",
		{
			min = $VBoxContainer/float/Min.value,
			max = $VBoxContainer/float/Max.value,
			step = $VBoxContainer/float/Step.value,
			default = $VBoxContainer/float/Default.value
		}
	)


func _on_Cancel_pressed() -> void:
	emit_signal("return_values", {})


func _on_PopupDialog_popup_hide() -> void:
	emit_signal("return_values", {})


func configure_param(
	minimum: float = 0.0, maximum: float = 1.0, step: float = 0.01, default: float = 0.5
) -> Array:
	$VBoxContainer/float/Min.set_value(minimum)
	$VBoxContainer/float/Max.set_value(maximum)
	$VBoxContainer/float/Step.set_value(step)
	$VBoxContainer/float/Default.set_value(default)
	popup_centered()
	var result = yield(self, "return_values")
	queue_free()
	return result
