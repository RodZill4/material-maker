extends Popup

func _ready() -> void:
	content_scale_factor = mm_globals.ui_scale_factor()
	popup_centered()

func set_text(t) -> void:
	$PanelContainer/MarginContainer/VBoxContainer/Step.text = t

func set_progress(p) -> void:
	$PanelContainer/MarginContainer/VBoxContainer/ProgressBar.value = p * 100.0
