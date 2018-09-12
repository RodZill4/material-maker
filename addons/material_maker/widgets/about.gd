tool
extends WindowDialog


func _ready():
	if Engine.editor_hint:
		$VBoxContainer/VBoxContainer1/ApplicationName.text = "Material Maker"
	else:
		$VBoxContainer/VBoxContainer1/ApplicationName.text = ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/release")
	pass

func open_url(url):
	OS.shell_open(url)
