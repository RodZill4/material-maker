extends Popup

func _ready() -> void:
	content_scale_factor = mm_globals.main_window.get_window().content_scale_factor
	popup_centered()

func set_text(t) -> void:
	$PanelContainer/VBoxContainer/Step.text = t

func set_progress(p) -> void:
	$PanelContainer/VBoxContainer/ProgressBar.value = p * 100.0
