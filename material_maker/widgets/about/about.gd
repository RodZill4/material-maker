extends WindowDialog


func _ready() -> void:
	if Engine.editor_hint:
		$VBoxContainer/VBoxContainer1/ApplicationName.text = "Material Maker"
	else:
		$VBoxContainer/VBoxContainer1/ApplicationName.text = ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/release")

func open_url(url) -> void:
	OS.shell_open(url)
