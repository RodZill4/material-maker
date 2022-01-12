extends Popup


func _ready() -> void:
	popup_centered()


func set_text(t) -> void:
	$PanelContainer/VBoxContainer/Step.text = t


func set_progress(p) -> void:
	$PanelContainer/VBoxContainer/ProgressBar.value = p * 100.0
