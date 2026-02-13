extends Popup

func _ready() -> void:
	content_scale_factor = mm_globals.ui_scale_factor()
	_on_panel_container_minimum_size_changed()
	popup_centered()

func set_text(t) -> void:
	$PanelContainer/MarginContainer/VBoxContainer/Step.text = t

func set_progress(p) -> void:
	$PanelContainer/MarginContainer/VBoxContainer/ProgressBar.value = p * 100.0

func _on_panel_container_minimum_size_changed() -> void:
	max_size = get_contents_minimum_size()
	move_to_center()
