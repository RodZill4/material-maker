extends WindowDialog

onready var application_name_label = $HBoxContainer/VBoxContainer/HBoxContainer3/VBoxContainer/ApplicationName
onready var authors_grid = $HBoxContainer/VBoxContainer/VBoxContainer/Authors

const CONTRIBUTORS = [
	{ name="Rodolphe Suescun", contribution="Lead developer" },
	{ name="Hugo Locurcio", contribution="Lots of contributions, mostly related to UI and rendering" },
]

func _ready() -> void:
	if Engine.editor_hint:
		application_name_label.text = "Material Maker"
	else:
		application_name_label.text = ProjectSettings.get_setting("application/config/name")+" v"+ProjectSettings.get_setting("application/config/actual_release")
	for c in CONTRIBUTORS:
		var label : Label = Label.new()
		label.text = c.name
		authors_grid.add_child(label)
		label = Label.new()
		label.text = c.contribution
		authors_grid.add_child(label)

func open_url(url) -> void:
	OS.shell_open(url)
