extends Window

signal return_values(values)

func _ready():
	content_scale_factor = mm_globals.ui_scale_factor()
	min_size = Vector2(450, 60) * content_scale_factor

func _on_OK_pressed() -> void:
	emit_signal("return_values", { min=$VBoxContainer/float/Min.value, max=$VBoxContainer/float/Max.value, step=$VBoxContainer/float/Step.value, default=$VBoxContainer/float/Default.value} )

func _on_Cancel_pressed() -> void:
	emit_signal("return_values", {})

func _on_PopupDialog_popup_hide() -> void:
	emit_signal("return_values", {})

func configure_param(minimum : float = 0.0, maximum : float = 1.0, step : float = 0.01, default : float = 0.5) -> Dictionary:
	$VBoxContainer/float/Min.set_value(minimum)
	$VBoxContainer/float/Max.set_value(maximum)
	$VBoxContainer/float/Step.set_value(step)
	$VBoxContainer/float/Default.set_value(default)
	hide()
	popup_centered()
	var result = await self.return_values
	queue_free()
	return result
