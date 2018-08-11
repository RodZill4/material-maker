extends WindowDialog


func _ready():
	$VBoxContainer/VBoxContainer1/ApplicationName.text = ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/release")
	pass

func open_url(url):
	OS.shell_open(url)
